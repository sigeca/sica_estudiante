import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart'; // Asegúrate de definir las clases Alimentacion y Alimento aquí
import 'CumplimientoAlimentacionPage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class AlimentacionPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const AlimentacionPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _AlimentacionPageState createState() => _AlimentacionPageState();
}

class _AlimentacionPageState extends State<AlimentacionPage> with SingleTickerProviderStateMixin {
  List<Alimentacion> alimentaciones = [];
  List<AlimentoVista> catalogoAlimentos = [];
  bool isLoading = true;
  late TabController _tabController;

  final TextEditingController _searchAlimentacionController = TextEditingController();
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
    final resAlimentaciones = await ApiService.fetchAlimentaciones(widget.idpersona);
    final resCatalogo = await ApiService.fetchCatalogoAlimentos(widget.idpersona);

    if (mounted) {
      setState(() {
        alimentaciones = resAlimentaciones;
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
            Tab(icon: Icon(Icons.restaurant), text: "Planes"),
            Tab(icon: Icon(Icons.fastfood), text: "Alimentos"),
          ],
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListaAlimentacion(),
              _buildListaCatalogo(),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaAlimentacion(),
        backgroundColor: Colors.green,
        child: Icon(Icons.add_circle_outline),
      ),
    );
  }

  Widget _buildListaAlimentacion() {
    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: alimentaciones.length,
      itemBuilder: (context, index) {
        final plan = alimentaciones[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            title: Text(plan.laalimentacion, style: TextStyle(fontWeight: FontWeight.bold)),
           // subtitle: Text("Estado: ${plan.estado}"),
            subtitle: Text("ID: ${plan.idalimentacion}"),
            children: plan.detalles.map<Widget>((d) => ListTile(
              title: Text(d.detalle),
              subtitle: Text("${d.fechadesde} al ${d.fechahasta}"),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today, color: Colors.green),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CumplimientoAlimentacionPage(detalle: d, nombreAlimento: d.elalimento),
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
  if (catalogoAlimentos.isEmpty) return Center(child: Text("No hay alimentos registrados"));
  
  return ListView.builder(
    itemCount: catalogoAlimentos.length,
    itemBuilder: (context, index) {
      final alimento = catalogoAlimentos[index];
      return ListTile(
        leading: Icon(Icons.fastfood, color: Colors.orange),
        title: Text(alimento.nombre), // Ajusta según tu modelo AlimentoVista
        subtitle: Text("Calorías o detalle aquí"),
      );
    },
  );
}



  void _mostrarDialogoNuevaAlimentacion() {
    // Lógica para registrar nueva alimentación
  }
}
