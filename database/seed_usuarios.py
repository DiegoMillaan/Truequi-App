import boto3

# Conectar a DynamoDB en la misma región que tu Serverless
dynamodb = boto3.resource('dynamodb', region_name='us-east-1')

def setup_database():
    # 1. Crear la tabla Usuarios
    try:
        print("Creando tabla 'Usuarios' en AWS DynamoDB...")
        tabla = dynamodb.create_table(
            TableName='Usuarios',
            KeySchema=[
                {'AttributeName': 'correo', 'KeyType': 'HASH'}  # Clave primaria
            ],
            AttributeDefinitions=[
                {'AttributeName': 'correo', 'AttributeType': 'S'} # S = String
            ],
            BillingMode='PAY_PER_REQUEST' # Modo serverless para no generar costos
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

    # 2. Insertar los datos semilla (Seed Data)
    print("Insertando usuario de prueba...")
    tabla = dynamodb.Table('Usuarios')
    tabla.put_item(
        Item={
            'correo': 'admin@gmail.com',
            'password': '12345',
            'nombre': 'Admin de Prueba'
        }
    )
    print("¡Misión cumplida! El usuario admin@gmail.com está listo para el login.")

if __name__ == '__main__':
    setup_database()