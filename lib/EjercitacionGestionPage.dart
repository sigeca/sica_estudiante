import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoEjercitacionPage.dart';
import 'SicaAppBar.dart';
import 'SicaDrawer.dart';
import 'MedicacionGestionPage.dart';
import 'AlimentacionGestionPage.dart';

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

  // --- FUNCIÓN PARA ABRIR VIDEO ---
  Future<void> _lanzarURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;

    // Si es solo el ID de YouTube, construimos la URL
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

  String? _getYouTubeThumbnail(String? urlString) {
    if (urlString == null || urlString.isEmpty) return null;
    String finalUrl = urlString.trim();
    String videoId = "";
    if (!finalUrl.startsWith('http')) {
      videoId = finalUrl;
    } else {
      try {
        Uri uri = Uri.parse(finalUrl);
        if (uri.host.contains('youtube.com')) {
          videoId = uri.queryParameters['v'] ?? "";
        } else if (uri.host.contains('youtu.be')) {
          videoId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : "";
        }
      } catch (e) {
        return null;
      }
    }
    if (videoId.isNotEmpty) {
      return 'https://img.youtube.com/vi/$videoId/0.jpg';
    }
    return null;
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
        showDrawer: true,
      ),
      drawer: SicaDrawer(idpersona: widget.idpersona, cedula: widget.cedula),
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
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12), 
                        side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1)
                      ),
                      child: Column(
                        children: [
                          ListTile(
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
                          ),
                          if (eje.videos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.video_library, size: 14, color: Colors.blue),
                                      SizedBox(width: 6),
                                      Text("RUTINA MULTIMEDIA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                                    ],
                                  ),
                                  ...eje.videos.map((v) {
                                    String? thumbUrl = _getYouTubeThumbnail(v.enlace);
                                    return InkWell(
                                      onTap: () => _lanzarURL(v.enlace),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(vertical: 6),
                                        child: Row(
                                          children: [
                                            if (thumbUrl != null)
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: Image.network(thumbUrl, width: 70, height: 40, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.play_circle_fill, color: Colors.red, size: 40)),
                                              )
                                            else
                                              Icon(Icons.play_circle_fill, color: Colors.red, size: 40),
                                            SizedBox(width: 10),
                                            Expanded(
                                              child: Text(v.nombre, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                            ),
                                            Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                            Divider(height: 1),
                          ],
                          ...eje.detalles.map((d) {
                            String? detailThumbUrl = _getYouTubeThumbnail(d.videoEnlace);
                            return ListTile(
                              dense: true,
                              title: Text(d.detalle, style: TextStyle(fontSize: 12)),
                              subtitle: Text("Progreso: ${d.porcentaje.toStringAsFixed(0)} veces", style: TextStyle(fontSize: 10)),
                              trailing: d.videoEnlace != null && d.videoEnlace!.isNotEmpty
                                ? InkWell(
                                    onTap: () => _lanzarURL(d.videoEnlace),
                                    child: detailThumbUrl != null 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(detailThumbUrl, width: 60, height: 34, fit: BoxFit.cover, errorBuilder: (_,__,___) => Icon(Icons.play_circle_fill, color: Colors.red, size: 30)),
                                          )
                                        : Icon(Icons.play_circle_fill, color: Colors.red, size: 30),
                                  )
                                : Icon(Icons.fitness_center, size: 16, color: Colors.blueGrey),
                            );
                          }).toList(),
                          Divider(height: 1),
                          ListTile(
                            dense: true,
                            tileColor: Colors.blue.withOpacity(0.05),
                            leading: Icon(Icons.check_circle_outline, color: Colors.blue),
                            title: Text("VER CUMPLIMIENTO DE LA RUTINA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                            subtitle: Text("Registrar sesiones y ver progreso", style: TextStyle(fontSize: 10)),
                            trailing: Icon(Icons.chevron_right, color: Colors.blue),
                            onTap: () async {
                              String instruccion = "Sin instrucción específica";
                              String fechaDesde = "";
                              String fechaHasta = "";
                              String? videoEnlace;
                              if (eje.detalles.isNotEmpty) {
                                final firstDetail = eje.detalles.first;
                                instruccion = firstDetail.detalle;
                                fechaDesde = firstDetail.fechadesde;
                                fechaHasta = firstDetail.fechahasta;
                                videoEnlace = firstDetail.videoEnlace;
                              }
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (context) => CumplimientoEjercitacionPage(
                                  idejercitacion: eje.idejercitacion,
                                  nombreEjercicio: eje.laejercitacion,
                                  instruccion: instruccion,
                                  fechaDesde: fechaDesde,
                                  fechaHasta: fechaHasta,
                                  videoEnlace: videoEnlace,
                                )
                              ));
                              _cargarEjercitaciones(); 
                            },
                          ),
                        ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) return;
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MedicacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula)));
          } else if (index == 1) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AlimentacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula)));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: "Medicación"),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: "Alimentación"),
          BottomNavigationBarItem(icon: Icon(Icons.fitness_center), label: "Ejercitación"),
        ],
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
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1)
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


