import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'CarritoProductoPage.dart';
import 'SicaAppBar.dart';
import 'CartController.dart';

class ProductosVendedorPage extends StatefulWidget {
  final String idpersona;
  final String cedula;
  final String idpersona1;
  final String cedula1;

  const ProductosVendedorPage({
    Key? key, 
    required this.idpersona, 
    required this.cedula, 
    required this.idpersona1, 
    required this.cedula1
  }) : super(key: key);

  @override
  State<ProductosVendedorPage> createState() => _ProductosVendedorPageState();
}

class _ProductosVendedorPageState extends State<ProductosVendedorPage> {
  late Future<List<Producto>> _productosFuture;
  late Future<Persona> _personaInfoFuture;
  final Map<int, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _productosFuture = ApiService.fetchProductosPorVendedor(widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona);
  }

  // --- LÓGICA DE ZOOM (Basada en EjercicioCatalogoPage) ---
  void _mostrarZoomImagen(BuildContext context, String url, String nombre) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer( // Permite pellizcar para hacer zoom
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(nombre, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _incrementQuantity(int productoId, double stockMaximo) {
    setState(() {
      int currentQty = _itemQuantities[productoId] ?? 1;
      // Solo incrementa si no ha superado el stock disponible
      if (currentQty < stockMaximo) {
        _itemQuantities[productoId] = currentQty + 1;
      }
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

  void _addToCart(Producto producto, int quantity) async {
// Mostramos un indicador de carga si fuera necesario
  
  bool exito = await ApiService.addProductoCarrito(
    idpersona: widget.idpersona1, // ID de la persona que compra
    idproducto: producto.idproducto,
    cantidad: quantity,
    precio: double.parse(producto.precio.toString()), // Asegurar que sea double
  );

  if (exito) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${producto.elproducto} (x$quantity) añadido al carrito'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade800,
      ),
    );
    
    // Refrescar los productos para ver el stock actualizado inmediatamente
    setState(() {
      _productosFuture = ApiService.fetchProductosPorVendedor(widget.idpersona);
      _itemQuantities.remove(producto.idproducto); // Resetear la cantidad local seleccionada
      CartController().updateCartCount(widget.idpersona1); // Actualizar contador global
    });
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('❌ Error al conectar con el servidor'),
        backgroundColor: Colors.red,
      ),
    );
  }

  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: SicaAppBar(
        idpersona: widget.idpersona1,
        cedula: widget.cedula1,
      ),
    body: Column(
        children: [
          // Sección de perfil simplificada (Estilo EjercitacionGestionPage)
          FutureBuilder<Persona>(
            future: _personaInfoFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final persona = snapshot.data!;
              final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${widget.cedula}.jpg";
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Row(
                  children: [
                    CircleAvatar(radius: 25, backgroundImage: NetworkImage(fotoUrl)),
                    const SizedBox(width: 12),
                    Text(persona.lapersona, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: FutureBuilder<List<Producto>>(
              future: _productosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Sin productos"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final prod = snapshot.data![index];
                    final fotoUrl = "https://educaysoft.org/descargarproducto.php?archivo=producto${prod.idproducto}.jpg";
                    final quantity = _itemQuantities[prod.idproducto] ?? (prod.stock > 0 ? 1 : 0);
                   // Calculamos el stock que se muestra en pantalla
                    double stockVisual = prod.stock - quantity;
                    bool tieneStock = prod.stock > 0;




                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen con detección de toque para Zoom
                            GestureDetector(
                              onTap: () => _mostrarZoomImagen(context, fotoUrl, prod.elproducto),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      fotoUrl,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 100, height: 100,
                                        color: Colors.grey[100],
                                        child: const Icon(Icons.shopping_bag, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black45,
                                      child: Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prod.elproducto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(prod.detalle, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2),
                                  const SizedBox(height: 8),
                                  Text(
                                         'Precio: \$${prod.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)
                                   ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                        // El stock disminuye visualmente según aumenta quantity
                                        Text(
                                          'Stock disponible: ${stockVisual.toStringAsFixed(0)}', 
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold, 
                                            fontSize: 12, 
                                            color: tieneStock ? Colors.blueGrey : Colors.red
                                          )
                                        ),                                    

                                      // Selector de cantidad
                                      Row(
                                        children: [
                                            IconButton(
                                                      icon: const Icon(Icons.remove_circle_outline), 
                                                      onPressed: tieneStock ? () => _decrementQuantity(prod.idproducto) : null
                                                    ),

                                          Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
                                             IconButton(
                                                      icon: const Icon(Icons.add_circle_outline), 
                                                      // Deshabilitar si quantity llega al stock máximo
                                                      onPressed: (tieneStock && quantity < prod.stock) 
                                                          ? () => _incrementQuantity(prod.idproducto, prod.stock) 
                                                          : null,
                                                    ),

                                        ],
                                      ),
                                    ],
                                  ),
                                    ElevatedButton.icon(
                                      // Si stock es 0, onPressed es null (se deshabilita el botón)
                                      onPressed: tieneStock ? () => _addToCart(prod, quantity) : null,
                                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                                      label: Text(tieneStock ? "AÑADIR" : "SIN STOCK"),
                                      style: ElevatedButton.styleFrom(
                                        minimumSize: const Size(double.infinity, 36),
                                        backgroundColor: tieneStock ? Colors.blue.shade700 : Colors.grey,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),


                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CarritoProductoPage(idpersona: widget.idpersona1, cedula: widget.cedula1))),
        icon: const Icon(Icons.shopping_cart_checkout),
        label: const Text('VER CARRITO'),
        backgroundColor: Colors.orange.shade800,
      ),
    );
  }
}
