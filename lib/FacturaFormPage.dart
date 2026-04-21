import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class FacturaFormPage extends StatefulWidget {
  final String idpersona;
  final String cedula;
  final List<Producto> cartItems;
  final Map<int, int> itemQuantities;

  const FacturaFormPage({
    Key? key,
    required this.idpersona,
    required this.cedula,
    required this.cartItems,
    required this.itemQuantities,
  }) : super(key: key);

  @override
  _FacturaFormPageState createState() => _FacturaFormPageState();
}

class _FacturaFormPageState extends State<FacturaFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Header Controllers
  final TextEditingController _serieController = TextEditingController(text: '001');
  final TextEditingController _folioController = TextEditingController();
  final TextEditingController _fechaEmisionController = TextEditingController();
  final TextEditingController _fechaVencimientoController = TextEditingController();
  
  // Data for Selects
  Map<String, dynamic>? _initialData;
  List<EstadoFactura> _estados = [];
  List<TipoImpuesto> _impuestos = [];
  String? _selectedEstado;
  String? _selectedTipoPago;
  List<TipoPagoFactura> _tipopagos = [];
  String? _idCliente;
  String? _nombreCliente;

  bool _isLoading = true;
  
  // Line Items Data
  List<DetalleFactura> _detalles = [];
  
  // Totals
  double _subtotalGlobal = 0.0;
  double _descuentoGlobal = 0.0;
  double _impuestoGlobal = 0.0;
  double _totalFinal = 0.0;

  @override
  void initState() {
    super.initState();
    _folioController.text = DateFormat('YmdHis').format(DateTime.now());
    _fechaEmisionController.text = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    _fechaVencimientoController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _fetchData();
  }

  Future<void> _fetchData() async {
    final data = await ApiService.fetchFacturaInitialData(widget.idpersona);
    if (data['status'] == true) {
      setState(() {
        _initialData = data;
        if (data['cliente'] != null) {
          _idCliente = data['cliente']['idcliente'].toString();
          _nombreCliente = data['cliente']['elcliente'];
        }
        _estados = (data['estados'] as List).map((e) => EstadoFactura.fromJson(e)).toList();
        _tipopagos = (data['tipopagos'] as List).map((e) => TipoPagoFactura.fromJson(e)).toList();
        _impuestos = (data['impuestos'] as List).map((e) => TipoImpuesto.fromJson(e)).toList();
        
        if (_estados.isNotEmpty) _selectedEstado = _estados.first.idestadofactura;
        if (_tipopagos.isNotEmpty) _selectedTipoPago = _tipopagos.first.idtipopagofactura;
        
        // Initialize Detalles from Cart
        String defaultImpuesto = _impuestos.isNotEmpty ? _impuestos.first.idtipoimpuesto : "0";
        
        _detalles = widget.cartItems.map((p) {
          int cant = widget.itemQuantities[p.idproducto] ?? 1;
          double precio = p.precio;
          return DetalleFactura(
            idproducto: p.idproducto.toString(),
            descripcion: p.elproducto,
            cantidad: cant.toDouble(),
            preciounitario: precio,
            porcentajedescuento: 0.0,
            idtipoimpuesto: defaultImpuesto,
            total: cant * precio,
          );
        }).toList();
        
        _calculateTotals();
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${data['message']}')));
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    double subtotal = 0.0;
    double descuento = 0.0;
    double sumaPctImpuesto = 0.0;
    int count = 0;

    for (var det in _detalles) {
      double lineSub = det.cantidad * det.preciounitario;
      double lineDesc = lineSub * (det.porcentajedescuento / 100);
      subtotal += lineSub;
      descuento += lineDesc;
      
      // Get tax value
      var imp = _impuestos.firstWhere((i) => i.idtipoimpuesto == det.idtipoimpuesto, 
          orElse: () => TipoImpuesto(idtipoimpuesto: "0", nombre: "N/A", valor: 0.0));
      sumaPctImpuesto += imp.valor;
      count++;
    }

    double promedioImp = count > 0 ? (sumaPctImpuesto / count) : 0.0;
    double base = subtotal - descuento;
    double impuesto = base * (promedioImp / 100);
    double total = base + impuesto;

    setState(() {
      _subtotalGlobal = subtotal;
      _descuentoGlobal = descuento;
      _impuestoGlobal = impuesto;
      _totalFinal = total;
    });
  }

  Future<void> _submit() async {
    if (_idCliente == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: No se encontró el registro del cliente')));
      return;
    }

    setState(() => _isLoading = true);

    final header = Factura(
      idfactura: "",
      serie: _serieController.text,
      folio: _folioController.text,
      idcliente: _idCliente!,
      fechaemision: DateTime.parse(_fechaEmisionController.text.replaceAll(' ', 'T')),
      fechavencimiento: DateTime.parse(_fechaVencimientoController.text),
      idestadofactura: _selectedEstado!,
      idtipopagofactura: _selectedTipoPago!,
      subtotal: _subtotalGlobal,
      totalimpuesto: _impuestoGlobal,
      totaldescuento: _descuentoGlobal,
      totalfinal: _totalFinal,
    );

    final result = await ApiService.saveFactura(widget.idpersona, header, _detalles);

    setState(() => _isLoading = false);

    if (result['status'] == true) {
      _showSuccess(result['idfactura'].toString());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${result['message']}')));
    }
  }

  void _showSuccess(String idfactura) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Factura Guardada'),
        content: const Text('La factura se ha registrado con éxito en el sistema.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Back to cart (which should be cleared)
            },
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Ver PDF'),
            onPressed: () => _openPdf(idfactura),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf(String idfactura) async {
    final url = Uri.parse(ApiService.getFacturaPdfUrl(idfactura));
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el PDF')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Generar Factura'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Datos de Cabecera'),
              _buildHeaderFields(),
              const SizedBox(height: 20),
              _buildSectionTitle('Detalle de Productos'),
              _buildDetallesList(),
              const SizedBox(height: 20),
              _buildTotalsCard(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('GUARDAR FACTURA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
    );
  }

  Widget _buildHeaderFields() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildTextField(_serieController, 'Serie')),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(_folioController, 'Folio')),
              ],
            ),
            const SizedBox(height: 10),
            _buildTextField(TextEditingController(text: _nombreCliente ?? 'Cargando...'), 'Cliente', enabled: false),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildTextField(_fechaEmisionController, 'Emisión', enabled: false)),
                const SizedBox(width: 10),
                Expanded(child: _buildDropdownEstado()),
              ],
            ),
            const SizedBox(height: 10),
            _buildDropdownTipoPago(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool enabled = true}) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }

  Widget _buildDropdownEstado() {
    return DropdownButtonFormField<String>(
      value: _selectedEstado,
      decoration: InputDecoration(
        labelText: 'Estado',
        labelStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: _estados.map((e) => DropdownMenuItem(value: e.idestadofactura, child: Text(e.nombre, style: const TextStyle(fontSize: 12)))).toList(),
      onChanged: (val) => setState(() => _selectedEstado = val),
    );
  }

  Widget _buildDropdownTipoPago() {
    return DropdownButtonFormField<String>(
      value: _selectedTipoPago,
      decoration: InputDecoration(
        labelText: 'Tipo de Pago',
        labelStyle: const TextStyle(fontSize: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: _tipopagos.map((e) => DropdownMenuItem(value: e.idtipopagofactura, child: Text(e.nombre))).toList(),
      onChanged: (val) => setState(() => _selectedTipoPago = val),
    );
  }

  Widget _buildDetallesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _detalles.length,
      itemBuilder: (context, index) {
        final det = _detalles[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(det.descripcion, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetalleVal('Cant.', det.cantidad.toStringAsFixed(0)),
                    _buildDetalleVal('Precio', '\$${det.preciounitario.toStringAsFixed(2)}'),
                    _buildTaxDropdown(index),
                    _buildDetalleVal('Total', '\$${det.total.toStringAsFixed(2)}', isBold: true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleVal(String label, String val, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildTaxDropdown(int index) {
    return Column(
      children: [
        const Text('Impuesto', style: TextStyle(fontSize: 10, color: Colors.grey)),
        SizedBox(
          width: 80,
          child: DropdownButton<String>(
            isExpanded: true,
            value: _detalles[index].idtipoimpuesto,
            style: const TextStyle(fontSize: 11, color: Colors.black),
            items: _impuestos.map((i) => DropdownMenuItem(value: i.idtipoimpuesto, child: Text(i.nombre))).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _detalles[index] = DetalleFactura(
                    idproducto: _detalles[index].idproducto,
                    descripcion: _detalles[index].descripcion,
                    cantidad: _detalles[index].cantidad,
                    preciounitario: _detalles[index].preciounitario,
                    porcentajedescuento: _detalles[index].porcentajedescuento,
                    idtipoimpuesto: val,
                    total: _detalles[index].total,
                  );
                  _calculateTotals();
                });
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTotalsCard() {
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.green.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal:', '\$${_subtotalGlobal.toStringAsFixed(2)}'),
            _buildTotalRow('Descuento:', '-\$${_descuentoGlobal.toStringAsFixed(2)}'),
            _buildTotalRow('Impuesto:', '+\$${_impuestoGlobal.toStringAsFixed(2)}'),
            const Divider(),
            _buildTotalRow('TOTAL FINAL:', '\$${_totalFinal.toStringAsFixed(2)}', isFinal: true),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String val, {bool isFinal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isFinal ? 16 : 14, fontWeight: isFinal ? FontWeight.bold : FontWeight.normal)),
          Text(val, style: TextStyle(fontSize: isFinal ? 18 : 14, fontWeight: isFinal ? FontWeight.bold : FontWeight.normal, color: isFinal ? Colors.green.shade800 : Colors.black)),
        ],
      ),
    );
  }
}
