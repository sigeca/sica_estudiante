import 'package:flutter/material.dart';
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
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final rut = filtered[index];
        return Card(
          margin: EdgeInsets.only(bottom: 8),
          elevation: 0.5,
          child: ExpansionTile(
            title: Text(rut.laejercitacion, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
            children: rut.detalles.map((d) => ListTile(
              dense: true,
              title: Text(d.detalle, style: TextStyle(fontSize: 12)),
              subtitle: Text("Progreso: ${d.porcentaje}%", style: TextStyle(fontSize: 10)),
              trailing: Icon(Icons.play_circle_fill, color: Colors.indigo, size: 18),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CumplimientoEjercitacionPage(detalle: d, nombreEjercicio: d.elejercicio))),
            )).toList(),
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
}
