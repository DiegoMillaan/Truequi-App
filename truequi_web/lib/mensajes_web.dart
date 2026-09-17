import 'dart:ui';
import 'package:flutter/material.dart';
import 'home_web.dart'; 

class MensajesWeb extends StatelessWidget {
  const MensajesWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.5),
        elevation: 0,
        iconTheme: const IconThemeData(color: TruequiColors.purpura),
        title: const Text('Bandeja de Entrada', style: TextStyle(color: TruequiColors.textoOscuro, fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE5DFFF), Color(0xFFFFF3E0)], begin: Alignment.topLeft, end: Alignment.bottomRight))),
          BackdropFilter(filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60), child: Container(color: Colors.transparent)),
          
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  width: 800, height: 600,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(40), border: Border.all(color: Colors.white.withOpacity(0.9), width: 2)),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mark_chat_unread_rounded, size: 100, color: TruequiColors.amarillo.withOpacity(0.8)),
                        const SizedBox(height: 20),
                        const Text('Tus conversaciones', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: TruequiColors.textoOscuro)),
                        const SizedBox(height: 10),
                        const Text('Aún no tienes mensajes sobre tus trueques.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}