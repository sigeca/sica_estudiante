import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';

class CarritoProductoPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const CarritoProductoPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  State<CarritoProductoPage> createState() => _CarritoProductoPageState();
}

class _CarritoProductoPageState extends State<CarritoProductoPage> {
  final Map<int, int> _itemQuantities = {};
  List<Producto>? _listaProductos;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  void _cargarProductos() async {
    try {
      final productos = await ApiService.fetchProductosCarrito(widget.idpersona);
      setState(() {
        _listaProductos = productos;
        // Sincronizar cantidades iniciales desde la base de datos
        for (var prod in productos) {
          _itemQuantities[prod.idproducto] = prod.cantidad.toInt(); // Asumiendo que 'cantidad' es el campo del modelo
        }
      });
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
    }
  }

  // --- MÉTODOS DE CANTIDAD ---

  void _incrementQuantity(int productoId, double maxLimit) {
    setState(() {
      int currentQty = _itemQuantities[productoId] ?? 0;
      if (currentQty < maxLimit) {
        _itemQuantities.update(productoId, (value) => value + 1, ifAbsent: () => 1);
      }
    });
  }

  void _decrementQuantity(int productoId) {
    setState(() {
      if (_itemQuantities.containsKey(productoId) && _itemQuantities[productoId]! > 0) {
        _itemQuantities.update(productoId, (value) => value - 1);
      }
    });
  }

  // --- LÓGICA DE ELIMINACIÓN ---

  Future<void> _restToCart(Producto producto, int quantity) async {
    if (quantity <= 0) return; // Seguridad extra

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Procesando devolución de ${producto.elproducto}...')),
    );

    bool exito = await ApiService.devolverProductoCarritoFlutter(
      producto.idcarritoproducto
    );

    if (exito) {
      // Refrescar el carrito completo desde el backend para mantener sincronización
      _cargarProductos();

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${producto.elproducto} eliminado del carrito'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error al devolver el producto'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // (El método _mostrarZoomImagen y _procesarPago se mantienen igual...)
  // ... [Omitidos por brevedad, pero mantenlos en tu archivo] ...

  void _mostrarZoomImagen(BuildContext context, String url, String nombre) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
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
          ],
        ),
      ),
    );
  }





Future<void> _procesarPago() async {
  if (_listaProductos == null || _listaProductos!.isEmpty) return;

  // 1. Mostrar diálogo de carga
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(child: CircularProgressIndicator()),
  );

  // 3. Llamar a la API de verificación de cliente
  bool esCliente = await ApiService.esCliente(widget.cedula);

  if (!esCliente) {
    Navigator.pop(context); // Cerrar diálogo de carga
    _mostrarErrorNoCliente();
    return;
  }

  // 2. Preparar los datos (ID del producto y su cantidad actual)
  List<Map<String, dynamic>> itemsAPagar = _listaProductos!.map((prod) {
    return {
      'idproducto': prod.idproducto,
      'cantidad': _itemQuantities[prod.idproducto] ?? 1,
    };
  }).toList();

  // 3. Llamar a la API
  bool exito = await ApiService.procesarPagoCarrito(widget.idpersona, itemsAPagar);

  // Cerrar diálogo de carga
  Navigator.pop(context);

  if (exito) {
    // 4. Limpiar el carrito localmente tras el éxito
    setState(() {
      _listaProductos = [];
      _itemQuantities.clear();
    });

    _mostrarMensajeExito();
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('❌ Error al procesar el pago')),
    );
  }
}





void _mostrarMensajeExito() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¡Pago Exitoso!'),
      content: const Text('Tus productos han sido procesados correctamente.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}


void _mostrarErrorNoCliente() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Text('Registro Requerido'),
        ],
      ),
      content: const Text('No puedes realizar el pago hasta que estés registrado como cliente.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}












  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: _listaProductos == null
          ? const Center(child: CircularProgressIndicator())
          : _listaProductos!.isEmpty
              ? const Center(child: Text("Tu carrito está vacío"))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _listaProductos!.length,
                  itemBuilder: (context, index) {
                    final producto = _listaProductos![index];
                    final fotoUrl = "https://educaysoft.org/descargarproducto.php?archivo=producto${producto.idproducto}.jpg";
                    
                    // Lógica de cantidad y límites
                    final int quantity = _itemQuantities[producto.idproducto] ?? 0;
                    final double maxDisponible = producto.cantidad; // Cantidad original en el carrito
                    final bool tieneCantidad = quantity > 0;

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
                            // Imagen (Igual que en ProductoVendedor)
                            GestureDetector(
                              onTap: () => _mostrarZoomImagen(context, fotoUrl, producto.elproducto),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  fotoUrl,
                                  width: 100, height: 100, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 100, height: 100, color: Colors.grey[100], child: const Icon(Icons.shopping_bag)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(producto.elproducto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Máximo en carrito: ${maxDisponible.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('\$${producto.precio.toStringAsFixed(2)}', 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                                      
                                      // SELECTOR DE CANTIDAD CON LÓGICA DE BLOQUEO
                                   //   Row(
                                     //   children: [
                                    //      IconButton(
                                      //      icon: const Icon(Icons.remove_circle_outline), 
                                      //      onPressed: tieneCantidad ? () => _decrementQuantity(producto.idproducto) : null,
                                      //    ),
                                       //   Text('$quantity', style: TextStyle(fontWeight: FontWeight.bold, color: tieneCantidad ? Colors.black : Colors.red)),
                                       //   IconButton(
                                       //     icon: const Icon(Icons.add_circle_outline), 
                                        //    onPressed: (quantity < maxDisponible) ? () => _incrementQuantity(producto.idproducto, maxDisponible) : null,
                                         // ),
                                     //   ],
                                    //  ),
                                    ],
                                  ),
                                  // BOTÓN DEVOLVER (Se deshabilita si quantity es 0)
                                  ElevatedButton.icon(
                                    onPressed: tieneCantidad ? () => _restToCart(producto, quantity) : null,
                                    icon: const Icon(Icons.assignment_return, size: 16),
                                    label: Text(tieneCantidad ? "DEVOLVER" : "SIN CANTIDAD"),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(double.infinity, 36),
                                      backgroundColor: tieneCantidad ? Colors.red.shade400 : Colors.grey[300],
                                      foregroundColor: tieneCantidad ? Colors.white : Colors.grey[600],
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
                ),
      floatingActionButton: FloatingActionButton.extended(
         onPressed: (_listaProductos != null && _listaProductos!.isNotEmpty) ? _procesarPago : null,
        icon: const Icon(Icons.payments_outlined),
        label: const Text('PAGAR AHORA'),
        backgroundColor: (_listaProductos != null && _listaProductos!.isNotEmpty) ? Colors.orange.shade800 : Colors.grey,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
