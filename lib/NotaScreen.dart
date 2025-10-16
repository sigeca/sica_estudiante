import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart'; // Make sure you have this package imported

// Assuming you have a Nota class defined like this:
//class Nota {
  final String? fecha;
 // final String? comentario;
 / final String? porcentaje;

//  Nota({this.fecha, this.comentario, this.porcentaje});
//}

// Assuming _notaFuture is a Future<List<Nota>> that fetches your data
late Future<List<Nota>> _notaFuture; // Initialize this appropriately in your stateful widget

// For demonstration purposes, let's create a dummy _notaFuture
Future<List<Nota>> _fetchNotasDummy() async {
  await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
  return [
    Nota(fecha: '2023-01-15', comentario: 'Participación en clase', porcentaje: '5.0'),
    Nota(fecha: '2023-01-20', comentario: 'Tarea 1', porcentaje: '10.0'),
    Nota(fecha: '2023-01-25', comentario: 'Examen parcial', porcentaje: '20.0'),
    Nota(fecha: '2023-02-01', comentario: 'Proyecto final', porcentaje: '40.0'),
    Nota(fecha: '2023-02-05', comentario: 'Ajuste por inasistencia', porcentaje: '-5.0'),
  ];
}


class NotasScreen extends StatefulWidget {
  const NotasScreen({super.key});

  @override
  State<NotasScreen> createState() => _NotasScreenState();
}

class _NotasScreenState extends State<NotasScreen> {

  @override
  void initState() {
    super.initState();
    _notaFuture = _fetchNotasDummy(); // Initialize your future here
  }

  // Method to calculate the sum of percentages
  double _calculateTotalPercentage(List<Nota> notas) {
    double total = 0.0;
    for (var nota in notas) {
      total += double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
    }
    return total;
  }

  // Method to show the bottom sheet with the total percentage
  void _showTotalPercentagePanel(BuildContext context, double totalPercentage) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return Container(
          height: 150, // You can adjust the height as needed
          padding: const EdgeInsets.all(20.0),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'Sumatoria Total de Porcentajes:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${totalPercentage.toStringAsFixed(2)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: totalPercentage < 0 ? Colors.red : Colors.green,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String latexFormula = r'P_x = \sum_{y=1}^{2}(A_x)_y \cdot p_a + \sum_{y=1}^{2}(B_x)_y \cdot p_b + \sum_{y=1}^{2}(C_x)_y \cdot p_c + \sum_{y=1}^{2}(E_x)_y \cdot p_e ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calificaciones del participante'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder<List<Nota>>(
        future: _notaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data!.isEmpty) {
            return const Center(child: Text('No hay calificaciones para mostrar.'));
          } else {
            final notas = snapshot.data!;
            return ListView.builder(
              itemCount: notas.length,
              itemBuilder: (context, index) {
                final nota = notas[index];
                final porcentaje = double.tryParse(nota.porcentaje ?? '0') ?? 0.0;
                final isNegativo = porcentaje < 0;

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  color: isNegativo ? Colors.orange.shade100 : Colors.white,
                  elevation: 2,
                  child: ListTile(
                    title: Text(
                      'Fecha: ${nota.fecha}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNegativo ? Colors.orange.shade800 : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      'Tipo de Participación: ${nota.comentario}',
                      style: TextStyle(
                        color: isNegativo ? Colors.orange.shade700 : Colors.black54,
                      ),
                    ),
                    trailing: Text(
                      '${nota.porcentaje}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isNegativo ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FutureBuilder<List<Nota>>(
        future: _notaFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
            final totalPercentage = _calculateTotalPercentage(snapshot.data!);
            return FloatingActionButton.extended(
              onPressed: () {
                _showTotalPercentagePanel(context, totalPercentage);
              },
              label: const Text('Ver Sumatoria'),
              icon: const Icon(Icons.calculate),
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
            );
          }
          return Container(); // Return an empty container while waiting for data
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Positions the button at the bottom right
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey.shade50,
        elevation: 4.0,
        child: Container(
          height: 120.0,
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 1.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fórmula de Cálculo:',
                style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
              const SizedBox(height: 2),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Center(
                    child: Math.tex(
                      latexFormula,
                      textStyle: const TextStyle(fontSize: 10),
                      onErrorFallback: (FlutterMathException e) {
                        return Text('Error al mostrar fórmula: ${e.message}', style: const TextStyle(color: Colors.red));
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Donde: P = Promedio, x = Índice del parcial, p = Ponderación',
                style: TextStyle(fontSize: 8, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
