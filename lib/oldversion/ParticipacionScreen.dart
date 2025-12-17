import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'evento.dart';
import 'api_service.dart';

class ParticipacionScreen extends StatefulWidget {
  final String idevento;
  final String fecha;
  final String temacorto;
  final String tema;

  const ParticipacionScreen({
    Key? key,
    required this.idevento,
    required this.fecha,
    required this.temacorto,
    required this.tema,
  }) : super(key: key);

  @override
  _ParticipacionScreenState createState() => _ParticipacionScreenState();
}

class _ParticipacionScreenState extends State<ParticipacionScreen> {
  int _selectedIndex = 0;
  late Future<List<Participacion>> _participacionesFuture;
  Future<List<Participante>>? participantesFuture;
  Participante? participanteSeleccionado;

  @override
  void initState() {
    super.initState();
    _participacionesFuture = _fetchParticipaciones();
    participantesFuture = ApiService.fetchParticipantes(widget.idevento);
  }

  Future<List<Participacion>> _fetchParticipaciones() async {
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/participacion/participacion_persona3flutter'),
      body: {'idevento': widget.idevento, 'fecha': widget.fecha, 'temacorto': widget.temacorto},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Participacion.fromJson(e)).toList();
    } else {
      throw Exception('Error al cargar las participaciones');
    }
  }

  Future<void> _registrarParticipacion(Participacion nuevaParticipacion) async {
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/participacion/save'),
      body: {
        'idevento': nuevaParticipacion.idevento,
        'fecha': nuevaParticipacion.fecha.toIso8601String(),
        'porcentaje': nuevaParticipacion.porcentaje.toString(),
        'ayuda': nuevaParticipacion.ayuda.toString(),
        'idpersona': nuevaParticipacion.idpersona,
        'comentario': nuevaParticipacion.comentario,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _participacionesFuture = _fetchParticipaciones();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participación registrada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al registrar la participación')),
      );
    }
  }

  Future<void> _modificarParticipacion(Participacion participacion) async {
    final response = await http.post(
      Uri.parse('URL_DE_TU_API/modificar_participacion'),
      body: {
        'idparticipacion': participacion.idparticipacion.toString(),
        'idevento': participacion.idevento,
        'fecha': participacion.fecha.toIso8601String(),
        'porcentaje': participacion.porcentaje.toString(),
        'ayuda': participacion.ayuda.toString(),
        'idpersona': participacion.idpersona,
        'comentario': participacion.comentario,
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _participacionesFuture = _fetchParticipaciones();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participación modificada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al modificar la participación')),
      );
    }
  }

  Future<void> _eliminarParticipacion(int idparticipacion) async {
    final response = await http.post(
      Uri.parse('URL_DE_TU_API/eliminar_participacion'),
      body: {'idparticipacion': idparticipacion.toString()},
    );

    if (response.statusCode == 200) {
      setState(() {
        _participacionesFuture = _fetchParticipaciones();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Participación eliminada correctamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la participación')),
      );
    }
  }

  void _mostrarFormularioParticipacion([Participacion? participacion]) {
    final _formKey = GlobalKey<FormState>();
    final _fechaController = TextEditingController(
        text: participacion?.fecha.toLocal().toString().split(' ')[0] ?? widget.fecha);
    final _porcentajeController = TextEditingController(text: participacion?.porcentaje.toString() ?? '');
    final _ponderacionController = TextEditingController(text: participacion?.ponderacion.toString() ?? '');
    final _ayudaController = TextEditingController(text: participacion?.ayuda.toString() ?? '');
    //final _comentarioController = TextEditingController(text: participacion?.comentario ?? '');
    final _comentarioController = TextEditingController(text: widget.temacorto);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<List<Participante>>(
          future: participantesFuture!,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Error al cargar participantes: ${snapshot.error.toString()}'),

              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(
                title: Text('Sin participantes'),
                content: Text('No se encontraron participantes para este evento.'),
              );
            } else {
              final participantes = snapshot.data!;
              Participante? participanteSeleccionadoLocal = participanteSeleccionado ??
                  (participacion != null
                      ? participantes.firstWhere(
                          (p) => p.idpersona == participacion.idpersona,
                          orElse: () => participantes.first,
                        )
                      : null);

              return AlertDialog(
                title: Text(participacion == null ? 'Registrar Participación' : 'Modificar Participación'),
                content: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextFormField(
                          initialValue: widget.idevento,
                          decoration: const InputDecoration(labelText: 'ID Evento'),
                          enabled: false,
                        ),
                        TextFormField(
                          controller: _fechaController,
                          decoration: const InputDecoration(labelText: 'Fecha (YYYY-MM-DD)'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa la fecha.';
                            }
                            return null;
                          },
                        ),
                        DropdownButtonFormField<Participante>(
                          value: participanteSeleccionadoLocal,
                          decoration: const InputDecoration(labelText: 'Persona'),
                          items: participantes.map((p) {
                            return DropdownMenuItem(
                              value: p,
                              child: Text(p.nombres),
                            );
                          }).toList(),
                          onChanged: (Participante? nuevo) {
                            participanteSeleccionado = nuevo;
                          },
                          validator: (value) => value == null ? 'Selecciona una persona.' : null,
                        ),
                        TextFormField(
                          controller: _porcentajeController,
                          decoration: const InputDecoration(labelText: 'Porcentaje'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa el porcentaje.';
                            }
                            final n = num.tryParse(value);
                            if (n == null) {
                              return '"$value" no es un número válido.';
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _ayudaController,
                          decoration: const InputDecoration(labelText: 'Ayuda'),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final n = num.tryParse(value);
                              if (n == null) {
                                return '"$value" no es un número válido.';
                              }
                            }
                            return null;
                          },
                        ),
                        TextFormField(
                          controller: _comentarioController,
                          decoration: const InputDecoration(labelText: 'Comentario'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final nuevaParticipacion = Participacion(
                                idparticipacion: participacion?.idparticipacion ?? '',
                                idevento: widget.idevento,
                                fecha: DateTime.parse(_fechaController.text),
                                porcentaje: double.parse(_porcentajeController.text).toString(),
                                ponderacion: double.parse(_ponderacionController.text).toString(),
                                ayuda: double.tryParse(_ayudaController.text) ?? 0.0,
                                idpersona: participanteSeleccionado!.idpersona,
                                nombres: participanteSeleccionado!.nombres,
                                comentario: _comentarioController.text,
                              );
                              if (participacion == null) {
                                _registrarParticipacion(nuevaParticipacion);
                              } else {
                                _modificarParticipacion(nuevaParticipacion);
                              }
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(participacion == null ? 'Registrar' : 'Guardar Cambios'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _confirmarEliminarParticipacion(int idparticipacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta participación?'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                _eliminarParticipacion(idparticipacion);
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _mostrarListaParticipaciones(List<Participacion> participaciones) {
    if (participaciones.isEmpty) {
      return const Center(child: Text('No hay participaciones registradas para este evento.'));
    }


        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue,
              child: Text(
                widget.tema,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
              ),
            ),
 

     Expanded(
       child: ListView.builder(
      itemCount: participaciones.length,
      itemBuilder: (context, index) {
        final participacion = participaciones[index];
       final porcentaje = double.tryParse(participacion.porcentaje?.toString() ?? '0') ?? 0.0;
       final esBajo = porcentaje <= 70;

      return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            color: esBajo ? Colors.orange.shade100 : Colors.white, // Color más sutil para negativo
            elevation: 2,
        child: ListTile(
          title: Text('${participacion.nombres}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Porcentaje de participación: ${participacion.porcentaje}%'),
              Text('Ayuda: ${participacion.ayuda}'),
              Text('Comentario: ${participacion.comentario}'),
            ],
          ),
                      trailing: Text(                                                                                                                                                                        
                         '${participacion.porcentaje}%',
                         style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                           color: esBajo ? Colors.orange : Colors.green, // Color según si es negativo o positivo
                         ),
                       ),
       ),
        );
      },
    ),
    ),
    ],
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return FutureBuilder<List<Participacion>>(
          future: _participacionesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (snapshot.hasData) {
              return _mostrarListaParticipaciones(snapshot.data!);
            } else {
              return const Center(child: Text('No se encontraron participaciones.'));
            }
          },
        );
      default:
        return const Center(child: Text('Opción no válida'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Participaciones Scrum')),
      body: _buildBody(),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _mostrarFormularioParticipacion(),
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Lista'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Registrar'),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            if (index == 1) {
              _mostrarFormularioParticipacion();
            }
            _selectedIndex = 0;
          });
        },
      ),
    );
  }
}
