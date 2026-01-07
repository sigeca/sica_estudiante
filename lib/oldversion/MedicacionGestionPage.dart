import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoPage.dart';

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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarMedicaciones();
  }

  Future<void> _cargarMedicaciones() async {
    final data = await ApiService.fetchMedicaciones(widget.idpersona);
    setState(() {
      medicaciones = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = medicaciones.where((m) => m.lamedicacion.toLowerCase().contains(filter.toLowerCase())).toList();

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
          // BUSCADOR INTEGRADO
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
                    final med = filtrados[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
                      child: ExpansionTile(
                        title: Text(med.lamedicacion, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text("ID: ${med.idmedicacion}", style: TextStyle(fontSize: 10)),
                        children: med.detalles.map((d) => ListTile(
                          dense: true,
                          title: Text(d.elmedicamento, style: TextStyle(fontSize: 12)),
                          subtitle: Text(d.detalle, style: TextStyle(fontSize: 10)),



                          trailing: Icon(Icons.chevron_right, size: 16, color: Colors.blue),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CumplimientoPage(detalle: d, nombreMedicamento: d.elmedicamento))),
                        )).toList(),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => {}, // Aquí va tu lógica de _mostrarDialogoMedicacion()
        backgroundColor: Color(0xFF2D3142),
        label: Text("AÑADIR PLAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        icon: Icon(Icons.add, size: 18),
      ),
    );
  }
}
