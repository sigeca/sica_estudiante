import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Asegúrate de que este archivo esté correcto
import 'evento.dart'; // Asegúrate de que este archivo esté correcto
import 'portafolio.dart';
import 'LoginPage.dart';
import 'LoginPagex.dart';
import 'ComUniTiPage.dart';
import 'SaludPage.dart';
import 'DocumentosPortafolioScreen.dart';
import 'EventoDetalleScreen.dart';
import 'MedicacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'AlimentacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'EjercitacionGestionPage.dart'; // Asumiendo que aquí manejas la lista de medicación
import 'tipo_oferta.dart';
import 'RegistroPage.dart';
import 'SicaAppBar.dart';
import 'CartController.dart';
import 'package:sica_estudiante/CarritoProductoPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // El control de sesión inicial se maneja en SplashScreen
  // Activa el modo de extremo a extremo (Edge-to-Edge)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

// Opcional: Configura el estilo de las barras para que sean transparentes
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, // Barra superior transparente
    systemNavigationBarColor: Colors.transparent, // Barra inferior transparente
    statusBarIconBrightness:
        Brightness.dark, // Iconos oscuros (o light según tu fondo)
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
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: Colors.tealAccent),
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
        '/registro': (context) => const RegistroPage(),
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
  List<Widget> _pages = const [
    Center(child: CircularProgressIndicator()),
    Center(child: CircularProgressIndicator()),
    Center(child: CircularProgressIndicator()),
    Center(child: CircularProgressIndicator()),
    Center(child: CircularProgressIndicator()),
    AcercaDePage(),
  ];
  Persona? _personaInfo; // Para almacenar la info de la persona
  List<Perfil> _perfiles = []; // Para almacenar los perfiles
  Perfil? _perfilSeleccionado; // Perfil seleccionado

  @override
  void initState() {
    super.initState();
// 1. Obtener la información de la persona
    _fetchPersonaData();
    CartController().updateCartCount(widget.idpersona);

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
        });

        // 2. Obtener los perfiles
        final perfiles = await ApiService.fetchPerfiles(_personaInfo!.idusuario);
        if (mounted) {
          setState(() {
            _perfiles = perfiles;
            if (_perfiles.isNotEmpty) {
              _perfilSeleccionado = _perfiles.first;
            } else {
              _perfilSeleccionado = Perfil(idperfil: '0', nombre: 'Invitado');
            }

            // 3. Inicializar _pages después de obtener los datos
            _pages = <Widget>[
              EventoPage(
                  idpersona: widget.idpersona, cedula: _personaInfo!.cedula),
              ComUniTiPage(
                  idpersona: widget.idpersona, cedula: _personaInfo!.cedula),
              SaludPage(
                  idpersona: widget.idpersona, cedula: _personaInfo!.cedula),
              PerfilUsuarioPage(
                  persona: _personaInfo,
                  perfil: _perfilSeleccionado,
                  perfiles: _perfiles,
                  onPerfilChanged: (p) => setState(() => _perfilSeleccionado = p)),
              const AcercaDePage(),
            ];
          });
        }
      }
    } catch (e) {
      // Manejo de errores (por si la info de la persona falla)
      print('Error al cargar info de persona en HomeScreen: $e');
      if (mounted) {
        setState(() {
          _perfilSeleccionado = Perfil(idperfil: '0', nombre: 'Invitado');
          // Inicializar _pages con un valor por defecto o la idpersona si falla la cédula
          _pages = <Widget>[
            EventoPage(idpersona: widget.idpersona, cedula: widget.idpersona),
            ComUniTiPage(idpersona: widget.idpersona, cedula: widget.idpersona),
            SaludPage(idpersona: widget.idpersona, cedula: widget.idpersona),
            PerfilUsuarioPage(
                persona: _personaInfo,
                perfil: _perfilSeleccionado,
                perfiles: _perfiles,
                onPerfilChanged: (p) => setState(() => _perfilSeleccionado = p)),
            const AcercaDePage(),
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
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/loginx', (Route<dynamic> route) => false);
    }
  }

  PreferredSizeWidget _buildHeader() {
    return SicaAppBar(
      idpersona: widget.idpersona,
      cedula: _personaInfo?.cedula ?? '',
      showLogout: true,
      onLogout: _logout,
    );
  }

  Widget _buildUserProfile(Persona persona) {
    final fotoUrl =
        "https://educaysoft.org/descargar2.php?archivo=${persona.cedula}.jpg";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.network(
                fotoUrl,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 42,
                  height: 42,
                  color: Colors.grey[200],
                  child: const Icon(Icons.person, size: 24, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  persona.lapersona,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_perfiles.length > 1)
                  DropdownButtonHideUnderline(
                    child: DropdownButton<Perfil>(
                      value: _perfilSeleccionado,
                      isDense: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                      onChanged: (Perfil? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _perfilSeleccionado = newValue;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Usted está logueado como ${newValue.nombre}'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      items:
                          _perfiles.map<DropdownMenuItem<Perfil>>((Perfil p) {
                        return DropdownMenuItem<Perfil>(
                          value: p,
                          child: Text(p.nombre),
                        );
                      }).toList(),
                    ),
                  )
                else
                  Text(
                    'Perfil: ${_perfilSeleccionado?.nombre ?? 'Invitado'}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.bold,
                    ),
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
    return Scaffold(
      appBar: _buildHeader(),
      body: Column(
        children: [
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
          BottomNavigationBarItem(
              icon: Icon(Icons.storefront), label: 'ComUniTi'),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite, color: Colors.red), // Corazón Rojo
            label: 'Salud',
          ),
          // --- AQUÍ ESTÁ TU NUEVA OPCIÓN 'TÚ' ---
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tú',
          ),
// ---------------------------------
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Acerca de',
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
  final String cedula;

  const EventoPage({super.key, required this.idpersona, required this.cedula});

  @override
  State<EventoPage> createState() => _EventoPageState();
}

class _EventoPageState extends State<EventoPage> {
  late Future<Persona> _personaInfoFuture;
  late Future<List<Evento>> _eventosFuture;
  late Future<List<Asignatura>> _asignaturasFuture;
  late Future<List<TipoOferta>> _tipoOfertaFuture;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    _eventosFuture = ApiService.fetchEventos(widget.idpersona);
    _personaInfoFuture = ApiService.fetchPersonaInfo(widget.idpersona);
    _asignaturasFuture = ApiService.fetchAsignaturasMalla();
    _tipoOfertaFuture = ApiService.fetchTipoOferta();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _fetchData();
        });
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- RIBBON 1: EVENTOS ---
            _buildRibbonHeader(
                'Eventos y cursos tomados', Icons.event_available),
            FutureBuilder<List<Evento>>(
              future: _eventosFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final eventos = snapshot.data!;
                  return Container(
                    height: 220,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: eventos.length,
                      itemBuilder: (context, index) => EventoCard(
                          evento: eventos[index],
                          idpersona: widget.idpersona,
                          cedula: widget.cedula),
                    ),
                  );
                }
                return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: Text('No hay eventos.')));
              },
            ),

            // --- RIBBON 2: CURSOS MOOC ---
            _buildRibbonHeader('Cursos (Malla MOOC)', Icons.book),
            FutureBuilder<List<Asignatura>>(
              future: _asignaturasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red[300], size: 40),
                        const SizedBox(height: 8),
                        Text(
                          'No se pudieron cargar las asignaturas',
                          style: TextStyle(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final asignaturas = snapshot.data!;
                  return Container(
                    height: 160,
                    margin: const EdgeInsets.only(bottom: 20),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: asignaturas.length,
                      itemBuilder: (context, index) =>
                          AsignaturaCard(asignatura: asignaturas[index]),
                    ),
                  );
                }
                return Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.grey[400], size: 30),
                      const SizedBox(height: 8),
                      Text('No hay asignaturas en esta malla.',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                );
              },
            ),

            // --- RIBBON 3: SALUD Y BIENESTAR ---
            _buildRibbonHeader('Salud y Bienestar', Icons.favorite),
            Container(
              height: 140,
              margin: const EdgeInsets.only(bottom: 30),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ActionCard(
                    title: 'Alimentación',
                    imagePath: 'assets/alimentacion.png',
                    color: Colors.green[50]!,
                    onTap: () {
                      final page = AlimentacionGestionPage(
                          idpersona: widget.idpersona, cedula: widget.cedula);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => page));
                    },
                  ),
                  ActionCard(
                    title: 'Medicación',
                    imagePath: 'assets/medicacion.png',
                    color: Colors.blue[50]!,
                    onTap: () {
                      final page = MedicacionGestionPage(
                          idpersona: widget.idpersona, cedula: widget.cedula);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => page));
                    },
                  ),
                  ActionCard(
                    title: 'Ejercitación',
                    imagePath: 'assets/ejercitacion.png',
                    color: Colors.orange[50]!,
                    onTap: () {
                      final page = EjercitacionGestionPage(
                          idpersona: widget.idpersona, cedula: widget.cedula);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => page));
                    },
                  ),
                ],
              ),
            ),

            // --- RIBBON 4: COMUNIDAD (TIPO OFERTA) ---
            _buildRibbonHeader(
                'Comunidad (Marketplace)', Icons.shopping_basket),
            FutureBuilder<List<TipoOferta>>(
              future: _tipoOfertaFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 140,
                      child: Center(child: CircularProgressIndicator()));
                } else if (snapshot.hasError) {
                  return const SizedBox(); // Ocultar si hay error
                } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final tipos = snapshot.data!;
                  return Container(
                    height: 140,
                    margin: const EdgeInsets.only(bottom: 30),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: tipos.length,
                      itemBuilder: (context, index) {
                        final tipo = tipos[index];
                        String img = 'assets/servicio.png';
                        Color col = Colors.green[50]!;

                        if (tipo.nombre.toLowerCase().contains('venta')) {
                          img = 'assets/venta.png';
                          col = Colors.blue[50]!;
                        } else if (tipo.nombre
                            .toLowerCase()
                            .contains('alquiler')) {
                          img = 'assets/alquiler.png';
                          col = Colors.orange[50]!;
                        } else if (tipo.nombre
                            .toLowerCase()
                            .contains('trueque')) {
                          img = 'assets/trueque.png';
                          col = Colors.teal[50]!;
                        } else if (tipo.nombre
                                .toLowerCase()
                                .contains('donación') ||
                            tipo.nombre.toLowerCase().contains('donacion')) {
                          img = 'assets/donacion.png';
                          col = Colors.pink[50]!;
                        }

                        return ActionCard(
                          title: tipo.nombre,
                          imagePath: img,
                          color: col,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  body: ComUniTiPage(
                                    idpersona: widget.idpersona,
                                    cedula: widget.cedula,
                                    initialCategory: tipo.nombre,
                                    showBackButton: true,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRibbonHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

// ---------------------- ACTION CARD WIDGET (Health) ---------------------------
class ActionCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- ASIGNATURA CARD WIDGET ---------------------------------
class AsignaturaCard extends StatelessWidget {
  final Asignatura asignatura;
  const AsignaturaCard({super.key, required this.asignatura});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    asignatura.codigo,
                    style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  asignatura.nombre,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.layers, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Nivel ${asignatura.nivel}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------- EVENTO CARD WIDGET ---------------------------------

class EventoCard extends StatefulWidget {
  final Evento evento;
  final String idpersona;
  final String cedula;

  const EventoCard(
      {super.key,
      required this.evento,
      required this.idpersona,
      required this.cedula});

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
      width: 200,
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
                cedula: widget.cedula,
              ),
            ),
          );
        },
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
          elevation: 6,
          shadowColor: Colors.black26,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- HERO IMAGE ---
                Image.network(
                  'https://educaysoft.org/descargar.php?archivo=heros/movil${widget.evento.idevento}.jpg',
                  height: 80, // Altura reducida para consistencia
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://educaysoft.org/descargar.php?archivo=heros/movilunknow.jpg',
                      height: 80,
                      fit: BoxFit.cover,
                    );
                  },
                ),
                // --- CONTENIDO ---
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today,
                                color: Theme.of(context).primaryColor,
                                size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.evento.titulo,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
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
                            physics: _isExpanded
                                ? const BouncingScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.evento.detalle,
                                  style: TextStyle(
                                    fontSize: 12,
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
                                        _isExpanded
                                            ? 'Ver menos'
                                            : 'Leer más...',
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.1),
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
                            Icon(Icons.arrow_forward_ios,
                                size: 14, color: Colors.grey[400]),
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

class PerfilUsuarioPage extends StatefulWidget {
  final Persona? persona;
  final Perfil? perfil;
  final List<Perfil> perfiles;
  final Function(Perfil)? onPerfilChanged;

  const PerfilUsuarioPage({
    Key? key,
    this.persona,
    this.perfil,
    this.perfiles = const [],
    this.onPerfilChanged,
  }) : super(key: key);

  @override
  State<PerfilUsuarioPage> createState() => _PerfilUsuarioPageState();
}

class _PerfilUsuarioPageState extends State<PerfilUsuarioPage> {
  late Future<List<Portafolio>> _portafolioFuture;

  @override
  void initState() {
    super.initState();
    if (widget.persona != null) {
      _portafolioFuture = ApiService.fetchPortafolio(widget.persona!.idpersona);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.persona == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final fotoUrl =
        "https://educaysoft.org/descargar2.php?archivo=${widget.persona!.cedula}.jpg";

    return Container(
      width: double.infinity,
      color: const Color(0xFFF5F7FA),
      child: ListView(
        children: [
          const SizedBox(height: 40),
          // Imagen del usuario en el centro superior
          Center(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.network(
                  fotoUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 120,
                    height: 120,
                    color: Colors.grey[200],
                    child: const Icon(Icons.person, size: 60, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ID del usuario
          Center(
            child: Text(
              'Usuario ID: ${widget.persona!.idusuario}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueAccent.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Nombres del usuario
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.persona!.lapersona,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Cédula: ${widget.persona!.cedula}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 30),

          // SECCIÓN: TUS PERFILES
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.badge, size: 20, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  'Tus Perfiles',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Listado de perfiles (ahora dentro del ListView)
          ...widget.perfiles.map((p) {
            final isSelected = p.idperfil == widget.perfil?.idperfil;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blueAccent.withOpacity(0.05)
                    : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isSelected ? Colors.blueAccent : Colors.grey[100],
                  child: Icon(
                    Icons.person_outline,
                    color: isSelected ? Colors.white : Colors.blueAccent,
                  ),
                ),
                title: Text(
                  p.nombre,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blueAccent : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                    : const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                onTap: () {
                  final lowerName = p.nombre.toLowerCase();
                  if (lowerName.contains('vendedor')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VendedorDashboardPage(
                            idpersona: widget.persona!.idpersona),
                      ),
                    );
                  } else if (lowerName.contains('clien') ||
                      lowerName.contains('estud') ||
                      lowerName.contains('compr') ||
                      lowerName.contains('consum')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClienteDashboardPage(
                            idpersona: widget.persona!.idpersona,
                            cedula: widget.persona!.cedula),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Perfil: ${p.nombre} seleccionado'),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                    if (widget.onPerfilChanged != null) {
                      widget.onPerfilChanged!(p);
                    }
                  }
                },
              ),
            );
          }).toList(),

          const SizedBox(height: 30),

          // SECCIÓN: TU PORTAFOLIO
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.folder_shared, size: 20, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Tu Portafolio',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Listado de portafolios con FutureBuilder
          FutureBuilder<List<Portafolio>>(
            future: _portafolioFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text('Error al cargar portafolios',
                      style: TextStyle(color: Colors.red[700])),
                );
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                final portafolios = snapshot.data!;
                return Column(
                  children: portafolios.map((p) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.folder_open,
                            color: Colors.orange, size: 28),
                        title: Text(
                          'Portafolio: ${p.idportafolio}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${p.lapersona}\n${p.elperiodo}',
                            style: const TextStyle(fontSize: 12)),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new,
                              color: Colors.blueAccent),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DocumentosPortafolioScreen(
                                    idportafolio: p.idportafolio),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }).toList(),
                );
              } else {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(child: Text('No hay portafolios para mostrar.')),
                );
              }
            },
          ),

          const SizedBox(height: 40),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'SICA - Gestión de Perfil',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AcercaDePage extends StatelessWidget {
  const AcercaDePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(
              'https://educaysoft.org/sica/images/logo.jpg',
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.business,
                  size: 100,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            const Text(
              'SICA',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent),
            ),
            const SizedBox(height: 8),
            Text(
              'Versión 1.0.0',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            const Text(
              'Creado por Estudiantes de Ingeniería de Software',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'El equipo de desarrollo agradece sus donaciones para disfrutar de una tacita de café.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Funcionalidad de donaciones en construcción.')),
                      );
                    },
                    icon: const Icon(Icons.favorite),
                    label: const Text('Donar a los desarrolladores'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------- VENDEDOR DASHBOARD PAGE ---------------------------------

class VendedorDashboardPage extends StatefulWidget {
  final String idpersona;
  const VendedorDashboardPage({Key? key, required this.idpersona})
      : super(key: key);

  @override
  State<VendedorDashboardPage> createState() => _VendedorDashboardPageState();
}

class _VendedorDashboardPageState extends State<VendedorDashboardPage> {
  int _selectedIndex = 0;

  late List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      VendedorProductosView(idcustodio: widget.idpersona),
      VendedorCartsView(idcustodio: widget.idpersona, isHistory: false),
      VendedorCartsView(idcustodio: widget.idpersona, isHistory: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    String title = 'Mis Productos';
    if (_selectedIndex == 1) title = 'Carrito Productos';
    if (_selectedIndex == 2) title = 'Histórico Carrito Producto';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

class VendedorProductosView extends StatefulWidget {
  final String idcustodio;
  const VendedorProductosView({Key? key, required this.idcustodio})
      : super(key: key);

  @override
  State<VendedorProductosView> createState() => _VendedorProductosViewState();
}

class _VendedorProductosViewState extends State<VendedorProductosView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _future = ApiService.fetchProductosPorVendedor(widget.idcustodio);
  }

  void _mostrarZoomImagen(BuildContext context, String url, String nombre) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: const Icon(Icons.image_not_supported,
                        size: 100, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20)),
                child: Text(nombre,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tienes productos asignados'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              final fotoUrl =
                  "https://educaysoft.org/descargarproducto.php?archivo=producto${p.idproducto}.jpg";

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () =>
                            _mostrarZoomImagen(context, fotoUrl, p.elproducto),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            fotoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[100],
                              child: const Icon(Icons.shopping_bag,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.elproducto,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              p.detalle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stock: ${p.stock.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blueAccent),
                                    ),
                                    Text(
                                      'Precio: \$${p.precio.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                                Icon(Icons.inventory,
                                    size: 20, color: Colors.blueAccent.withOpacity(0.5)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class VendedorCartsView extends StatefulWidget {
  final String idcustodio;
  final bool isHistory;

  const VendedorCartsView(
      {Key? key, required this.idcustodio, required this.isHistory})
      : super(key: key);

  @override
  State<VendedorCartsView> createState() => _VendedorCartsViewState();
}

class _VendedorCartsViewState extends State<VendedorCartsView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.isHistory) {
      _future =
          ApiService.fetchHistoricocarritoproductoVendedor(widget.idcustodio);
    } else {
      _future = ApiService.fetchCarritoproductoVendedor(widget.idcustodio);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(widget.isHistory
                    ? 'No hay historial disponible'
                    : 'No hay carritos activos'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.elproducto,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '\$${p.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Cliente: ${p.lapersona}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.tag, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Cantidad: ${p.cantidad}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                      if (p.fechacarga.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Cargado: ${p.fechacarga}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (widget.isHistory && p.fechadescarga.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_outline,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              'Descargado: ${p.fechadescarga}',
                              style: TextStyle(
                                  color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (widget.isHistory &&
                          p.elestadoproductocarrito.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p.elestadoproductocarrito,
                            style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ---------------------- CLIENTE DASHBOARD PAGE ---------------------------------

class ClienteDashboardPage extends StatefulWidget {
  final String idpersona;
  final String cedula;
  const ClienteDashboardPage(
      {Key? key, required this.idpersona, required this.cedula})
      : super(key: key);

  @override
  State<ClienteDashboardPage> createState() => _ClienteDashboardPageState();
}

class _ClienteDashboardPageState extends State<ClienteDashboardPage> {
  int _selectedIndex = 0;

  late List<Widget> _views;

  @override
  void initState() {
    super.initState();
    _views = [
      CarritoProductoView(idpersona: widget.idpersona, cedula: widget.cedula),
      ClienteCartsView(idpersona: widget.idpersona, isHistory: true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0
            ? 'Mi Carrito de Compras'
            : 'Historial de Compras'),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: _views[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.teal,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}

class ClienteCartsView extends StatefulWidget {
  final String idpersona;
  final bool isHistory;

  const ClienteCartsView(
      {Key? key, required this.idpersona, required this.isHistory})
      : super(key: key);

  @override
  State<ClienteCartsView> createState() => _ClienteCartsViewState();
}

class _ClienteCartsViewState extends State<ClienteCartsView> {
  late Future<List<Producto>> _future;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (widget.isHistory) {
      _future =
          ApiService.fetchHistoricocarritoproductoCliente(widget.idpersona);
    } else {
      _future = ApiService.fetchCarritoproductoCliente(widget.idpersona);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          _loadData();
        });
      },
      child: FutureBuilder<List<Producto>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Text(widget.isHistory
                    ? 'No tienes historial de compras'
                    : 'Tu carrito está vacío'));
          }

          final list = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              p.elproducto,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            '\$${p.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.store, size: 16, color: Colors.teal),
                          const SizedBox(width: 4),
                          Text(
                            'Vendedor: ${p.elcustodio}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shopping_basket,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Cantidad: ${p.cantidad}',
                            style: TextStyle(
                                color: Colors.grey[700], fontSize: 14),
                          ),
                        ],
                      ),
                      if (p.fechacarga.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Fecha: ${p.fechacarga}',
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (widget.isHistory &&
                          p.elestadoproductocarrito.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.teal.withOpacity(0.3))),
                              child: Text(
                                p.elestadoproductocarrito,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal),
                              ),
                            ),
                            if (p.fechadescarga.isNotEmpty)
                              Text(
                                'Finalizado: ${p.fechadescarga}',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 11),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
