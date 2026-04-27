import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'api_service.dart';
import 'evento.dart';

class CumplimientoAlimentacionPage extends StatefulWidget {
  final String idalimentacion;
  final String nombreAlimento;
  final String instruccion;
  final String fechaDesde;
  final String fechaHasta;
  final String? videoEnlace;

  const CumplimientoAlimentacionPage({
    Key? key, 
    required this.idalimentacion, 
    required this.nombreAlimento,
    required this.instruccion,
    required this.fechaDesde,
    required this.fechaHasta,
    this.videoEnlace,
  }) : super(key: key);

  @override
  _CumplimientoAlimentacionPageState createState() => _CumplimientoAlimentacionPageState();
}

class _CumplimientoAlimentacionPageState extends State<CumplimientoAlimentacionPage> {
  // Ahora guardamos la hora formateada: "2023-10-25" -> "14:30"
  Map<String, List<String>> _horasCumplimiento = {}; 
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
      if (widget.fechaDesde.isEmpty || widget.fechaHasta.isEmpty) return;
      DateTime inicio = DateTime.parse(widget.fechaDesde);
      DateTime fin = DateTime.parse(widget.fechaHasta);
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
      final cumplimientos = await ApiService.fetchCumplimientosAlimentacion(widget.idalimentacion);
      
      Map<String, List<String>> tempMap = {};
      for (var c in cumplimientos) {
        if (c.fecha.isNotEmpty) {
           final time = c.hora.length >= 5 ? c.hora.substring(0, 5) : c.hora;
           if (!tempMap.containsKey(c.fecha)) {
             tempMap[c.fecha] = [];
           }
           tempMap[c.fecha]!.add(time);
        }
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

  Future<void> _toggleCheck(DateTime initialDate) async {
    // 1. Seleccionar Fecha
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "SELECCIONE FECHA DE CUMPLIMIENTO",
    );

    if (pickedDate == null) return;

    // 2. Seleccionar Hora
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "SELECCIONE HORA DE CUMPLIMIENTO",
    );

    if (pickedTime != null) {
      try {
        final String fechaString = DateFormat('yyyy-MM-dd').format(pickedDate);
        final String horaString = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}:00";
        
        await ApiService.registrarCumplimientoAlimentacion(
            widget.idalimentacion, 
            fechaString, 
            horaString
        );

        // Recargamos para obtener los datos actualizados
        await _cargarDatos();

      } catch (e) {
        print('Error en la operación: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No se pudo actualizar el cumplimiento"))
        );
      }
    }
  }

  // --- FUNCIÓN PARA ABRIR VIDEO ---
  Future<void> _lanzarURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    String finalUrl = urlString.trim();
    if (!finalUrl.startsWith('http')) {
      finalUrl = 'https://www.youtube.com/watch?v=$finalUrl';
    }

    final Uri uri = Uri.parse(finalUrl);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('No se pudo lanzar $uri');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el video: $e')),
        );
      }
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
            Text(widget.nombreAlimento, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
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
                    Text(widget.instruccion, style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87), textAlign: TextAlign.center),
                    if (widget.videoEnlace != null && widget.videoEnlace!.isNotEmpty) ...[
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: () => _lanzarURL(widget.videoEnlace),
                        icon: Icon(Icons.play_circle_fill, size: 18),
                        label: Text("VER VIDEO TUTORIAL", style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final Set<String> allDateStrings = {};
                    for (var d in _diasTratamiento) {
                      allDateStrings.add(DateFormat('yyyy-MM-dd').format(d));
                    }
                    allDateStrings.addAll(_horasCumplimiento.keys);
                    
                    // Siempre asegurar que hoy esté visible si el plan está activo o reciente
                    allDateStrings.add(DateFormat('yyyy-MM-dd').format(DateTime.now()));

                    final List<DateTime> displayDates = allDateStrings.map((s) => DateTime.parse(s)).toList();
                    displayDates.sort((a, b) => b.compareTo(a)); // Más reciente arriba

                    if (displayDates.isEmpty) return Center(child: Text("Sin fechas registradas"));

                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: displayDates.length,
                      separatorBuilder: (ctx, i) => Divider(height: 1, indent: 70),
                      itemBuilder: (context, index) {
                        DateTime fecha = displayDates[index];
                        String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
                        String diaSemana = DateFormat('EEEE', 'es').format(fecha);
                        String mes = DateFormat('MMM', 'es').format(fecha).toUpperCase();
                        String diaNumero = DateFormat('d').format(fecha);
                        diaSemana = "${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}";
                        
                        bool cumplido = _horasCumplimiento.containsKey(fechaStr);
                        List<String> horas = _horasCumplimiento[fechaStr] ?? [];
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
                                          Text("Tomas: ${horas.join(', ')}", style: TextStyle(color: Colors.green[600], fontSize: 13, fontWeight: FontWeight.w500))
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
                    );
                  }
                ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _toggleCheck(DateTime.now()),
        backgroundColor: Colors.teal,
        label: Text("REGISTRAR TOMA"),
        icon: Icon(Icons.add_task),
      ),
    );
  }
}
