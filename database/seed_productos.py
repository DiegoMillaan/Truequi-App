import boto3
import uuid

# Conectamos a DynamoDB en la región donde desplegaste tu Serverless
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

# Apuntamos a la tabla que acabas de crear
tabla = dynamodb.Table('Productos')

def poblar_catalogo():
    print("Iniciando la carga de datos semilla en AWS DynamoDB...")
    
    # Asignaremos estos productos al ID 1 (tu cuenta de Administrador principal en MySQL)
    vendedor_id = "1"
    
    # Lista de productos de prueba para el trueque
    productos_falsos = [
        {
            "titulo": "Calculadora Científica Casio",
            "descripcion": "Calculadora en perfecto estado, ideal para materias de ingeniería. Busco intercambiar por un libro de Cálculo.",
            "precio": "150.0",
            "categoria": "Electrónica",
            "imagenUrl": "https://truequi-images-dm2026.s3.amazonaws.com/dummy/calculadora.jpg"
        },
        {
            "titulo": "Libro 'Clean Code' original",
            "descripcion": "Libro de Robert C. Martin. Lo leí una vez, está como nuevo. Acepto trueque por accesorios de computadora o teclado mecánico.",
            "precio": "400.0",
            "categoria": "Libros",
            "imagenUrl": "https://truequi-images-dm2026.s3.amazonaws.com/dummy/cleancode.jpg"
        },
        {
            "titulo": "Mochila para Laptop 15 pulgadas",
            "descripcion": "Mochila color negro, impermeable, poco uso. La cambio porque me regalaron otra. Cabe perfecto una MacBook.",
            "precio": "250.0",
            "categoria": "Accesorios",
            "imagenUrl": "https://truequi-images-dm2026.s3.amazonaws.com/dummy/mochila.jpg"
        },
        {
            "titulo": "Audífonos Inalámbricos Básicos",
            "descripcion": "Audífonos Bluetooth con caja de carga. Tienen 4 horas de batería. Busco un mouse inalámbrico a cambio.",
            "precio": "200.0",
            "categoria": "Electrónica",
            "imagenUrl": "https://truequi-images-dm2026.s3.amazonaws.com/dummy/audifonos.jpg"
        }
    ]

    try:
        for p in productos_falsos:
            # Construimos el objeto exacto que espera tu esquema
            item = {
                'id': str(uuid.uuid4()),
                'titulo': p["titulo"],
                'descripcion': p["descripcion"],
                'precio': p["precio"],
                'categoria': p["categoria"],
                'vendedorId': vendedor_id,
                'imagenUrl': p["imagenUrl"]
            }
            # Insertamos en la nube
            tabla.put_item(Item=item)
            print(f"✅ Producto agregado: {p['titulo']}")
        
        print("\n¡Misión cumplida! El catálogo tiene datos listos para el Home Page.")
    except Exception as e:
        print(f"\n❌ Error al insertar datos: {e}")

if __name__ == '__main__':
    poblar_catalogo()