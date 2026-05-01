import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'evento.dart';
import 'SicaAppBar.dart';

class TemaDetalleScreen extends StatelessWidget {
  final String idtema;
  final String idpersona;
  final String cedula;

  const TemaDetalleScreen({
    Key? key,
    required this.idtema,
    required this.idpersona,
    required this.cedula,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SicaAppBar(
        idpersona: idpersona,
        cedula: cedula,
        title: 'Detalle del Tema',
      ),
      body: FutureBuilder<List<Tema>>(
        future: ApiService.fetchTema(idtema),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error al cargar el tema: ${snapshot.error}'));
          } else {
            if (snapshot.data == null || snapshot.data!.isEmpty) {
               return const Center(child: Text('No se encontró información del tema.'));
            }

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
                  _buildDetailTile(context, 'Objetivo', tema.objetivoaprendizaje),
                  _buildDetailTile(context, 'Experiencia', tema.experiencia),
                  _buildDetailTile(context, 'Reflexión', tema.reflexion),
                  _buildDetailTile(context, 'Secuencia', tema.secuencia),
                  _buildDetailTile(context, 'Autónomo', tema.aprendizajeautonomo),
                  _buildDetailTile(context, 'Duración (min)', tema.duracionminutos),
                  _buildDetailTile(context, 'Video Tutorial', tema.enlace, isLink: true, icon: Icons.play_circle_fill),
                  _buildDetailTile(context, 'Link Presentación', tema.linkpresentacion, isLink: true, icon: Icons.link),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<void> _lanzarURL(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;
    String finalUrl = urlString.trim();
    if (finalUrl.contains('.pdf') || finalUrl.contains('descargar.php')) {
      final encodedUrl = Uri.encodeComponent(finalUrl);
      finalUrl = 'https://docs.google.com/viewer?url=$encodedUrl';
    }
    final Uri uri = Uri.parse(finalUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo lanzar $uri');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir el enlace: $e')),
      );
    }
  }

  Widget _buildDetailTile(BuildContext context, String label, String value, {bool isLink = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$label:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0, color: Theme.of(context).primaryColor),
              ),
              if (icon != null) ...[
                const SizedBox(width: 5),
                Icon(icon, size: 18, color: Colors.grey),
              ]
            ],
          ),
          const SizedBox(height: 4.0),
          isLink
              ? InkWell(
                  onTap: () => _lanzarURL(context, value),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          value.isNotEmpty ? value : 'Enlace no disponible',
                          style: const TextStyle(
                            fontSize: 14.0,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                    ],
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
