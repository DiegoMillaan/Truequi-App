import boto3
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla = dynamodb.Table('Productos')

def poblar_catalogo():
    print("Actualizando catálogo semilla con vendedores reales y ubicaciones en DynamoDB...")
    
    productos_reales = [
        {
            "titulo": "Calculadora Científica Casio",
            "descripcion": "Calculadora en perfecto estado, ideal para materias de ingeniería. Busco intercambiar por un libro de Cálculo.",
            "precio": "350.0",
            "categoria": "Electrónica",
            "vendedorId": "diegomillan999@gmail.com",
            "vendedorNombre": "Diego Millán",
            "ubicacion": "CU UAQ - Querétaro",
            "imagenUrl": "https://images.unsplash.com/photo-1587145820266-a5951ee6f620?q=80&w=800&auto=format&fit=crop"
        },
        {
            "titulo": "Libro 'Clean Code' original",
            "descripcion": "Libro de Robert C. Martin. Lo leí una vez, está como nuevo. Acepto trueque por accesorios de computadora o teclado mecánico.",
            "precio": "600.0",
            "categoria": "Libros",
            "vendedorId": "jlara08@alumnos.uaq.mx",
            "vendedorNombre": "J. Lara",
            "ubicacion": "Facultad de Informática UAQ",
            "imagenUrl": "https://images.unsplash.com/photo-1555066931-4365d14bab8c?q=80&w=800&auto=format&fit=crop"
        },
        {
            "titulo": "Mochila para Laptop 15 pulgadas",
            "descripcion": "Mochila color negro, impermeable, poco uso. La cambio porque me regalaron otra. Cabe perfecto una MacBook.",
            "precio": "450.0",
            "categoria": "Accesorios",
            "vendedorId": "admin@gmail.com",
            "vendedorNombre": "Admin Truequi",
            "ubicacion": "Centro Histórico - Querétaro",
            "imagenUrl": "https://images.unsplash.com/photo-1553062407-98eeb64c6a62?q=80&w=800&auto=format&fit=crop"
        },
        {
            "titulo": "Audífonos Inalámbricos Bluetooth",
            "descripcion": "Audífonos de diadema con cancelación de ruido básica. Tienen 10 horas de batería. Busco un mouse inalámbrico a cambio.",
            "precio": "800.0",
            "categoria": "Electrónica",
            "vendedorId": "diegomillan999@gmail.com",
            "vendedorNombre": "Diego Millán",
            "ubicacion": "Juriquilla - Querétaro",
            "imagenUrl": "https://images.unsplash.com/photo-1505740420928-5e560c06d30e?q=80&w=800&auto=format&fit=crop"
        }
    ]

    try:
        for p in productos_reales:
            item = {
                'id': str(uuid.uuid4()),
                'titulo': p["titulo"],
                'descripcion': p["descripcion"],
                'precio': p["precio"],
                'categoria': p["categoria"],
                'vendedorId': p["vendedorId"],
                'vendedorNombre': p["vendedorNombre"],
                'ubicacion': p["ubicacion"],
                'imagenUrl': p["imagenUrl"],
                'fechaCreacion': datetime.now(timezone.utc).isoformat()
            }
            tabla.put_item(Item=item)
            print(f"✅ Producto agregado: {p['titulo']} ({p['vendedorId']})")
        print("\n¡Catálogo actualizado con vendedores y ubicaciones reales!")
    except Exception as e:
        print(f"\n❌ Error al insertar datos: {e}")

if __name__ == '__main__':
    poblar_catalogo()