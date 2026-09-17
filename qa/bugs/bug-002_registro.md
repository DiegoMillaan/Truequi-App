# [BUG-002] Falta de validación en campos de Nombre y Correo en el Formulario de Registro

**Módulo**: Registro \
**Severidad:** Media \
**Entorno:** Mobile \
**Estado:** Abierto 

### Descripción
El formulario de registro no aplica reglas de validación ni formato correcto en los campos de entrada:
- Permite registrar un usuario cuyo nombre esté compuesto únicamente por números.
- Acepta direcciones de correo electrónico con dominios no válidos o mal escritos (ejemplo: `gsmail.clm`).

### Pasos para reproducir
1. Abrir la aplicación e ir a la pantalla de **Registro**.
2. En el campo **Nombre**, ingresar solo números (ej. `123456`).
3. En el campo **Correo**, ingresar una dirección con sintaxis/dominio incorrecto (ej. `usuario@gsmail.clm`).
4. Ingresar una contraseña válida y presionar el botón de **Registrar**.

### Resultado esperado
1. El campo **Nombre** debe exigir caracteres alfabéticos y rechazar nombres compuestos únicamente por números o caracteres especiales.
2. El campo **Correo** debe validar la estructura del email con el fin de rechazar dominios mal estructurados o con caracteres invalidos.

### Resultado actual
El formulario procesa la solicitud sin mostrar ningún mensaje de advertencia o error, permitiendo la creación de la cuenta con datos inconsistentes.

### Notas / Sugerencias
* **Frontend (Mobile):**
  * **Nombre:** Agregar un validador en el `TextFormField` que exija caracteres alfabéticos (ej. `RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$')`) para bloquear entradas puramente numéricas.
  * **Correo:** Utilizar la propiedad `validator` de `TextFormField` con expresión regular o integrar paquetes como `email_validator` / `deep_email_validator` para comprobar sintaxis y existencia de dominios.
* **Backend:** Reforzar las validaciones en los controladores del API de registro para no confiar únicamente en las restricciones de la aplicación móvil.