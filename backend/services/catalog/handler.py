import json
import math
import boto3
import uuid
import os
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla_productos = dynamodb.Table('Productos')
tabla_mensajes = dynamodb.Table('Mensajes')
tabla_usuarios = dynamodb.Table('Usuarios')
s3_client = boto3.client('s3', region_name='us-east-1')
BUCKET_NAME = os.environ.get('BUCKET_NAME', 'truequi-images-dm2026')

def respuesta(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Access-Control-Allow-Origin": "*", "Access-Control-Allow-Headers": "Content-Type", "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"},
        "body": json.dumps(body)
    }

# ==========================================
# 1. PUBLICAR PRODUCTO
# ==========================================
def crear_producto(event, context):
    try:
        body = json.loads(event['body'])
        item = {
            'id': str(uuid.uuid4()), 'titulo': body.get('titulo').strip(), 'descripcion': str(body.get('descripcion')).strip()[:500],
            'precio': str(float(body.get('precio'))), 'categoria': str(body.get('categoria'))[:50], 'vendedorId': str(body.get('vendedorId')),
            'vendedorNombre': str(body.get('vendedorNombre')), 'ubicacion': str(body.get('ubicacion', 'Querétaro')),
            'imagenUrl': str(body.get('imagenUrl', '')), 'estado': 'Disponible', 'fechaCreacion': datetime.now(timezone.utc).isoformat()
        }
        tabla_productos.put_item(Item=item)
        return respuesta(201, {"message": "Producto publicado", "producto": item})
    except Exception as e: return respuesta(500, {"error": str(e)})

# ==========================================
# 2. FEED DE PRODUCTOS (SOLO DISPONIBLES)
# ==========================================
def obtener_productos(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        categoria, busqueda = query_params.get('categoria'), query_params.get('q', '').strip().lower()
        response = tabla_productos.scan(Limit=300)
        
        # FILTRO CRÍTICO: Solo mostrar productos con estado "Disponible"
        items = [i for i in response.get('Items', []) if i.get('estado', 'Disponible') == 'Disponible']

        if categoria and categoria != 'Todas': items = [i for i in items if i.get('categoria', '').lower() == categoria.lower()]
        if busqueda: items = [i for i in items if busqueda in i.get('titulo', '').lower() or busqueda in i.get('descripcion', '').lower()]
        items.sort(key=lambda x: x.get('fechaCreacion', ''), reverse=True)

        return respuesta(200, {"status": "success", "total": len(items), "productos": items})
    except Exception as e: return respuesta(500, {"error": str(e)})

# ==========================================
# 3. ELIMINAR PRODUCTO PROPIO
# ==========================================
def eliminar_producto(event, context):
    try:
        producto_id = (event.get('pathParameters') or {}).get('id')
        if not producto_id: return respuesta(400, {"error": "Falta ID."})
        tabla_productos.delete_item(Key={'id': str(producto_id)})
        return respuesta(200, {"message": "Producto eliminado del catálogo."})
    except Exception as e: return respuesta(500, {"error": str(e)})

# ==========================================
# 4. URL S3
# ==========================================
def obtener_upload_url(event, context):
    try:
        ext = (event.get('queryStringParameters') or {}).get('ext', 'jpg').replace('.', '').lower()
        file_name = f"{uuid.uuid4()}.{ext}"
        url = s3_client.generate_presigned_url('put_object', Params={'Bucket': BUCKET_NAME, 'Key': file_name}, ExpiresIn=300)
        return respuesta(200, {"uploadUrl": url, "publicUrl": f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}"})
    except Exception as e: return respuesta(500, {"error": str(e)})

# ==========================================
# 5. PERFIL DE USUARIO
# ==========================================
def obtener_perfil(event, context):
    try:
        vendedor_id = (event.get('pathParameters') or {}).get('id')
        response = tabla_productos.query(IndexName='VendedorIndex', KeyConditionExpression='vendedorId = :vid', ExpressionAttributeValues={':vid': str(vendedor_id)})
        user = tabla_usuarios.get_item(Key={'correo': str(vendedor_id)}).get('Item', {})
        user.pop('password', None)
        return respuesta(200, {"usuario": user, "misProductos": response.get('Items', [])})
    except Exception as e: return respuesta(500, {"error": str(e)})

def actualizar_perfil(event, context):
    try:
        body = json.loads(event['body'])
        correo = body.get('correo')
        update_expr, expr_values, expr_names = [], {}, {}

        if body.get('nombre'):
            update_expr.append("#n = :nom")
            expr_values[":nom"], expr_names["#n"] = str(body['nombre']).strip(), "nombre"
        if body.get('fotoUrl'):
            update_expr.append("foto = :foto")
            expr_values[":foto"] = str(body['fotoUrl']).strip()

        if not update_expr: return respuesta(400, {"error": "Sin datos"})
        kwargs = {"Key": {'correo': str(correo)}, "UpdateExpression": "SET " + ", ".join(update_expr), "ExpressionAttributeValues": expr_values, "ReturnValues": "ALL_NEW"}
        if expr_names: kwargs["ExpressionAttributeNames"] = expr_names

        res = tabla_usuarios.update_item(**kwargs)
        user = res.get('Attributes', {})
        user.pop('password', None)
        return respuesta(200, {"usuario": user})
    except Exception as e: return respuesta(500, {"error": str(e)})

def calificar_usuario(event, context):
    try:
        body = json.loads(event['body'])
        correo, nueva_estrellas = body.get('correo'), float(body.get('estrellas', 5.0))

        user = tabla_usuarios.get_item(Key={'correo': str(correo)}).get('Item', {})
        total, promedio = int(user.get('totalCalificaciones', 0)), float(user.get('promedio', 5.0))

        nuevo_total = total + 1
        nuevo_promedio = ((promedio * total) + nueva_estrellas) / nuevo_total

        tabla_usuarios.update_item(Key={'correo': str(correo)}, UpdateExpression="SET promedio = :p, totalCalificaciones = :t", ExpressionAttributeValues={':p': str(round(nuevo_promedio, 1)), ':t': nuevo_total})
        return respuesta(200, {"message": "Calificación guardada"})
    except Exception as e: return respuesta(500, {"error": str(e)})

# ==========================================
# 6. MENSAJERÍA
# ==========================================
def crear_mensaje(event, context):
    try:
        body = json.loads(event['body'])
        remitente, destinatario = str(body.get('remitente', '')).strip().lower(), str(body.get('destinatario', '')).strip().lower()
        if remitente == 'invitado' or remitente == destinatario: return respuesta(400, {"error": "Acción no permitida."})
        conversacion_id = body.get('conversacionId') or f"{body.get('productoId')}_{sorted([remitente, destinatario])[0]}_{sorted([remitente, destinatario])[1]}"

        item = {'id': str(uuid.uuid4()), 'conversacionId': conversacion_id, 'remitente': remitente, 'destinatario': destinatario, 'productoId': body.get('productoId'), 'productoTitulo': body.get('productoTitulo'), 'contenido': body.get('contenido')[:500], 'fecha': datetime.now(timezone.utc).isoformat(), 'estado': body.get('estado', 'Pendiente')}
        tabla_mensajes.put_item(Item=item)
        return respuesta(201, {"mensaje": item})
    except Exception as e: return respuesta(500, {"error": str(e)})

def obtener_mensajes(event, context):
    try:
        usuario = (event.get('queryStringParameters') or {}).get('usuario')
        res_rec = tabla_mensajes.query(IndexName='DestinatarioIndex', KeyConditionExpression='destinatario = :u', ExpressionAttributeValues={':u': str(usuario)})
        res_env = tabla_mensajes.query(IndexName='RemitenteIndex', KeyConditionExpression='remitente = :u', ExpressionAttributeValues={':u': str(usuario)})
        mapa = {m['id']: m for m in res_rec.get('Items', []) + res_env.get('Items', [])}
        mensajes = list(mapa.values())
        mensajes.sort(key=lambda x: x.get('fecha', ''), reverse=True)
        return respuesta(200, {"mensajes": mensajes})
    except Exception as e: return respuesta(500, {"error": str(e)})

def actualizar_estado_mensaje(event, context):
    try:
        mensaje_id = (event.get('pathParameters') or {}).get('id')
        nuevo_estado = json.loads(event['body']).get('estado')

        res = tabla_mensajes.update_item(Key={'id': str(mensaje_id)}, UpdateExpression="SET estado = :est", ExpressionAttributeValues={':est': nuevo_estado}, ReturnValues="ALL_NEW")
        
        # SI SE ACEPTA O COMPLETA, EL PRODUCTO DESAPARECE DEL CATÁLOGO (ESTADO = COMPLETADO)
        if nuevo_estado in ['Aceptado', 'Completado']:
            msg = tabla_mensajes.get_item(Key={'id': str(mensaje_id)}).get('Item', {})
            if msg and 'productoId' in msg:
                tabla_productos.update_item(Key={'id': msg['productoId']}, UpdateExpression="SET estado = :e", ExpressionAttributeValues={':e': 'Completado'})

        return respuesta(200, {"mensaje": res.get('Attributes', {})})
    except Exception as e: return respuesta(500, {"error": str(e)})