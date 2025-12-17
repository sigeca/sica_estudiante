import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'evento.dart'; // Evento might not be directly used in this screen, but keep if needed elsewhere
import 'evento.dart'; // Import the Participante model
import 'api_service.dart'; // Assuming ApiService still has fetchParticipantes

class PagoeventoPeople extends StatefulWidget { // Renamed class
  final String idpersona;
  final String idevento;

  const PagoeventoPeople({
    Key? key,
    required this.idpersona,
    required this.idevento,
  }) : super(key: key);

  @override
  _PagoeventoPeopleState createState() => _PagoeventoPeopleState(); // Renamed state class
}

class _PagoeventoPeopleState extends State<PagoeventoPeople> { // Renamed state class
  int _selectedIndex = 0;
  late Future<List<Pagoevento>> _pagoeventosFuture; // Changed to Pagoevento and _pagoeventosFuture
  Future<List<Participante>>? participantesFuture;
  Participante? participanteSeleccionado;

  @override
  void initState() {
    super.initState();
    _pagoeventosFuture = _fetchPagoeventos(); // Changed method call
    participantesFuture = ApiService.fetchParticipantes(widget.idevento);
  }

  // --- Fetching Pagoeventos ---
  Future<List<Pagoevento>> _fetchPagoeventos() async { // Changed method name
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/pagoevento/pagoevento_persona4flutter'), // **Update URL for Pagoevento list**
      body: {'idevento': widget.idevento, 'idpersona': widget.idpersona},
    );

    if (response.statusCode == 200) {
        print('Respuesta del servidor: ${response.body}');
      final json = jsonDecode(response.body);
      final List data = json['data'];
      return data.map((e) => Pagoevento.fromJson(e)).toList(); // Changed to Pagoevento.fromJson
    } else {
      throw Exception('Error al cargar los pagos de evento'); // Updated error message
    }
  }

  // --- Registering Pagoevento ---
  Future<void> _registrarPagoevento(Pagoevento nuevoPagoevento) async { // Changed method name and parameter
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/pagoevento/save'), // **Update URL for Pagoevento save**
      body: {
        'idevento': nuevoPagoevento.idevento,
        'fecha': nuevoPagoevento.fecha.toIso8601String(),
        'valor': nuevoPagoevento.valor.toString(), // Changed to valor
        'idpersona': nuevoPagoevento.idpersona,
        'comentario': nuevoPagoevento.comentario, // Changed to comentario
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _pagoeventosFuture = _fetchPagoeventos(); // Refresh list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago de evento registrado correctamente')), // Updated message
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al registrar el pago de evento: ${response.body}')), // Updated message with body
      );
    }
  }

  // --- Modifying Pagoevento ---
  Future<void> _modificarPagoevento(Pagoevento pagoevento) async { // Changed method name and parameter
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/pagoevento/update'), // **Update URL for Pagoevento update**
      body: {
        'idpagoevento': pagoevento.idpagoevento.toString(), // Use idpagoevento
        'idevento': pagoevento.idevento,
        'fecha': pagoevento.fecha.toIso8601String().split('T')[0], // Ensure date format YYYY-MM-DD
        'valor': pagoevento.valor.toString(), // Changed to valor
        'idpersona': pagoevento.idpersona,
        'comentario': pagoevento.comentario, // Changed to comentario
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _pagoeventosFuture = _fetchPagoeventos(); // Refresh list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago de evento modificado correctamente')), // Updated message
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al modificar el pago de evento: ${response.body}')), // Updated message with body
      );
    }
  }

  // --- Deleting Pagoevento ---
  Future<void> _eliminarPagoevento(String idpagoevento) async { // Changed method name and parameter type
    final response = await http.post(
      Uri.parse('https://educaysoft.org/sica/index.php/pagoevento/delete'), // **Update URL for Pagoevento delete**
      body: {'idpagoevento': idpagoevento}, // Use idpagoevento as string
    );

    if (response.statusCode == 200) {
      setState(() {
        _pagoeventosFuture = _fetchPagoeventos(); // Refresh list
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago de evento eliminado correctamente')), // Updated message
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el pago de evento: ${response.body}')), // Updated message with body
      );
    }
  }

  // --- Show Pagoevento Form ---
  void _mostrarFormularioPagoevento([Pagoevento? pagoevento]) { // Changed method name and parameter
    final _formKey = GlobalKey<FormState>();
    final _fechaController = TextEditingController(
        text: pagoevento?.fecha.toLocal().toString().split(' ')[0] ?? DateTime.now().toString().split(' ')[0]  );
    final _valorController = TextEditingController(text: pagoevento?.valor.toString() ?? ''); // Changed to valor
    final _nombresController = TextEditingController(text: pagoevento?.nombres ?? ''); // Changed to comentario
    final _comentarioController = TextEditingController(text: pagoevento?.comentario ?? ''); // Changed to comentario

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
                content: Text('Error al cargar personas: ${snapshot.error}'), // Updated message
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const AlertDialog(
                title: Text('Sin personas'),
                content: Text('No se encontraron personas disponibles para este evento.'), // Updated message
              );
            } else {
              final participantes = snapshot.data!;
              Participante? participanteSeleccionadoLocal = participanteSeleccionado ??
                  (pagoevento != null
                      ? participantes.firstWhere(
                          (p) => p.idpersona == pagoevento.idpersona,
                          orElse: () => participantes.first,
                        )
                      : null);

              return AlertDialog(
                title: Text(pagoevento == null ? 'Registrar Pago de Evento' : 'Modificar Pago de Evento'), // Updated title
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
                          readOnly: true, // Make it read-only and add a date picker
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.tryParse(_fechaController.text) ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (pickedDate != null) {
                              _fechaController.text = pickedDate.toIso8601String().split('T')[0];
                            }
                          },
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
                            setState(() { // Use setState to update the dropdown value
                              participanteSeleccionado = nuevo;
                              participanteSeleccionadoLocal = nuevo; // Update local variable for immediate display
                            });
                          },
                          validator: (value) => value == null ? 'Selecciona una persona.' : null,
                        ),
                        TextFormField(
                          controller: _valorController,
                          decoration: const InputDecoration(labelText: 'Valor'), // Changed to Valor
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, ingresa el valor.'; // Updated message
                            }
                            final n = num.tryParse(value);
                            if (n == null) {
                              return '"$value" no es un número válido.';
                            }
                            return null;
                          },
                        ),
                       TextFormField(
                          controller: _comentarioController, // Changed to comentarioController
                          decoration: const InputDecoration(labelText: 'Concepto'), // Changed to Concepto
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final nuevoPagoevento = Pagoevento( // Changed to Pagoevento
                                idpagoevento: pagoevento?.idpagoevento ?? '', // Pass existing ID for modification
                                idevento: widget.idevento,
                                fecha: DateTime.parse(_fechaController.text),
                                valor: double.parse(_valorController.text), // Changed to valor
                                idpersona: participanteSeleccionado!.idpersona,
                                nombres: _nombresController.text, // Changed to comentario
                                comentario: _comentarioController.text, // Changed to comentario
                              );
                              if (pagoevento == null) {
                                _registrarPagoevento(nuevoPagoevento); // Call registrar method
                              } else {
                                _modificarPagoevento(nuevoPagoevento); // Call modificar method
                              }
                              Navigator.of(context).pop();
                            }
                          },
                          child: Text(pagoevento == null ? 'Registrar Pago' : 'Guardar Cambios'), // Updated text
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

  // --- Confirm Delete Pagoevento ---
  void _confirmarEliminarPagoevento(String idpagoevento) { // Changed method name and parameter type
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar este pago de evento?'), // Updated message
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                _eliminarPagoevento(idpagoevento); // Call delete method
                Navigator.of(context).pop();
              },
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // --- Display Pagoeventos List ---
  Widget _mostrarListaPagoeventos(List<Pagoevento> pagoeventos) { // Changed method name and parameter
    if (pagoeventos.isEmpty) {
      return const Center(child: Text('No hay pagos de evento registrados para este evento.')); // Updated message
    }
    return ListView.builder(
      itemCount: pagoeventos.length,
      itemBuilder: (context, index) {
        final pagoevento = pagoeventos[index]; // Changed to pagoevento
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          elevation: 2,
          child: ListTile(
            title: Text('Persona: ${pagoevento.nombres}'), // Display person's name
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fecha: ${pagoevento.fecha.toLocal().toString().split(' ')[0]}'),
                Text('Valor: \$${pagoevento.valor.toStringAsFixed(2)}'), // Changed to Valor
                Text('Ccomentario: ${pagoevento.comentario}'), // Changed to Concepto
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _mostrarFormularioPagoevento(pagoevento)), // Call form method
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    if (pagoevento.idpagoevento != null) {
                      _confirmarEliminarPagoevento(pagoevento.idpagoevento!); // Call delete confirmation
                    } else {
                      print("Error: Pagoevento ID is null and cannot be deleted.");
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Build Body based on selected index ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagos de Evento')), // Updated AppBar title
      body: FutureBuilder<List<Pagoevento>>( // Changed to Pagoevento
        future: _pagoeventosFuture, // Changed future
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            return _mostrarListaPagoeventos(snapshot.data!); // Call new list display method
          } else {
            return const Center(child: Text('No se encontraron pagos de evento.')); // Updated message
          }
        },
      ),
      floatingActionButton: FloatingActionButton( // FloatingActionButton always visible for adding
        onPressed: () => _mostrarFormularioPagoevento(), // Call form method
        child: const Icon(Icons.add),
      ),
      // Removed BottomNavigationBar as it was only used for list/register, now directly use FloatingActionButton
      // and display list by default.
    );
  }
}
