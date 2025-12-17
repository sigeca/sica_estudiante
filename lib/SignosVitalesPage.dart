import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'api_service.dart';
import 'evento.dart';

class SignosVitalesPage extends StatefulWidget {
  final String idpersona;
  const SignosVitalesPage({Key? key, required this.idpersona}) : super(key: key);

  @override
  _SignosVitalesPageState createState() => _SignosVitalesPageState();
}

class _SignosVitalesPageState extends State<SignosVitalesPage> {
  List<SignoVital> signos = [];
  List<Map<String, dynamic>> tiposSignos = []; // Para el Dropdown
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatosCompletos();
  }

  Future<void> _cargarDatosCompletos() async {
    setState(() => isLoading = true);
    try {
      // Cargamos tipos y registros en paralelo
      final futureTipos = ApiService.fetchTiposSignoVital();
      final futureSignos = ApiService.fetchSignosVitales(widget.idpersona);

      final resultados = await Future.wait([futureTipos, futureSignos]);

      setState(() {
        tiposSignos = resultados[0] as List<Map<String, dynamic>>;
        signos = resultados[1] as List<SignoVital>;
        // Ordenar por fecha descendente
        signos.sort((a, b) => b.fecha.compareTo(a.fecha));
        isLoading = false;
      });
    } catch (e) {
      print("Error cargando datos: $e");
      setState(() => isLoading = false);
    }
  }

  // --- DIÁLOGO DE FORMULARIO (CREAR / EDITAR) ---
  void _mostrarFormulario({SignoVital? signoExistente}) {
    final _valorController = TextEditingController(
      text: signoExistente != null ? signoExistente.valor.toString() : ''
    );
    final _fechaController = TextEditingController(
      text: signoExistente != null 
          ? DateFormat('yyyy-MM-dd HH:mm:ss').format(signoExistente.fecha)
          : DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())
    );
    
    // Valor inicial del Dropdown
    int? _tipoSeleccionado = signoExistente?.idtiposignovital;
    
    // Si es nuevo y hay tipos, seleccionar el primero por defecto
    if (_tipoSeleccionado == null && tiposSignos.isNotEmpty) {
      _tipoSeleccionado = int.tryParse(tiposSignos.first['idtiposignovital'].toString());
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(signoExistente == null ? "Nuevo Registro" : "Editar Registro"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // DROPDOWN TIPOS
                    DropdownButtonFormField<int>(
                      value: _tipoSeleccionado,
                      decoration: InputDecoration(labelText: "Tipo de Signo Vital"),
                      items: tiposSignos.map((t) {
                        return DropdownMenuItem<int>(
                          value: int.parse(t['idtiposignovital']),
                          child: Text(t['nombre']),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setStateDialog(() => _tipoSeleccionado = val);
                      },
                    ),
                    SizedBox(height: 10),
                    
                    // CAMPO VALOR
                    TextField(
                      controller: _valorController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: "Valor (Ej: 36.5, 120)"),
                    ),
                    SizedBox(height: 10),

                    // CAMPO FECHA
                    TextField(
                      controller: _fechaController,
                      readOnly: true, // Para forzar el uso del picker o dejarlo automático
                      decoration: InputDecoration(
                        labelText: "Fecha y Hora",
                        suffixIcon: IconButton(
                          icon: Icon(Icons.calendar_today),
                          onPressed: () async {
                             // Selección simple de fecha
                             DateTime? picked = await showDatePicker(
                               context: context,
                               initialDate: DateTime.now(),
                               firstDate: DateTime(2000),
                               lastDate: DateTime(2030),
                             );
                             if(picked != null){
                               // Selección de hora
                               TimeOfDay? time = await showTimePicker(
                                 context: context, 
                                 initialTime: TimeOfDay.now()
                               );
                               if(time != null){
                                 final finalDate = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
                                 _fechaController.text = DateFormat('yyyy-MM-dd HH:mm:ss').format(finalDate);
                               }
                             }
                          },
                        )
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text("Cancelar"),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text("Guardar"),
                  onPressed: () async {
                    if (_valorController.text.isNotEmpty && _tipoSeleccionado != null) {
                      Navigator.pop(context); // Cerrar diálogo
                      setState(() => isLoading = true); // Mostrar carga

                      String valor = _valorController.text;
                      
                      try {
                        if (signoExistente == null) {
                          // CREAR
                          await ApiService.registrarSignoVital(
                            widget.idpersona,
                            _tipoSeleccionado!,
                            valor,
                            _fechaController.text
                          );
                        } else {
                          // ACTUALIZAR
                          await ApiService.actualizarSignoVital(
                            signoExistente.idsignovital,
                            widget.idpersona,
                            _tipoSeleccionado!,
                            valor,
                            _fechaController.text
                          );
                        }
                        // Recargar lista
                        _cargarDatosCompletos();
                      } catch (e) {
                        print("Error: $e");
                        setState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al guardar")));
                      }
                    }
                  },
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- ELIMINAR ---
  void _confirmarEliminar(String idsignovital) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("¿Eliminar registro?"),
        content: Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancelar")),
          TextButton(
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => isLoading = true);
              await ApiService.eliminarSignoVital(idsignovital);
              _cargarDatosCompletos();
            },
          )
        ],
      ),
    );
  }

  // --- VISTA PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Historial Signos Vitales"),
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        child: Icon(Icons.add),
        onPressed: () => _mostrarFormulario(signoExistente: null),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : signos.isEmpty
              ? Center(child: Text("No hay registros. Toca + para agregar."))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: signos.length,
                  itemBuilder: (context, index) {
                    final s = signos[index];
                    
                    // Buscar nombre del tipo
                    String nombreTipo = "Tipo ${s.idtiposignovital}";
                    if (tiposSignos.isNotEmpty) {
                      final tipoObj = tiposSignos.firstWhere(
                        (t) => t['idtiposignovital'] == s.idtiposignovital.toString(),
                        orElse: () => {'nombre': nombreTipo}
                      );
                      nombreTipo = tipoObj['nombre'];
                    }

                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.favorite_border, color: Colors.blue[800]),
                        ),
                        title: Text(
                          "$nombreTipo: ${s.valor}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(s.fecha)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => _mostrarFormulario(signoExistente: s),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmarEliminar(s.idsignovital),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
