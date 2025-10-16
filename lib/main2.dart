iport 'package:flutter/material.dart';
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
void main() {
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
      routes:{
     // theme: ThemeData(primarySwatch: Colors.teal),
      '/': (context) => const SplashScreen(),
      '/login': (context) => const LoginPage(),
      '/home': (context)  =>const HomeScreen(),
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _pages = <Widget>[
    const EventoPage(),
    const PortafolioPage(),
  ];

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
            'https://educaysoft.org/sica/images/logo.jpg', // Cambia esto por la URL de tu logo
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
  const EventoPage({super.key});
  @override
  State<EventoPage> createState() => _EventoPageState();
}

class _EventoPageState extends State<EventoPage> {
  final _idController = TextEditingController();
  final _estadoController = TextEditingController();
  List<Evento> eventos = [];
  bool cargando =false;

 void _fetchEventos() async {
     setState(() => cargando=true);
    try{
    final id = _idController.text;
    final estado = _estadoController.text;
    // eventos = await ApiService.fetchEventos(id, estado);
     eventos = await ApiService.fetchEventos(id);
    } catch(e){

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Error al cargar: $e'),
         ));
       }

    setState(() => cargando = false);
  }


@override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _idController, decoration: const InputDecoration(labelText: 'ID Persona')),
     //   TextField(controller: _estadoController, decoration: const InputDecoration(labelText: 'Estado')),
        ElevatedButton(onPressed: _fetchEventos, child: const Text('Buscar')),
        Expanded(
          child: ListView.builder(
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              final evento = eventos[index];
              return Card(
                child: ListTile(
                  title: Text('Evento: ${evento.titulo}'),
                  subtitle: Text('ID: ${evento.idevento}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () {
                      // Código para lanzar otra app

 Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EventoDetalleScreen(idevento: evento.idevento,idpersona: evento.idpersona),
    ),
  );


                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}



class PortafolioPage extends StatefulWidget {
  const PortafolioPage({super.key});
  @override
  State<PortafolioPage> createState() => _PortafolioPageState();
}

class _PortafolioPageState extends State<PortafolioPage> {
 final _idController = TextEditingController();
  List<Portafolio> portafolios = [];
  bool cargando = false;
 void _fetchPortafolio() async {
    setState(()=> cargando =true);
    try{
    final id = _idController.text;
     portafolios = await ApiService.fetchPortafolio(id);
    } catch(e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
           content: Text('Error al cargar: $e'),
       ));
    }

    setState(() => cargando = false);
  }

 @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _idController, decoration: const InputDecoration(labelText: 'ID Persona')),
        ElevatedButton(onPressed: _fetchPortafolio, child: const Text('Buscar')),
        Expanded(
          child: ListView.builder(
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
                      // Código para lanzar otra app
                        Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => DocumentosPortafolioScreen(idportafolio: p.idportafolio),
    ),
  );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}


