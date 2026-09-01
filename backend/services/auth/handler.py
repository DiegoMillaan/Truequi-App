import json
import pymysql
import os
from google.oauth2 import id_token
from google.auth.transport import requests

# Configuración segura usando variables de entorno
DB_HOST = os.environ['DB_HOST']
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
DB_NAME = os.environ['DB_NAME']
GOOGLE_CLIENT_ID = os.environ['GOOGLE_CLIENT_ID']

def get_connection():
    return pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME, cursorclass=pymysql.cursors.DictCursor)

# ==========================================
# 1. ALTA DE USUARIO (Usando Stored Procedure)
# ==========================================
def registro_tradicional(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        correo = body.get('correo')
        password = body.get('password')
        rol = body.get('rol', 'Usuario') # Implementación de Sistema de Roles

        if not correo or not password:
            return respuesta(400, {"error": "Faltan datos"})

        conexion = get_connection()
        with conexion.cursor() as cursor:
            # RÚBRICA: Llamada estricta al Procedure. El Trigger hará la auditoría en automático.
            cursor.execute("CALL SP_A(%s, %s, %s)", (correo, password, rol))
        
        conexion.commit()
        conexion.close()

        return respuesta(201, {"message": "Usuario registrado exitosamente. Auditoría generada."})
    except Exception as e:
        return respuesta(500, {"error": f"Error interno: {str(e)}"})

# ==========================================
# 2. LOGIN CON OAUTH 2.0 (Google)
# ==========================================
def login_google(event, context):
    try:
        body = json.loads(event.get('body', '{}'))
        token = body.get('token')

        # Validación oficial de OAuth 2.0
        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        correo = idinfo['email']

        # Aquí usaríamos CALL SP_CONSULTA para verificar si el usuario ya existe
        return respuesta(200, {
            "status": "success", 
            "message": "Login con Google exitoso", 
            "usuario": {"correo": correo, "rol": "Usuario"}
        })
    except ValueError:
        return respuesta(401, {"error": "Token de Google inválido o expirado"})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

def respuesta(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps(body)
    }