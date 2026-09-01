import json
import boto3
import uuid

dynamodb = boto3.resource('dynamodb')
s3_client = boto3.client('s3')

tabla_productos = dynamodb.Table('Productos')
BUCKET_NAME = 'truequi-images-bucket'

def crear_producto(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        
        if not body.get('titulo') or not body.get('precio'):
            return respuesta(400, {"error": "Título y precio son obligatorios"})

        item = {
            'id': str(uuid.uuid4()),
            'titulo': body.get('titulo'),
            'descripcion': body.get('descripcion', ''),
            'precio': str(body.get('precio')),
            'categoria': body.get('categoria', 'General'),
            'vendedorId': body.get('vendedorId')
        }
        
        tabla_productos.put_item(Item=item)
        return respuesta(201, {"message": "Producto registrado", "producto": item})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def obtener_productos(event, context):
    try:
        response = tabla_productos.scan()
        return respuesta(200, {"productos": response.get('Items', [])})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def obtener_upload_url(event, context):
    try:
        query_params = event.get('queryStringParameters') or {}
        file_name = query_params.get('filename', f"{uuid.uuid4()}.jpg")
        
        # Genera un enlace temporal de 1 hora para subir imágenes directamente a S3
        url = s3_client.generate_presigned_url(
            'put_object', 
            Params={'Bucket': BUCKET_NAME, 'Key': file_name}, 
            ExpiresIn=3600
        )
        return respuesta(200, {"uploadUrl": url, "fileName": file_name})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def health_check(event, context):
    return respuesta(200, {"status": "ok", "service": "catalog-microservice"})

def respuesta(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }