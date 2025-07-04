import 'package:flutter/material.dart';

class DetallePropuestaScreen extends StatelessWidget {
  final Map<String, dynamic> propuesta;

  const DetallePropuestaScreen({super.key, required this.propuesta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Propuesta')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              propuesta['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              propuesta['descripcion'] ?? 'Sin descripción',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (propuesta.containsKey('empresa'))
              Text(
                'Empresa: ${propuesta['empresa']}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            if (propuesta.containsKey('region'))
              Text(
                'Región: ${propuesta['region']}',
                style: const TextStyle(fontSize: 16),
              ),
            if (propuesta.containsKey('comuna'))
              Text(
                'Comuna: ${propuesta['comuna']}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 16),
            if (propuesta.containsKey('requisitos'))
              Text(
                'Requisitos: ${propuesta['requisitos']}',
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Aquí más adelante vas a guardar el "me gusta" en Firestore
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Me interesa (like enviado)')),
                );
              },
              child: const Text('Me interesa'),
            ),
          ],
        ),
      ),
    );
  }
}
