import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evento.dart';
import 'api_service.dart';

// Página para mostrar los artículos de un vendedor
class ArticulosVendedorPage extends StatefulWidget {
  final String idpersona;

  const ArticulosVendedorPage({Key? key, required this.idpersona}) : super(key: key);

  @override
  State<ArticulosVendedorPage> createState() => _ArticulosVendedorPageState();
}

class _ArticulosVendedorPageState extends State<ArticulosVendedorPage> {
  late Future<List<Articulo>> _articulosFuture;
  final Map<int, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _articulosFuture = ApiService.fetchArticulosPorVendedor(widget.idpersona);
  }

  void _incrementQuantity(int articuloId) {
    setState(() {
      _itemQuantities.update(articuloId, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decrementQuantity(int articuloId) {
    setState(() {
      if (_itemQuantities.containsKey(articuloId) && _itemQuantities[articuloId]! > 1) {
        _itemQuantities.update(articuloId, (value) => value - 1);
      } else {
        _itemQuantities.remove(articuloId);
      }
    });
  }

  void _addToCart(Articulo articulo, int quantity) {
    // Implementa la lógica para agregar el artículo y la cantidad al carrito
    // Por ejemplo, puedes usar un proveedor de estado o una lista global
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${articulo.elarticulo} (x$quantity) agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Artículos del vendedor'),
        backgroundColor: Colors.blue[700],
      ),
      body: FutureBuilder<List<Articulo>>(
        future: _articulosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final articulos = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // Cambiado a 5 columnas
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.6, // Ajustado para un aspecto más compacto
              ),
              itemCount: articulos.length,
              itemBuilder: (context, index) {
                final articulo = articulos[index];
                final fotoUrl = "https://educaysoft.org/descargar3.php?archivo=articulo${articulo.idarticulo}.jpg";
                final quantity = _itemQuantities[articulo.idarticulo] ?? 1;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15.0),
                          child: Image.network(
                            fotoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 80),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              articulo.elarticulo,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              articulo.detalle,
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Precio del producto
                            Text(
                              'Precio: \$${articulo.precio.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Selector de cantidad
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _decrementQuantity(articulo.idarticulo),
                                ),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => _incrementQuantity(articulo.idarticulo),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Botón de agregar al carrito
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => _addToCart(articulo, quantity),
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Añadir'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No hay artículos disponibles para este vendedor.'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Lógica para navegar a la página del carrito
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navegando al carrito de compras...')),
          );
        },
        icon: const Icon(Icons.shopping_cart_checkout),
        label: const Text('Ver Carrito'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
