import boto3
import json
import uuid
import os
import sys
import hashlib
from datetime import datetime, timezone
from decimal import Decimal

try:
    import pymysql
except ImportError:
    print("Falta la librería pymysql. Instálala ejecutando: pip install pymysql cryptography")
    sys.exit(1)

try:
    import bcrypt
    TIENE_BCRYPT = True
except ImportError:
    TIENE_BCRYPT = False

REGION = 'us-east-1'
TABLAS_DYNAMO = {
    'Usuarios': 'correo',
    'Productos': 'id',
    'Mensajes': 'id'
}
ARCHIVO_BACKUP_DEFECTO = 'respaldo_truequi_db.json'

dynamodb = boto3.resource('dynamodb', region_name=REGION)


def cargar_variables_env():
    """Busca y carga automáticamente el archivo .env del proyecto sin requerir librerías externas."""
    rutas_posibles = [
        '.env',
        '../.env',
        'backend/.env',
        'backend/services/auth/.env',
        '../backend/services/auth/.env'
    ]
    for ruta in rutas_posibles:
        if os.path.exists(ruta):
            with open(ruta, 'r', encoding='utf-8') as f:
                for linea in f:
                    linea = linea.strip()
                    if linea and not linea.startswith('#') and '=' in linea:
                        clave, valor = linea.split('=', 1)
                        os.environ.setdefault(clave.strip(), valor.strip().strip('"').strip("'"))
            print(f" Credenciales MySQL cargadas desde: {ruta}")
            return
    print("ℹNo se encontró archivo .env local, usando variables de entorno del sistema.")


cargar_variables_env()

DB_HOST = os.environ.get('DB_HOST', 'truequi-db.c0rqa2akcsq3.us-east-1.rds.amazonaws.com')
DB_USER = os.environ.get('DB_USER', 'admin')
DB_PASSWORD = os.environ.get('DB_PASS') or os.environ.get('DB_PASSWORD', 'Tonycar411010')
DB_NAME = os.environ.get('DB_NAME', 'truequi_bd')
DB_PORT = int(os.environ.get('DB_PORT', 3306))


def obtener_conexion_mysql():
    if not DB_HOST or not DB_USER or not DB_NAME:
        raise ValueError(
            "Faltan las variables DB_HOST, DB_USER, DB_PASSWORD o DB_NAME en tu archivo .env "
            "para conectar con la tabla T_USER en MySQL."
        )
    return pymysql.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
        port=DB_PORT,
        cursorclass=pymysql.cursors.DictCursor,
        autocommit=True
    )


def generar_hash_seed(password_plano, formato_referencia=None):
    """Genera el hash compatible con el formato que use tu tabla T_USER."""
    if formato_referencia and formato_referencia.startswith('$2'):
        if TIENE_BCRYPT:
            return bcrypt.hashpw(password_plano.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    if TIENE_BCRYPT:
        return bcrypt.hashpw(password_plano.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
    return hashlib.sha256(password_plano.encode('utf-8')).hexdigest()


class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 > 0 else int(obj)
        if isinstance(obj, datetime):
            return obj.isoformat()
        return super(DecimalEncoder, self).default(obj)


def hacer_backup(nombre_archivo=ARCHIVO_BACKUP_DEFECTO):
    print(f"\n Iniciando respaldo completo (DynamoDB + MySQL) en '{nombre_archivo}'...")
    datos_respaldo = {
        "fecha_respaldo": datetime.now(timezone.utc).isoformat(),
        "tablas": {},
        "mysql_t_user": []
    }

    # 1.1 Respaldar DynamoDB
    for nombre_tabla in TABLAS_DYNAMO.keys():
        try:
            tabla = dynamodb.Table(nombre_tabla)
            items = []
            response = tabla.scan()
            items.extend(response.get('Items', []))

            while 'LastEvaluatedKey' in response:
                response = tabla.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
                items.extend(response.get('Items', []))

            datos_respaldo["tablas"][nombre_tabla] = items
            print(f"  [DynamoDB] Tabla '{nombre_tabla}': {len(items)} registros respaldados.")
        except Exception as e:
            print(f"  [DynamoDB] Error al respaldar '{nombre_tabla}': {e}")

    # 1.2 Respaldar MySQL (T_USER)
    try:
        conn = obtener_conexion_mysql()
        with conn.cursor() as cursor:
            cursor.execute("SELECT ID_USER, USERNAME, PASSWORD, ROL FROM T_USER")
            usuarios_mysql = cursor.fetchall()
            datos_respaldo["mysql_t_user"] = usuarios_mysql
            print(f"  [MySQL RDS] Tabla 'T_USER': {len(usuarios_mysql)} cuentas de acceso respaldadas.")
        conn.close()
    except Exception as e:
        print(f"  [MySQL RDS] Error al respaldar 'T_USER': {e}")

    with open(nombre_archivo, 'w', encoding='utf-8') as f:
        json.dump(datos_respaldo, f, cls=DecimalEncoder, ensure_ascii=False, indent=2)

    print(f" Respaldo guardado exitosamente en: {os.path.abspath(nombre_archivo)}\n")


def limpiar_base_de_datos(hacer_respaldo_previo=True):
    if hacer_respaldo_previo:
        print(" Realizando respaldo automático antes de limpiar por seguridad...")
        hacer_backup(ARCHIVO_BACKUP_DEFECTO)

    print("🧹 Limpiando todas las tablas en AWS DynamoDB y MySQL RDS...")

    # 2.1 Vaciar tablas de DynamoDB (incluyendo paginación completa)
    for nombre_tabla, llave_primaria in TABLAS_DYNAMO.items():
        try:
            tabla = dynamodb.Table(nombre_tabla)
            items = []
            response = tabla.scan()
            items.extend(response.get('Items', []))
            while 'LastEvaluatedKey' in response:
                response = tabla.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
                items.extend(response.get('Items', []))

            if not items:
                print(f"  [DynamoDB] Tabla '{nombre_tabla}' ya estaba vacía.")
                continue

            with tabla.batch_writer() as batch:
                for item in items:
                    batch.delete_item(Key={llave_primaria: item[llave_primaria]})

            print(f"  [DynamoDB] Tabla '{nombre_tabla}' vaciada ({len(items)} registros eliminados).")
        except Exception as e:
            print(f"  [DynamoDB] Error limpiando '{nombre_tabla}': {e}")

    # 2.2 Vaciar tabla T_USER en MySQL (usando SP_B para activar el trigger de bitácora)
    try:
        conn = obtener_conexion_mysql()
        with conn.cursor() as cursor:
            cursor.execute("SELECT ID_USER, USERNAME FROM T_USER")
            usuarios_mysql = cursor.fetchall()

            if not usuarios_mysql:
                print("  [MySQL RDS] Tabla 'T_USER' ya estaba vacía.")
            else:
                for u in usuarios_mysql:
                    try:
                        cursor.callproc('SP_B', (u['ID_USER'],))
                    except Exception:
                        cursor.execute("DELETE FROM T_USER WHERE ID_USER = %s", (u['ID_USER'],))
                print(f" [MySQL RDS] Tabla 'T_USER' vaciada ({len(usuarios_mysql)} cuentas eliminadas y registradas en bitácora).")
        conn.close()
    except Exception as e:
        print(f" [MySQL RDS] Error limpiando 'T_USER': {e}")

    print("Base de datos completamente limpia.\n")


def recuperar_base_de_datos(nombre_archivo=ARCHIVO_BACKUP_DEFECTO):
    if not os.path.exists(nombre_archivo):
        print(f"\n No se encontró el archivo de respaldo '{nombre_archivo}'.")
        return

    print(f"\n Restaurando base de datos desde '{nombre_archivo}'...")
    limpiar_base_de_datos(hacer_respaldo_previo=False)

    with open(nombre_archivo, 'r', encoding='utf-8') as f:
        datos_respaldo = json.load(f, parse_float=Decimal)

    # 3.1 Restaurar DynamoDB
    tablas_data = datos_respaldo.get("tablas", {})
    for nombre_tabla, items in tablas_data.items():
        if nombre_tabla not in TABLAS_DYNAMO:
            continue
        try:
            tabla = dynamodb.Table(nombre_tabla)
            with tabla.batch_writer() as batch:
                for item in items:
                    batch.put_item(Item=item)
            print(f" [DynamoDB] Tabla '{nombre_tabla}': {len(items)} registros recuperados.")
        except Exception as e:
            print(f" [DynamoDB] Error restaurando '{nombre_tabla}': {e}")

    # 3.2 Restaurar MySQL (T_USER con sus contraseñas y hashes exactos)
    usuarios_mysql = datos_respaldo.get("mysql_t_user", [])
    if usuarios_mysql:
        try:
            conn = obtener_conexion_mysql()
            with conn.cursor() as cursor:
                for u in usuarios_mysql:
                    cursor.callproc('SP_A', (u['USERNAME'], u['PASSWORD'], u.get('ROL', 'Usuario')))
            conn.close()
            print(f" [MySQL RDS] Tabla 'T_USER': {len(usuarios_mysql)} cuentas de acceso recuperadas.")
        except Exception as e:
            print(f" [MySQL RDS] Error restaurando 'T_USER': {e}")

    print(f"¡Recuperación completada! Todo volvió al estado del {datos_respaldo.get('fecha_respaldo')}.\n")


def cargar_seed_base():
    print("\n Cargando SEED BASE predeterminado en MySQL y DynamoDB...")

    # Detectar formato de hash del respaldo si existe para que el login del Seed funcione
    formato_hash_ref = None
    if os.path.exists(ARCHIVO_BACKUP_DEFECTO):
        try:
            with open(ARCHIVO_BACKUP_DEFECTO, 'r', encoding='utf-8') as f:
                respaldo_previo = json.load(f)
                lista_u = respaldo_previo.get("mysql_t_user", [])
                if lista_u:
                    formato_hash_ref = lista_u[0].get("PASSWORD", "")
        except Exception:
            pass

    password_seed_hash = generar_hash_seed("123456", formato_hash_ref)

    # 4.1 Usuarios predeterminados en MySQL (T_USER)
    cuentas_seed = [
        ('admin@gmail.com', password_seed_hash, 'Admin'),
        ('diegomillan999@gmail.com', password_seed_hash, 'Usuario'),
        ('jlara08@alumnos.uaq.mx', password_seed_hash, 'Usuario')
    ]
    try:
        conn = obtener_conexion_mysql()
        with conn.cursor() as cursor:
            for correo, pwd_hash, rol in cuentas_seed:
                cursor.execute("SELECT ID_USER FROM T_USER WHERE USERNAME = %s", (correo,))
                if not cursor.fetchone():
                    cursor.callproc('SP_A', (correo, pwd_hash, rol))
        conn.close()
        print(f"  [MySQL RDS] {len(cuentas_seed)} cuentas creadas en 'T_USER' (Contraseña semilla: 123456).")
    except Exception as e:
        print(f"  [MySQL RDS] Error cargando cuentas semilla en 'T_USER': {e}")

    # 4.2 Perfiles predeterminados en DynamoDB (Usuarios)
    tabla_usuarios = dynamodb.Table('Usuarios')
    usuarios_seed = [
        {
            'correo': 'admin@gmail.com',
            'nombre': 'Admin Truequi UAQ',
            'telefono': '4421234567',
            'promedio': '5.0',
            'totalCalificaciones': 2,
            'truequesCompletados': 2,
            'fotoUrl': 'https://ui-avatars.com/api/?name=Admin+Truequi&background=6B42E0&color=fff',
            'favoritos': [],
            'resenas': [
                {
                    'id': str(uuid.uuid4()),
                    'autorNombre': 'Diego Millán',
                    'autorCorreo': 'diegomillan999@gmail.com',
                    'estrellas': '5.0',
                    'comentario': 'Excelente trato en la explanada de Informática, el artículo estaba impecable.',
                    'fecha': datetime.now(timezone.utc).isoformat()
                }
            ],
            'denunciasRecibidas': []
        },
        {
            'correo': 'diegomillan999@gmail.com',
            'nombre': 'Diego Millán',
            'telefono': '4429876543',
            'promedio': '5.0',
            'totalCalificaciones': 1,
            'truequesCompletados': 1,
            'fotoUrl': 'https://ui-avatars.com/api/?name=Diego+Millan&background=FFA800&color=fff',
            'favoritos': [],
            'resenas': [],
            'denunciasRecibidas': []
        },
        {
            'correo': 'jlara08@alumnos.uaq.mx',
            'nombre': 'J. Lara',
            'telefono': '4425550192',
            'promedio': '4.9',
            'totalCalificaciones': 3,
            'truequesCompletados': 3,
            'fotoUrl': 'https://ui-avatars.com/api/?name=J+Lara&background=101828&color=fff',
            'favoritos': [],
            'resenas': [],
            'denunciasRecibidas': []
        }
    ]

    for u in usuarios_seed:
        tabla_usuarios.put_item(Item=u)
    print(f"  [DynamoDB] {len(usuarios_seed)} perfiles de usuario cargados en 'Usuarios'.")

    # 4.3 Productos predeterminados
    tabla_productos = dynamodb.Table('Productos')
    id_prod_casio = "prod-seed-casio-001"
    productos_seed = [
        {
            "id": id_prod_casio,
            "titulo": "Calculadora Científica Casio Classwiz",
            "descripcion": "Calculadora en perfecto estado, ideal para materias de ingeniería en la UAQ. Busco libro de Cálculo o audífonos.",
            "precio": "350",
            "categoria": "Electrónica y Cómputo",
            "municipio": "Santiago de Querétaro",
            "latitud": Decimal("20.5931"),
            "longitud": Decimal("-100.4101"),
            "vendedorId": "diegomillan999@gmail.com",
            "vendedorNombre": "Diego Millán",
            "imagenUrl": "https://images.unsplash.com/photo-1587145820266-a5951ee6f620?q=80&w=800",
            "imagenesUrls": ["https://images.unsplash.com/photo-1587145820266-a5951ee6f620?q=80&w=800"],
            "estado": "Disponible",
            "fechaCreacion": datetime.now(timezone.utc).isoformat()
        },
        {
            "id": str(uuid.uuid4()),
            "titulo": "Taladro Inalámbrico DeWalt 20V",
            "descripcion": "Taladro con dos baterías y cargador. Lo usé para un proyecto y ya no lo ocupo. Busco herramienta manual o monitor.",
            "precio": "2500",
            "categoria": "Herramientas",
            "municipio": "Santiago de Querétaro",
            "latitud": Decimal("20.7042"),
            "longitud": Decimal("-100.4439"),
            "vendedorId": "admin@gmail.com",
            "vendedorNombre": "Admin Truequi UAQ",
            "imagenUrl": "https://images.unsplash.com/photo-1504148455328-c376907d081c?q=80&w=800",
            "imagenesUrls": ["https://images.unsplash.com/photo-1504148455328-c376907d081c?q=80&w=800"],
            "estado": "Disponible",
            "fechaCreacion": datetime.now(timezone.utc).isoformat()
        },
        {
            "id": str(uuid.uuid4()),
            "titulo": "Set de Acuarelas Profesionales Winsor & Newton",
            "descripcion": "Caja de acuarelas con 24 pastillas con muy poco uso. Intercambio por óleos, lienzos o pinceles.",
            "precio": "1200",
            "categoria": "Arte y Papelería",
            "municipio": "Corregidora",
            "latitud": Decimal("20.5312"),
            "longitud": Decimal("-100.4408"),
            "vendedorId": "jlara08@alumnos.uaq.mx",
            "vendedorNombre": "J. Lara",
            "imagenUrl": "https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800",
            "imagenesUrls": ["https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800"],
            "estado": "Disponible",
            "fechaCreacion": datetime.now(timezone.utc).isoformat()
        },
        {
            "id": str(uuid.uuid4()),
            "titulo": "Estetoscopio Littmann Classic III",
            "descripcion": "Color negro en su caja original. Busco intercambiar por libros de anatomía o medicina interna.",
            "precio": "1800",
            "categoria": "Salud y Equipo Médico",
            "municipio": "El Marqués",
            "latitud": Decimal("20.6254"),
            "longitud": Decimal("-100.3129"),
            "vendedorId": "admin@gmail.com",
            "vendedorNombre": "Admin Truequi UAQ",
            "imagenUrl": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=1170",
            "imagenesUrls": ["https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=1170"],
            "estado": "Disponible",
            "fechaCreacion": datetime.now(timezone.utc).isoformat()
        }
    ]

    for p in productos_seed:
        tabla_productos.put_item(Item=p)
    print(f" [DynamoDB] {len(productos_seed)} productos semilla cargados en 'Productos'.")

    # 4.4 Propuesta de mensaje inicial
    tabla_mensajes = dynamodb.Table('Mensajes')
    participantes = sorted(["admin@gmail.com", "diegomillan999@gmail.com"])
    conversacion_id = f"{id_prod_casio}_{participantes[0]}_{participantes[1]}"

    mensaje_seed = {
        'id': str(uuid.uuid4()),
        'conversacionId': conversacion_id,
        'remitente': 'admin@gmail.com',
        'destinatario': 'diegomillan999@gmail.com',
        'productoId': id_prod_casio,
        'productoTitulo': 'Calculadora Científica Casio Classwiz',
        'contenido': '¡Hola Diego! Me interesa tu calculadora Casio. Te ofrezco a cambio el libro de Cálculo de Stewart en excelente estado.',
        'fecha': datetime.now(timezone.utc).isoformat(),
        'estado': 'Pendiente'
    }
    tabla_mensajes.put_item(Item=mensaje_seed)
    print("  [DynamoDB] 1 negociación de prueba cargada en 'Mensajes'.")
    print("¡Catálogo Seed Base listo!\n")


def mostrar_menu():
    while True:
        print("=====================================================")
        print("   GESTOR DE BASE DE DATOS TRUEQUI (DYNAMODB + MYSQL)")
        print("=====================================================")
        print("  1. [BACKUP]  Guardar respaldo actual en JSON")
        print("  2. [CLEAN]   Limpiar TODA la base de datos (dejar en 0)")
        print("  3. [SEED]    Cargar datos predeterminados (Seed Base)")
        print("  4. [RESTORE] Recuperar lo que se tenía desde el Backup")
        print("  5. Salir")
        print("=====================================================")
        opcion = input("Selecciona una opción (1-5): ").strip()

        if opcion == '1':
            hacer_backup()
        elif opcion == '2':
            limpiar_base_de_datos(hacer_respaldo_previo=True)
        elif opcion == '3':
            cargar_seed_base()
        elif opcion == '4':
            recuperar_base_de_datos()
        elif opcion == '5':
            print("Saliendo del gestor...")
            break
        else:
            print("Opción no válida.\n")


if __name__ == '__main__':
    if len(sys.argv) > 1:
        cmd = sys.argv[1].lower()
        if cmd == 'backup':
            hacer_backup()
        elif cmd == 'clean':
            limpiar_base_de_datos(hacer_respaldo_previo=True)
        elif cmd == 'seed':
            cargar_seed_base()
        elif cmd == 'restore':
            recuperar_base_de_datos()
        else:
            print("Uso rápido: python gestor_db_truequi.py [backup | clean | seed | restore]")
    else:
        mostrar_menu()