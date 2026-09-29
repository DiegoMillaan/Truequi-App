import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def purgar_tabla(nombre_tabla):
    print(f"Borrando registros viejos de {nombre_tabla}...")
    tabla = dynamodb.Table(nombre_tabla)
    scan = tabla.scan()
    with tabla.batch_writer() as batch:
        for each in scan.get('Items', []):
            batch.delete_item(Key={'id': each['id']})
    print(f"¡Tabla {nombre_tabla} limpia!")

if __name__ == '__main__':
    purgar_tabla('Productos')
    purgar_tabla('Mensajes')