import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoPage.dart';
import 'SicaAppBar.dart';
import 'AlimentacionGestionPage.dart';
import 'EjercitacionGestionPage.dart';
import 'SicaDrawer.dart';

class MedicacionGestionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const MedicacionGestionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _MedicacionGestionPageState createState() => _MedicacionGestionPageState();
}

class _MedicacionGestionPageState extends State<MedicacionGestionPage> {
  List<Medicacion> medicaciones = [];
  String filter = "";
  String filterEstado = "Todos";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMedicaciones();
  }

  Future<void> _cargarMedicaciones() async {
    try {
      final data = await ApiService.fetchMedicaciones(widget.idpersona);
      if (mounted) {
        setState(() {
          medicaciones = data;
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

  Widget _buildDetalleSubtitle(String? dateString, int porcentaje) {
    if (dateString == null || dateString.isEmpty) {
      return Text("Sin registro de toma", 
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 10));
    }

    try {
      final DateTime lastTaken = DateTime.parse(dateString);
      final DateTime today = DateTime.now();
      
      final lastTakenDateOnly = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final difference = todayDateOnly.difference(lastTakenDateOnly).inDays;

      String text;
      Color color;

      if (difference == 0 || difference == 1) {
        text = "$porcentaje ${porcentaje == 1 ? 'vez' : 'veces'}";
        color = Colors.green.shade700;
      } else {
        text = "Hace $difference días";
        color = Colors.red.shade700;
      }
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(difference <= 1 ? Icons.check_circle : Icons.history, size: 10, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
        ],
      );
    } catch (e) {
      return Text("Error en fecha", style: TextStyle(fontSize: 10, color: Colors.grey));
    }
  }

  // --- DIÁLOGOS DE GESTIÓN ---

  void _mostrarDialogoMedicacion({Medicacion? medicacionExistente}) {
    final isEditing = medicacionExistente != null;
    final _nombreController = TextEditingController(text: isEditing ? medicacionExistente.nombre : '');
    final _fechaDesdeController = TextEditingController(text: isEditing ? medicacionExistente.fechadesde : '');
    final _fechaHastaController = TextEditingController(text: isEditing ? medicacionExistente.fechahasta : '');
    int _estadoSeleccionado = isEditing ? medicacionExistente.idestadomedicacion : 1;

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
                  decoration: InputDecoration(labelText: "Nombre del Plan", border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
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
                  await ApiService.actualizarMedicacion(medicacionExistente.idmedicacion, _nombreController.text, 2, _estadoSeleccionado);
                } else {
                  // Valores por defecto para fechas si es nuevo
                  String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await ApiService.registrarMedicacion(_nombreController.text, hoy, hoy, widget.idpersona, 2, _estadoSeleccionado);
                }
                _cargarMedicaciones();
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
    // Filtrar por el nombre y el estado de la medicación
    final filtrados = medicaciones.where((m) {
      final matchesSearch = m.nombre.toLowerCase().contains(filter.toLowerCase());
      final matchesEstado = filterEstado == 'Todos' || m.elestadomedicacion == filterEstado;
      return matchesSearch && matchesEstado;
    }).toList();

    // Obtener estados disponibles únicos para el menú horizontal
    List<String> estadosDisponibles = ['Todos'];
    final estados = medicaciones.map((m) => m.elestadomedicacion).toSet().toList();
    estados.sort();
    estadosDisponibles.addAll(estados);

    return Scaffold(
      appBar: SicaAppBar(
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        title: "Control de Medicación",
        showDrawer: true,
      ),
      drawer: SicaDrawer(idpersona: widget.idpersona, cedula: widget.cedula),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: estadosDisponibles.map((estado) {
                final isSelected = filterEstado == estado;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(estado, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black87)),
                    selected: isSelected,
                    selectedColor: Colors.blue,
                    backgroundColor: Colors.grey.shade200,
                    showCheckmark: false,
                    onSelected: (bool selected) {
                      setState(() {
                        filterEstado = estado;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    final med = filtrados[index];

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                        side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1)
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: med.imagenMedicacion.isNotEmpty
                                ? Image.network(
                                    'https://educaysoft.org/descargar.php?archivo=imagenes/${med.imagenMedicacion}',
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 40,
                                      height: 40,
                                      color: Colors.blue.withOpacity(0.1),
                                      child: Icon(Icons.medication, color: Colors.blue, size: 24),
                                    ),
                                  )
                                : Container(
                                    width: 40,
                                    height: 40,
                                    color: Colors.blue.withOpacity(0.1),
                                    child: Icon(Icons.medication, color: Colors.blue, size: 24),
                                  ),
                            ),
                            title: Text(med.nombre, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.blue.shade900)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (med.tipo != null && med.tipo!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(med.tipo!, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                  ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    _buildEstadoChip(med.elestadomedicacion, _getColorEstado(med.idestadomedicacion)),
                                    SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => _mostrarDialogoMedicacion(medicacionExistente: med),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.blue, size: 12),
                                            SizedBox(width: 4),
                                            Text("Editar", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: Colors.grey.shade300),
                          ...med.detalles.map((d) => ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            title: Text(d.elmedicamento.isNotEmpty ? d.elmedicamento : med.nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 2),
                                Text(d.detalle, style: TextStyle(fontSize: 12, color: Colors.black87)),
                                SizedBox(height: 4),
                                _buildDetalleSubtitle(d.ultimaFechaCumplimiento, d.porcentaje.toInt()),
                              ],
                            ),
                            trailing: Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                            onTap: () async {
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (context) => CumplimientoPage(detalle: d, nombreMedicamento: med.nombre)
                              ));
                              _cargarMedicaciones(); 
                            },
                          )).toList(),
                          SizedBox(height: 8),
                        ],
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoMedicacion(), 
        backgroundColor: Color(0xFF2D3142),
        label: Text("AÑADIR PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
    );
  }
}
