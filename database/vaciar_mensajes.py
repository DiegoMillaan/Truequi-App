import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def purgar_mensajes():
    print("Borrando todo el historial de chats en AWS DynamoDB...")
    tabla = dynamodb.Table('Mensajes')
    scan = tabla.scan()
    items = scan.get('Items', [])
    
    if not items:
        print("La tabla ya está vacía. ¡No hay nada que borrar!")
        return

    with tabla.batch_writer() as batch:
        for each in items:
            batch.delete_item(Key={'id': each['id']})
            
    print(f"¡Se han eliminado {len(items)} mensajes correctamente! La bandeja está en cero.")

if __name__ == '__main__':
    purgar_mensajes()