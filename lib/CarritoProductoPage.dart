import 'package:flutter/material.dart';
import 'evento.dart';
import 'api_service.dart';
import 'FacturaFormPage.dart';

class CarritoProductoPage extends StatelessWidget {
  final String idpersona;
  final String cedula;

  const CarritoProductoPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Carrito de Compras'),
        backgroundColor: Colors.teal,
      ),
      body: CarritoProductoView(idpersona: idpersona, cedula: cedula),
    );
  }
}

class CarritoProductoView extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const CarritoProductoView({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  State<CarritoProductoView> createState() => _CarritoProductoViewState();
}

class _CarritoProductoViewState extends State<CarritoProductoView> {
  final Map<int, int> _itemQuantities = {};
  List<Producto>? _listaProductos;
  String? _ownerName;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
    _cargarDatosPersona();
  }

  void _cargarDatosPersona() async {
    try {
      final persona = await ApiService.fetchPersonaInfo(widget.idpersona);
      setState(() {
        _ownerName = persona.lapersona;
      });
    } catch (e) {
      debugPrint("Error al cargar datos de la persona: $e");
    }
  }

  void _cargarProductos() async {
    try {
      final productos = await ApiService.fetchProductosCarrito(widget.idpersona);
      setState(() {
        _listaProductos = productos;
        for (var prod in productos) {
          _itemQuantities[prod.idproducto] = prod.cantidad.toInt();
        }
      });
    } catch (e) {
      debugPrint("Error al cargar productos: $e");
    }
  }

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

  Future<void> _restToCart(Producto producto, int quantity) async {
    if (quantity <= 0) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Procesando devolución de ${producto.elproducto}...')),
    );

    bool exito = await ApiService.devolverProductoCarritoFlutter(
      producto.idcarritoproducto
    );

    if (exito) {
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

    final success = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => FacturaFormPage(
          idpersona: widget.idpersona,
          cedula: widget.cedula,
          cartItems: _listaProductos!,
          itemQuantities: _itemQuantities,
        ),
      ),
    );

    if (success == true) {
      _cargarProductos();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _listaProductos == null
            ? const Center(child: CircularProgressIndicator())
            : _listaProductos!.isEmpty
                ? const Center(child: Text("Tu carrito está vacío"))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                    itemCount: _listaProductos!.length,
                    itemBuilder: (context, index) {
                      final producto = _listaProductos![index];
                      final fotoUrl = "https://educaysoft.org/descargarproducto.php?archivo=producto${producto.idproducto}.jpg";
                      final int quantity = _itemQuantities[producto.idproducto] ?? 0;
                      final double maxDisponible = producto.cantidad;
                      final bool tieneCantidad = quantity > 0;

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: () => _mostrarZoomImagen(context, fotoUrl, producto.elproducto),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    fotoUrl,
                                    width: 90, height: 90, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: Colors.grey[100], child: const Icon(Icons.shopping_bag, size: 40)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(producto.elproducto, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Vendedor: ${producto.elcustodio}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('\$${producto.precio.toStringAsFixed(2)}', 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle, color: Colors.redAccent), 
                                              onPressed: tieneCantidad ? () => _decrementQuantity(producto.idproducto) : null,
                                            ),
                                            Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                            IconButton(
                                              icon: const Icon(Icons.add_circle, color: Colors.teal), 
                                              onPressed: (quantity < maxDisponible) ? () => _incrementQuantity(producto.idproducto, maxDisponible) : null,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: tieneCantidad ? () => _restToCart(producto, quantity) : null,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text("QUITAR DEL CARRITO"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade50,
                                        foregroundColor: Colors.red,
                                        elevation: 0,
                                        minimumSize: const Size(double.infinity, 40),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        if (_listaProductos != null && _listaProductos!.isNotEmpty)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _procesarPago,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('PAGAR AHORA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              backgroundColor: Colors.teal,
              elevation: 4,
            ),
          ),
      ],
    );
  }
}
