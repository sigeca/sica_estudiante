import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'api_service.dart';
import 'evento.dart';




class CumplimientoAlimentacionPage extends StatefulWidget {
  final DetalleAlimentacion detalle;
  final String nombreAlimento;

  const CumplimientoAlimentacionPage({
    Key? key, 
    required this.detalle, 
    required this.nombreAlimento
  }) : super(key: key);

  @override
  _CumplimientoAlimentacionPageState createState() => _CumplimientoAlimentacionPageState();
}

class _CumplimientoAlimentacionPageState extends State<CumplimientoAlimentacionPage> {
  Map<String, bool> _cumplimientoMap = {}; // Fecha -> Cumplido (tinyint 0/1)
  bool isLoading = true;
  List<DateTime> _diasPlan = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null).then((_) {
      _generarDias();
      _cargarDatos();
    });
  }

  void _generarDias() {
    DateTime inicio = DateTime.parse(widget.detalle.fechadesde);
    DateTime fin = DateTime.parse(widget.detalle.fechahasta);
    int diff = fin.difference(inicio).inDays;
    for (int i = 0; i <= diff; i++) {
      _diasPlan.add(inicio.add(Duration(days: i)));
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar desde la tabla cumplimientoalimentacion
      final data = await ApiService.fetchCumplimientosAlimentacion(widget.detalle.iddetallealimentacion);
      setState(() {
        _cumplimientoMap = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleCumplimiento(DateTime fecha) async {
    final String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
    bool actual = _cumplimientoMap[fechaStr] ?? false;
    
    try {
      await ApiService.registrarCumplimientoAlimentacion(
        widget.detalle.iddetallealimentacion,
        fecha,
        actual ? 0 : 1
      );
      _cargarDatos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al actualizar")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Seguimiento: ${widget.nombreAlimento}"),
        backgroundColor: Colors.orange,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: _diasPlan.length,
            itemBuilder: (context, index) {
              DateTime fecha = _diasPlan[index];
              String fStr = DateFormat('yyyy-MM-dd').format(fecha);
              bool check = _cumplimientoMap[fStr] ?? false;

              return ListTile(
                leading: Icon(check ? Icons.check_box : Icons.check_box_outline_blank, 
                             color: check ? Colors.green : Colors.grey),
                title: Text(DateFormat('EEEE d MMMM', 'es').format(fecha)),
                onTap: () => _toggleCumplimiento(fecha),
              );
            },
          ),
    );
  }
}
