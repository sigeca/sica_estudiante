import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'evento.dart';
import 'api_service.dart';
import 'ProductoVendedorPage.dart'; // Importa la nueva página de artículos

class ComUniTiPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const ComUniTiPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  State<ComUniTiPage> createState() => _ComUniTiPageState();
}

class _ComUniTiPageState extends State<ComUniTiPage> {
  late Future<List<Vendedor>> _vendedoresFuture;

  @override
  void initState() {
    super.initState();
    _vendedoresFuture = ApiService.fetchVendedores();
  }

  @override
  Widget build(BuildContext context) {
    // Determinar el número de columnas basado en el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 2; // 5 columnas para pantallas anchas, 2 para estrechas
    final childAspectRatio = screenWidth > 600 ? 0.7 : 0.8; // Ajustar la relación de aspecto

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Vendedores disponibles',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Vendedor>>(
            future: _vendedoresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final vendedores = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: vendedores.length,
                  itemBuilder: (context, index) {
                    final vendedor = vendedores[index];
                    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${vendedor.cedula}.jpg";
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductosVendedorPage(idpersona: vendedor.idpersona.toString(),cedula:vendedor.cedula, idpersona1: widget.idpersona,cedula1: widget.cedula
                            ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(10.0),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)),
                                child: Image.network(
                                  fotoUrl,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 80, color: Colors.grey),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      vendedor.elvendedor,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Ver artículos',
                                      style: TextStyle(fontSize: 12, color: Colors.blue),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text('No hay vendedores disponibles.'));
              }
            },
          ),
        ),
      ],
    );
  }
}
