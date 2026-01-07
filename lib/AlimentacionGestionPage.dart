import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoAlimentacionPage.dart';

class AlimentacionGestionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const AlimentacionGestionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _AlimentacionGestionPageState createState() => _AlimentacionGestionPageState();
}

class _AlimentacionGestionPageState extends State<AlimentacionGestionPage> {
  List<Alimentacion> alimentaciones = [];
  String filter = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAlimentaciones();
  }

  Future<void> _cargarAlimentaciones() async {
    try {
      final data = await ApiService.fetchAlimentaciones(widget.idpersona);
      if (mounted) {
        setState(() {
          alimentaciones = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- MÉTODOS DE APOYO PARA UI ---

  Color _getColorEstado(int idEstado) {
    switch (idEstado) {
      case 1: return Colors.green; 
      case 2: return Colors.orange; 
      case 3: return Colors.red; 
      case 4: return Colors.blue; 
      default: return Colors.grey;
    }
  }

  Widget _buildEstadoChip(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(top: 4, bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLastTakenDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return Text("Sin registro de toma", 
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10));
    }

    try {
      final DateTime lastTaken = DateTime.parse(dateString);
      final DateTime today = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm');
      final String formattedDate = formatter.format(lastTaken);
      
      final lastTakenDateOnly = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final difference = todayDateOnly.difference(lastTakenDateOnly).inDays;

      String text;
      Color color;

      if (difference == 0) {
        text = "¡Hoy! ($formattedDate)";
        color = Colors.green.shade700;
      } else if (difference == 1) {
        text = "Ayer";
        color = Colors.orange.shade700;
      } else {
        text = "Hace $difference días";
        color = Colors.red.shade700;
      }
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 10, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      );
    } catch (e) {
      return Text("Error en fecha", style: TextStyle(fontSize: 10, color: Colors.grey));
    }
  }

  // --- DIÁLOGOS DE GESTIÓN ---

  void _mostrarDialogoAlimentacion({Alimentacion? alimentacionExistente}) {
    final isEditing = alimentacionExistente != null;
    final _nombreController = TextEditingController(text: isEditing ? alimentacionExistente.nombre : '');
    final _fechaDesdeController = TextEditingController(text: isEditing ? alimentacionExistente.fechadesde : '');
    final _fechaHastaController = TextEditingController(text: isEditing ? alimentacionExistente.fechahasta : '');
    int _estadoSeleccionado = isEditing ? alimentacionExistente.idestadoalimentacion : 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? "Editar Plan" : "Nuevo Plan"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(labelText: "Nombre del Plan", border: OutlineInputBorder(), prefixIcon: Icon(Icons.fitness_center)),
                ),
                SizedBox(height: 15),
                DropdownButton<int>(
                  value: _estadoSeleccionado,
                  isExpanded: true,
                  items: [
                    DropdownMenuItem(child: Text("Activo"), value: 1),
                    DropdownMenuItem(child: Text("Suspendido"), value: 2),
                    DropdownMenuItem(child: Text("Finalizado"), value: 4),
                  ],
                  onChanged: (val) => setStateDialog(() => _estadoSeleccionado = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
            ElevatedButton(
              onPressed: () async {
                if (_nombreController.text.isEmpty) return;
                Navigator.pop(context);
                if (isEditing) {
                  await ApiService.actualizarAlimentacion(alimentacionExistente.idalimentacion, _nombreController.text, 2, _estadoSeleccionado);
                } else {
                  // Valores por defecto para fechas si es nuevo
                  String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await ApiService.registrarAlimentacion(_nombreController.text, hoy, hoy, widget.idpersona, 2, _estadoSeleccionado);
                }
                _cargarAlimentaciones();
              },
              child: Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtrar por el nombre de la medicación
    final filtrados = alimentaciones.where((m) => m.nombre.toLowerCase().contains(filter.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Control de Medicación", style: TextStyle(fontSize: 16, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Buscar plan de medicación...",
                prefixIcon: Icon(Icons.search, size: 18),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => filter = val),
            ),
          ),
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final ali = filtrados[index];

                    // Cálculo de última toma global del plan
                    String? ultimaTomaGlobal;
                    for (var detalle in ali.detalles) {
                      if (detalle.ultimaFechaCumplimiento != null && detalle.ultimaFechaCumplimiento!.isNotEmpty) {
                        try {
                          final current = DateTime.parse(detalle.ultimaFechaCumplimiento!);
                          if (ultimaTomaGlobal == null || current.isAfter(DateTime.parse(ultimaTomaGlobal!))) {
                            ultimaTomaGlobal = detalle.ultimaFechaCumplimiento;
                          }
                        } catch(_) {}
                      }
                    }

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                        side: BorderSide(color: Colors.grey.withOpacity(0.1))
                      ),
                      child: ExpansionTile(
                        leading: InkWell(
                          onTap: () => _mostrarDialogoAlimentacion(alimentacionExistente: ali),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Icon(Icons.edit, color: Colors.blue, size: 16),
                          ),
                        ),
                        title: Text(ali.nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEstadoChip(ali.elestadoalimentacion, _getColorEstado(ali.idestadoalimentacion)),
                            _buildLastTakenDate(ultimaTomaGlobal),
                          ],
                        ),
                        children: ali.detalles.map((d) => ListTile(
                          dense: true,
                          title: Text(d.detalle, style: TextStyle(fontSize: 12)),
                          subtitle: Text("Progreso: ${d.porcentaje.toStringAsFixed(0)} veces", style: TextStyle(fontSize: 10)),
                          trailing: Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CumplimientoAlimentacionPage(detalle: d, nombreAlimento: ali.nombre)
                            ));
                            _cargarAlimentaciones(); 
                          },
                        )).toList(),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoAlimentacion(), 
        backgroundColor: Color(0xFF2D3142),
        label: Text("AÑADIR PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
    );
  }
}
