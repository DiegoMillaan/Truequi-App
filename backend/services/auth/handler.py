import json
import boto3

# Inicializar el cliente de AWS DynamoDB
dynamodb = boto3.resource('dynamodb')

# IMPORTANTE: Este nombre de tabla debe coincidir con el que Josue o Ximena cree.
tabla_usuarios = dynamodb.Table('Usuarios')

def login(event, context):
    try:
        # 1. Extraer el body del POST que manda el Frontend
        if not event.get('body'):
            return respuesta(400, {"error": "El cuerpo de la petición está vacío"})
            
        body = json.loads(event['body'])
        correo = body.get('correo')
        password = body.get('password')

        # 2. Validar que no manden campos vacíos
        if not correo or not password:
            return respuesta(400, {"error": "Falta correo o contraseña"})

        # 3. Consultar la Base de Datos (Asumimos que 'correo' es la Primary Key)
        response = tabla_usuarios.get_item(Key={'correo': correo})
        usuario = response.get('Item')

        # 4. Validar si el usuario existe y la contraseña es correcta
        # En el Sprint 6 validaremos hashes. Para el Sprint 2 comparamos directo.
        if not usuario or usuario.get('password') != password:
            return respuesta(401, {"error": "Credenciales inválidas"})

        # 5. Éxito: Devolvemos código 200 y los datos (sin la contraseña)
        return respuesta(200, {
            "status": "success",
            "message": "Inicio de sesión exitoso",
            "token": "fake-jwt-token-sprint-2",
            "usuario": {
                "nombre": usuario.get('nombre', 'Usuario'),
                "correo": usuario.get('correo')
            }
        })

    except Exception as e:
        # Si algo falla en el servidor o en la conexión a DB, devolvemos error 500
        print(f"Error interno: {str(e)}")
        return respuesta(500, {"error": "Error interno del servidor"})

# Función auxiliar para generar las respuestas HTTP con los headers de CORS
def respuesta(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }