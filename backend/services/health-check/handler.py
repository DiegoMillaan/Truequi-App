import json

def check(event, context):
    return {
        "statusCode": 200,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "status": "success",
            "message": "¡Conexión exitosa a AWS! El backend de Intercambios está en línea."
        })
    }