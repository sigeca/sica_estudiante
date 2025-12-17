import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// IMPORTANTE: Esta librería corrige el error de "Locale data has not been initialized"
import 'package:intl/date_symbol_data_local.dart'; 
import 'api_service.dart';
import 'evento.dart';

class CumplimientoPage extends StatefulWidget {
  final DetalleMedicacion detalle;
  final String nombreMedicamento;

  const CumplimientoPage({
    Key? key, 
    required this.detalle, 
    required this.nombreMedicamento
  }) : super(key: key);

  @override
  _CumplimientoPageState createState() => _CumplimientoPageState();
}

class _CumplimientoPageState extends State<CumplimientoPage> {
  Map<String, int> _estados = {}; // Mapa: "2023-10-25" -> 1 (Cumplido)
  bool isLoading = true;
  List<DateTime> _diasTratamiento = [];

  @override
  void initState() {
    super.initState();
    
    // --- SOLUCIÓN DEL ERROR ---
    // Inicializamos el formato de fecha en español antes de cargar nada
    initializeDateFormatting('es', null).then((_) {
      if (mounted) {
        _generarDias();
        _cargarDatos();
      }
    });
  }

  // 1. Generar lista de días entre Fecha Desde y Fecha Hasta
  void _generarDias() {
    try {
      if (widget.detalle.fechadesde.isEmpty || widget.detalle.fechahasta.isEmpty) return;

      DateTime inicio = DateTime.parse(widget.detalle.fechadesde);
      DateTime fin = DateTime.parse(widget.detalle.fechahasta);
      
      _diasTratamiento.clear();

      int diasDiferencia = fin.difference(inicio).inDays;
      // Seguridad: Limitar a 5 años máximo para evitar bucles infinitos por error de fechas
      if(diasDiferencia < 0 || diasDiferencia > 1825) diasDiferencia = 0; 

      for (int i = 0; i <= diasDiferencia; i++) {
        _diasTratamiento.add(inicio.add(Duration(days: i)));
      }
    } catch (e) {
      print("Error generando días: $e");
    }
  }

  // 2. Cargar datos desde la API
  Future<void> _cargarDatos() async {
    try {
      final cumplimientos = await ApiService.fetchCumplimientos(widget.detalle.iddetallemedicacion);
      
      Map<String, int> tempMap = {};
      for (var c in cumplimientos) {
          final fechaSolo = c.fechahora.substring(0, 10);
        tempMap[fechaSolo] = c.cumplimiento;

      }

      if (mounted) {
        setState(() {
          _estados = tempMap;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error cargando datos: $e");
      if (mounted) setState(() => isLoading = false);
    }
  }

  // 3. Marcar/Desmarcar Checkbox
  Future<void> _toggleCheck(DateTime fecha) async {
    final String fechaString = DateFormat('yyyy-MM-dd').format(fecha);
    final bool isCumplido =_estados[fechaString]==1;
 //   int estadoActual = _estados[fechaStr] ?? 0;
 //   int nuevoEstado = estadoActual == 1 ? 0 : 1;

    try {
if (isCumplido) {
        
            // 🎯 CAMBIO 2: Llamar a la función del ApiService con el DATETIME
            await ApiService.eliminarCumplimiento(
                widget.detalle.iddetallemedicacion,fecha 
            ); 
}else{
// 🎯 Caso 2: MARCAR (cumplimiento = 1).
            // ENVIAMOS EL MOMENTO EXACTO (DATETIME.NOW)
            final DateTime fechaHoraToma = DateTime.now();
await ApiService.registrarCumplimiento(
                widget.detalle.iddetallemedicacion, 
                fechaHoraToma, // Envía la fecha y hora actuales.
                1 // Cumplimiento = 1
            );
}


            // ... (Actualización de _estados y recarga de datos)
// ... (Tu código de actualización de estado y recarga)
        setState(() {
            _estados[fechaString] = isCumplido ? 0 : 1;
        });
        await _cargarDatos();

       } catch (e) {
            // Manejo de error
            print('Error al registrar cumplimiento: $e');
// 🎯 IMPORTANTE: Imprime el cuerpo de la respuesta del servidor para depurar el error
        print('Error al registrar cumplimiento (API response): $e');
        
        // Revertir el estado en caso de error
        if (mounted) {
            setState(() {
                _estados[fechaString] = isCumplido ? 1 : 0;
            });
        }
        // ... (Puedes añadir un ScaffoldMessenger aquí para alertar al usuario)


       }
    






    // Actualización visual inmediata (Optimistic UI)
/*
    setState(() {
      _estados[fechaStr] = nuevoEstado;
    });

    try {
      await ApiService.registrarCumplimiento(
        widget.detalle.iddetallemedicacion, 
        fechaStr, 
        nuevoEstado
      );
    } catch (e) {
      // Revertir si falla
      setState(() {
        _estados[fechaStr] = estadoActual;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error de conexión. Intente nuevamente."))
      );
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Control Diario", style: TextStyle(fontSize: 18)),
            Text(widget.nombreMedicamento, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400)),
          ],
        ),
        backgroundColor: Colors.teal,
      ),
      body: isLoading 
        ? Center(child: CircularProgressIndicator(color: Colors.teal))
        : Column(
            children: [
              // --- Cabecera con Instrucción ---
              Container(
                padding: const EdgeInsets.all(16.0),
                width: double.infinity,
                color: Colors.teal.withOpacity(0.05),
                child: Column(
                  children: [
                    Text(
                      "INSTRUCCIÓN MÉDICA",
                      style: TextStyle(fontSize: 10, color: Colors.teal, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    SizedBox(height: 5),
                    Text(
                      widget.detalle.detalle,
                      style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // --- Lista de Días ---
              Expanded(
                child: _diasTratamiento.isEmpty 
                ? Center(child: Text("Rango de fechas no válido o vacío"))
                : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: _diasTratamiento.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, indent: 70),
                  itemBuilder: (context, index) {
                    DateTime fecha = _diasTratamiento[index];
                    String fechaStr = DateFormat('yyyy-MM-dd').format(fecha);
                    
                    // Formato en Español (ej: Lunes, 25 OCT)
                    String diaSemana = DateFormat('EEEE', 'es').format(fecha);
                    String mes = DateFormat('MMM', 'es').format(fecha).toUpperCase();
                    String diaNumero = DateFormat('d').format(fecha);
                    
                    // Capitalizar día (lunes -> Lunes)
                    diaSemana = "${diaSemana[0].toUpperCase()}${diaSemana.substring(1)}";
                    
                    bool cumplido = (_estados[fechaStr] ?? 0) == 1;
                    bool esHoy = DateFormat('yyyy-MM-dd').format(DateTime.now()) == fechaStr;

                    return Material(
                      color: esHoy ? Colors.teal.withOpacity(0.05) : Colors.white,
                      child: InkWell(
                        onTap: () => _toggleCheck(fecha),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              // Caja Izquierda (Día Numérico)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: esHoy ? Colors.teal : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Column(
                                  children: [
                                    Text(diaNumero, 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 18,
                                        color: esHoy ? Colors.white : Colors.black87
                                      )
                                    ),
                                    Text(mes, 
                                      style: TextStyle(
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold,
                                        color: esHoy ? Colors.white : Colors.grey[600]
                                      )
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 16),
                              
                              // Texto Central (Día Semana y Año)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(diaSemana, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(fecha.year.toString(), style: TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),

                              // Checkbox Derecha
                              Transform.scale(
                                scale: 1.3,
                                child: Checkbox(
                                  activeColor: Colors.teal,
                                  shape: CircleBorder(), // Checkbox redondo
                                  value: cumplido,
                                  onChanged: (val) => _toggleCheck(fecha),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
    );
  }
}
