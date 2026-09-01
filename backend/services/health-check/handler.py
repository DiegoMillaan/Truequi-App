import json
import pymysql

def check(event, context):
    try:
        # Usa el endpoint exacto de tu RDS
        conexion = pymysql.connect(host='truequi-db.c0rqa2akcsq3.us-east-1.rds.amazonaws.com', user='admin', password='Tonycar411010', database='truequi_bd')
        conexion.ping(reconnect=True)
        return {"statusCode": 200, "headers": {"Access-Control-Allow-Origin": "*"}, "body": json.dumps({"status": "success", "message": "Motor relacional Truequi 100% operativo."})}
    except Exception as e:
        return {"statusCode": 500, "headers": {"Access-Control-Allow-Origin": "*"}, "body": json.dumps({"status": "error", "message": f"Falla de conexión: {str(e)}"})}