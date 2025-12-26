import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'api_service.dart';
import 'evento.dart';

class CumplimientoPage extends StatefulWidget {
  final DetalleMedicacion detalle;
  final String nombreMedicamento;

  const CumplimientoPage({
    Key? key, 
    required this.detalle, 
    required this.nombreMedicamento
  }) : super(key: key);

  @override
  _CumplimientoPageState createState() => _CumplimientoPageState();
}

class _CumplimientoPageState extends State<CumplimientoPage> {
  // Ahora guardamos la hora formateada: "2023-10-25" -> "14:30"
  Map<String, String> _horasCumplimiento = {}; 
  bool isLoading = true;
  List<DateTime> _diasTratamiento = [];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es', null).then((_) {
      if (mounted) {
        _generarDias();
        _cargarDatos();
      }
    });
  }

  void _generarDias() {
    try {
      if (widget.detalle.fechadesde.isEmpty || widget.detalle.fechahasta.isEmpty) return;
      DateTime inicio = DateTime.parse(widget.detalle.fechadesde);
      DateTime fin = DateTime.parse(widget.detalle.fechahasta);
      _diasTratamiento.clear();
      int diasDiferencia = fin.difference(inicio).inDays;
      if(diasDiferencia < 0 || diasDiferencia > 1825) diasDiferencia = 0; 

      for (int i = 0; i <= diasDiferencia; i++) {
        _diasTratamiento.add(inicio.add(Duration(days: i)));
      }
    } catch (e) {
      print("Error generando días: $e");
    }
  }

  Future<void> _cargarDatos() async {
    try {
      final cumplimientos = await ApiService.fetchCumplimientos(widget.detalle.iddetallemedicacion);
      
      Map<String, String> tempMap = {};
      for (var c in cumplimientos) {
        // Extraemos la fecha para la llave y la hora para mostrarla
        final fechaKey = c.fechahora.substring(0, 10);
        final DateTime horaDt = DateTime.parse(c.fechahora);
        tempMap[fechaKey] = DateFormat('HH:mm').format(horaDt);
      }

      if (mounted) {
        setState(() {
          _horasCumplimiento = tempMap;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleCheck(DateTime fecha) async {
    final String fechaString = DateFormat('yyyy-MM-dd').format(fecha);
    final bool yaEstaCumplido = _horasCumplimiento.containsKey(fechaString);

    try {
      // Si ya está cumplido y se toca de nuevo, actualizamos la hora (o puedes implementar borrar con un longPress)
      // En este caso, según tu requerimiento, actualizaremos la hora a "Ahora"
      final DateTime fechaHoraToma = DateTime.now();
      
      await ApiService.registrarCumplimiento(
          widget.detalle.iddetallemedicacion, 
          fechaHoraToma, 
          1 
      );

      // Recargamos para obtener la hora exacta grabada en el servidor
      await _cargarDatos();

    } catch (e) {
      print('Error en la operación: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo actualizar el cumplimiento"))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Control Diario", style: TextStyle(fontSize: 18)),
            Text(widget.nombreMedicamento, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.teal))
        : Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                color: Colors.teal.withOpacity(0.05),
                child: Column(
                  children: [
                    Text("INSTRUCCIÓN MÉDICA", style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    SizedBox(height: 5),
                    Text(widget.detalle.detalle, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87), textAlign: TextAlign.center),
                  ],
                ),
              ),
              Expanded(
                child: _diasTratamiento.isEmpty 
                ? Center(child: Text("Sin fechas registradas"))
                : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _diasTratamiento.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    DateTime fecha = _diasTratamiento[index];
                    String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
                    String diaSemana = DateFormat('EEEE', 'es').format(fecha);
                    String mes = DateFormat('MMM', 'es').format(fecha).toUpperCase();
                    String diaNumero = DateFormat('d').format(fecha);
                    diaSemana = "${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}";
                    
                    bool cumplido = _horasCumplimiento.containsKey(fechaStr);
                    String? horaToma = _horasCumplimiento[fechaStr];
                    bool esHoy = DateFormat('yyyy-MM-dd').format(DateTime.now()) == fechaStr;

                    return Material(
                      color: cumplido ? Colors.green.withOpacity(0.05) : (esHoy ? Colors.teal.withOpacity(0.05) : Colors.white),
                      child: InkWell(
                        onTap: () => _toggleCheck(fecha),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: cumplido ? Colors.green : (esHoy ? Colors.teal : Colors.grey[200]),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Column(
                                  children: [
                                    Text(diaNumero, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: (cumplido || esHoy) ? Colors.white : Colors.black87)),
                                    Text(mes, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: (cumplido || esHoy) ? Colors.white : Colors.grey[600])),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(diaSemana, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cumplido ? Colors.green[700] : Colors.black87)),
                                    if (cumplido) 
                                      Text("Tomado a las: $horaToma", style: TextStyle(color: Colors.green[600], fontSize: 13, fontWeight: FontWeight.w500))
                                    else
                                      Text("Pendiente", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Icon(
                                cumplido ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: cumplido ? Colors.green : Colors.grey,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
