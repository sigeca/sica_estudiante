import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'evento.dart';

class VendedorReportesView extends StatefulWidget {
  final String idcustodio;

  const VendedorReportesView({Key? key, required this.idcustodio}) : super(key: key);

  @override
  State<VendedorReportesView> createState() => _VendedorReportesViewState();
}

class _VendedorReportesViewState extends State<VendedorReportesView> {
  String _selectedIdCarrito = '0';
  String _selectedIdProducto = '0';
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;

  List<Map<String, String>> _carritosOptions = [{'id': '0', 'name': 'Todos los carritos'}];
  List<Map<String, String>> _productosOptions = [{'id': '0', 'name': 'Todos los productos'}];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final list = await ApiService.fetchHistoricocarritoproductoVendedor(widget.idcustodio);
      final Set<String> seenCarritos = {};
      final Set<String> seenProductos = {};

      for (var p in list) {
        if (p.idcarrito.isNotEmpty && p.idcarrito != '0' && !seenCarritos.contains(p.idcarrito)) {
          seenCarritos.add(p.idcarrito);
          _carritosOptions.add({'id': p.idcarrito, 'name': p.lapersona.isNotEmpty ? p.lapersona : 'Carrito ${p.idcarrito}'});
        }
        if (p.idproducto != 0 && !seenProductos.contains(p.idproducto.toString())) {
          seenProductos.add(p.idproducto.toString());
          _productosOptions.add({'id': p.idproducto.toString(), 'name': p.elproducto});
        }
      }
    } catch (e) {
      // Ignorar error, dejaremos las opciones por defecto
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isDesde) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  void _generarReporte() async {
    if (_fechaDesde == null || _fechaHasta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona las fechas Desde y Hasta')),
      );
      return;
    }

    final dDesde = "${_fechaDesde!.year}-${_fechaDesde!.month.toString().padLeft(2, '0')}-${_fechaDesde!.day.toString().padLeft(2, '0')}";
    final dHasta = "${_fechaHasta!.year}-${_fechaHasta!.month.toString().padLeft(2, '0')}-${_fechaHasta!.day.toString().padLeft(2, '0')}";

    final uri = Uri.parse('https://educaysoft.org/sica/index.php/historicocarritoproducto/generar_pdf'
        '?idcarrito=$_selectedIdCarrito'
        '&idproducto=$_selectedIdProducto'
        '&fechadesde=$dDesde'
        '&fechahasta=$dHasta');

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el reporte')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Criterios para Reporte PDF',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              
              const Text('El Carrito:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedIdCarrito,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                items: _carritosOptions.map((map) {
                  return DropdownMenuItem<String>(
                    value: map['id'],
                    child: Text(map['name']!),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedIdCarrito = val!;
                  });
                },
              ),
              const SizedBox(height: 15),

              const Text('El Producto:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value: _selectedIdProducto,
                isExpanded: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
                items: _productosOptions.map((map) {
                  return DropdownMenuItem<String>(
                    value: map['id'],
                    child: Text(map['name']!),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedIdProducto = val!;
                  });
                },
              ),
              const SizedBox(height: 15),

              const Text('Rango de Fecha de Carga:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Desde',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        child: Text(
                          _fechaDesde != null ? "${_fechaDesde!.year}-${_fechaDesde!.month.toString().padLeft(2, '0')}-${_fechaDesde!.day.toString().padLeft(2, '0')}" : 'Seleccionar',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Hasta',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        ),
                        child: Text(
                          _fechaHasta != null ? "${_fechaHasta!.year}-${_fechaHasta!.month.toString().padLeft(2, '0')}-${_fechaHasta!.day.toString().padLeft(2, '0')}" : 'Seleccionar',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generarReporte,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Generar Reporte'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
