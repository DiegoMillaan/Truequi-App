import boto3
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla = dynamodb.Table('Productos')

def poblar_catalogo():
    print("Actualizando catálogo semilla con nuevas categorías en DynamoDB...")
    
    productos_reales = [
        {
            "titulo": "Calculadora Científica Casio",
            "descripcion": "Calculadora en perfecto estado, ideal para materias de ingeniería.",
            "precio": "350.0",
            "categoria": "Electrónica",
            "vendedorId": "diegomillan999@gmail.com",
            "vendedorNombre": "Diego Millán",
            "ubicacion": "CU UAQ",
            "imagenUrl": "https://images.unsplash.com/photo-1587145820266-a5951ee6f620?q=80&w=800"
        },
        {
            "titulo": "Taladro Inalámbrico DeWalt 20V",
            "descripcion": "Taladro con dos baterías y cargador. Lo usé para un proyecto de carpintería y ya no lo necesito. Busco herramienta manual o rotomartillo.",
            "precio": "2500.0",
            "categoria": "Herramientas",
            "vendedorId": "admin@gmail.com",
            "vendedorNombre": "Admin Truequi",
            "ubicacion": "Juriquilla",
            "imagenUrl": "https://images.unsplash.com/photo-1504148455328-c376907d081c?q=80&w=800"
        },
        {
            "titulo": "Set de Acuarelas Profesionales Windsor & Newton",
            "descripcion": "Caja de acuarelas con 24 pastillas. Poco uso. Intercambio por óleos o pinceles de cerda natural.",
            "precio": "1200.0",
            "categoria": "Arte y Papelería",
            "vendedorId": "jlara08@alumnos.uaq.mx",
            "vendedorNombre": "J. Lara",
            "ubicacion": "Centro Histórico",
            "imagenUrl": "https://images.unsplash.com/photo-1513364776144-60967b0f800f?q=80&w=800"
        },
        {
            "titulo": "Estetoscopio Littmann Classic III",
            "descripcion": "Color negro, en su caja original. Busco intercambiar por libros de medicina interna.",
            "precio": "1800.0",
            "categoria": "Salud y Equipo",
            "vendedorId": "admin@gmail.com",
            "vendedorNombre": "Admin Truequi",
            "ubicacion": "Facultad de Medicina UAQ",
            "imagenUrl": "https://images.unsplash.com/photo-1576091160550-2173dba999ef?q=80&w=1170&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=NHwxMjA3fDA%3D"
        }
    ]

    try:
        for p in productos_reales:
            item = {
                'id': str(uuid.uuid4()),
                'titulo': p["titulo"], 'descripcion': p["descripcion"], 'precio': p["precio"],
                'categoria': p["categoria"], 'vendedorId': p["vendedorId"], 'vendedorNombre': p["vendedorNombre"],
                'ubicacion': p["ubicacion"], 'imagenUrl': p["imagenUrl"], 'estado': 'Disponible',
                'fechaCreacion': datetime.now(timezone.utc).isoformat()
            }
            tabla.put_item(Item=item)
            print(f"✅ Producto agregado: {p['titulo']}")
    except Exception as e:
        print(f"\n❌ Error al insertar datos: {e}")

if __name__ == '__main__':
    poblar_catalogo()