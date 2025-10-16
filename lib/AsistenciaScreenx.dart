import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'evento.dart'; // Evento might not be directly used in this screen, but keep if needed elsewhere
import 'evento.dart'; // Import the Participante model
import 'api_service.dart'; // Assuming ApiService still has fetchParticipantes


class AsistenciaiScreen extends StatefulWidget {
  final String idevento;
  final String fecha;

  const AsistenciaScreen({
      super.key});
    required this.idevento,
    required this.fecha,
  }) : super(key: key);

  @override
  State<AsistenciaScreenState> createState() => _AsistenciaScreenState();
}

class _AsistenciaScreenState extends State<AsistenciaScreen> {
  final TextEditingController _eventoController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();

  List<Estudiante> estudiantes = [];
  bool cargando = false;

  final opcionesAsistencia = {
    1: 'Puntual',
    2: 'Atrasado',
    3: 'Falta Just.',
    4: 'Falta Injust.'
  };

  void cargarEstudiantes() async {
    setState(() => cargando = true);
    try {
      estudiantes = await ApiService.obtenerEstudiantes(
        _eventoController.text,
        _fechaController.text,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar: $e')),
      );
    }
    setState(() => cargando = false);
  }

  void guardarAsistencias() async {
    int exitos = 0;
    int errores = 0;

    for (var est in estudiantes) {
      if (est.idasistencia != null && est.tipoAsistencia != null) {
        try {
          await ApiService.actualizarAsistencia(
            est.idasistencia!,
            est.tipoAsistencia!,
          );
          exitos++;
        } catch (e) {
          errores++;
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Actualizados: $exitos, Errores: $errores'),
      ),
    );
  }

  bool get camposCompletos =>
      _eventoController.text.isNotEmpty && _fechaController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asistencia')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _eventoController,
              decoration: const InputDecoration(
                labelText: 'ID del Evento',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _fechaController,
              decoration: const InputDecoration(
                labelText: 'Fecha (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: cargarEstudiantes,
                  child: const Text('Cargar estudiantes'),
                ),
                ElevatedButton(
                  onPressed: camposCompletos
                      ? () async {
                          try {
                            await ApiService.registrarAsistenciaAll(
                              idevento: _eventoController.text,
                              fecha: _fechaController.text,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Asistencia inicial registrada'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('❌ Error al registrar asistencia inicial: $e'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Asistencia All'),
                ),
              ],
            ),
            const SizedBox(height: 10),
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

