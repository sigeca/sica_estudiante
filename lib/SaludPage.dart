import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'evento.dart'; // Contiene Medicacion y DetalleMedicacion
import 'SignosVitalesPage.dart';
import 'CumplimientoPage.dart'; // Necesario para la funcionalidad de cumplimiento

class SaludPage extends StatefulWidget {
  final String idpersona;
  final String cedula;

  const SaludPage({Key? key, required this.idpersona, required this.cedula}) : super(key: key);

  @override
  _SaludPageState createState() => _SaludPageState();
}

class _SaludPageState extends State<SaludPage> with SingleTickerProviderStateMixin {
  List<Medicacion> medicaciones = [];
  List<MedicamentoVista> medicamentosVista = []; // Nueva lista para la vista medicacion2
  bool isLoading = true;
  late TabController _tabController;

  // --- Colores y Estilos Unificados ---
  static const Color primaryColor =  Colors.redAccent;
  static const Color secondaryColor = Colors.blueAccent;  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  //  _cargarMedicaciones();

    _cargarTodo();
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
      print("Error cargando medicaciones: $e");
    }
  }

  // --- DIÁLOGOS ---

  // Utilidad Fecha
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
      locale: const Locale('es', 'ES'), 
    );
    if (picked != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // Diálogo para Agregar/Editar MEDICACIÓN (Se mantienen las fechas ya que existen en evento.dart)
  void _mostrarDialogoMedicacion({Medicacion? medicacionExistente}) {
    final isEditing = medicacionExistente != null;
    final _nombreController = TextEditingController(text: isEditing ? medicacionExistente!.nombre : '');
    
    // Se utilizan fechadesde y fechahasta que SÍ están definidas en evento.dart
    final _fechaDesdeController = TextEditingController(text:isEditing ? medicacionExistente!.fechadesde:'');
    final _fechaHastaController = TextEditingController(text:isEditing ? medicacionExistente!.fechahasta:'');
    
    // Si NO se está editando, se requiere que el usuario seleccione las fechas.
    // Si SÍ se está editando, no se precargan ni se actualizan (basado en la API original de la V1).

    int _tipoSeleccionado = isEditing ? medicacionExistente!.idtipomedicacion : 1;
    int _estadoSeleccionado = isEditing ? medicacionExistente!.idestadomedicacion : 1; 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(isEditing ? "Editar Medicación" : "Nueva Medicación"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: InputDecoration(
                        labelText: "Nombre del medicamento",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                      ),
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
                          SizedBox(width: 10),
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

                    Text("Tipo:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    DropdownButton<int>(
                      value: _tipoSeleccionado,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.grey),
                      items: [
                        DropdownMenuItem(child: Row(children: [Icon(Icons.local_pharmacy, color: primaryColor), SizedBox(width: 8), Text("Farmacéutica")]), value: 1),
                        DropdownMenuItem(child: Row(children: [Icon(Icons.local_dining, color: Colors.green), SizedBox(width: 8), Text("Dietética")]), value: 2),
                      ],
                      onChanged: (val) => setStateDialog(() => _tipoSeleccionado = val!),
                    ),
                    
                    SizedBox(height: 15),
                    Text("Estado:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    DropdownButton<int>(
                      value: _estadoSeleccionado,
                      isExpanded: true,
                      underline: Container(height: 1, color: Colors.grey),
                      items: [
                        DropdownMenuItem(child: _buildEstadoChip("Activo", Colors.green), value: 1),
                        DropdownMenuItem(child: _buildEstadoChip("Suspendido", Colors.orange), value: 2),
                        DropdownMenuItem(child: _buildEstadoChip("Finalizado", Colors.red), value: 3),
                        DropdownMenuItem(child: _buildEstadoChip("En revisión", Colors.blue), value: 4),
                      ],
                      onChanged: (val) => setStateDialog(() => _estadoSeleccionado = val!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), 
                  child: Text("Cancelar", style: TextStyle(color: Colors.grey))
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (_nombreController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complete el nombre del medicamento.")));
                       return;
                    }
                    
                    // Solo validar fechas si se está agregando (isEditing=false)
                    if (!isEditing && (_fechaDesdeController.text.isEmpty || _fechaHastaController.text.isEmpty)) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Complete las fechas Desde y Hasta para registrar.")));
                       return;
                    }

                    if (_nombreController.text.isNotEmpty) {
                      Navigator.pop(context);
                      try {
                        if (isEditing) {
                          // Al editar no se envían las fechas (API de la V1)
                          await ApiService.actualizarMedicacion(
                            medicacionExistente!.idmedicacion,
                            _nombreController.text,
                            _tipoSeleccionado,
                            _estadoSeleccionado
                          );
                        } else {
                          // Al agregar SÍ se envían las fechas
                          await ApiService.registrarMedicacion(
                            _nombreController.text,
                            _fechaDesdeController.text,
                            _fechaHastaController.text,
                            widget.idpersona,
                            _tipoSeleccionado,
                            _estadoSeleccionado 
                          );
                        }
                        _cargarMedicaciones();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                      }
                    }
                  },
                  child: Text(isEditing ? "Actualizar" : "Guardar", style: TextStyle(color: Colors.white)),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Diálogo para Agregar Instrucción/Detalle
  void _mostrarDialogoDetalle(String idMedicacion) {
    final _detalleController = TextEditingController();
    final _fechaDesdeController = TextEditingController();
    final _fechaHastaController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text("Nueva Instrucción/Detalle"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _detalleController, 
                decoration: InputDecoration(labelText: "Instrucción (Ej. 1 pastilla c/8h)", border: OutlineInputBorder()),
              ),
              SizedBox(height: 15),
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
          TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancelar", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (_detalleController.text.isNotEmpty && _fechaDesdeController.text.isNotEmpty && _fechaHastaController.text.isNotEmpty) {
                Navigator.pop(context);
                try {
                  await ApiService.registrarDetalleMedicacion(
                      idMedicacion, _detalleController.text, _fechaDesdeController.text, _fechaHastaController.text);
                  _cargarMedicaciones();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error registrando detalle: $e")));
                }
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Debe completar todos los campos del detalle.")));
              }
            },
            child: Text("Guardar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }


  // Chip de Estado 
  Widget _buildEstadoChip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  // Utilidad para color de estado 
  Color _getColorEstado(int idEstado) {
    switch (idEstado) {
      case 1: return Colors.green; 
      case 2: return Colors.orange; 
      case 3: return Colors.red; 
      case 4: return Colors.blue; 
      default: return Colors.grey;
    }
  }

  // Utilidad para color de porcentaje (CORREGIDO: Definición limpia)
  Color _getColorPorcentaje(double porcentaje) {
    if (porcentaje > 80) return Colors.green;
    if (porcentaje > 50) return Colors.orange;
    return Colors.red;
  }

  // --- WIDGET PARA LISTAR MEDICAMENTOS (CORREGIDO acceso a porcentaje) ---
  Widget _buildListaMedicamentos(List<Medicacion> lista, bool esDieta) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(esDieta ? Icons.local_dining : Icons.local_pharmacy, size: 60, color: Colors.grey[400]), 
            SizedBox(height: 10),
            Text("No hay registros de ${esDieta ? 'dietética' : 'farmacia'}", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: lista.length,
      itemBuilder: (context, index) {
        final item = lista[index];
      
// 🎯 NUEVA LÓGICA: Encontrar la última fecha de cumplimiento de CUALQUIER detalle
    String? ultimaTomaGlobal;

    for (var detalle in item.detalles) {
        if (detalle.ultimaFechaCumplimiento != null && detalle.ultimaFechaCumplimiento!.isNotEmpty) {
            final current = DateTime.parse(detalle.ultimaFechaCumplimiento!);
            if (ultimaTomaGlobal == null || current.isAfter(DateTime.parse(ultimaTomaGlobal))) {
                ultimaTomaGlobal = detalle.ultimaFechaCumplimiento;
            }
        }
    }
    // FIN DE NUEVA LÓGICA




        final Color cardColor = esDieta ? Colors.green.shade50 : Colors.white;
        final Color iconColor = esDieta ? Colors.green : secondaryColor;
        final IconData iconData = esDieta ? Icons.eco : Icons.medical_services;
        
        return Card(
          color: cardColor,
          elevation: 3,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ExpansionTile( 
            tilePadding: EdgeInsets.fromLTRB(16, 8, 8, 8),
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Icon(iconData, color: iconColor),
            ),
            title: Text(
              item.nombre,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),

subtitle: Column( // 🎯 CAMBIAR a Column para poder apilar los widgets
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 4.0), // Ajustar padding
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getColorEstado(item.idestadomedicacion).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getColorEstado(item.idestadomedicacion).withOpacity(0.5))
                ),
                child: Text(
                  item.elestadomedicacion,
                  style: TextStyle(fontSize: 12, color: _getColorEstado(item.idestadomedicacion), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            // 🎯 AÑADIR NUEVO WIDGET DE FECHA
            _buildLastTakenDate(ultimaTomaGlobal), 
          ],
        ),




            trailing: IconButton( 
                icon: Icon(Icons.edit, color: Colors.blueGrey),
                onPressed: () => _mostrarDialogoMedicacion(medicacionExistente: item),
            ),
            
            children: [
              Divider(height: 1, indent: 16, endIndent: 16),
              if (item.detalles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text("Sin instrucciones detalladas. Agregue una.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                )
              else
                ...item.detalles.map((d) {
                  
                  // CORRECCIÓN: Usar la función de utilidad y el valor real de DetalleMedicacion.porcentaje
                  final Color colorPorc = _getColorPorcentaje(d.porcentaje);

                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    leading: Icon(Icons.info_outline, size: 20, color: Colors.grey),
                    title: Text(d.detalle),
                    subtitle: Text("${d.fechadesde} ➔ ${d.fechahasta}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CORRECCIÓN: Usar el valor real de DetalleMedicacion.porcentaje
                        Text("${d.porcentaje.toStringAsFixed(0)} veces", 
                            style: TextStyle(fontWeight: FontWeight.bold, color: colorPorc)),
                        IconButton(
                          icon: Icon(Icons.open_in_new),
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(
                                builder: (context) => CumplimientoPage(detalle: d, nombreMedicamento: item.nombre)));
                            _cargarMedicaciones();
                          },
                        )
                      ],
                    ),
                  );
                }).toList(),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.add, color: primaryColor),
                      label: Text("Agregar Instrucción", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
                      onPressed: () => _mostrarDialogoDetalle(item.idmedicacion),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


// ... dentro de class _SaludPageState extends State<SaludPage> ...

// 🎯 NUEVA FUNCIÓN: Genera el widget de la última fecha de toma
Widget _buildLastTakenDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return Text("Sin registro de toma", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey));
    }

    final DateTime lastTaken = DateTime.parse(dateString);
    final DateTime today = DateTime.now();
    final DateFormat formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final String formattedDate = formatter.format(lastTaken);
    
    // Calcula la diferencia en días. Compara solo la fecha, no la hora.
    final lastTakenDateOnly = DateTime(lastTaken.year, lastTaken.month, lastTaken.day);
    final todayDateOnly = DateTime(today.year, today.month, today.day);
    final difference = todayDateOnly.difference(lastTakenDateOnly).inDays;

    String text;
    Color color;
    IconData icon;

    if (difference == 0) {
      text = "¡Última toma HOY!  ($formattedDate)";
      color = Colors.green.shade700;
      icon = Icons.check_circle;
    } else if (difference == 1) {
      text = "Última toma ayer";
      color = Colors.orange.shade700;
      icon = Icons.warning_amber;
    } else if (difference > 1) {
      text = "Hace $difference días ($formattedDate)";
      color = Colors.red.shade700;
      icon = Icons.error;
    } else {
      text = "Última toma: $formattedDate"; // Fecha futura o error (no debería pasar)
      color = Colors.grey.shade600;
      icon = Icons.calendar_today;
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
      ],
    );
}

// ... Continúa con el resto de _SaludPageState ...



Future<void> _cargarTodo() async {
    try {
      // Cargamos ambos sets de datos
      final resMedicaciones = await ApiService.fetchMedicaciones(widget.idpersona);
      
      // Simulación de llamada a la vista medicacion2 (Debes tener este endpoint en ApiService)
      final resVista = await ApiService.fetchMedicacion2(widget.idpersona); 

      if (mounted) {
        setState(() {
          medicaciones = resMedicaciones;
          // Filtrar duplicados por idMedicamento
          final ids = <String>{};
          medicamentosVista = resVista;
          //medicamentosVista = resVista.where((m) => ids.add(m.idMedicamento)).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- NUEVA VISTA: LISTADO DE MEDICAMENTOS (VISTA 2) ---
  Widget _buildListaMedicamentosVista() {
    if (medicamentosVista.isEmpty) {
      return Center(child: Text("No hay medicamentos registrados en el historial."));
    }

    return ListView.builder(
      padding: EdgeInsets.all(12),
      itemCount: medicamentosVista.length,
      itemBuilder: (context, index) {
        final med = medicamentosVista[index];
        // URL de imagen solicitada
        final urlImagen = "https://educaysoft.org/descargar.php?archivo=medicamentos/medicamento${med.idMedicamento}.jpg";

        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del medicamento
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    urlImagen,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 80, height: 80, color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(width: 15),
                // Información textual
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        med.nombre,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[900]),
                      ),
                      SizedBox(height: 5),
                      Text(
                        med.detalle,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }











  // --- VISTA PRINCIPAL ---

  @override
  Widget build(BuildContext context) {
    final farmaceuticas = medicaciones.where((m) => m.idtipomedicacion == 1).toList();
    final dieteticas = medicaciones.where((m) => m.idtipomedicacion == 2).toList();
    
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${widget.cedula}.jpg";
    return Scaffold(
      backgroundColor: Colors.grey[100],
appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.yellowAccent, // Fondo Amarillo brillante
        title: Row(children: [
          CircleAvatar(backgroundImage: NetworkImage(fotoUrl), radius: 18),
          SizedBox(width: 10),
          // CORRECCIÓN 1: Cambiar el color del texto del título a oscuro
          Text("Mi Salud(Medicación)", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        ]),
        actions: [
          IconButton(
            // CORRECCIÓN 2: Cambiar el color del ícono a oscuro
            icon: Icon(Icons.monitor_heart, color: Colors.black87),
            tooltip: "Ver Signos Vitales",
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SignosVitalesPage(idpersona: widget.idpersona)));
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          // CORRECCIÓN 3: Cambiar el color del indicador de la pestaña a oscuro
          indicatorColor: Colors.black,
       //   indicatorWeight: 3,
          // CORRECCIÓN 4: Cambiar el color de los textos y íconos de las pestañas a oscuro
          labelColor: Colors.black, // Color para el texto (label) de la pestaña seleccionada
          unselectedLabelColor: Colors.black54, // Color para el texto de las pestañas no seleccionadas
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          isScrollable: true, // Para que quepan bien las 3 pestañas
          tabs: [
            Tab(icon: Icon(Icons.list_alt), text: "📋 Medicamentos"), 
            Tab(icon: Icon(Icons.local_pharmacy), text: "💊 Farmacéutica"), 
            Tab(icon: Icon(Icons.restaurant_menu), text: "🥦 Dietética"), 
          ],
        ),
      ),


      body: isLoading
        ? Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildListaMedicamentosVista(), // NUEVA
              _buildListaMedicamentos(farmaceuticas, false), 
              _buildListaMedicamentos(dieteticas, true),     
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarDialogoMedicacion(), 
        label: Text("Nuevo"),
        icon: Icon(Icons.add),
        backgroundColor: primaryColor,
      ),
    );
  }
}
