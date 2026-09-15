import json
import pymysql
import os
import re
from google.oauth2 import id_token
from google.auth.transport import requests

# Configuración segura usando variables de entorno
DB_HOST = os.environ['DB_HOST']
DB_USER = os.environ['DB_USER']
DB_PASS = os.environ['DB_PASS']
DB_NAME = os.environ['DB_NAME']
GOOGLE_CLIENT_ID = os.environ.get('GOOGLE_CLIENT_ID', '')

def get_connection():
    return pymysql.connect(host=DB_HOST, user=DB_USER, password=DB_PASS, database=DB_NAME, cursorclass=pymysql.cursors.DictCursor)

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
# FUNCIÓN DE DEFENSA: Parseo seguro de JSON
# ==========================================
def obtener_body_seguro(event):
    body = event.get('body')
    if not body:
        return None, "El cuerpo de la petición está vacío."
    try:
        return json.loads(body), None
    except json.JSONDecodeError:
        return None, "Formato JSON inválido. Revisa la estructura de los datos."

# ==========================================
# FUNCIÓN DE DEFENSA: Validación de Correo
# ==========================================
def es_correo_valido(correo):
    if not correo or not isinstance(correo, str):
        return False
    patron = r'^[\w\.-]+@[\w\.-]+\.\w+$'
    return re.match(patron, correo.strip()) is not None

# ==========================================
# 1. ALTA DE USUARIO (SP_A)
# ==========================================
def registro_tradicional(event, context):
    try:
        body, error = obtener_body_seguro(event)
        if error: return respuesta(400, {"error": error})
        
        correo = body.get('correo')
        password = body.get('password')
        rol = body.get('rol', 'Usuario')

        # DEFENSAS: Validar correo y longitud de contraseña
        if not es_correo_valido(correo):
            return respuesta(400, {"error": "El correo proporcionado no es válido."})
            
        if not password or not isinstance(password, str) or len(password) < 5:
            return respuesta(400, {"error": "La contraseña debe ser texto y tener al menos 5 caracteres."})

        conexion = get_connection()
        with conexion.cursor() as cursor:
            # Validar si el usuario ya existe para evitar error 500 de MySQL
            cursor.execute("SELECT ID_USER FROM T_USER WHERE USERNAME = %s", (correo.strip(),))
            if cursor.fetchone():
                conexion.close()
                return respuesta(409, {"error": "El correo ya está registrado en el sistema."})

            cursor.execute("CALL SP_A(%s, %s, %s)", (correo.strip(), password, str(rol)[:20]))
        
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
        body, error = obtener_body_seguro(event)
        if error: return respuesta(400, {"error": error})
        
        token = body.get('token')
        if not token or not isinstance(token, str):
            return respuesta(400, {"error": "Token de Google ausente o con formato inválido."})

        idinfo = id_token.verify_oauth2_token(token, requests.Request(), GOOGLE_CLIENT_ID)
        correo = idinfo['email']

        return respuesta(200, {
            "status": "success",
            "message": "Login con Google exitoso",
            "usuario": {"correo": correo, "rol": "Usuario"}
        })
    except ValueError as e:
        return respuesta(401, {"error": "Token de Google inválido o expirado."})
    except Exception as e:
        return respuesta(500, {"error": f"Error interno: {str(e)}"})

# ==========================================
# 3. LOGIN TRADICIONAL (SP_LOGIN)
# ==========================================
def login_tradicional(event, context):
    try:
        body, error = obtener_body_seguro(event)
        if error: return respuesta(400, {"error": error})
        
        correo = body.get('correo')
        password = body.get('password')

        if not es_correo_valido(correo) or not password:
            return respuesta(400, {"error": "Credenciales inválidas o incompletas."})

        conexion = get_connection()
        usuario_valido = None
        
        with conexion.cursor() as cursor:
            # Uso estricto de Stored Procedure para cumplir reglas del profesor
            cursor.execute("CALL SP_LOGIN(%s)", (correo.strip(),))
            usuario = cursor.fetchone()
            
            if usuario and str(usuario.get('PASSWORD')) == str(password):
                usuario_valido = usuario
        
        conexion.close()

        if usuario_valido:
            return respuesta(200, {
                "status": "success",
                "message": "Login tradicional exitoso",
                "usuario": {"correo": usuario_valido.get('USERNAME'), "rol": usuario_valido.get('ROL')}
            })
        else:
            return respuesta(401, {"error": "Correo o contraseña incorrectos"})

    except Exception as e:
        return respuesta(500, {"error": f"Error interno: {str(e)}"})

# ==========================================
# 4. CAMBIO DE USUARIO (SP_C)
# ==========================================
def actualizar_usuario(event, context):
    try:
        body, error = obtener_body_seguro(event)
        if error: return respuesta(400, {"error": error})
        
        id_user = body.get('id')
        correo = body.get('correo')
        password = body.get('password')

        if not id_user or not isinstance(id_user, int):
            return respuesta(400, {"error": "El ID de usuario es obligatorio y debe ser un número entero."})
        if not es_correo_valido(correo) or not password:
            return respuesta(400, {"error": "Datos incompletos para actualizar."})

        conexion = get_connection()
        with conexion.cursor() as cursor:
            cursor.execute("CALL SP_C(%s, %s, %s)", (id_user, correo.strip(), password))
        conexion.commit()
        conexion.close()

        return respuesta(200, {"message": "Usuario actualizado. Auditoría (Cambio) generada."})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 5. BAJA DE USUARIO (SP_B)
# ==========================================
def eliminar_usuario(event, context):
    try:
        body, error = obtener_body_seguro(event)
        if error: return respuesta(400, {"error": error})
        
        id_user = body.get('id')
        if not id_user or not isinstance(id_user, int):
            return respuesta(400, {"error": "El ID de usuario a eliminar es inválido."})

        conexion = get_connection()
        with conexion.cursor() as cursor:
            cursor.execute("CALL SP_B(%s)", (id_user,))
        conexion.commit()
        conexion.close()

        return respuesta(200, {"message": "Usuario eliminado. Auditoría (Baja) generada."})
    except Exception as e:
        return respuesta(500, {"error": str(e)})

# ==========================================
# 6. HEALTH CHECK (Microservicio Auth)
# ==========================================
def health_check(event, context):
    return respuesta(200, {
        "status": "ok", 
        "service": "truequi-auth", 
        "message": "Microservicio de autenticación seguro operando correctamente"
    })