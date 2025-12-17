import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evento.dart';
import 'api_service.dart';
import 'CarritoProductoPage.dart';

// Página para mostrar los artículos de un vendedor
class ProductosVendedorPage extends StatefulWidget {
  final String idpersona;
  final String cedula;
  final String idpersona1;
  final String cedula1;

  const ProductosVendedorPage({Key? key, required this.idpersona,required this.cedula, required this.idpersona1, required this.cedula1}) : super(key: key);

  @override
  State<ProductosVendedorPage> createState() => _ProductosVendedorPageState();
}

class _ProductosVendedorPageState extends State<ProductosVendedorPage> {
  late Future<List<Producto>> _productosFuture;
  late Future<Persona> _personaInfoFuture; // Added for person info
  final Map<int, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _productosFuture = ApiService.fetchProductosPorVendedor(widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona); // Initialize person info fetch
  }

  void _incrementQuantity(int productoId) {
    setState(() {
      _itemQuantities.update(productoId, (value) => value + 1, ifAbsent: () => 1);
    });
  }

  void _decrementQuantity(int productoId) {
    setState(() {
      if (_itemQuantities.containsKey(productoId) && _itemQuantities[productoId]! > 1) {
        _itemQuantities.update(productoId, (value) => value - 1);
      } else {
        _itemQuantities.remove(productoId);
      }
    });
  }

  void _addToCart(Producto producto, int quantity) {
    // Implementa la lógica para agregar el artículo y la cantidad al carrito
    // Por ejemplo, puedes usar un proveedor de estado o una lista global
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto.elproducto} (x$quantity) agregado al carrito'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

// Reusing the _buildPersonaInfo method from EventoPage
  Widget _buildPersonaInfo(Persona persona) {
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${widget.cedula}.jpg";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              fotoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            persona.lapersona,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19, // Tamaño adecuado para un nombre
              fontWeight: FontWeight.bold, // Letras resaltadas
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87, // Color del texto
              shadows: [ // Efecto repujado/sombra sutil
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }






  @override
  Widget build(BuildContext context) {
    // Determinar el número de columnas basado en el ancho de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 5 : 2; // 5 columnas para pantallas anchas, 2 para estrechas
    final childAspectRatio = screenWidth > 600 ? 0.6 : 0.7; // Ajustar la relación de aspecto

    return Scaffold(
      appBar: AppBar(
        title: const Text('Artículos del vendedor'),
        backgroundColor: Colors.blue[700],
      ),

 

      body: Column(
          children: [
              // 1. Información de la persona (FutureBuilder<Persona>)
          FutureBuilder<Persona>(
            future: _personaInfoFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                print("Error FutureBuilder Persona (PortafolioPage): ${snapshot.error}");
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'No se pudo cargar la información del usuario.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                );
              } else if (snapshot.hasData) {
                return _buildPersonaInfo(snapshot.data!);
              } else {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text('No hay información del usuario disponible.')),
                );
              }
            },
          ),



   // 2. La lista de productos (FutureBuilder<List<Producto>>)
          Expanded( // Wrap the second FutureBuilder in Expanded so the GridView takes available space
            child: FutureBuilder<List<Producto>>(
       future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final productos = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                final fotoUrl = "https://educaysoft.org/descargar3.php?archivo=producto${producto.idproducto}.jpg";
                final quantity = _itemQuantities[producto.idproducto] ?? 1;

                return Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: InkWell(
                    onTap: () {
                      // Opcional: Lógica para ver detalles del artículo
                    },
                    borderRadius: BorderRadius.circular(15.0),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(15.0)),
                            child: Image.network(
                              fotoUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 80, color: Colors.grey),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto.elproducto,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  producto.detalle,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Precio: \$${producto.precio.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.green,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 24),
                                      onPressed: () => _decrementQuantity(producto.idproducto),
                                    ),
                                    Text(
                                      '$quantity',
                                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 24),
                                      onPressed: () => _incrementQuantity(producto.idproducto),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _addToCart(producto, quantity),
                                    icon: const Icon(Icons.shopping_cart, size: 18),
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('No hay artículos disponibles para este vendedor.'));
          }
        },
      ),
      ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Ajuste para que no se superponga
        child: FloatingActionButton.extended(
          onPressed: () {
            // Lógica para navegar a la página del carrito

 final String compradorId = widget.idpersona1;
 final String cedulaId = widget.cedula1;

  // Opcionalmente, para depuración, verifica si es null (no debería serlo si el diseño es correcto)
  if (compradorId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error: ID de comprador no disponible.')),
    );
    return; // Detener la navegación si el ID es nulo
 }


                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CarritoProductoPage(idpersona: compradorId,cedula:cedulaId),
                              ),
                            );



          //  ScaffoldMessenger.of(context).showSnackBar(
           //   const SnackBar(content: Text('Navegando al carrito de compras...')),
           //1 );
          },
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('Ver Carrito'),
          backgroundColor: Colors.orange,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
