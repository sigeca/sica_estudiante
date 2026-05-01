import 'package:flutter/material.dart';
import 'api_service.dart';
import 'evento.dart'; 
import 'SignosVitalesPage.dart';
import 'AlimentacionPage.dart';
import 'EjercitacionPage.dart';
import 'CumplimientoPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'MedicacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'AlimentacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'EjercitacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'SicaAppBar.dart';

class SaludPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const SaludPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _SaludPageState createState() => _SaludPageState();
}

class _SaludPageState extends State<SaludPage> {
  // Colores minimalistas
  static const Color primaryColor = Color(0xFF2D3142);
  static const Color accentColor = Color(0xFF4F5D75);
  static const Color backgroundColor = Color(0xFFF5F7FA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SicaAppBar(
        idpersona: widget.idpersona,
        cedula: widget.cedula,
        title: "Gestión de Salud",
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.redAccent),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SignosVitalesPage(idpersona: widget.idpersona)),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("SEGUIMIENTO Y CUMPLIMIENTO"),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMenuCard("Medicación", Icons.medical_services, Colors.blue, () => _navTo(context, "medicacion"))),
                SizedBox(width: 12),
                Expanded(child: _buildMenuCard("Catálogo Meds", Icons.inventory_2, Colors.blueGrey, () => _navTo(context, "cat_meds"))),
              ],
            ),
            SizedBox(height: 16),
            _buildSectionTitle("HÁBITOS DE VIDA"),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _buildMenuCard("Alimentación", Icons.restaurant, Colors.orange, () => _navTo(context, "alimentacion"))),
                SizedBox(width: 12),
                Expanded(child: _buildMenuCard("Catálogo Alim.", Icons.apple, Colors.green, () => _navTo(context, "cat_alim"))),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildMenuCard("Ejercitación", Icons.fitness_center, Colors.deepPurple, () => _navTo(context, "ejercitacion"))),
                SizedBox(width: 12),
                Expanded(child: _buildMenuCard("Catálogo Ejerc.", Icons.directions_run, Colors.indigo, () => _navTo(context, "cat_ejer"))),
              ],
            ),
            SizedBox(height: 24),
            _buildSignosVitalesBanner(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: accentColor, letterSpacing: 1.2),
    );
  }

  Widget _buildMenuCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignosVitalesBanner() {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.redAccent, Colors.orangeAccent]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.monitor_heart, color: Colors.white)),
        title: Text("Signos Vitales", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text("Monitoreo de presión y pulso", style: TextStyle(color: Colors.white70, fontSize: 11)),
        trailing: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignosVitalesPage(idpersona: widget.idpersona))),
      ),
    );
  }

// Dentro de SaludPage.dart en la función _navTo:
void _navTo(BuildContext context, String route) {
  Widget page;
  switch (route) {
    case "medicacion": 
      page = MedicacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula); 
      break;
    case "cat_meds": 
      page = MedicamentoCatalogoPage(idpersona: widget.idpersona); 
      break;
    case "alimentacion": 
      page = AlimentacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula); 
      break;
    case "cat_alim": 
      page = AlimentoCatalogoPage(idpersona: widget.idpersona); 
      break;
    case "ejercitacion": 
      page = EjercitacionGestionPage(idpersona: widget.idpersona, cedula: widget.cedula); 
      break;
    case "cat_ejer": 
      page = EjercicioCatalogoPage(idpersona: widget.idpersona); 
      break;


    default: 
      page = AlimentacionPage(idpersona: widget.idpersona, cedula: widget.cedula);
  }
  Navigator.push(context, MaterialPageRoute(builder: (context) => page));
}


}


class MedicamentoCatalogoPage extends StatefulWidget {
  final String idpersona;
  const MedicamentoCatalogoPage({Key? key, required this.idpersona}) : super(key: key);

  @override
  _MedicamentoCatalogoPageState createState() => _MedicamentoCatalogoPageState();
}

class _MedicamentoCatalogoPageState extends State<MedicamentoCatalogoPage> {
  List<MedicamentoVista> todosLosMeds = [];
  List<MedicamentoVista> filtrados = [];
  bool isLoading = true;
  String query = "";

  @override
  void initState() {
    super.initState();
    _cargarMedicamentos();
  }

  Future<void> _cargarMedicamentos() async {
    try {
      // Reutiliza la lógica de SaludPage1 para obtener los medicamentos
      final data = await ApiService.fetchMedicacion2(widget.idpersona);
      
      // Agrupar por ID para evitar duplicados si la API devuelve registros repetidos
      Map<String, MedicamentoVista> agrupados = {};
      for (var item in data) {
        if (!agrupados.containsKey(item.idmedicamento)) {
          agrupados[item.idmedicamento] = item;
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
              m.detallemedicamento.toLowerCase().contains(val.toLowerCase()))
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
        title: Text("Diccionario de Medicamentos", style: TextStyle(fontSize: 16, color: Colors.white)),
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
              ? Center(child: Text("No se encontraron medicamentos"))
              : ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final med = filtrados[index];
                    final String urlImagen = "https://educaysoft.org/descargar.php?archivo=medicamentos/medicamento${med.idmedicamento}.jpg";

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
                          onTap: () => _mostrarZoomImagen(context, urlImagen, med.nombre),
                          child: Hero( // Efecto de transición suave
                            tag: 'med_${med.idmedicamento}',
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
                        title: Text(med.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            med.detallemedicamento,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                        trailing: Icon(Icons.zoom_in, color: Colors.blue.withOpacity(0.5)),
                        onTap: () => _mostrarZoomImagen(context, urlImagen, med.nombre),
                      ),
                    );
                  },
                ),
    );
  }
}
