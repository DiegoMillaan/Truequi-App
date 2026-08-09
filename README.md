# Truequi - Plataforma de Intercambios

## Objetivo (Product Goal)
Crear una plataforma multiplataforma (web y móvil) accesible y segura que fomente la economía circular, permitiendo a las personas intercambiar objetos de valor de forma directa, sin necesidad de transacciones monetarias. 

Este proyecto se desarrolla bajo el marco de trabajo Scrum, con un enfoque de integración y despliegue continuo desde el Sprint 1.

## Arquitectura Resumida y Stack Tecnológico
El proyecto utiliza una arquitectura separada (Frontend / Backend) alojada nativamente en la nube:
* **Frontend (Web y Móvil):** Dart y Flutter.
* **Backend:** API REST Serverless con Python 3.9.
* **Infraestructura (Cloud):** Amazon Web Services (AWS Lambda, API Gateway).
* **Base de Datos:** Amazon DynamoDB.
* **Gestión de Infraestructura:** Serverless Framework.

## Requisitos Previos
Para levantar este proyecto en un entorno local, se requiere instalar las siguientes herramientas:
* [Git](https://git-scm.com/)
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (versión ^3.12.2)
* [Node.js y npm](https://nodejs.org/) (Para instalar Serverless Framework)
* [AWS CLI](https://aws.amazon.com/cli/) (Configurado con credenciales de Administrador)

## Instalación y Ejecución

### 1. Clonar el repositorio
\`\`\`bash
git clone https://github.com/DiegoMillaan/intercambios-app.git
cd intercambios-app
\`\`\`

### 2. Levantar el Backend (AWS)
Navega a la carpeta del servicio y despliega la infraestructura en la nube:
\`\`\`bash
cd backend/services/health-check
npm install -g serverless
serverless deploy
\`\`\`

### 3. Levantar el Frontend (Web/Móvil)
Navega a la carpeta de la aplicación y ejecuta Flutter:
\`\`\`bash
cd mobile
flutter pub get
flutter run
\`\`\`

## Pruebas
Las pruebas unitarias y de integración se ejecutarán mediante GitHub Actions en los próximos sprints. 
* Para correr pruebas locales en frontend: `flutter test`

## Procedimiento de Despliegue
* **Backend:** El despliegue de la API y la infraestructura se maneja como código (IaC) mediante Serverless Framework, ejecutando `serverless deploy` hacia el ambiente `dev` en la región `us-east-1`.
* **Frontend Web:** (Se definirá el servicio de hosting en AWS S3/Amplify).
* **Frontend Móvil:** Distribución inicial mediante canal controlado (Internal/Closed testing) en Google Play Console.

## URLs Productivas
* **API Health Check (AWS):** [https://iqe7v3bpy4.execute-api.us-east-1.amazonaws.com/dev/health](https://iqe7v3bpy4.execute-api.us-east-1.amazonaws.com/dev/health)
* **Aplicación Web:** *(URL pendiente de publicación)*

## Enlaces y Documentación
* **[Tablero Scrum (GitHub Projects)](https://github.com/users/DiegoMillaan/projects/1)**: Gestión del Product Backlog, Sprints y tareas.
* **[Documentación Técnica](/docs/)**: Directorio interno con decisiones de arquitectura, manuales operativos y diagramas.