import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; 
import 'api_service.dart';
import 'evento.dart'; 
import 'CumplimientoEjercitacionPage.dart';

class EjercitacionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const EjercitacionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _EjercitacionPageState createState() => _EjercitacionPageState();
}

class _EjercitacionPageState extends State<EjercitacionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  List<Ejercitacion> ejercitaciones = [];
  List<EjercicioVista> catalogo = [];
  String filter = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => isLoading = true);
    try {
      final resEjer = await ApiService.fetchEjercitaciones(widget.idpersona);
      final resCat = await ApiService.fetchCatalogoEjercicios(widget.idpersona);
      setState(() {
        ejercitaciones = resEjer;
        catalogo = resCat;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text("Rutinas de Ejercicio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.indigo,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "MIS RUTINAS", icon: Icon(Icons.timer, size: 20)),
            Tab(text: "CATÁLOGO", icon: Icon(Icons.list_alt, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator(color: Colors.indigo))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaRutinas(),
                    _buildListaCatalogo(),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaEjercitacion(),
        backgroundColor: Colors.indigo,
        mini: true,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.indigo,
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 12, color: Colors.white),
        decoration: InputDecoration(
          hintText: "Buscar rutina o ejercicio...",
          hintStyle: TextStyle(color: Colors.white60),
          prefixIcon: Icon(Icons.search, size: 16, color: Colors.white60),
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
        ),
        onChanged: (val) => setState(() => filter = val.toLowerCase()),
      ),
    );
  }

  Widget _buildListaRutinas() {
    final filtered = ejercitaciones.where((e) => e.laejercitacion.toLowerCase().contains(filter)).toList();
    if (filtered.isEmpty) return Center(child: Text("No se encontraron resultados", style: TextStyle(fontSize: 12, color: Colors.grey)));
    
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final rut = filtered[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), 
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.3), width: 1)
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: Text(rut.laejercitacion, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                subtitle: Text("ID: ${rut.idejercitacion}", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
              if (rut.videos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("VIDEOS DE RUTINA", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.indigo)),
                      ...rut.videos.map((v) {
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
                Divider(),
              ],
              ...rut.detalles.map((d) {
                String? detailThumbUrl = _getYouTubeThumbnail(d.videoEnlace);
                return ListTile(
                  dense: true,
                  title: Text(d.detalle, style: TextStyle(fontSize: 12)),
                  subtitle: Text("Ejercicio", style: TextStyle(fontSize: 10, color: Colors.grey)),
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
                tileColor: Colors.indigo.withOpacity(0.05),
                leading: Icon(Icons.check_circle_outline, color: Colors.indigo),
                title: Text("VER CUMPLIMIENTO DE LA RUTINA", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.indigo)),
                subtitle: Text("Registrar sesiones y ver progreso", style: TextStyle(fontSize: 10)),
                trailing: Icon(Icons.chevron_right, color: Colors.indigo),
                onTap: () {
                  String instruccion = "Sin instrucción específica";
                  String fechaDesde = "";
                  String fechaHasta = "";
                  String? videoEnlace;
                  if (rut.detalles.isNotEmpty) {
                    final firstDetail = rut.detalles.first;
                    instruccion = firstDetail.detalle;
                    fechaDesde = firstDetail.fechadesde;
                    fechaHasta = firstDetail.fechahasta;
                    videoEnlace = firstDetail.videoEnlace;
                  }
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => CumplimientoEjercitacionPage(
                      idejercitacion: rut.idejercitacion,
                      nombreEjercicio: rut.laejercitacion,
                      instruccion: instruccion,
                      fechaDesde: fechaDesde,
                      fechaHasta: fechaHasta,
                      videoEnlace: videoEnlace,
                    )
                  ));
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListaCatalogo() {
     final filtered = catalogo.where((e) => e.nombre.toLowerCase().contains(filter)).toList();
     return ListView.separated(
       padding: EdgeInsets.all(16),
       itemCount: filtered.length,
       separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
       itemBuilder: (context, index) => ListTile(
         dense: true,
         title: Text(filtered[index].nombre, style: TextStyle(fontSize: 12)),
         trailing: Icon(Icons.chevron_right, size: 14),
       ),
     );
  }

  void _mostrarDialogoNuevaEjercitacion() { /* Lógica de guardado */ }

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
}
