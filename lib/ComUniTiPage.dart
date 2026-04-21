import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'ProductoVendedorPage.dart'; 
import 'tipo_oferta.dart';

class ComUniTiPage extends StatefulWidget {
  final String idpersona;
  final String cedula;
  final String? initialCategory;
  final bool showBackButton;

  const ComUniTiPage({
    Key? key,
    required this.idpersona,
    required this.cedula,
    this.initialCategory,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  State<ComUniTiPage> createState() => _ComUniTiPageState();
}

class _ComUniTiPageState extends State<ComUniTiPage> {
  late Future<List<ProductoFeed>> _productosFuture;
  late Future<List<TipoOferta>> _tiposFuture;
  String _selectedCategory = 'Todos'; // 'Todos', 'Venta', 'Alquiler', 'Servicio', etc.
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? 'Todos';
    _productosFuture = ApiService.fetchTodosLosProductos();
    _tiposFuture = ApiService.fetchTipoOferta();
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
          padding: EdgeInsets.only(
            top: widget.showBackButton ? MediaQuery.of(context).padding.top + 10 : 15,
            bottom: 15,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (widget.showBackButton)
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              const Text(
                'ComUniTi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
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

        // Dynamic Filtros Ribbon
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: FutureBuilder<List<TipoOferta>>(
            future: _tiposFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 45, child: Center(child: LinearProgressIndicator()));
              }
              
              if (snapshot.hasError) {
                return Row(
                  children: [
                    const Text('Error al cargar categorías', style: TextStyle(color: Colors.red, fontSize: 12)),
                    TextButton(onPressed: () => setState(() => _tiposFuture = ApiService.fetchTipoOferta()), child: const Text('Reintentar'))
                  ],
                );
              }

              List<String> categories = ['Todos'];
              if (snapshot.hasData) {
                categories.addAll(snapshot.data!.map((e) => e.nombre).toList());
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: categories.map((cat) {
                    Color baseCol = Colors.blue.shade600;
                    String cleanCat = cat.toLowerCase();
                    if (cleanCat.contains('venta')) baseCol = Colors.indigo.shade800;
                    else if (cleanCat.contains('alquiler')) baseCol = Colors.orange;
                    else if (cleanCat.contains('servicio')) baseCol = Colors.green;
                    else if (cleanCat.contains('donación') || cleanCat.contains('donacion')) baseCol = Colors.pink;
                    else if (cleanCat.contains('trueque')) baseCol = Colors.teal;
                    else if (cleanCat.contains('cambio')) baseCol = Colors.cyan;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _buildCategoryButton(cat, baseCol),
                    );
                  }).toList(),
                ),
              );
            },
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

                if (_searchQuery.isNotEmpty) {
                  final query = _searchQuery.toLowerCase();
                  productos = productos.where((p) => 
                    p.elproducto.toLowerCase().contains(query) || 
                    p.nombrevendedor.toLowerCase().contains(query)
                  ).toList();
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
    return Container(
      constraints: const BoxConstraints(minWidth: 100),
      child: ElevatedButton(
        onPressed: () {
          _onCategorySelected(category);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? color.withOpacity(0.8) : color,
          foregroundColor: Colors.white,
          elevation: isSelected ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isSelected ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
          ),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        ),
        child: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                    // Stock Info
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 12, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Stock disponible: ${producto.stock.toStringAsFixed(producto.stock.truncateToDouble() == producto.stock ? 0 : 2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
