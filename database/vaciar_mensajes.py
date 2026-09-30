import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def purgar_mensajes():
    tabla = dynamodb.Table('Mensajes')
    scan = tabla.scan()
    items = scan.get('Items', [])
    
    if not items:
        return

if __name__ == '__main__':
    purgar_mensajes()