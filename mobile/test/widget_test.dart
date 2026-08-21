// This is a basic Flutter widget test for Truequi.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Smoke test de la pantalla de conexión AWS', (WidgetTester tester) async {
    // Construye la aplicación llamando a TruequiApp (con "i")
    await tester.pumpWidget(const TruequiApp());

    // Verifica que el título de la pantalla exista
    expect(find.text('Test de conexión'), findsOneWidget);

    // Verifica que el botón para probar la conexión con AWS exista
    expect(find.text('Comprobar conexión'), findsOneWidget);

    // Verifica que NO exista un contador en cero (como en la app por defecto de Flutter)
    expect(find.text('0'), findsNothing);
  });
}