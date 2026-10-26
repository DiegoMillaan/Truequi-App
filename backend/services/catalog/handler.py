import json
import math
import re
import boto3
import uuid
import os
import random
from datetime import datetime, timezone
from decimal import Decimal

class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            if obj % 1 == 0:
                return int(obj)
            return float(obj)
        return super(DecimalEncoder, self).default(obj)

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla_productos = dynamodb.Table('Productos')
tabla_mensajes = dynamodb.Table('Mensajes')
tabla_usuarios = dynamodb.Table('Usuarios')
s3_client = boto3.client('s3', region_name='us-east-1')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'truequi-images-dm2026')

def respuesta(status_code, body):
    return {
        "statusCode": status_code, 
        "headers": {
            "Access-Control-Allow-Origin": "*", 
            "Access-Control-Allow-Headers": "Content-Type", 
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"
        }, 
        "body": json.dumps(body, cls=DecimalEncoder)
    }

# ==========================================
# 1. PUBLICAR PRODUCTO
# ==========================================
def crear_producto(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        titulo = body.get('titulo', '').strip()
        descripcion = body.get('descripcion', '').strip()
        
        # 1. Validación contra artículos o servicios ilícitos (Punto 9)
        termino_detectado = contiene_contenido_ilicito(f"{titulo} {descripcion}")
        if termino_detectado:
            return respuesta(400, {
                'error': f'Publicación rechazada por políticas de seguridad: se detectó contenido no permitido ({termino_detectado}).'
            })

        # 2. Validación de ubicación en la ZMQ (Punto 11)
        lat = body.get('latitud')
        lng = body.get('longitud')
        if lat is not None and lng is not None:
            if not esta_en_zmq(float(lat), float(lng)):
                return respuesta(403, {
                    'error': 'Solo se permiten publicaciones dentro de la Zona Metropolitana de Querétaro.'
                })

        # 3. Soporte para hasta 5 imágenes manteniendo compatibilidad (Punto 13)
        imagenes_urls = body.get('imagenesUrls', [])
        imagen_principal = body.get('imagenUrl') or (imagenes_urls[0] if imagenes_urls else '')
        if not imagenes_urls and imagen_principal:
            imagenes_urls = [imagen_principal]
        imagenes_urls = imagenes_urls[:5]  # Máximo 5 imágenes

        nuevo_item = {
            'id': str(uuid.uuid4()),
            'titulo': titulo,
            'descripcion': descripcion,
            'precio': str(body.get('precio', '0')),
            'categoria': body.get('categoria', 'General'),
            'municipio': body.get('municipio', 'Santiago de Querétaro'),
            'imagenUrl': imagen_principal,
            'imagenesUrls': imagenes_urls,
            'vendedorId': body.get('vendedorId', ''),
            'vendedorNombre': body.get('vendedorNombre', 'Usuario'),
            'estado': 'Disponible',
            'estadoModeracion': 'Aprobado',
            'fechaCreacion': datetime.now(timezone.utc).isoformat()
        }

        tabla_productos.put_item(Item=nuevo_item)
        return respuesta(201, {'mensaje': 'Producto creado', 'producto': nuevo_item})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 2. FEED DE PRODUCTOS (SOLO DISPONIBLES)
# ==========================================
def obtener_productos(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        categoria, busqueda = query_params.get('categoria'), query_params.get('q', '').strip().lower()
        response = tabla_productos.scan(Limit=300)
        items = [i for i in response.get('Items', []) if i.get('estado', 'Disponible') == 'Disponible']
        if categoria and categoria != 'Todas':
            items = [i for i in items if i.get('categoria', '').lower() == categoria.lower()]
        if busqueda:
            items = [i for i in items if busqueda in i.get('titulo', '').lower() or busqueda in i.get('descripcion', '').lower()]
        items.sort(key=lambda x: x.get('fechaCreacion', ''), reverse=True)
        return respuesta(200, {"status": "success", "total": len(items), "productos": items})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 3. ELIMINAR PRODUCTO PROPIO
# ==========================================
def eliminar_producto(event, context):
    try:
        producto_id = (event.get('pathParameters') or {}).get('id')
        if not producto_id:
            return respuesta(400, {"error": "Falta ID."})
        tabla_productos.delete_item(Key={'id': str(producto_id)})
        return respuesta(200, {"message": "Producto eliminado del catálogo."})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 4. URL S3
# ==========================================
def obtener_upload_url(event, context):
    try:
        ext = (event.get('queryStringParameters') or {}).get('ext', 'jpg').replace('.', '').lower()
        file_name = f"{uuid.uuid4()}.{ext}"
        url = s3_client.generate_presigned_url('put_object', Params={'Bucket': BUCKET_NAME, 'Key': file_name}, ExpiresIn=300)
        return respuesta(200, {"uploadUrl": url, "publicUrl": f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}"})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 5. PERFIL DE USUARIO
# ==========================================
def obtener_perfil(event, context):
    try:
        vendedor_id = (event.get('pathParameters') or {}).get('id')
        response = tabla_productos.query(
            IndexName='VendedorIndex',
            KeyConditionExpression='vendedorId = :vid',
            ExpressionAttributeValues={':vid': str(vendedor_id)}
        )
        user = tabla_usuarios.get_item(Key={'correo': str(vendedor_id)}).get('Item', {})
        user.pop('password', None)
        return respuesta(200, {"usuario": user, "misProductos": response.get('Items', [])})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def actualizar_perfil(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        correo = body.get('correo')
        if not correo:
            return respuesta(400, {'error': 'Correo requerido'})

        res = tabla_usuarios.get_item(Key={'correo': str(correo)})
        usuario = res.get('Item', {
            'correo': str(correo),
            'promedio': '5.0',
            'totalCalificaciones': 0,
            'truequesCompletados': 0,
            'favoritos': []
        })

        if 'nombre' in body:
            usuario['nombre'] = body['nombre']
        if 'fotoUrl' in body:
            usuario['fotoUrl'] = body['fotoUrl']
        if 'telefono' in body:
            usuario['telefono'] = body['telefono']
        if 'favoritos' in body and isinstance(body['favoritos'], list):
            usuario['favoritos'] = body['favoritos']

        tabla_usuarios.put_item(Item=usuario)
        return respuesta(200, {'mensaje': 'Perfil actualizado', 'usuario': usuario})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def calificar_usuario(event, context):
    try:
        body = json.loads(event['body'])
        correo, nueva_estrellas = body.get('correo'), float(body.get('estrellas', 5.0))
        user = tabla_usuarios.get_item(Key={'correo': str(correo)}).get('Item', {})
        total, promedio = int(user.get('totalCalificaciones', 0)), float(user.get('promedio', 5.0))
        nuevo_total = total + 1
        nuevo_promedio = ((promedio * total) + nueva_estrellas) / nuevo_total
        tabla_usuarios.update_item(
            Key={'correo': str(correo)},
            UpdateExpression="SET promedio = :p, totalCalificaciones = :t",
            ExpressionAttributeValues={':p': str(round(nuevo_promedio, 1)), ':t': nuevo_total}
        )
        return respuesta(200, {"message": "Calificación guardada"})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 6. MENSAJERÍA Y VALIDACIÓN DE PIN (CON PUNTO 14)
# ==========================================
def crear_mensaje(event, context):
    try:
        body = json.loads(event['body'])
        remitente, destinatario = str(body.get('remitente', '')).strip().lower(), str(body.get('destinatario', '')).strip().lower()
        if remitente == 'invitado' or remitente == destinatario:
            return respuesta(400, {"error": "Acción no permitida."})
        conversacion_id = body.get('conversacionId') or f"{body.get('productoId')}_{sorted([remitente, destinatario])[0]}_{sorted([remitente, destinatario])[1]}"
        item = {
            'id': str(uuid.uuid4()),
            'conversacionId': conversacion_id,
            'remitente': remitente,
            'destinatario': destinatario,
            'productoId': body.get('productoId'),
            'productoTitulo': body.get('productoTitulo'),
            'contenido': body.get('contenido')[:500],
            'fecha': datetime.now(timezone.utc).isoformat(),
            'estado': body.get('estado', 'Pendiente')
        }
        tabla_mensajes.put_item(Item=item)
        return respuesta(201, {"mensaje": item})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def obtener_mensajes(event, context):
    try:
        usuario = (event.get('queryStringParameters') or {}).get('usuario')
        res_rec = tabla_mensajes.query(IndexName='DestinatarioIndex', KeyConditionExpression='destinatario = :u', ExpressionAttributeValues={':u': str(usuario)})
        res_env = tabla_mensajes.query(IndexName='RemitenteIndex', KeyConditionExpression='remitente = :u', ExpressionAttributeValues={':u': str(usuario)})
        mapa = {m['id']: m for m in res_rec.get('Items', []) + res_env.get('Items', [])}
        mensajes = list(mapa.values())
        mensajes.sort(key=lambda x: x.get('fecha', ''), reverse=True)
        return respuesta(200, {"mensajes": mensajes})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def actualizar_estado_mensaje(event, context):
    try:
        mensaje_id = (event.get('pathParameters') or {}).get('id')
        body = json.loads(event['body'])
        nuevo_estado = body.get('estado')

        # Si el vendedor ACEPTA, generamos el PIN de Doble Candado
        if nuevo_estado == 'Aceptado':
            pin_secreto = str(random.randint(1000, 9999))
            res = tabla_mensajes.update_item(
                Key={'id': str(mensaje_id)}, 
                UpdateExpression="SET estado = :est, pinValidacion = :pin", 
                ExpressionAttributeValues={':est': nuevo_estado, ':pin': pin_secreto}, 
                ReturnValues="ALL_NEW"
            )
        
        # Si el vendedor intenta COMPLETAR, verificamos el PIN cruzado
        elif nuevo_estado == 'Completado':
            pin_ingresado = body.get('pin')
            msg_actual = tabla_mensajes.get_item(Key={'id': str(mensaje_id)}).get('Item', {})
            
            # Validación de Seguridad Zero-Trust
            if msg_actual.get('pinValidacion') and msg_actual.get('pinValidacion') != pin_ingresado:
                return respuesta(400, {"error": "PIN Incorrecto. El trueque no puede validarse."})

            ya_estaba_completado = msg_actual.get('estado') == 'Completado'

            res = tabla_mensajes.update_item(
                Key={'id': str(mensaje_id)}, 
                UpdateExpression="SET estado = :est", 
                ExpressionAttributeValues={':est': nuevo_estado}, 
                ReturnValues="ALL_NEW"
            )

            # Retirar producto definitivamente
            if 'productoId' in msg_actual:
                tabla_productos.update_item(
                    Key={'id': msg_actual['productoId']},
                    UpdateExpression="SET estado = :e",
                    ExpressionAttributeValues={':e': 'Completado'}
                )

            # PUNTO 14: INCREMENTAR EL CONTADOR REAL DE TRUEQUES EN AMBOS PERFILES
            if not ya_estaba_completado:
                usuarios_involucrados = set(filter(None, [
                    msg_actual.get('remitente'),
                    msg_actual.get('destinatario')
                ]))
                for correo_usr in usuarios_involucrados:
                    tabla_usuarios.update_item(
                        Key={'correo': str(correo_usr)},
                        UpdateExpression="ADD truequesCompletados :inc",
                        ExpressionAttributeValues={':inc': Decimal(1)}
                    )
        
        # Para Rechazado
        else:
            res = tabla_mensajes.update_item(
                Key={'id': str(mensaje_id)},
                UpdateExpression="SET estado = :est",
                ExpressionAttributeValues={':est': nuevo_estado},
                ReturnValues="ALL_NEW"
            )

        return respuesta(200, {"mensaje": res.get('Attributes', {})})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# PUNTO 9: DICCIONARIO DE MODERACIÓN AUTOMÁTICA
# ==========================================
PALABRAS_ILICITAS = [
    'droga', 'marihuana', 'weed', 'cocaína', 'cocaina', 'metanfetamina', 'cristal',
    'fentanilo', 'lsd', 'hongos alucinogenos', 'vape', 'vaper', 'wax', 'thc',
    'arma', 'pistola', 'revolver', 'rifle', 'escopeta', 'municiones', 'balas',
    'navaja automatica', 'taser', 'explosivo', 'pirotecnia',
    'clonazepam', 'ivotril', 'rivotril', 'alprazolam', 'xanax', 'receta medica',
    'hackeo', 'cuenta robada', 'tarjetas clonadas', 'billetes falsos', 'ine falsa',
    'factura falsa', 'prostitucion', 'escort', 'contenido adulto', 'onlyfans',
    'animales exoticos', 'pirateria'
]

def contiene_contenido_ilicito(texto: str) -> str | None:
    texto_limpio = texto.lower()
    for palabra in PALABRAS_ILICITAS:
        patron = r'\b' + re.escape(palabra) + r'\b'
        if re.search(patron, texto_limpio) or palabra in texto_limpio:
            return palabra
    return None

# ==========================================
# PUNTO 11: GEOCERCA ZONA METROPOLITANA DE QUERÉTARO
# Centro ZMQ: (20.5888, -100.3899) | Radio permitido: 35 km
# ==========================================
def esta_en_zmq(lat: float, lng: float) -> bool:
    lat_centro, lng_centro = 20.5888, -100.3899
    radio_tierra_km = 6371.0
    d_lat = math.radians(lat - lat_centro)
    d_lng = math.radians(lng - lng_centro)
    a = (math.sin(d_lat / 2) ** 2 +
         math.cos(math.radians(lat_centro)) * math.cos(math.radians(lat)) *
         math.sin(d_lng / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distancia_km = radio_tierra_km * c
    return distancia_km <= 35.0