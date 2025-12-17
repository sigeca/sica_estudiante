import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'evento.dart';
import 'CumplimientoPage.dart';
import 'SignosVitalesPage.dart'; // Importa la nueva página

class SaludPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const SaludPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _SaludPageState createState() => _SaludPageState();
}

class _SaludPageState extends State<SaludPage> with SingleTickerProviderStateMixin {
  List<Medicacion> medicaciones = [];
  bool isLoading = true;
  late TabController _tabController; // Controlador para las pestañas

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // 2 Pestañas
    _cargarMedicaciones();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _cargarMedicaciones() async {
    try {
      final resultados = await ApiService.fetchMedicaciones(widget.idpersona);
      if (mounted) {
        setState(() {
          medicaciones = resultados;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- DIÁLOGOS DE AGREGAR Y FECHAS (Se mantienen casi igual, solo cambia el guardar) ---
  
  // Utilidad Fecha
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Diálogo Detalle (Instrucción) - SIN CAMBIOS
  void _mostrarDialogoDetalle(String idMedicacion) {
    final _detalleController = TextEditingController();
    final _fechaDesdeController = TextEditingController();
    final _fechaHastaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Nueva Instrucción"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _detalleController, decoration: InputDecoration(labelText: "Instrucción")),
              TextField(
                controller: _fechaDesdeController,
                readOnly: true,
                onTap: () => _selectDate(context, _fechaDesdeController),
                decoration: InputDecoration(labelText: "Desde", icon: Icon(Icons.calendar_today)),
              ),
              TextField(
                controller: _fechaHastaController,
                readOnly: true,
                onTap: () => _selectDate(context, _fechaHastaController),
                decoration: InputDecoration(labelText: "Hasta", icon: Icon(Icons.event_busy)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              if (_detalleController.text.isNotEmpty) {
                Navigator.pop(context);
                      try {
                await ApiService.registrarDetalleMedicacion(
                    idMedicacion, _detalleController.text, _fechaDesdeController.text, _fechaHastaController.text);
                _cargarMedicaciones();
                      } catch (e) {
                        print("Error: $e");
                      }
              }
            },
            child: Text("Guardar"),
          )
        ],
      ),
    );
  }

  // --- DIÁLOGO PARA AGREGAR MEDICAMENTO (MODIFICADO PARA ELEGIR TIPO) ---
  void _agregarMedicacion() {
    final _nombreController = TextEditingController();
     final _fechaDesdeController = TextEditingController();
    final _fechaHastaController = TextEditingController();

   
    int _tipoSeleccionado = 1; // 1 = Farmacia por defecto

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Necesario para actualizar el Dropdown dentro del Dialog
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Nueva Medicación"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nombreController,
                    decoration: InputDecoration(labelText: "Nuevo medicamento"),
                  ),
              TextField(
                controller: _fechaDesdeController,
                readOnly: true,
                onTap: () => _selectDate(context, _fechaDesdeController),
                decoration: InputDecoration(labelText: "Desde", icon: Icon(Icons.calendar_today)),
              ),
              TextField(
                controller: _fechaHastaController,
                readOnly: true,
                onTap: () => _selectDate(context, _fechaHastaController),
                decoration: InputDecoration(labelText: "Hasta", icon: Icon(Icons.event_busy)),
              ),

                  SizedBox(height: 15),
                  Text("Tipo de medicación:", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<int>(
                    value: _tipoSeleccionado,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(child: Text("💊 Farmacéutica"), value: 1),
                      DropdownMenuItem(child: Text("🥦 Dietética"), value: 2),
                    ],
                    onChanged: (val) {
                      setStateDialog(() {
                        _tipoSeleccionado = val!;
                      });
                    },
                  )
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar")),
                ElevatedButton(
                  onPressed: () async {
                    if (_nombreController.text.isNotEmpty) {
                      Navigator.pop(context);
                      try {
                        await ApiService.registrarMedicacion(
                          _nombreController.text,
                          _fechaDesdeController.text,
                          _fechaHastaController.text,
                          widget.idpersona,
                          _tipoSeleccionado, // Enviamos el ID (1 o 2)
                        );
                        _cargarMedicaciones();
                      } catch (e) {
                        print("Error: $e");
                      }
                    }
                  },
                  child: Text("Guardar"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- WIDGET PARA LISTAR MEDICAMENTOS ---
  Widget _buildListaMedicamentos(List<Medicacion> lista, bool esDieta) {
    if (lista.isEmpty) return Center(child: Text("No hay registros en esta categoría"));

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final med = lista[index];
        
        // REQUERIMIENTO: Fondo verde flex para dietéticas
        final Color cardColor = esDieta ? Colors.green.shade50 : Colors.white;
        final Color iconColor = esDieta ? Colors.green : Colors.redAccent;
        final IconData iconData = esDieta ? Icons.eco : Icons.medical_services;

        return Card(
          color: cardColor, // Aplica el color de fondo
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          margin: EdgeInsets.only(bottom: 16),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(med.nombre, style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(esDieta ? "Suplemento / Dieta" : "Medicamento"),
            children: [
              if (med.detalles.isEmpty)
                Padding(padding: EdgeInsets.all(16), child: Text("Sin instrucciones.")),
              ...med.detalles.map((det) {
                // ... lógica de porcentaje igual ...
                Color colorPorc = Colors.red;
                if (det.porcentaje > 50) colorPorc = Colors.orange;
                if (det.porcentaje > 80) colorPorc = Colors.green;

                return ListTile(
                  title: Text(det.detalle),
                  subtitle: Text("${det.fechadesde} ➔ ${det.fechahasta}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${det.porcentaje.toStringAsFixed(0)}%", 
                          style: TextStyle(fontWeight: FontWeight.bold, color: colorPorc)),
                      IconButton(
                        icon: Icon(Icons.open_in_new),
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(
                              builder: (context) => CumplimientoPage(detalle: det, nombreMedicamento: med.nombre)));
                          _cargarMedicaciones();
                        },
                      )
                    ],
                  ),
                );
              }).toList(),
              TextButton.icon(
                icon: Icon(Icons.add, color: iconColor),
                label: Text("Agregar Instrucción", style: TextStyle(color: iconColor)),
                onPressed: () => _mostrarDialogoDetalle(med.idmedicacion),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filtrar las listas
    final farmaceuticas = medicaciones.where((m) => m.idtipomedicacion == 1).toList();
    final dieteticas = medicaciones.where((m) => m.idtipomedicacion == 2).toList();
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${widget.cedula}.jpg";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Row(children: [
           CircleAvatar(backgroundImage: NetworkImage(fotoUrl), radius: 16),
           SizedBox(width: 10),
           Text("Mi Salud")
        ]),
        // REQUERIMIENTO: Botón para Signos Vitales
        actions: [
          IconButton(
            icon: Icon(Icons.monitor_heart),
            tooltip: "Ver Signos Vitales",
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => SignosVitalesPage(idpersona: widget.idpersona))
              );
            },
          )
        ],
        // REQUERIMIENTO: Pestañas para separar vistas
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.medication), text: "Farmacia"),
            Tab(icon: Icon(Icons.restaurant), text: "Dietética"),
          ],
        ),
      ),
      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListaMedicamentos(farmaceuticas, false), // Tab 1: Normal
              _buildListaMedicamentos(dieteticas, true),     // Tab 2: Verde (True activa estilo)
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _agregarMedicacion,
        label: Text("Nuevo"),
        icon: Icon(Icons.add),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
