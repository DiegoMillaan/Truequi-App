import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def purgar_mensajes():
    tabla = dynamodb.Table('Mensajes')
    scan = tabla.scan()
    items = scan.get('Items', [])
    
    if not items:
        return

    with tabla.batch_writer() as batch:
        for each in items:
            batch.delete_item(Key={'id': each['id']})

if __name__ == '__main__':
    purgar_mensajes()