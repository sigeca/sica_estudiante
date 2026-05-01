import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoEjercitacionPage.dart';
import 'SicaAppBar.dart';

class EjercitacionGestionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const EjercitacionGestionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _EjercitacionGestionPageState createState() => _EjercitacionGestionPageState();
}

class _EjercitacionGestionPageState extends State<EjercitacionGestionPage> {
  List<Ejercitacion> ejercitaciones = [];
  String filter = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEjercitaciones();
  }

  Future<void> _cargarEjercitaciones() async {
    try {
      final data = await ApiService.fetchEjercitaciones(widget.idpersona);
      if (mounted) {
        setState(() {
          ejercitaciones = data;
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

  void _mostrarDialogoEjercitacion({Ejercitacion? ejercitacionExistente}) {
    final isEditing = ejercitacionExistente != null;
    final _nombreController = TextEditingController(text: isEditing ? ejercitacionExistente.nombre : '');
    final _fechaDesdeController = TextEditingController(text: isEditing ? ejercitacionExistente.fechadesde : '');
    final _fechaHastaController = TextEditingController(text: isEditing ? ejercitacionExistente.fechahasta : '');
    int _estadoSeleccionado = isEditing ? ejercitacionExistente.idestadoejercitacion : 1;

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
                  await ApiService.actualizarEjercitacion(ejercitacionExistente.idejercitacion, _nombreController.text, 2, _estadoSeleccionado);
                } else {
                  // Valores por defecto para fechas si es nuevo
                  String hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
                  await ApiService.registrarEjercitacion(_nombreController.text, hoy, hoy, widget.idpersona, 2, _estadoSeleccionado);
                }
                _cargarEjercitaciones();
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
    // Filtrar por el nombre de la ejercitación
    final filtrados = ejercitaciones.where((m) => m.nombre.toLowerCase().contains(filter.toLowerCase())).toList();

    return Scaffold(
      appBar: SicaAppBar(
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        title: "Control de Ejercitación",
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: "Buscar plan de ejercitación...",
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
                    final eje = filtrados[index];

                    // Cálculo de última toma global del plan
                    String? ultimaTomaGlobal;
                    for (var detalle in eje.detalles) {
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
                          onTap: () => _mostrarDialogoEjercitacion(ejercitacionExistente: eje),
                          child: CircleAvatar(
                            radius: 15,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Icon(Icons.edit, color: Colors.blue, size: 16),
                          ),
                        ),
                        title: Text(eje.nombre, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildEstadoChip(eje.elestadoejercitacion, _getColorEstado(eje.idestadoejercitacion)),
                            _buildLastTakenDate(ultimaTomaGlobal),
                          ],
                        ),
                        children: eje.detalles.map((d) => ListTile(
                          dense: true,
                          title: Text(d.detalle, style: TextStyle(fontSize: 12)),
                          subtitle: Text("Progreso: ${d.porcentaje.toStringAsFixed(0)} veces", style: TextStyle(fontSize: 10)),
                          trailing: Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CumplimientoEjercitacionPage(detalle: d, nombreEjercicio: eje.nombre)
                            ));
                            _cargarEjercitaciones(); 
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
        onPressed: () => _mostrarDialogoEjercitacion(), 
        backgroundColor: Color(0xFF2D3142),
        label: Text("AÑADIR PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
    );
  }
}


class EjercicioCatalogoPage extends StatefulWidget {
  final String idpersona;
  const EjercicioCatalogoPage({Key? key, required this.idpersona}) : super(key: key);

  @override
  _EjercicioCatalogoPageState createState() => _EjercicioCatalogoPageState();
}

class _EjercicioCatalogoPageState extends State<EjercicioCatalogoPage> {
  List<EjercicioVista> todosLosMeds = [];
  List<EjercicioVista> filtrados = [];
  bool isLoading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _cargarEjercicios();
  }

  Future<void> _cargarEjercicios() async {
    try {
      // Reutiliza la lógica de SaludPage1 para obtener los ejercicios
      final data = await ApiService.fetchEjercitacion2(widget.idpersona);
      
      // Agrupar por ID para evitar duplicados si la API devuelve registros repetidos
      Map<String, EjercicioVista> agrupados = {};
      for (var item in data) {
        if (!agrupados.containsKey(item.idEjercicio)) {
          agrupados[item.idEjercicio] = item;
        }
      }

      if (mounted) {
        setState(() {
          todosLosMeds = agrupados.values.toList();
          filtrados = todosLosMeds;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filtrar(String val) {
    setState(() {
      query = val;
      filtrados = todosLosMeds
          .where((m) =>
              m.nombre.toLowerCase().contains(val.toLowerCase()) ||
              m.detalleejercicio.toLowerCase().contains(val.toLowerCase()))
          .toList();
    });
  }

  // Función para mostrar zoom de la imagen
  void _mostrarZoomImagen(BuildContext context, String url, String nombre) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer( // Permite pellizcar para hacer zoom (pinch to zoom)
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
                    return Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: EdgeInsets.all(20),
                    child: Icon(Icons.image_not_supported, size: 100, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                child: Text(nombre, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Diccionario de Ejercicios", style: TextStyle(fontSize: 16, color: Colors.white)),
        backgroundColor: Color(0xFF2D3142),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: TextField(
              onChanged: _filtrar,
              style: TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: "Buscar por nombre o componente...",
                prefixIcon: Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : filtrados.isEmpty
              ? Center(child: Text("No se encontraron ejercicios"))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final eje = filtrados[index];
                    final String urlImagen = "https://educaysoft.org/descargar.php?archivo=ejercicios/ejercicio${eje.idEjercicio}.jpg";

                    return Card(
                      elevation: 0,
                      margin: EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(10),
                        leading: GestureDetector(
                          onTap: () => _mostrarZoomImagen(context, urlImagen, eje.nombre),
                          child: Hero( // Efecto de transición suave
                            tag: 'med_${eje.idEjercicio}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                urlImagen,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 60, height: 60,
                                  color: Colors.blueGrey.withOpacity(0.1),
                                  child: Icon(Icons.medication, color: Colors.blueGrey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(eje.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            eje.detalleejercicio,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        trailing: Icon(Icons.zoom_in, color: Colors.blue.withOpacity(0.5)),
                        onTap: () => _mostrarZoomImagen(context, urlImagen, eje.nombre),
                      ),
                    );
                  },
                ),
    );
  }
}


