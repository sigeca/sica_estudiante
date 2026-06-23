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
  // Ahora guardamos la lista de cumplimientos por fecha
  Map<String, List<Cumplimiento>> _cumplimientosPorFecha = {}; 
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
      
      Map<String, List<Cumplimiento>> tempMap = {};
      for (var c in cumplimientos) {
        final fechaKey = c.fechahora.substring(0, 10);
        if (!tempMap.containsKey(fechaKey)) {
          tempMap[fechaKey] = [];
        }
        tempMap[fechaKey]!.add(c);
      }

      if (mounted) {
        setState(() {
          _cumplimientosPorFecha = tempMap;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _mostrarOpcionesDia(DateTime fecha) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
            List<Cumplimiento> tomasActualizadas = _cumplimientosPorFecha[fechaStr] ?? [];

            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Tomas del ${DateFormat('dd MMM yyyy', 'es').format(fecha)}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Divider(),
                  if (tomasActualizadas.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text("No hay tomas registradas en este día.", style: TextStyle(color: Colors.grey)),
                    ),
                  ...tomasActualizadas.map((toma) {
                    DateTime dt = DateTime.parse(toma.fechahora);
                    return ListTile(
                      leading: Icon(Icons.check_circle, color: Colors.green),
                      title: Text("Toma a las ${DateFormat('HH:mm').format(dt)}", style: TextStyle(fontWeight: FontWeight.w500)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () async {
                              final TimeOfDay? pickedTime = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.fromDateTime(dt),
                                helpText: "EDITAR HORA DE TOMA",
                              );
                              if (pickedTime != null) {
                                DateTime newDate = DateTime(fecha.year, fecha.month, fecha.day, pickedTime.hour, pickedTime.minute);
                                await ApiService.actualizarCumplimiento(toma.idcumplimiento, newDate, 1);
                                await _cargarDatos();
                                setModalState(() {});
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              await ApiService.eliminarCumplimiento(toma.idcumplimiento);
                              await _cargarDatos();
                              setModalState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final TimeOfDay? pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        helpText: "AGREGAR NUEVA TOMA",
                      );
                      if (pickedTime != null) {
                        DateTime newDate = DateTime(fecha.year, fecha.month, fecha.day, pickedTime.hour, pickedTime.minute);
                        await ApiService.registrarCumplimiento(widget.detalle.iddetallemedicacion, newDate, 1);
                        await _cargarDatos();
                        setModalState(() {});
                      }
                    },
                    icon: Icon(Icons.add),
                    label: Text("Añadir toma"),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  )
                ],
              ),
            );
          }
        );
      }
    );
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
                    
                    bool cumplido = _cumplimientosPorFecha.containsKey(fechaStr) && _cumplimientosPorFecha[fechaStr]!.isNotEmpty;
                    List<Cumplimiento> tomas = _cumplimientosPorFecha[fechaStr] ?? [];
                    List<String> horasToma = tomas.map((t) => DateFormat('HH:mm').format(DateTime.parse(t.fechahora))).toList();
                    bool esHoy = DateFormat('yyyy-MM-dd').format(DateTime.now()) == fechaStr;

                    return Material(
                      color: cumplido ? Colors.green.withOpacity(0.05) : (esHoy ? Colors.teal.withOpacity(0.05) : Colors.white),
                      child: InkWell(
                        onTap: () => _mostrarOpcionesDia(fecha),
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
                                      Text("Tomas a las: ${horasToma.join(', ')}", style: TextStyle(color: Colors.green[600], fontSize: 13, fontWeight: FontWeight.w500))
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
