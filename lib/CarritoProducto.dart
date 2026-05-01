import 'package:flutter/material.dart';
import 'dart:convert';
import 'evento.dart';
import 'api_service.dart';
import 'SicaAppBar.dart';
import 'CartController.dart';

class CarritoProductoPage extends StatefulWidget {
  final String idpersona;
  final String cedula; // Añadido para consistencia

  const CarritoProductoPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  State<CarritoProductoPage> createState() => _CarritoProductoPageState();
}

class _CarritoProductoPageState extends State<CarritoProductoPage> {
  late Future<List<Producto>> _productosFuture;
  final Map<int, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _productosFuture = ApiService.fetchProductosCarrito(widget.idpersona);
  }

  // --- LÓGICA DE ZOOM ---
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

  void _restToCart(Producto producto, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('♻️ ${producto.elproducto} (x$quantity) devuelto'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
    CartController().updateCartCount(widget.idpersona);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: SicaAppBar(
        idpersona: widget.idpersona,
        cedula: widget.cedula,
      ),
      body: CarritoProductoView(
          idpersona: widget.idpersona, cedula: widget.cedula),
    );
  }
}

class CarritoProductoView extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const CarritoProductoView(
      {Key? key, required this.idpersona, required this.cedula})
      : super(key: key);

  @override
  State<CarritoProductoView> createState() => _CarritoProductoViewState();
}

class _CarritoProductoViewState extends State<CarritoProductoView> {
  late Future<List<Producto>> _productosFuture;
  final Map<int, int> _itemQuantities = {};

  @override
  void initState() {
    super.initState();
    _productosFuture = ApiService.fetchProductosCarrito(widget.idpersona);
  }

  // --- LÓGICA DE ZOOM ---
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
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(Icons.image_not_supported,
                        size: 100, color: Colors.grey),
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

  void _incrementQuantity(int productoId) {
    setState(() {
      _itemQuantities.update(productoId, (value) => value + 1,
          ifAbsent: () => 1);
    });
  }

  void _decrementQuantity(int productoId) {
    setState(() {
      if (_itemQuantities.containsKey(productoId) &&
          _itemQuantities[productoId]! > 1) {
        _itemQuantities.update(productoId, (value) => value - 1);
      } else {
        _itemQuantities.remove(productoId);
      }
    });
  }

  void _restToCart(Producto producto, int quantity) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('♻️ ${producto.elproducto} (x$quantity) devuelto'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
    CartController().updateCartCount(widget.idpersona);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<List<Producto>>(
            future: _productosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final productos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: productos.length,
                  itemBuilder: (context, index) {
                    final producto = productos[index];
                    final fotoUrl =
                        "https://educaysoft.org/descargarproducto.php?archivo=producto${producto.idproducto}.jpg";
                    final quantity = _itemQuantities[producto.idproducto] ?? 1;

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
                            // Imagen con Zoom
                            GestureDetector(
                              onTap: () => _mostrarZoomImagen(
                                  context, fotoUrl, producto.elproducto),
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
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[100],
                                        child: const Icon(Icons.shopping_bag,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  const Positioned(
                                    right: 4,
                                    bottom: 4,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.black45,
                                      child: Icon(Icons.zoom_in,
                                          size: 14, color: Colors.white),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Información y Controles
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(producto.elproducto,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  Text(producto.detalle,
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey[600]),
                                      maxLines: 2),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          '\$${producto.precio.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.green)),
                                      Row(
                                        children: [
                                          IconButton(
                                              icon: const Icon(Icons
                                                  .remove_circle_outline),
                                              onPressed: () =>
                                                  _decrementQuantity(
                                                      producto.idproducto)),
                                          Text('$quantity',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          IconButton(
                                              icon: const Icon(
                                                  Icons.add_circle_outline),
                                              onPressed: () =>
                                                  _incrementQuantity(
                                                      producto.idproducto)),
                                        ],
                                      ),
                                    ],
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () =>
                                        _restToCart(producto, quantity),
                                    icon: const Icon(Icons.assignment_return,
                                        size: 16),
                                    label: const Text("DEVOLVER"),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize:
                                          const Size(double.infinity, 36),
                                      backgroundColor: Colors.red.shade400,
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
              } else {
                return const Center(
                    child: Text('No hay artículos en tu carrito.'));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              // Lógica de Pago
            },
            icon: const Icon(Icons.payments_outlined),
            label: const Text('PAGAR AHORA'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: Colors.orange.shade800,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
      ],
    );
  }
}
