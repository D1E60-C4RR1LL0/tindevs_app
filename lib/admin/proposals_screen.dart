import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class ProposalsScreen extends StatelessWidget {
  Future<void> _updatePropuesta({
    required String propuestaId,
    required String newEstado,
  }) async {
    final propuestaRef = FirebaseFirestore.instance
        .collection('propuestas')
        .doc(propuestaId);

    await propuestaRef.update({'estadoValidacion': newEstado});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('propuestas')
                // Si quieres ver TODAS, quita el where:
                // .where('estadoValidacion', isEqualTo: 'pendiente')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final propuestas = snapshot.data!.docs;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                DataColumn(label: Text('Título')),
                DataColumn(label: Text('Descripción')),
                DataColumn(label: Text('Estado')),
                DataColumn(label: Text('Documento')),
                DataColumn(label: Text('Acciones')),
              ],
              rows:
                  propuestas.map((propuestaDoc) {
                    final data = propuestaDoc.data() as Map<String, dynamic>;

                    return DataRow(
                      cells: [
                        DataCell(Text(data['titulo'] ?? '')),
                        DataCell(Text(data['descripcion'] ?? '')),
                        DataCell(Text(data['estadoValidacion'] ?? '')),
                        DataCell(
                          data['documentoValidacionUrl'] != null &&
                                  data['documentoValidacionUrl']
                                      .toString()
                                      .isNotEmpty
                              ? InkWell(
                                child: const Text(
                                  'Ver documento',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onTap: () async {
                                  final url = data['documentoValidacionUrl'];
                                  if (await canLaunchUrl(Uri.parse(url))) {
                                    await launchUrl(
                                      Uri.parse(url),
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'No se pudo abrir el documento.',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              )
                              : const Text('No subido'),
                        ),

                        DataCell(
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.check, color: Colors.green),
                                tooltip: 'Aprobar',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text('Confirmar aprobación'),
                                          content: Text(
                                            '¿Está seguro que desea aprobar esta propuesta?',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancelar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                            ),
                                            TextButton(
                                              child: Text('Aprobar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await _updatePropuesta(
                                      propuestaId: propuestaDoc.id,
                                      newEstado: 'aprobada',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Propuesta aprobada'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.close, color: Colors.red),
                                tooltip: 'Rechazar',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: Text('Confirmar rechazo'),
                                          content: Text(
                                            '¿Está seguro que desea rechazar esta propuesta?',
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text('Cancelar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                            ),
                                            TextButton(
                                              child: Text('Rechazar'),
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await _updatePropuesta(
                                      propuestaId: propuestaDoc.id,
                                      newEstado: 'rechazada',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Propuesta rechazada'),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          );
        },
      ),
    );
  }
}
