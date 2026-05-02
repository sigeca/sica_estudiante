import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'evento.dart';
import 'splash_screen.dart';
import 'portafolio.dart';
import 'EventoDetalleScreen.dart';
import 'DocumentosPortafolioScreen.dart';
import 'LoginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
void main() async {
WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear(); // 🔥 Borra toda la sesión guardada


  runApp(const SicaApp());
}

class SicaApp extends StatelessWidget {
  const SicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SICA',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(),
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
  final idpersona = args is String ? args : '';
          return HomeScreen(idpersona: idpersona);



        },
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String idpersona;

  const HomeScreen({super.key, required this.idpersona});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = <Widget>[
      EventoPage(idpersona: widget.idpersona),
      PortafolioPage(idpersona: widget.idpersona),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  PreferredSizeWidget _buildHeader() {
    return AppBar(
      title: Row(
        children: [
          Image.network(
            'https://educaysoft.org/sica/images/logo.jpg',
            height: 40,
          ),
          const SizedBox(width: 10),
          const Text('SICA - Educaysoft'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildHeader(),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Portafolio'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class EventoPage extends StatefulWidget {
  final String idpersona;

  const EventoPage({super.key, required this.idpersona});

  @override
  State<EventoPage> createState() => _EventoPageState();
}

class _EventoPageState extends State<EventoPage> {
  late Future<List<Evento>> _eventos ;
  late Future<Persona> _personaInfoFuture; // Para cargar los datos de la persona
  late Future<List<Evento>> _eventosFuture;

  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _fetchEventos();
    _eventosFuture = ApiService.fetchEventos(widget.idpersona);
        _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona); // Cargar datos de la persona
  }

  void _fetchEventos() async {
    setState(() => cargando = true);
    try {
      _eventos =  ApiService.fetchEventos(widget.idpersona);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar: $e'),
      ));
    }
    setState(() => cargando = false);
  }







  @override
  Widget build(BuildContext context) {
  //  return cargando
return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch, // Para que el título y la info de persona se centren si es necesario.
      children: [
        Padding( // Tu título existente
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0), // Padding interno para el texto
            decoration: BoxDecoration(
              color: Colors.blue[700], // Un azul un poco más oscuro para mejor contraste
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: Offset(0,2),
                )
              ]
            ),
            child: Text(
              'Eventos y cursos tomados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),

        // Sección para mostrar la información de la persona






    Expanded(
 child: FutureBuilder<List<Evento>>(
            future: _eventosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Si la info de persona ya cargó, quizás no quieras otro CicularProgressIndicator tan grande.
                // Podría ser un return const SizedBox.shrink(); o un indicador más pequeño.
                // Por ahora, se mantiene para claridad.
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error al cargar eventos: ${snapshot.error}', style: TextStyle(color: Colors.red[700])));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final eventos = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8.0), // Espacio arriba de la lista
                  itemCount: eventos.length,
                  itemBuilder: (context, index) {
                    final evento = eventos[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                      elevation: 3,
                      child: ListTile(
                        leading: Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                        title: Text(evento.titulo, style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('ID: ${evento.idevento}'), // Puedes añadir más detalles si los tienes
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new, color: Colors.blueAccent),
                          tooltip: "Ver detalles",
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EventoDetalleScreen(
                                  idevento: evento.idevento,
                                  titulo: evento.titulo,
                                  idpersona: widget.idpersona,


        ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              } else {
                return const Center(child: Text('No hay eventos para mostrar.'));
              }
            },
          ),
        ),
      ],
    );
  }
}








class PortafolioPage extends StatefulWidget {
  final String idpersona;

  const PortafolioPage({super.key, required this.idpersona});

  @override
  State<PortafolioPage> createState() => _PortafolioPageState();
}

class _PortafolioPageState extends State<PortafolioPage> {
  List<Portafolio> portafolios = [];
  bool cargando = false;

  @override
  void initState() {
    super.initState();
    _fetchPortafolio();
  }

  void _fetchPortafolio() async {
    setState(() => cargando = true);
    try {
      portafolios = await ApiService.fetchPortafolio(widget.idpersona);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar: $e'),
      ));
    }
    setState(() => cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    return cargando
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            itemCount: portafolios.length,
            itemBuilder: (context, index) {
              final p = portafolios[index];
              return Card(
                child: ListTile(
                  title: Text('Portafolio: ${p.idportafolio}'),
                  subtitle: Text('${p.lapersona} - ${p.elperiodo}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentosPortafolioScreen(idportafolio: p.idportafolio),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
  }
}

