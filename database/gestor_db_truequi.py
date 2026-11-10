import boto3
import json
import uuid
import os
import sys
from datetime import datetime, timezone
from decimal import Decimal

# Configuración de AWS DynamoDB
REGION = 'us-east-1'
TABLAS = {
    'Usuarios': 'correo',
    'Productos': 'id',
    'Mensajes': 'id'
}
ARCHIVO_BACKUP_DEFECTO = 'respaldo_truequi_db.json'

dynamodb = boto3.resource('dynamodb', region_name=REGION)

# Serializador para manejar objetos Decimal de DynamoDB al guardar en JSON
class DecimalEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, Decimal):
            return float(obj) if obj % 1 > 0 else int(obj)
        return super(DecimalEncoder, self).default(obj)


# =====================================================================
# 1. RESPALDAR BASE DE DATOS (PARA RECUPERACIÓN POSTERIOR)
# =====================================================================
def hacer_backup(nombre_archivo=ARCHIVO_BACKUP_DEFECTO):
    print(f"\n📦 Iniciando respaldo completo de DynamoDB en '{nombre_archivo}'...")
    datos_respaldo = {
        "fecha_respaldo": datetime.now(timezone.utc).isoformat(),
        "tablas": {}
    }

    for nombre_tabla in TABLAS.keys():
        try:
            tabla = dynamodb.Table(nombre_tabla)
            items = []
            response = tabla.scan()
            items.extend(response.get('Items', []))

            while 'LastEvaluatedKey' in response:
                response = tabla.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
                items.extend(response.get('Items', []))

            datos_respaldo["tablas"][nombre_tabla] = items
            print(f"  ✔️ Tabla '{nombre_tabla}': {len(items)} registros respaldados.")
        except Exception as e:
            print(f"  ❌ Error al respaldar '{nombre_tabla}': {e}")

    with open(nombre_archivo, 'w', encoding='utf-8') as f:
        json.dump(datos_respaldo, f, cls=DecimalEncoder, ensure_ascii=False, indent=2)

    print(f"✅ Respaldo guardado exitosamente en: {os.path.abspath(nombre_archivo)}\n")


# =====================================================================
# 2. LIMPIEZA DE BASE DE DATOS (CON BACKUP AUTOMÁTICO DE SEGURIDAD)
# =====================================================================
def limpiar_base_de_datos(hacer_respaldo_previo=True):
    if hacer_respaldo_previo:
        print("🛡️ Realizando respaldo automático antes de limpiar por seguridad...")
        hacer_backup(ARCHIVO_BACKUP_DEFECTO)

    print("🧹 Limpiando todas las tablas de Truequi en AWS DynamoDB...")
    for nombre_tabla, llave_primaria in TABLAS.items():
        try:
            tabla = dynamodb.Table(nombre_tabla)
            scan = tabla.scan()
            items = scan.get('Items', [])

            if not items:
                print(f"  ℹ️ Tabla '{nombre_tabla}' ya estaba vacía.")
                continue

            with tabla.batch_writer() as batch:
                for item in items:
                    batch.delete_item(Key={llave_primaria: item[llave_primaria]})

            print(f"  🗑️ Tabla '{nombre_tabla}' vaciada ({len(items)} registros eliminados).")
        except Exception as e:
            print(f"  ❌ Error limpiando '{nombre_tabla}': {e}")

    print("✅ ¡Base de datos completamente limpia (en cero)!\n")


# =====================================================================
# 3. RECUPERACIÓN / RESTAURACIÓN (DESDE EL ARCHIVO DE RESPALDO)
# =====================================================================
def recuperar_base_de_datos(nombre_archivo=ARCHIVO_BACKUP_DEFECTO):
    if not os.path.exists(nombre_archivo):
        print(f"\n❌ No se encontró el archivo de respaldo '{nombre_archivo}'.")
        return

    print(f"\n♻️ Restaurando base de datos desde '{nombre_archivo}'...")
    # Primero limpiamos sin sobrescribir el backup para dejar el estado exacto
    limpiar_base_de_datos(hacer_respaldo_previo=False)

    with open(nombre_archivo, 'r', encoding='utf-8') as f:
        datos_respaldo = json.load(f, parse_float=Decimal)

    tablas_data = datos_respaldo.get("tablas", {})

    for nombre_tabla, items in tablas_data.items():
        if nombre_tabla not in TABLAS:
            continue
        try:
            tabla = dynamodb.Table(nombre_tabla)
            with tabla.batch_writer() as batch:
                for item in items:
                    batch.put_item(Item=item)
            print(f"  ✔️ Tabla '{nombre_tabla}': {len(items)} registros recuperados.")
        except Exception as e:
            print(f"  ❌ Error restaurando '{nombre_tabla}': {e}")

    print(f"✅ ¡Recuperación completada! Todo volvió al estado del {datos_respaldo.get('fecha_respaldo')}.\n")


# =====================================================================
# 4. SEED BASE (CARGAR DATOS PREDETERMINADOS PARA DEMOSTRACIÓN)
# =====================================================================
def cargar_seed_base():
    print("\n🌱 Cargando SEED BASE predeterminado en DynamoDB...")

    # 4.1 Usuarios predeterminados
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
    print(f"  ✔️ {len(usuarios_seed)} usuarios base cargados.")

    # 4.2 Productos predeterminados (con las categorías exactas de HomeWeb)
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
    print(f"  ✔️ {len(productos_seed)} productos semilla cargados.")

    # 4.3 Propuesta de mensaje inicial
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
    print("  ✔️ 1 negociación de prueba cargada en 'Mensajes'.")
    print("✅ ¡Catálogo Seed Base listo para demostración!\n")


# =====================================================================
# MENÚ INTERACTIVO Y COMANDOS RÁPIDOS PARA DEMOSTRACIÓN
# =====================================================================
def mostrar_menu():
    while True:
        print("=====================================================")
        print("   🛠️  GESTOR DE BASE DE DATOS TRUEQUI (AWS DYNAMODB)  ")
        print("=====================================================")
        print("  1. [BACKUP]  Guardar respaldo actual en JSON")
        print("  2. [CLEAN]   Limpiar toda la base de datos (dejar en 0)")
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