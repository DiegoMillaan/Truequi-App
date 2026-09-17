# [Bug-001] Error interno al intentar iniciar sesión

**Módulo:** Login \
**Severidad:** Alta\
**Entorno:** Mobile\
**Estado:** Abierto

### Descripción
Al intentar iniciar sesión con credenciales no registradas, la aplicación falla con un error no controlado de la base de datos.

### Pasos para reproducir
1. Abrir la pantalla de Login.
2. Ingresar un correo no registrado y cualquier contraseña.
3. Presionar **Iniciar Sesión**.

### Resultado esperado
Mostrar un mensaje amigable al usuario indicando que debe registrarse porque no se encontraron las credenciales.


### Resultado actual
Lanza el mensaje: `Error interno: (1305, "PROCEDURE truequi_bd.SP_LOGIN does not exist")`