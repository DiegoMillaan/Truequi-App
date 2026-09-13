import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  final String correo;
  
  const PerfilPage({super.key, required this.correo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Perfil de: $correo'),
    );
  }
}