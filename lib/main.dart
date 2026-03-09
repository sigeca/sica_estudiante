import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Asegúrate de que este archivo esté correcto
import 'evento.dart';     // Asegúrate de que este archivo esté correcto
import 'portafolio.dart';
import 'LoginPage.dart';
import 'LoginPagex.dart';
import 'ComUniTiPage.dart';
import 'SaludPage.dart';
import 'DocumentosPortafolioScreen.dart';
import 'EventoDetalleScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El control de sesión inicial se maneja en SplashScreen
  // Activa el modo de extremo a extremo (Edge-to-Edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

// Opcional: Configura el estilo de las barras para que sean transparentes
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Barra superior transparente
    systemNavigationBarColor: Colors.transparent, // Barra inferior transparente
    statusBarIconBrightness: Brightness.dark, // Iconos oscuros (o light según tu fondo)
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

  runApp(const SicaApp());
}

class SicaApp extends StatelessWidget {
  const SicaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SICA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.blueAccent,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(secondary: Colors.tealAccent),
      ),
      initialRoute: '/',
      routes: {
        // La ruta inicial carga el splash screen
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginPage(), // Login con Biometría
        '/loginx': (context) => const LoginPagex(), // Login con Credenciales
        '/home': (context) {
          final args = ModalRoute.of(context)!.settings.arguments;
          final idpersona = args is String ? args : '';
          return HomeScreen(idpersona: idpersona);
        },
      },
    );
  }
}

// ---------------------- NUEVA CLASE: SPLASH SCREEN ---------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Retraso para mostrar el splash screen al menos 1 segundo
    await Future.delayed(const Duration(seconds: 1)); 

    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final isBiometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;
    final idpersona = prefs.getString('idpersona');

    if (!mounted) return;

    if (isLoggedIn && idpersona != null && idpersona.isNotEmpty) {
      // Si el usuario está logueado y tiene biometría habilitada
      if (isBiometricsEnabled) {
         // Redirigir a la pantalla de Login Biométrico para autenticación rápida
        Navigator.pushReplacementNamed(context, '/login'); 
      } else {
        // Si está logueado pero sin biometría, ir directamente a Home (puede necesitar autenticación manual si la sesión expira)
        Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
      }
    } else {
      // Si no hay sesión, ir al login de credenciales (asumimos que es la ruta de inicio por defecto)
      Navigator.pushReplacementNamed(context, '/loginx'); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Puedes colocar aquí el logo o un placeholder
            Icon(Icons.school, size: 100, color: Colors.blueAccent), 
            SizedBox(height: 20),
            Text(
              'SICA - Cargando...',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 40),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- HOME SCREEN (Mantenido sin cambios) ---------------------------------

class HomeScreen extends StatefulWidget {
  final String idpersona;

  const HomeScreen({super.key, required this.idpersona});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late List<Widget> _pages;
Persona? _personaInfo; // Para almacenar la info de la persona

  @override
  void initState() {
    super.initState();
// 1. Obtener la información de la persona
    _fetchPersonaData();

//    _pages = <Widget>[
  //    EventoPage(idpersona: widget.idpersona),
  //    PortafolioPage(idpersona: widget.idpersona),
  //    ComUniTiPage(idpersona: widget.idpersona),
  //    ComUniTiPage(cedula: _personaInfo!.cedula), // Usar .cedula aquí
  //  ];
  }
Future<void> _fetchPersonaData() async {
    try {
      final persona = await ApiService.fetchPersonaInfo(widget.idpersona);
      if (mounted) {
        setState(() {
          _personaInfo = persona;
          // 2. Inicializar _pages después de obtener los datos
          _pages = <Widget>[
            EventoPage(idpersona: widget.idpersona),
            PortafolioPage(idpersona: widget.idpersona),
            // Pasar la cédula a ComUniTiPage
            ComUniTiPage(idpersona: widget.idpersona,cedula: _personaInfo!.cedula), // Usar .cedula aquí
            SaludPage(idpersona: widget.idpersona,cedula: _personaInfo!.cedula), // Usar .cedula aquí
          ];
        });
      }
    } catch (e) {
      // Manejo de errores (por si la info de la persona falla)
      print('Error al cargar info de persona en HomeScreen: $e');
      if (mounted) {
        setState(() {
          // Inicializar _pages con un valor por defecto o la idpersona si falla la cédula
           _pages = <Widget>[
            EventoPage(idpersona: widget.idpersona),
            PortafolioPage(idpersona: widget.idpersona),
            ComUniTiPage(idpersona:widget.idpersona,cedula: widget.idpersona), // Asumir idpersona como fallback
          ];
        });
      }
    }
  }






  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Borra toda la sesión guardada

    // Redirige al usuario a la pantalla de login principal.
    if (mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/loginx', (Route<dynamic> route) => false);
    }
  }


  PreferredSizeWidget _buildHeader() {
    return AppBar(
      title: Row(
        children: [
          Image.network(
            'https://educaysoft.org/sica/images/logo.jpg',
            height: 40,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.school, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 10),
          const Text('SICA - Educaysoft', style: TextStyle(fontSize: 18)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar Sesión',
          onPressed: _logout,
        ),
      ],
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
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'ComUniTi'),
          // --- AQUÍ ESTÁ TU NUEVA OPCIÓN ---
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.red), // Corazón Rojo
            label: 'Salud',
          ),
// ---------------------------------
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ajustes',
          ),

        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

// ---------------------- EVENTO PAGE (Mantenido sin cambios) ---------------------------------

class EventoPage extends StatefulWidget {
  final String idpersona;

  const EventoPage({super.key, required this.idpersona});

  @override
  State<EventoPage> createState() => _EventoPageState();
}

class _EventoPageState extends State<EventoPage> {
  late Future<Persona> _personaInfoFuture;
  late Future<List<Evento>> _eventosFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _eventosFuture = ApiService.fetchEventos(widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona); 
  }

  Widget _buildPersonaInfo(Persona persona) {
    final fotoUrl = "https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg";
    // 🎯 LÍNEA AGREGADA PARA IMPRIMIR LA URL
  print('EventoPage - URL de la foto de la persona: $fotoUrl');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              fotoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            persona.lapersona,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
              shadows: [
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black.withOpacity(0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0,2),
                )
              ]
            ),
            child: const Text(
              'Eventos y cursos tomados',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
        ),
      ),

        // Sección para mostrar la información de la persona
        FutureBuilder<Persona>(
          future: _personaInfoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('Error al cargar info de usuario: ${snapshot.error}', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))),
              );
            } else if (snapshot.hasData) {
              return _buildPersonaInfo(snapshot.data!);
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No hay información del usuario disponible.')),
              );
            }
          },
        ),

    Expanded(
      child: RefreshIndicator( 
          onRefresh: () async {
            setState(() {
              _fetchData(); 
            });
          },
          child: FutureBuilder<List<Evento>>(
            future: _eventosFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.teal)));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error al cargar eventos: ${snapshot.error}', style: TextStyle(color: Colors.red[700])));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final eventos = snapshot.data!;
                return SizedBox(
                  height: 320, // Aumentado para mejor visualización
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                    itemCount: eventos.length,
                    itemBuilder: (context, index) {
                      return EventoCard(
                        evento: eventos[index],
                        idpersona: widget.idpersona,
                      );
                    },
                  ),
                );

              } else {
                return const Center(child: Text('No hay eventos para mostrar.'));
              }
            },
          ),
      ),
    ),
      ],
    );
  }
}

// ---------------------- EVENTO CARD WIDGET ---------------------------------

class EventoCard extends StatefulWidget {
  final Evento evento;
  final String idpersona;

  const EventoCard({super.key, required this.evento, required this.idpersona});

  @override
  State<EventoCard> createState() => _EventoCardState();
}

class _EventoCardState extends State<EventoCard> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventoDetalleScreen(
                idevento: widget.evento.idevento,
                titulo: widget.evento.titulo,
                idpersona: widget.idpersona,
                idtipogrupoparticipante: widget.evento.idtipogrupoparticipante,
              ),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HERO IMAGE ---
                Image.network(
                  'https://educaysoft.org/descargar.php?archivo=heros/movil${widget.evento.idevento}.jpg',
                  height: 120, // Altura incrementada para impacto visual
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://educaysoft.org/descargar.php?archivo=heros/movilunknow.jpg',
                      height: 120,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                // --- CONTENIDO ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.evento.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 16,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // DESCRIPCIÓN CON "LEER MÁS"
                        Expanded(
                          child: SingleChildScrollView(
                            physics: _isExpanded ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.evento.detalle,
                                  style: TextStyle(
                                    fontSize: 13, 
                                    color: Colors.grey[700],
                                    height: 1.3,
                                  ),
                                  maxLines: _isExpanded ? 10 : 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (widget.evento.detalle.length > 50) 
                                  GestureDetector(
                                    onTap: _toggleExpanded,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        _isExpanded ? 'Ver menos' : 'Leer más...',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Text(
                                'REF: ${widget.evento.idevento}',
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor, 
                                  fontSize: 10, 
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- PORTAFOLIO PAGE (Mantenido sin cambios) ---------------------------------

class PortafolioPage extends StatefulWidget {
  final String idpersona;

  const PortafolioPage({super.key, required this.idpersona});

  @override
  State<PortafolioPage> createState() => _PortafolioPageState();
}

class _PortafolioPageState extends State<PortafolioPage> {
  late Future<List<Portafolio>> _portafolioFuture;
  late Future<Persona> _personaInfoFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }
  
  void _fetchData() {
    _portafolioFuture = ApiService.fetchPortafolio(widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona);
  }


  Widget _buildPersonaInfo(Persona persona) {
    final fotoUrl = 'https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      child: Column(
        children: [
          ClipOval(
            child: Image.network(
              fotoUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                return Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            persona.lapersona,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87,
              shadows: const [
                Shadow(
                  offset: Offset(1.5, 1.5),
                  blurRadius: 2.0,
                  color: Colors.black38,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: const Text(
              'Portafolios de la persona',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        
        FutureBuilder<Persona>(
          future: _personaInfoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(20.0),
                child: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasError) {
              print("Error FutureBuilder Persona (PortafolioPage): ${snapshot.error}");
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(child: Text('No se pudo cargar la información del usuario.', textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))),
              );
            } else if (snapshot.hasData) {
              return _buildPersonaInfo(snapshot.data!);
            } else {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: Text('No hay información del usuario disponible.')),
              );
            }
          },
        ),
        
        Expanded(
          child: RefreshIndicator( 
            onRefresh: () async {
              setState(() {
                _fetchData();
              });
            },
            child: FutureBuilder<List<Portafolio>>(
              future: _portafolioFuture,
              builder: (context, snapshot) {
                 if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar portafolios: ${snapshot.error}', style: TextStyle(color: Colors.red[700])));
                  } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    final portafolios = snapshot.data!;
                    return ListView.builder(
                      itemCount: portafolios.length,
                      itemBuilder: (context, index) {
                        final p = portafolios[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          elevation: 3,
                          child: ListTile(
                            leading: const Icon(Icons.folder_open, color: Colors.orange),
                            title: Text('Portafolio: ${p.idportafolio}'),
                            subtitle: Text('${p.lapersona} - ${p.elperiodo}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.open_in_new, color: Colors.blueAccent),
                              tooltip: "Ver documentos",
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
                  } else {
                    return const Center(child: Text('No hay portafolios para mostrar.'));
                  }
              }
            ),
          ),
        ),
      ],
    );
  }
}

// Las clases 'ComUniTiPage', 'DocumentosPortafolioScreen', 'EventoDetalleScreen', 'Portafolio', 'Persona', etc., 
// se asumen que están definidas en otros archivos (como 'portafolio.dart', 'evento.dart') o en archivos dedicados.
