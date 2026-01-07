import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart'; 
import 'CumplimientoAlimentacionPage.dart';

class AlimentacionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const AlimentacionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _AlimentacionPageState createState() => _AlimentacionPageState();
}

class _AlimentacionPageState extends State<AlimentacionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  
  List<Alimentacion> alimentaciones = [];
  List<AlimentoVista> catalogo = [];
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
      final resAlim = await ApiService.fetchAlimentaciones(widget.idpersona);
      final resCat = await ApiService.fetchCatalogoAlimentos(widget.idpersona);
      setState(() {
        alimentaciones = resAlim;
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
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Plan Alimenticio", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: Colors.black87),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.orange,
          labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          tabs: [
            Tab(text: "MIS PLANES", icon: Icon(Icons.calendar_month_outlined, size: 20)),
            Tab(text: "ALIMENTOS", icon: Icon(Icons.restaurant_menu, size: 20)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading 
              ? Center(child: CircularProgressIndicator(strokeWidth: 2))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildListaPlanes(),
                    _buildListaCatalogo(),
                  ],
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoNuevaAlimentacion(),
        backgroundColor: Colors.orange,
        label: Text("NUEVO", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          hintText: "Buscar alimento o plan...",
          prefixIcon: Icon(Icons.search, size: 18),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          filled: true,
          fillColor: Color(0xFFF1F5F9),
        ),
        onChanged: (val) => setState(() => filter = val.toLowerCase()),
      ),
    );
  }

  Widget _buildListaPlanes() {
    final filtered = alimentaciones.where((a) => a.laalimentacion.toLowerCase().contains(filter)).toList();
    if (filtered.isEmpty) return _emptyState();
    
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final plan = filtered[index];
        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
          child: ExpansionTile(
            title: Text(plan.laalimentacion, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            subtitle: Text("ID: ${plan.idalimentacion}", style: TextStyle(fontSize: 10, color: Colors.grey)),
            children: plan.detalles.map((d) => ListTile(
              title: Text(d.detalle, style: TextStyle(fontSize: 12)),
              subtitle: Text("${d.fechadesde} - ${d.fechahasta}", style: TextStyle(fontSize: 10)),
              trailing: Icon(Icons.calendar_today, color: Colors.orange, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CumplimientoAlimentacionPage(detalle: d, nombreAlimento: d.elalimento))),
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildListaCatalogo() {
    final filtered = catalogo.where((a) => a.nombre.toLowerCase().contains(filter)).toList();
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return ListTile(
          leading: Icon(Icons.circle, color: Colors.orange.withOpacity(0.3), size: 12),
          title: Text(item.nombre, style: TextStyle(fontSize: 13)),
          subtitle: Text("Referencia nutricional", style: TextStyle(fontSize: 10)),
        );
      },
    );
  }

  Widget _emptyState() => Center(child: Text("No se encontraron resultados", style: TextStyle(fontSize: 12, color: Colors.grey)));

  void _mostrarDialogoNuevaAlimentacion() { /* Tu lógica de diálogo se mantiene */ }
}




class AlimentoCatalogoPage extends StatefulWidget {
  final String idpersona;
  const AlimentoCatalogoPage({Key? key, required this.idpersona}) : super(key: key);

  @override
  _AlimentoCatalogoPageState createState() => _AlimentoCatalogoPageState();
}

class _AlimentoCatalogoPageState extends State<AlimentoCatalogoPage> {
  List<AlimentoVista> todosLosMeds = [];
  List<AlimentoVista> filtrados = [];
  bool isLoading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _cargarAlimentos();
  }

  Future<void> _cargarAlimentos() async {
    try {
      // Reutiliza la lógica de SaludPage1 para obtener los alimentos
      final data = await ApiService.fetchAlimentacion2(widget.idpersona);
      
      // Agrupar por ID para evitar duplicados si la API devuelve registros repetidos
      Map<String, AlimentoVista> agrupados = {};
      for (var item in data) {
        if (!agrupados.containsKey(item.idalimento)) {
          agrupados[item.idalimento] = item;
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
              m.detallealimento.toLowerCase().contains(val.toLowerCase()))
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
        title: Text("Diccionario de Alimentos", style: TextStyle(fontSize: 16, color: Colors.white)),
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
              ? Center(child: Text("No se encontraron alimentos"))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final ali = filtrados[index];
                    final String urlImagen = "https://educaysoft.org/descargar.php?archivo=alimentos/alimento${ali.idalimento}.jpg";

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
                          onTap: () => _mostrarZoomImagen(context, urlImagen, ali.nombre),
                          child: Hero( // Efecto de transición suave
                            tag: 'ali.${ali.idalimento}',
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
                                  child: Icon(Icons.fitness_center, color: Colors.blueGrey),
                                ),
                              ),
                            ),
                          ),
                        ),
                        title: Text(ali.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            ali.detallealimento,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        trailing: Icon(Icons.zoom_in, color: Colors.blue.withOpacity(0.5)),
                        onTap: () => _mostrarZoomImagen(context, urlImagen, ali.nombre),
                      ),
                    );
                  },
                ),
    );
  }
}


