import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:url_launcher/url_launcher.dart'; 
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoAlimentacionPage.dart';
import 'SicaAppBar.dart';
import 'SicaDrawer.dart';
import 'MedicacionGestionPage.dart';
import 'EjercitacionGestionPage.dart';

class AlimentacionGestionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const AlimentacionGestionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _AlimentacionGestionPageState createState() => _AlimentacionGestionPageState();
}

class _AlimentacionGestionPageState extends State<AlimentacionGestionPage> {
  List<Alimentacion> alimentaciones = [];
  Map<String, String?> ultimasTomas = {};
  String filter = "";
  String filterEstado = "Todos";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAlimentaciones();
  }

  Future<void> _cargarAlimentaciones() async {
    try {
      final data = await ApiService.fetchAlimentaciones(widget.idpersona);
      
      Map<String, String?> tomasTemp = {};
      for (var ali in data) {
        try {
          final cumplimientos = await ApiService.fetchCumplimientosAlimentacion(ali.idalimentacion);
          String? ultima;
          for (var c in cumplimientos) {
             if (c.fecha.isNotEmpty && c.hora.isNotEmpty) {
                 final time = c.hora.length == 5 ? "${c.hora}:00" : c.hora;
                 final fechaHoraStr = "${c.fecha} $time";
                 if (ultima == null || fechaHoraStr.compareTo(ultima) > 0) {
                     ultima = fechaHoraStr;
                 }
             }
          }
          tomasTemp[ali.idalimentacion] = ultima;
        } catch(_) {}
      }

      if (mounted) {
        setState(() {
          alimentaciones = data;
          ultimasTomas = tomasTemp;
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
    // Filtrar por el nombre y el estado de la alimentacion
    final filtrados = alimentaciones.where((m) {
      final matchesSearch = m.nombre.toLowerCase().contains(filter.toLowerCase());
      final matchesEstado = filterEstado == 'Todos' || m.elestadoalimentacion == filterEstado;
      return matchesSearch && matchesEstado;
    }).toList();

    // Obtener última fecha helper
    String? getUltimaToma(Alimentacion ali) {
      String? ultima = ultimasTomas[ali.idalimentacion];
      if (ultima == null) {
        for (var d in ali.detalles) {
          if (d.ultimaFechaCumplimiento != null && d.ultimaFechaCumplimiento!.isNotEmpty) {
            if (ultima == null || d.ultimaFechaCumplimiento!.compareTo(ultima) > 0) {
              ultima = d.ultimaFechaCumplimiento;
            }
          }
        }
      }
      return ultima;
    }

    // Ordenar por última toma
    filtrados.sort((a, b) {
      String? aDate = getUltimaToma(a);
      String? bDate = getUltimaToma(b);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    // Obtener estados disponibles únicos
    List<String> estadosDisponibles = ['Todos'];
    final estados = alimentaciones.map((m) => m.elestadoalimentacion).toSet().toList();
    estados.sort();
    estadosDisponibles.addAll(estados);

    return Scaffold(
      appBar: SicaAppBar(
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        title: "Control de Alimentación",
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
                hintText: "Buscar plan de alimentación...",
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
                    String? ultimaTomaGlobal = ultimasTomas[ali.idalimentacion];
                    
                    if (ultimaTomaGlobal == null) {
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
                    }

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
                          ),
                          if (ali.videos.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.video_library, size: 14, color: Colors.deepOrange),
                                      SizedBox(width: 6),
                                      Text("PREPARACIÓN MULTIMEDIA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                                    ],
                                  ),
                                  ...ali.videos.map((v) {
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
                          ...ali.detalles.map((d) {
                            String? detailThumbUrl = _getYouTubeThumbnail(d.videoEnlace);
                            return ListTile(
                              dense: true,
                              title: Text(d.detalle, style: TextStyle(fontSize: 12)),
                              subtitle: Text("Ingrediente / Instrucción", style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                                : null,
                            );
                          }).toList(),
                          Divider(height: 1),
                          ListTile(
                            dense: true,
                            tileColor: Colors.teal.withOpacity(0.05),
                            leading: Icon(Icons.check_circle_outline, color: Colors.teal),
                            title: Text("VER CUMPLIMIENTO DEL PLAN", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal)),
                            subtitle: Text("Registrar tomas, ver historial y progreso", style: TextStyle(fontSize: 10)),
                            trailing: Icon(Icons.chevron_right, color: Colors.teal),
                            onTap: () async {
                              String instruccion = "Sin instrucción específica";
                              String fechaDesde = "";
                              String fechaHasta = "";
                              String? videoEnlace;
                              if (ali.detalles.isNotEmpty) {
                                final firstDetail = ali.detalles.first;
                                instruccion = firstDetail.detalle;
                                fechaDesde = firstDetail.fechadesde;
                                fechaHasta = firstDetail.fechahasta;
                                videoEnlace = firstDetail.videoEnlace;
                              }
                              await Navigator.push(context, MaterialPageRoute(
                                builder: (context) => CumplimientoAlimentacionPage(
                                  idalimentacion: ali.idalimentacion, 
                                  nombreAlimento: ali.nombre,
                                  instruccion: instruccion,
                                  fechaDesde: fechaDesde,
                                  fechaHasta: fechaHasta,
                                  videoEnlace: videoEnlace,
                                )
                              ));
                              _cargarAlimentaciones();
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
        onPressed: () => _mostrarDialogoAlimentacion(), 
        backgroundColor: Color(0xFF2D3142),
        label: Text("AÑADIR PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) return;
          if (index == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => MedicacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula)));
          } else if (index == 2) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EjercitacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula)));
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
