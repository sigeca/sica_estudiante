import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'evento.dart';
import 'api_service.dart';
import 'ArticuloVendedorPage.dart'; // Importa la nueva página de artículos

class ComUniTiPage extends StatefulWidget {
  final String idpersona;

  const ComUniTiPage({Key? key, required this.idpersona}) : super(key: key);

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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: vendedores.length,
                  itemBuilder: (context, index) {
                    final vendedor = vendedores[index];
                    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${vendedor.cedula}.jpg";
                    return Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          vendedor.elvendedor,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Nuevo botón "Ver artículos"
                        ElevatedButton(
                          onPressed: () {
                            // Navegar a la página de artículos del vendedor, pasando el idpersona
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticulosVendedorPage(idpersona: vendedor.idpersona.toString()),
                              ),
                            );
                          },
                          child: const Text('Ver artículos'),
                        ),
                      ],
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

