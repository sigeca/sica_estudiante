import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'ProductoVendedorPage.dart'; 

class ComUniTiPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const ComUniTiPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  State<ComUniTiPage> createState() => _ComUniTiPageState();
}

class _ComUniTiPageState extends State<ComUniTiPage> {
  late Future<List<ProductoFeed>> _productosFuture;
  String _selectedCategory = 'Todos'; // 'Todos', 'Venta', 'Alquiler', 'Servicios'

  @override
  void initState() {
    super.initState();
    _productosFuture = ApiService.fetchTodosLosProductos();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header con título
        Container(
          width: double.infinity,
          color: Colors.blue.shade800,
          padding: const EdgeInsets.only(top: 15, bottom: 15),
          child: const Text(
            'ComUniTi',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
          ),
        ),

        // Filtros (Venta, Alquiler, Servicios)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCategoryButton('Venta', Colors.indigo.shade800),
              _buildCategoryButton('Alquiler', Colors.orange),
              _buildCategoryButton('Servicios', Colors.green),
            ],
          ),
        ),
        
        const SizedBox(height: 10),

        // GridView de Productos
        Expanded(
          child: FutureBuilder<List<ProductoFeed>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                // Filtrar según categoría
                List<ProductoFeed> productos = snapshot.data!;
                if (_selectedCategory != 'Todos') {
                  productos = productos.where((p) => p.tipo.toLowerCase().contains(_selectedCategory.toLowerCase())).toList();
                }

                if (productos.isEmpty) {
                  return const Center(child: Text('No hay productos en esta categoría.'));
                }

                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth > 600 ? 4 : 2;

                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.68, // Ajustado para dar más espacio vertical al texto
                  ),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    return ProductoFeedCard(
                      producto: productos[index],
                      currentUserPersonaId: widget.idpersona,
                      currentUserCedula: widget.cedula,
                    );
                  },
                );
              } else {
                return const Center(child: Text('No hay productos disponibles.'));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(String category, Color color) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ElevatedButton(
          onPressed: () {
            _onCategorySelected(isSelected ? 'Todos' : category);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? color.withOpacity(0.8) : color,
            foregroundColor: Colors.white,
            elevation: isSelected ? 0 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: isSelected ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

class ProductoFeedCard extends StatelessWidget {
  final ProductoFeed producto;
  final String currentUserPersonaId;
  final String currentUserCedula;

  const ProductoFeedCard({
    Key? key,
    required this.producto,
    required this.currentUserPersonaId,
    required this.currentUserCedula,
  }) : super(key: key);

  Color _getBadgeColor(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'venta':
        return Colors.deepOrange.shade600;
      case 'alquiler':
        return Colors.orange.shade600;
      case 'trueque':
        return Colors.green.shade600;
      case 'servicios':
        return Colors.teal.shade600;
      case 'ventas':
        return Colors.indigo.shade600;
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final fotoProductoUrl = "https://educaysoft.org/descargarproducto.php?archivo=producto${producto.idproducto}.jpg";
    final fotoVendedorUrl = "https://educaysoft.org/descargar2.php?archivo=${producto.cedulavendedor}.jpg";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductosVendedorPage(
              idpersona: producto.idvendedor.toString(),
              cedula: producto.cedulavendedor,
              idpersona1: currentUserPersonaId,
              cedula1: currentUserCedula,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen con Badges
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      fotoProductoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(producto.tipo),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        producto.tipo,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (producto.tipo.toLowerCase() == 'trueque' && producto.subtipo.isNotEmpty)
                    Positioned(
                      top: 32,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          producto.subtipo,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Info Producto, Vendedor y Precio
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 6.0, 8.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nombre del Producto y Precio
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            producto.elproducto,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${producto.precio.toStringAsFixed(producto.precio.truncateToDouble() == producto.precio ? 0 : 2)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.indigo.shade900,
                              ),
                            ),
                            if (producto.tipo.toLowerCase() == 'alquiler')
                              Text(
                                '/mes',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    // Info Vendedor
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.transparent,
                          backgroundImage: NetworkImage(fotoVendedorUrl),
                          onBackgroundImageError: (_, __) => const Icon(Icons.person, size: 10),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            producto.nombrevendedor,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade800,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
