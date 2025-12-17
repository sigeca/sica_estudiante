import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart';
//
// --- Añadir la siguiente clase al final de EventoDetalleScreen.dart para que la funcionalidad funcione ---

class TemaDetalleScreen extends StatelessWidget {
  final String idtema;
  const TemaDetalleScreen({super.key, required this.idtema});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle del Tema ID: $idtema'),
        backgroundColor: Colors.purple,
      ),
      body: FutureBuilder<List<Tema>>(
        // Se asume que fetchTema existe en ApiService y devuelve un objeto Tema
        future: ApiService.fetchTema(idtema),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el tema: ${snapshot.error}'));
          } else {
            final Tema tema = snapshot.data!.first;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailTile(context, 'ID Tema', tema.idtema),
                  _buildDetailTile(context, 'Nombre Corto', tema.nombrecorto),
                  _buildDetailTile(context, 'Nombre Largo', tema.nombrelargo),
                  _buildDetailTile(context, 'N° Sesión', tema.numerosesion),
                  _buildDetailTile(context, 'Objetivo de Aprendizaje', tema.objetivoaprendizaje),
                  _buildDetailTile(context, 'Experiencia', tema.experiencia),
                  _buildDetailTile(context, 'Reflexión', tema.reflexion),
                  _buildDetailTile(context, 'Secuencia', tema.secuencia),
                  _buildDetailTile(context, 'Aprendizaje Autónomo', tema.aprendizajeautonomo),
                  _buildDetailTile(context, 'Duración (min)', tema.duracionminutos),
                  _buildDetailTile(context, 'video Tutorial', tema.enlace, isLink: true),
                  _buildDetailTile(context, 'Link Presentación', tema.linkpresentacion, isLink: true),
                  // Añade más campos según la estructura de la clase Tema
                ],
              ),
            );
          }
        },
      ),
    );
  }

Widget _buildDetailTile(BuildContext context, String label, String value, {bool isLink = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(height: 4.0),
          isLink
              ? InkWell(
                  // Simula un enlace
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Abriendo enlace: $value')),
                    );
                    // Aquí iría el código real para abrir el URL
                  },
                  child: Text(
                    value.isNotEmpty ? value : 'N/A',
                    style: TextStyle(
                      fontSize: 14.0,
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                )
              : Text(
                  value.isNotEmpty ? value : 'N/A',
                  style: const TextStyle(fontSize: 14.0),
                ),
          const Divider(),
        ],
      ),
    );
  }
}                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          



