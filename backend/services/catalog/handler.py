import json
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
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }

# ==========================================
# 1. PUBLICAR PRODUCTO (BLINDAJE DE NEGOCIO)
# ==========================================
def crear_producto(event, context):
    try:
        if not event.get('body'):
            return respuesta(400, {"error": "El cuerpo de la petición está vacío."})
        
        try:
            body = json.loads(event['body'])
        except json.JSONDecodeError:
            return respuesta(400, {"error": "Formato JSON inválido."})
        
        titulo = body.get('titulo')
        precio = body.get('precio')
        descripcion = body.get('descripcion', '')
        categoria = body.get('categoria', 'General')
        vendedorId = body.get('vendedorId')
        vendedorNombre = body.get('vendedorNombre', str(vendedorId))
        ubicacion = body.get('ubicacion', 'Querétaro')
        imagenUrl = body.get('imagenUrl', '')

        if not titulo or not isinstance(titulo, str) or len(titulo.strip()) < 5 or len(titulo) > 80:
            return respuesta(400, {"error": "El título debe tener entre 5 y 80 caracteres."})
        
        if not descripcion or not isinstance(descripcion, str) or len(descripcion.strip()) < 15:
            return respuesta(400, {"error": "La descripción es muy corta. Añade al menos 15 caracteres."})
        
        try:
            precio_num = float(precio)
        except (ValueError, TypeError):
            return respuesta(400, {"error": "El precio debe ser un número válido."})

        if precio_num <= 0 or precio_num > 100000:
            return respuesta(400, {"error": "El valor estimado debe ser mayor a $0 y menor a $100,000 MXN."})
            
        if not vendedorId or not isinstance(vendedorId, (int, str)):
            return respuesta(400, {"error": "El identificador del vendedor es inválido."})

        item = {
            'id': str(uuid.uuid4()),
            'titulo': titulo.strip(),
            'descripcion': str(descripcion).strip()[:500],
            'precio': str(precio_num), 
            'categoria': str(categoria)[:50],
            'vendedorId': str(vendedorId),
            'vendedorNombre': str(vendedorNombre),
            'ubicacion': str(ubicacion),
            'imagenUrl': str(imagenUrl),
            'fechaCreacion': datetime.now(timezone.utc).isoformat()
        }
        
        tabla_productos.put_item(Item=item)
        return respuesta(201, {"message": "Producto publicado exitosamente", "producto": item})

    except Exception as e:
        return respuesta(500, {"error": f"Error interno del servidor: {str(e)}"})

# ==========================================
# 2. FEED DE PRODUCTOS (CON BÚSQUEDA, FILTRO Y PAGINACIÓN)
# ==========================================
def obtener_productos(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        categoria = query_params.get('categoria')
        busqueda = query_params.get('q', '').strip().lower()
        limite = int(query_params.get('limit', 50))

        response = tabla_productos.scan(Limit=100)
        items = response.get('Items', [])

        if categoria and categoria != 'Todos':
            items = [i for i in items if i.get('categoria', '').lower() == categoria.lower()]

        if busqueda:
            items = [
                i for i in items 
                if busqueda in i.get('titulo', '').lower() or busqueda in i.get('descripcion', '').lower()
            ]

        items = items[:limite]
        return respuesta(200, {"status": "success", "total": len(items), "productos": items})
    except Exception as e:
        return respuesta(500, {"error": f"Error al consultar base de datos: {str(e)}"})

# ==========================================
# 3. URL PARA SUBIR IMÁGENES A S3 (PRODUCTOS Y PERFILES)
# ==========================================
def obtener_upload_url(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        extension = query_params.get('ext', 'jpg').replace('.', '').lower()
        carpeta = query_params.get('folder', '').strip('/')
        
        if extension not in ['jpg', 'jpeg', 'png', 'webp']:
            return respuesta(400, {"error": "Formato de imagen no permitido (solo JPG, PNG, WEBP)."})

        unique_name = f"{uuid.uuid4()}.{extension}"
        file_name = f"{carpeta}/{unique_name}" if carpeta else unique_name

        url = s3_client.generate_presigned_url(
            'put_object', 
            Params={'Bucket': BUCKET_NAME, 'Key': file_name}, 
            ExpiresIn=300
        )
        
        imagen_publica_url = f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}"
        return respuesta(200, {"uploadUrl": url, "fileName": file_name, "publicUrl": imagen_publica_url})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 4. PERFIL DE USUARIO (LECTURA Y ACTUALIZACIÓN DE FOTO)
# ==========================================
def obtener_perfil(event, context):
    try:
        path_params = event.get('pathParameters') or {}
        vendedor_id = path_params.get('id')
        
        if not vendedor_id:
            return respuesta(400, {"error": "Falta el ID del usuario en la ruta."})

        response = tabla_productos.query(
            IndexName='VendedorIndex',
            KeyConditionExpression='vendedorId = :vid',
            ExpressionAttributeValues={':vid': str(vendedor_id)}
        )

        datos_usuario = {}
        try:
            res_user = tabla_usuarios.get_item(Key={'correo': str(vendedor_id)})
            datos_usuario = res_user.get('Item', {})
            datos_usuario.pop('password', None)
        except Exception:
            pass
        
        return respuesta(200, {
            "usuarioId": vendedor_id,
            "usuario": datos_usuario,
            "totalProductos": response['Count'],
            "misProductos": response.get('Items', [])
        })
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def actualizar_perfil(event, context):
    try:
        if not event.get('body'):
            return respuesta(400, {"error": "El cuerpo de la petición está vacío."})
        body = json.loads(event['body'])
        correo = body.get('correo')
        nombre = body.get('nombre')
        foto_url = body.get('fotoUrl')

        if not correo:
            return respuesta(400, {"error": "El correo del usuario es obligatorio."})

        update_expr = []
        expr_values = {}
        expr_names = {}

        if nombre:
            update_expr.append("#n = :nom")
            expr_values[":nom"] = str(nombre).strip()
            expr_names["#n"] = "nombre"
        if foto_url:
            update_expr.append("foto = :foto")
            expr_values[":foto"] = str(foto_url).strip()

        if not update_expr:
            return respuesta(400, {"error": "No se enviaron campos para actualizar."})

        kwargs = {
            "Key": {'correo': str(correo)},
            "UpdateExpression": "SET " + ", ".join(update_expr),
            "ExpressionAttributeValues": expr_values,
            "ReturnValues": "ALL_NEW"
        }
        if expr_names:
            kwargs["ExpressionAttributeNames"] = expr_names

        res = tabla_usuarios.update_item(**kwargs)
        atributos = res.get('Attributes', {})
        atributos.pop('password', None)

        return respuesta(200, {"message": "Perfil actualizado correctamente", "usuario": atributos})
    except Exception as e:
        return respuesta(500, {"error": f"Error al actualizar perfil: {str(e)}"})

# ==========================================
# 5. MENSAJERÍA Y PROPUESTAS DE TRUEQUE
# ==========================================
def crear_mensaje(event, context):
    try:
        if not event.get('body'):
            return respuesta(400, {"error": "El cuerpo de la petición está vacío."})
        
        body = json.loads(event['body'])
        remitente = body.get('remitente')
        destinatario = body.get('destinatario')
        producto_id = body.get('productoId', '')
        producto_titulo = body.get('productoTitulo', 'Artículo en Truequi')
        contenido = body.get('contenido', '')

        if not remitente or not destinatario:
            return respuesta(400, {"error": "Remitente y destinatario son obligatorios."})
        if not contenido or len(str(contenido).strip()) < 3:
            return respuesta(400, {"error": "El mensaje o propuesta es demasiado corto."})

        item = {
            'id': str(uuid.uuid4()),
            'remitente': str(remitente).strip(),
            'destinatario': str(destinatario).strip(),
            'productoId': str(producto_id),
            'productoTitulo': str(producto_titulo),
            'contenido': str(contenido).strip()[:500],
            'fecha': datetime.now(timezone.utc).isoformat(),
            'estado': 'Pendiente'
        }

        tabla_mensajes.put_item(Item=item)
        return respuesta(201, {"message": "Propuesta enviada con éxito", "mensaje": item})
    except Exception as e:
        return respuesta(500, {"error": f"Error al enviar mensaje: {str(e)}"})

def obtener_mensajes(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        usuario = query_params.get('usuario')

        if not usuario:
            response = tabla_mensajes.scan(Limit=50)
            mensajes = response.get('Items', [])
        else:
            res_recibidos = tabla_mensajes.query(
                IndexName='DestinatarioIndex',
                KeyConditionExpression='destinatario = :u',
                ExpressionAttributeValues={':u': str(usuario)}
            )
            res_enviados = tabla_mensajes.query(
                IndexName='RemitenteIndex',
                KeyConditionExpression='remitente = :u',
                ExpressionAttributeValues={':u': str(usuario)}
            )
            
            mapa_mensajes = {}
            for m in res_recibidos.get('Items', []) + res_enviados.get('Items', []):
                mapa_mensajes[m['id']] = m
            mensajes = list(mapa_mensajes.values())

        mensajes.sort(key=lambda x: x.get('fecha', ''), reverse=True)
        return respuesta(200, {"status": "success", "total": len(mensajes), "mensajes": mensajes})
    except Exception as e:
        return respuesta(500, {"error": f"Error al obtener mensajes: {str(e)}"})