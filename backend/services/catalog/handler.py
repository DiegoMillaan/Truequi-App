import json
import boto3
import uuid
import os

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla_productos = dynamodb.Table('Productos')
s3_client = boto3.client('s3', region_name='us-east-1')
BUCKET_NAME = os.environ.get('BUCKET_NAME')

def respuesta(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
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
        imagenUrl = body.get('imagenUrl', '')

        # DEFENSA: Validaciones lógicas estrictas (Anti-Testing del profesor)
        if not titulo or not isinstance(titulo, str) or len(titulo.strip()) < 5 or len(titulo) > 80:
            return respuesta(400, {"error": "El título debe tener entre 5 y 80 caracteres."})
        
        if not descripcion or not isinstance(descripcion, str) or len(descripcion.strip()) < 15:
            return respuesta(400, {"error": "La descripción es muy corta. Añade al menos 15 caracteres."})
        
        # El precio debe ser un número real, mayor a 0 y menor a 100,000 MXN
        if precio is None or not isinstance(precio, (int, float)) or precio <= 0 or precio > 100000:
            return respuesta(400, {"error": "El valor estimado debe ser mayor a $0 y menor a $100,000 MXN."})
            
        if not vendedorId or not isinstance(vendedorId, (int, str)):
            return respuesta(400, {"error": "El identificador del vendedor es inválido."})

        item = {
            'id': str(uuid.uuid4()),
            'titulo': titulo.strip(),
            'descripcion': str(descripcion).strip()[:500],
            'precio': str(float(precio)), 
            'categoria': str(categoria)[:50],
            'vendedorId': str(vendedorId),
            'imagenUrl': str(imagenUrl)
        }
        
        tabla_productos.put_item(Item=item)
        return respuesta(201, {"message": "Producto publicado exitosamente", "producto": item})

    except Exception as e:
        return respuesta(500, {"error": f"Error interno del servidor: {str(e)}"})

# ==========================================
# 2. FEED DE PRODUCTOS (HOME PAGE)
# ==========================================
def obtener_productos(event, context):
    try:
        response = tabla_productos.scan(Limit=50) 
        return respuesta(200, {"status": "success", "productos": response.get('Items', [])})
    except Exception as e:
        return respuesta(500, {"error": f"Error al consultar base de datos: {str(e)}"})

# ==========================================
# 3. URL PARA SUBIR IMÁGENES A S3
# ==========================================
def obtener_upload_url(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        extension = query_params.get('ext', 'jpg').replace('.', '').lower()
        
        if extension not in ['jpg', 'jpeg', 'png', 'webp']:
            return respuesta(400, {"error": "Formato de imagen no permitido (solo JPG, PNG, WEBP)."})

        file_name = f"{uuid.uuid4()}.{extension}"
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
# 4. PERFIL DE USUARIO (INTEGRACIÓN)
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
        
        return respuesta(200, {
            "usuarioId": vendedor_id,
            "totalProductos": response['Count'],
            "misProductos": response.get('Items', [])
        })
    except Exception as e:
        return respuesta(500, {"error": str(e)})