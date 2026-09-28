import boto3
import uuid
from datetime import datetime, timezone

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')
tabla_mensajes = dynamodb.Table('Mensajes')

def poblar_mensajes():
    print("Insertando propuestas de trueque de prueba en la tabla 'Mensajes'...")
    
    mensajes_prueba = [
        {
            "remitente": "admin@gmail.com",
            "destinatario": "diegomillan999@gmail.com",
            "productoId": "prod-demo-1",
            "productoTitulo": "Calculadora Científica Casio",
            "contenido": "¡Hola! Me interesa tu calculadora Casio. Te ofrezco a cambio el libro de Cálculo de Stewart en excelente estado."
        },
        {
            "remitente": "maxsurf01@hotmail.com",
            "destinatario": "1",
            "productoId": "prod-demo-2",
            "productoTitulo": "Audífonos Inalámbricos Bluetooth",
            "contenido": "¿Aceptas cambio por un mouse inalámbrico Logitech nuevo en caja? Podemos vernos en la explanada de la UAQ."
        }
    ]

    try:
        for m in mensajes_prueba:
            item = {
                'id': str(uuid.uuid4()),
                'remitente': m['remitente'],
                'destinatario': m['destinatario'],
                'productoId': m['productoId'],
                'productoTitulo': m['productoTitulo'],
                'contenido': m['contenido'],
                'fecha': datetime.now(timezone.utc).isoformat(),
                'estado': 'Pendiente'
            }
            tabla_mensajes.put_item(Item=item)
            print(f"✅ Propuesta creada para: {m['productoTitulo']}")
        print("\n¡Tabla 'Mensajes' lista y poblada en DynamoDB!")
    except Exception as e:
        print(f"\n❌ Error al insertar mensajes: {e}")

if __name__ == '__main__':
    poblar_mensajes()