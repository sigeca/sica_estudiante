import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'evento.dart'; 
import 'SignosVitalesPage.dart';
import 'CumplimientoPage.dart';

class SaludPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const SaludPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _SaludPageState createState() => _SaludPageState();
}

class _SaludPageState extends State<SaludPage> with SingleTickerProviderStateMixin {
  List<Medicacion> medicaciones = [];
  List<MedicamentoVista> medicamentosVista = [];
  bool isLoading = true;
  late TabController _tabController;

  static const Color primaryColor = Colors.redAccent;
  static const Color secondaryColor = Colors.blueAccent;

  // Controladores de búsqueda independientes
  TextEditingController _searchMedicaController = TextEditingController(); // Para pestaña Medicación
  TextEditingController _searchMedsController = TextEditingController();   // Para pestaña Medicamentos
  
  List<Medicacion> _farmaceuticasFiltradas = [];
  List<MedicamentoVista> _vistaFiltrada = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Reducido a 2 pestañas
    _cargarTodo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchMedicaController.dispose();
    _searchMedsController.dispose();
    super.dispose();
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

  Color _getColorPorcentaje(double porcentaje) {
    if (porcentaje > 80) return Colors.green;
    if (porcentaje > 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildLastTakenDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return Text("Sin registro de toma", 
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12));
    }

    try {
      final DateTime lastTaken = DateTime.parse(dateString);
      final DateTime today = DateTime.now();
      final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
      final String formattedDate = formatter.format(lastTaken);
      
      final lastTakenDateOnly = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
      final todayDateOnly = DateTime(today.year, today.month, today.day);
      final difference = todayDateOnly.difference(lastTakenDateOnly).inDays;

      String text;
      Color color;
      IconData icon;

      if (difference == 0) {
        text = "¡Última toma HOY! ($formattedDate)";
        color = Colors.green.shade700;
        icon = Icons.check_circle;
      } else if (difference == 1) {
        text = "Última toma ayer";
        color = Colors.orange.shade700;
        icon = Icons.warning_amber;
      } else {
        text = "Hace $difference días ($formattedDate)";
        color = Colors.red.shade700;
        icon = Icons.error;
      }
      
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
        ],
      );
    } catch (e) {
      return Text("Error en fecha", style: TextStyle(fontSize: 12, color: Colors.grey));
    }
  }



  // Carga inicial de datos
  Future<void> _cargarTodo() async {
    try {
      final resMedicaciones = await ApiService.fetchMedicaciones(widget.idpersona);
      final resVista = await ApiService.fetchMedicacion2(widget.idpersona);

      if (mounted) {
        setState(() {
          medicaciones = resMedicaciones;
          
          // Agrupación de vista de medicamentos
          Map<String, MedicamentoVista> agrupados = {};
          for (var item in resVista) {
            if (agrupados.containsKey(item.idMedicamento)) {
              agrupados[item.idMedicamento]!.totalRegistros += 1;
            } else {
              agrupados[item.idMedicamento] = item;
            }
          }
          medicamentosVista = agrupados.values.toList();
          
          _aplicarFiltroMedica("");
          _aplicarFiltroMeds("");
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _aplicarFiltroMedica(String query) {
    setState(() {
      _farmaceuticasFiltradas = medicaciones
          .where((m) => m.nombre.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _aplicarFiltroMeds(String query) {
    setState(() {
      _vistaFiltrada = medicamentosVista
          .where((m) => m.nombre.toLowerCase().contains(query.toLowerCase()) || 
                         m.detallemedicamento.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  // --- DIÁLOGOS (Editado para quitar tipo dietética) ---

  void _mostrarDialogoMedicacion({Medicacion? medicacionExistente}) {
    final isEditing = medicacionExistente != null;
    final _nombreController = TextEditingController(text: isEditing ? medicacionExistente.nombre : '');
    final _fechaDesdeController = TextEditingController(text: isEditing ? medicacionExistente.fechadesde : '');
    final _fechaHastaController = TextEditingController(text: isEditing ? medicacionExistente.fechahasta : '');
    int _estadoSeleccionado = isEditing ? medicacionExistente.idestadomedicacion : 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(isEditing ? "Editar Medicación" : "Nueva Medicación"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: InputDecoration(labelText: "Nombre", border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
                ),
                SizedBox(height: 15),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _fechaDesdeController,
                        readOnly: true,
                        onTap: () => _selectDate(context, _fechaDesdeController),
                        decoration: InputDecoration(labelText: "Desde", icon: Icon(Icons.calendar_today)),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _fechaHastaController,
                        readOnly: true,
                        onTap: () => _selectDate(context, _fechaHastaController),
                        decoration: InputDecoration(labelText: "Hasta", icon: Icon(Icons.event_busy)),
                      ),
                    ),
                  ],
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
                  await ApiService.actualizarMedicacion(medicacionExistente.idmedicacion, _nombreController.text, 2, _estadoSeleccionado);
                } else {
                  await ApiService.registrarMedicacion(_nombreController.text, _fechaDesdeController.text, _fechaHastaController.text, widget.idpersona, 2, _estadoSeleccionado);
                }
                _cargarTodo();
              },
              child: Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DE APOYO ---

  Widget _buildSearchField(TextEditingController controller, Function(String) onChanged, String hint) {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(Icons.search, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  
// ... dentro de _SaludPageState ...

Widget _buildListaMedica() {
    if (_farmaceuticasFiltradas.isEmpty) {
      return Center(child: Text("No hay registros de medicación", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: _farmaceuticasFiltradas.length,
      itemBuilder: (context, index) {
        final item = _farmaceuticasFiltradas[index];

        // 🎯 Lógica para encontrar la última toma entre todos los detalles
        String? ultimaTomaGlobal;
        for (var detalle in item.detalles) {
          if (detalle.ultimaFechaCumplimiento != null && detalle.ultimaFechaCumplimiento!.isNotEmpty) {
            final current = DateTime.parse(detalle.ultimaFechaCumplimiento!);
            if (ultimaTomaGlobal == null || current.isAfter(DateTime.parse(ultimaTomaGlobal!))) {
              ultimaTomaGlobal = detalle.ultimaFechaCumplimiento;
            }
          }
        }

        return Card(
          elevation: 3,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile(
            initiallyExpanded: true, // Tarjeta siempre abierta
            leading: InkWell(
              onTap: () => _mostrarDialogoMedicacion(medicacionExistente: item), // El icono IZQUIERDO edita
              child: CircleAvatar(
                backgroundColor: primaryColor.withOpacity(0.1),
                child: Icon(Icons.edit, color: Colors.blue, size: 20),
              ),
            ),
            title: Text(item.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildEstadoChip(item.elestadomedicacion, _getColorEstado(item.idestadomedicacion)),
                _buildLastTakenDate(ultimaTomaGlobal), // 🎯 Última fecha debajo del estado
              ],
            ),
            children: [
              ...item.detalles.map<Widget>((d) {
                final Color colorPorc = _getColorPorcentaje(d.porcentaje);
                return ListTile(
                  title: Text(d.detalle, style: TextStyle(fontSize: 14)),
                  subtitle: Text("${d.fechadesde} ➔ ${d.fechahasta}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${d.porcentaje.toStringAsFixed(0)} veces", 
                           style: TextStyle(fontWeight: FontWeight.bold, color: colorPorc)),
                      IconButton(
                        icon: Icon(Icons.open_in_new),
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CumplimientoPage(detalle: d, nombreMedicamento: item.nombre),
                            ),
                          );
                          _cargarTodo(); // 🎯 Actualiza fecha y hora al volver
                        },
                      )
                    ],
                  ),
                );
              }).toList(),
              // Botón de agregar instrucción al final
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    icon: Icon(Icons.add, color: primaryColor),
                    label: Text("Agregar Instrucción", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                    onPressed: () => _mostrarDialogoDetalle(item.idmedicacion),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Utilidad para el chip de estado
  Widget _buildEstadoChip(String label, Color color) {
    return Container(
      margin: EdgeInsets.only(top: 4, bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5))
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
    );
  }







  @override
  Widget build(BuildContext context) {
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${widget.cedula}.jpg";
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellowAccent,
        title: Row(children: [
          CircleAvatar(backgroundImage: NetworkImage(fotoUrl), radius: 18),
          SizedBox(width: 10),
          Text("Mi Salud", style: TextStyle(color: Colors.black)),
        ]),
        actions: [
          IconButton(
            icon: Icon(Icons.monitor_heart, color: Colors.black),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => SignosVitalesPage(idpersona: widget.idpersona))),
          )
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(110),
          child: Column(
            children: [
              // 🎯 BUSCADOR DINÁMICO SEGÚN PESTAÑA
              _tabController.index == 0 
                ? _buildSearchField(_searchMedicaController, _aplicarFiltroMedica, "Buscar en mis medicaciones...")
                : _buildSearchField(_searchMedsController, _aplicarFiltroMeds, "Buscar en catálogo de medicamentos..."),
              TabBar(
                controller: _tabController,
                labelColor: Colors.black,
                indicatorColor: Colors.black,
                onTap: (index) => setState(() {}), // Para refrescar el buscador
                tabs: [
                  Tab(icon: Icon(Icons.medical_services), text: "Medicación"),
                  Tab(icon: Icon(Icons.inventory), text: "Medicamentos"),
                ],
              ),
            ],
          ),
        ),
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListaMedica(),
              _buildListaMedicamentosVista(_vistaFiltrada),
            ],
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoMedicacion(),
        backgroundColor: primaryColor,
        child: Icon(Icons.add),
      ),
    );
  }

  // --- MÉTODOS RESTANTES (Lógica de Detalle y Vista 2) ---

  void _mostrarDialogoDetalle(String idMedicacion) {
    // Lógica similar a la original para registrar detalle...
  }

  Widget _buildListaMedicamentosVista(List<MedicamentoVista> lista) {
     if (lista.isEmpty) return Center(child: Text("No hay resultados"));
     return ListView.builder(
       padding: EdgeInsets.all(12),
       itemCount: lista.length,
       itemBuilder: (context, index) {
         final med = lista[index];
         return Card(
           child: ListTile(
             leading: Image.network(
               "https://educaysoft.org/descargar.php?archivo=medicamentos/medicamento${med.idMedicamento}.jpg",
               width: 50, errorBuilder: (_,__,___) => Icon(Icons.medication),
             ),
             title: Text(med.nombre),
             subtitle: Text(med.detallemedicamento),
           ),
         );
       },
     );
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) controller.text = DateFormat('yyyy-MM-dd').format(picked);
  }
}
