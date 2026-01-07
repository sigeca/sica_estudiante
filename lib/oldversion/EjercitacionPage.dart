import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart'; // Asegúrate de definir las clases Ejercitacion y Alimento aquí
import 'CumplimientoEjercitacionPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class EjercitacionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const EjercitacionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _EjercitacionPageState createState() => _EjercitacionPageState();
}

class _EjercitacionPageState extends State<EjercitacionPage> with SingleTickerProviderStateMixin {
  List<Ejercitacion> ejercitaciones = [];
  List<AlimentoVista> catalogoAlimentos = [];
  bool isLoading = true;
  late TabController _tabController;

  final TextEditingController _searchEjercitacionController = TextEditingController();
  final TextEditingController _searchCatalogoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _cargarDatos();
  }

Future<void> _cargarDatos() async {
  try {
    // Pasar widget.idpersona a ambos métodos
    final resEjercitaciones = await ApiService.fetchEjercitaciones(widget.idpersona);
    final resCatalogo = await ApiService.fetchCatalogoEjercicios(widget.idpersona);

    if (mounted) {
      setState(() {
        ejercitaciones = resEjercitaciones;
        catalogoAlimentos = resCatalogo;
        isLoading = false;
      });
    }
  } catch (e) {
    print("Error cargando datos: $e"); // Esto te dirá exactamente qué falló
    if (mounted) setState(() => isLoading = false);
  }
}





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Mi Alimentación"),
        backgroundColor: Colors.green,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.local_fire_department), text: "Ejercitación"),
            Tab(icon: Icon(Icons.self_improvement), text: "Ejercicios"),
          ],
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListaEjercitacion(),
              _buildListaCatalogo(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaEjercitacion(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add_circle_outline),
      ),
    );
  }

  Widget _buildListaEjercitacion() {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: ejercitaciones.length,
      itemBuilder: (context, index) {
        final plan = ejercitaciones[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Text(plan.laejercitacion, style: TextStyle(fontWeight: FontWeight.bold)),
           // subtitle: Text("Estado: ${plan.estado}"),
            subtitle: Text("ID: ${plan.idejercitacion}"),
            children: plan.detalles.map<Widget>((d) => ListTile(
              title: Text(d.detalle),
              subtitle: Text("${d.fechadesde} al ${d.fechahasta}"),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.green),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CumplimientoEjercitacionPage(detalle: d, nombreAlimento: d.elejercicio),
                  ),
                ),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

Widget _buildListaCatalogo() {
  if (catalogoAlimentos.isEmpty) return Center(child: Text("No hay ejercicios registrados"));
  
  return ListView.builder(
    itemCount: catalogoAlimentos.length,
    itemBuilder: (context, index) {
      final ejercicio = catalogoAlimentos[index];
      return ListTile(
        leading: Icon(Icons.fastfood, color: Colors.orange),
        title: Text(ejercicio.nombre), // Ajusta según tu modelo AlimentoVista
        subtitle: Text("Calorías o detalle aquí"),
      );
    },
  );
}



  void _mostrarDialogoNuevaEjercitacion() {
    // Lógica para registrar nueva alimentación
  }
}
