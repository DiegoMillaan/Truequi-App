import boto3

dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def setup_database():
    try:
        print("Creando tabla 'Usuarios' en AWS DynamoDB...")
        tabla = dynamodb.create_table(
            TableName='Usuarios',
            KeySchema=[{'AttributeName': 'correo', 'KeyType': 'HASH'}],
            AttributeDefinitions=[{'AttributeName': 'correo', 'AttributeType': 'S'}],
            BillingMode='PAY_PER_REQUEST'
        )
        print("Esperando a que AWS termine de aprovisionar la tabla...")
        tabla.meta.client.get_waiter('table_exists').wait(TableName='Usuarios')
        print("¡Tabla creada exitosamente en la nube!")
    except Exception as e:
        if "ResourceInUseException" in str(e):
            print("La tabla ya existe en AWS, omitiendo creación.")
        else:
            print(f"Error crítico al crear tabla: {e}")
            return

    print("Insertando usuario de prueba con sistema de reputación...")
    tabla = dynamodb.Table('Usuarios')
    tabla.put_item(
        Item={
            'correo': 'admin@gmail.com',
            'password': '12345',
            'nombre': 'Admin Truequi',
            'promedio': '5.0',           # <--- OBLIGATORIO PARA LAS ESTRELLAS
            'totalCalificaciones': 0,    # <--- OBLIGATORIO PARA LAS ESTRELLAS
            'foto': 'https://ui-avatars.com/api/?name=Admin+Truequi&background=6B42E0&color=fff'
        }
    )
    print("¡Misión cumplida! El usuario admin@gmail.com está listo para el login.")

if __name__ == '__main__':
    setup_database()