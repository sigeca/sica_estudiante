import 'package:flutter/material.dart';                                                                              
import 'package:http/http.dart' as http;
import 'dart:convert';                
import 'evento.dart';                 
import 'api_service.dart';     


class CarritoProductoPage extends StatefulWidget {
    final String idpersona;
    const CarritoProductoPage({Key? key, required this.idpersona}) : super(key: key);

    @override
    State<CarritoProductoPage> createState() => _CarritoProductoPageState();
}

class _CarritoProductoPageState extends State<CarritoProductoPage> {
    late Future<List<Producto>> _productosFuture;
    final Map<int,int> _itemQuantities ={};

    @override
    void initState(){
        super.initState();
        _productosFuture = ApiService.fetchProductosCarrito(widget.idpersona);
        //_productosFuture = ApiService.fetchProductosCarrito('1');
WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.idpersona),
        duration: Duration(seconds: 2),
      ),
    );
  });



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
    // Implementa la lógica para agregar el artículo y la cantidad al carrito   
    // Por ejemplo, puedes usar un proveedor de estado o una lista global
    ScaffoldMessenger.of(context).showSnackBar(                                 
      SnackBar(                                                                 
        content: Text('${producto.elproducto} (x$quantity) agregado al carrito'),
        duration: const Duration(seconds: 2),                                   
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
        title: const Text('Productos en el carrito del vendedor'),
        backgroundColor: Colors.blue[700],
      ),  
      body: FutureBuilder<List<Producto>>(
        future: _productosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error 2: ${snapshot.error}'));
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
                                    onPressed: () => _restToCart(producto, quantity),
                                    icon: const Icon(Icons.receipt_long, size: 18),
                                    label: const Text('Devolver'),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), // Ajuste para que no se superponga
        child: FloatingActionButton.extended(
          onPressed: () {
            // Lógica para navegar a la página del carrito
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navegando al carrito de compras...')),
            );
          },
          icon: const Icon(Icons.shopping_cart_checkout),
          label: const Text('Comprar/Pagar'),
          backgroundColor: Colors.orange,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );




}
}
