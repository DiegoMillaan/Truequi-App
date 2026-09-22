# Truequi - Plataforma de Intercambios

## Objetivo (Product Goal)
Crear una plataforma multiplataforma (web y móvil) accesible y segura que fomente la economía circular, permitiendo a las personas intercambiar objetos de valor de forma directa, sin necesidad de transacciones monetarias. 

Este proyecto se desarrolla bajo el marco de trabajo Scrum, con un enfoque de integración y despliegue continuo desde el Sprint 1.

## Arquitectura Resumida y Stack Tecnológico
El proyecto utiliza una arquitectura de microservicios separada (Frontend / Backend) alojada nativamente en la nube:
* **Frontend (Web y Móvil):** Dart y Flutter (con diseño Liquid Glass / Glassmorphism para Web).
* **Backend:** API REST Serverless con Python 3.12.
* **Autenticación:** Google OAuth 2.0 y JWT personalizados.
* **Infraestructura (Cloud):** Amazon Web Services (AWS Lambda, API Gateway, S3).
* **Base de Datos:** Arquitectura híbrida con MySQL (Autenticación y Auditoría) y Amazon DynamoDB (Catálogo ágil de productos).
* **Gestión de Infraestructura:** Serverless Framework.

## Requisitos Previos
Para levantar este proyecto en un entorno local, se requiere instalar las siguientes herramientas:
* [Git](https://git-scm.com/)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión ^3.12.2)
* [Node.js y npm](https://nodejs.org/) (Para instalar Serverless Framework)
* [Python 3.12 y pip](https://www.python.org/) (Para manejo de scripts de Base de Datos locales)
* [AWS CLI](https://aws.amazon.com/cli/) (Configurado con credenciales de Administrador)

## Instalación y Ejecución

### 1. Clonar el repositorio
```bash
git clone [https://github.com/DiegoMillaan/Truequi-App.git](https://github.com/DiegoMillaan/Truequi-App.git)
cd Truequi-App

```

### 2. Configurar Bases de Datos (MySQL y DynamoDB)

Ejecuta el script SQL en tu instancia de MySQL para crear las tablas y procedimientos almacenados (SP_LOGIN, SP_A, etc.).
Luego, aprovisiona las tablas en AWS DynamoDB e inyecta los datos de prueba:

```bash
pip install boto3 pymysql google-auth
python database/seed_usuarios.py
python database/seed_productos.py

```

### 3. Levantar el Backend (AWS)

Navega a la carpeta de los microservicios y despliega la infraestructura en la nube.
Para desplegar el servicio de autenticación:

```bash
cd backend/services/auth
npm install -g serverless
serverless deploy

```

### 4. Levantar el Frontend

**Para desarrollo Móvil (Emulador/Físico):**

```bash
cd mobile
flutter pub get
flutter run

```

**Para desarrollo Web (Navegador):**

```bash
cd web
flutter pub get
flutter run -d chrome

```

## Pruebas

Las pruebas unitarias y de integración se ejecutarán mediante GitHub Actions en los próximos sprints.

* Para correr pruebas locales en frontend: `flutter test`

## Procedimiento de Despliegue

* **Backend:** El despliegue de las APIs y la infraestructura se maneja como código (IaC) mediante Serverless Framework, ejecutando `serverless deploy` hacia el ambiente `dev` en la región `us-east-1`.
* **Frontend Web:** Alojado nativamente en AWS S3 Static Website Hosting. Despliegue mediante CLI:
```bash
flutter build web
aws s3 sync build/web/ s3://truequi-web-2026-dm --delete

```


* **Frontend Móvil:** Distribución inicial mediante canal controlado (Internal/Closed testing) en Google Play Console.

## URLs Productivas

* **Aplicación Web Oficial:** http://truequi-web-2026-dm.s3-website-us-east-1.amazonaws.com
* **API Autenticación (Login/Google):** https://16663yaped.execute-api.us-east-1.amazonaws.com/dev/
* **API Catálogo (Productos):** https://y3cokge8sa.execute-api.us-east-1.amazonaws.com/dev/

## Enlaces y Documentación

* **[Tablero Scrum (GitHub Projects)](https://www.google.com/search?q=https://github.com/users/DiegoMillaan/projects/1)**: Gestión del Product Backlog, Sprints y tareas.
* **[Documentación Técnica](https://www.google.com/search?q=/docs/)**: Directorio interno con decisiones de arquitectura, manuales operativos y diagramas.



Hola