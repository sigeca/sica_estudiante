import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'evento.dart'; // Import the Estudiante model
import 'api_service.dart'; // Assuming ApiService has the necessary methods

class AsistenciaScreen extends StatefulWidget {
  final String idevento;
  final String fecha;

  const AsistenciaScreen({
    super.key,
    required this.idevento,
    required this.fecha,
  });

  @override
  State<AsistenciaScreen> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  List<Estudiante> estudiantes = [];
  bool cargando = true; // Set to true initially to show the loading indicator

  final opcionesAsistencia = {
    1: 'Puntual',
    2: 'Atrasado',
    3: 'Falta Just.',
    4: 'Falta Injust.'
  };

  @override
  void initState() {
    super.initState();
    _inicializarAsistencias();
  }

  // New function to handle initial loading and creation of attendance records
  Future<void> _inicializarAsistencias() async {
    setState(() => cargando = true);
    try {
      // First, try to load existing attendance records
      estudiantes = await ApiService.obtenerEstudiantes(
        widget.idevento,
        widget.fecha,
      );

      // If no students are found, create new attendance records
      if (estudiantes.isEmpty) {
        await ApiService.registrarAsistenciaAll(
          idevento: widget.idevento,
          fecha: widget.fecha,
        );
        // After creating, load the students again to display them
        estudiantes = await ApiService.obtenerEstudiantes(
          widget.idevento,
          widget.fecha,
        );
      }
      
      if (mounted) {
        setState(() {}); // Update the state after loading data
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al inicializar asistencias: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  // This function is no longer called directly from a button, but is used internally
  Future<void> cargarEstudiantes() async {
    setState(() => cargando = true);
    try {
      estudiantes = await ApiService.obtenerEstudiantes(
        widget.idevento,
        widget.fecha,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar estudiantes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (cargando)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: estudiantes.length,
                  itemBuilder: (context, index) {
                    final e = estudiantes[index];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                backgroundImage: NetworkImage(
                                  'https://educaysoft.org/descargar2.php?archivo=${e.cedula}.jpg',
                                ),
                              ),
                              title: Text(e.lapersona),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('idasistencia: ${e.idasistencia?.toString() ?? 'sin valor'}'),
                                  DropdownButton<int>(
                                    value: e.tipoAsistencia,
                                    hint: const Text('Seleccione asistencia'),
                                    items: opcionesAsistencia.entries
                                        .map((entry) => DropdownMenuItem<int>(
                                              value: entry.key,
                                              child: Text(entry.value),
                                            ))
                                        .toList(),
                                    onChanged: (valor) {
                                      setState(() => e.tipoAsistencia = valor);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Guardar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                onPressed: () async {
                                  if (e.idasistencia != null && e.tipoAsistencia != null) {
                                    try {
                                      await ApiService.actualizarAsistencia(
                                        e.idasistencia!,
                                        e.tipoAsistencia!,
                                      );
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('✅ Asistencia de ${e.lapersona} guardada'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    } catch (error) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '❌ Error al guardar asistencia de ${e.lapersona}',
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Completa el tipo de asistencia primero'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
