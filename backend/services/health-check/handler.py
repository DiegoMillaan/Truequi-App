import json

def check(event, context):
    return {
        "statusCode": 500,
        "headers": {
            "Access-Control-Allow-Origin": "*",
            "Content-Type": "application/json"
        },
        "body": json.dumps({
            "status": "error",
            "message": "Error 500: El servidor de Truequi está apagado temporalmente."
        })
    }