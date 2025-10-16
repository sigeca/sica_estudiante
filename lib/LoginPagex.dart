import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
// Agrega el paquete para la autenticación biométrica
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart'; // Necesario para PlatformException
import 'evento.dart';
import 'api_service.dart';

class LoginPagex extends StatefulWidget {
  const LoginPagex({super.key});

  @override
  _LoginPagexState createState() => _LoginPagexState();
}

class _LoginPagexState extends State<LoginPagex> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  
  // 1. Inicializa LocalAuthentication
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _canCheckBiometrics = false;
  
  List<Login> logins = [];

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    _tryBiometricLoginOnStart();
  }
  
  // Función para verificar si el dispositivo soporta biometría
  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics;
    try {
      canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      setState(() {
        _canCheckBiometrics = canCheckBiometrics;
      });
    } on PlatformException catch (e) {
      print("Error al verificar biometría: $e");
      canCheckBiometrics = false;
    }
  }

  // Intenta el login biométrico automático si el usuario ya ha iniciado sesión
  Future<void> _tryBiometricLoginOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && _canCheckBiometrics) {
      // Si ya hay una sesión y biometría disponible, intenta autenticar.
      await _authenticateBiometrics();
    }
  }

  // 3. Función para realizar la autenticación biométrica
  Future<bool> _authenticateBiometrics() async {
    bool authenticated = false;
    setState(() => _loading = true);

    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Por favor, usa tu huella dactilar para iniciar sesión', // Mensaje que ve el usuario
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Permite PIN/Patrón como alternativa
        ),
      );
    } on PlatformException catch (e) {
      print("Error de autenticación biométrica: $e");
      
      String specificError = 'Error de biometría desconocido.';
      
      // Agrega manejo de errores específico usando los códigos de error de local_auth
      switch (e.code) {
        case 'NotEnrolled':
          specificError = 'No hay huellas o rostro configurado en el dispositivo.';
          break;
        case 'NotAvailable':
          specificError = 'La biometría no está disponible en este dispositivo.';
          break;
        case 'PasscodeNotSet':
          specificError = 'Debes configurar un PIN/Contraseña en el dispositivo primero.';
          break;
        case 'LockedOut':
          specificError = 'Demasiados intentos fallidos. Usa tu PIN/contraseña.';
          break;
        case 'PermanentlyLockedOut':
          specificError = 'La biometría ha sido bloqueada. Reinicia o usa la contraseña.';
          break;
        case 'auth_failed': // A veces es un mensaje de fallo genérico
          specificError = 'Fallo al autenticar. Inténtalo de nuevo.';
          break;
        default:
          specificError = 'Error de biometría: ${e.code}. Verifica tu configuración.';
          break;
      }

      setState(() {
        _loading = false;
        _errorMessage =specificError;  
      });
      return false;
    }

    setState(() => _loading = false);

    if (authenticated) {
      // Después de la autenticación local exitosa, recupera las credenciales guardadas
      final prefs = await SharedPreferences.getInstance();
      final savedEmail = prefs.getString('email');
      final savedPassword = prefs.getString('password'); // ¡ATENCIÓN: Esto es INSEGURO!
      
      // Una vez que la biometría local es exitosa, se puede:
      // A) Recuperar un token seguro (mejor opción, requiere flutter_secure_storage)
      // B) Re-loguearse automáticamente con credenciales guardadas (opción INSEGURA)
      // C) Usar la biometría como un paso después del login normal para guardarlo

      // Implementaremos la opción C: Si la autenticación local es exitosa,
      // usaremos el idpersona guardado para ir a Home, asumiendo que el login
      // ya se hizo una vez y guardaste la sesión.
      
      final idpersona = prefs.getString('idpersona');
      if (idpersona != null) {
         Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
      } else {
        setState(() {
          _errorMessage = 'No se encontraron datos de sesión para la biometría.';
        });
      }
    }
    return authenticated;
  }

  Future<void> _saveUserSession(String email, String idpersona) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email);
    await prefs.setString('idpersona', idpersona);
    // Nota: Para un flujo de biometría completo, deberías guardar el token de
    // sesión aquí usando un almacenamiento seguro (como flutter_secure_storage),
    // no la contraseña.
  }

  Future<void> _login() async {
    // ... Tu función _login original (autenticación por email/contraseña)
    // Se mantiene igual. Solo asegúrate de que, en un login exitoso, 
    // se guarde también la opción de biometría si el usuario lo desea.
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      setState(() => _loading = true);

      final logins = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );
      final idpersona = logins[0].idpersona;
      setState(() => _loading = false);

      if (idpersona != null) {
        await _saveUserSession(_emailController.text.trim(), idpersona);

        // Preguntar al usuario si desea habilitar la biometría
        if (_canCheckBiometrics) {
          _showBiometricSetupDialog(idpersona);
        } else {
          Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
        }

      } else {
        setState(() {
          _errorMessage = 'Credenciales incorrectas o datos no disponibles.';
        });
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  // Diálogo para configurar la biometría después del primer login
  void _showBiometricSetupDialog(String idpersona) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Habilitar Biometría'),
          content: const Text('¿Deseas habilitar la huella dactilar/Face ID para futuros accesos?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No, gracias'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(this.context, '/home', arguments: idpersona);
              },
            ),
            TextButton(
              child: const Text('Habilitar'),
              onPressed: () async {
                Navigator.of(context).pop();
                // Opcionalmente, puedes forzar una autenticación de confirmación aquí
                final authenticated = await _authenticateBiometrics(); 
                if (authenticated) {
                    Navigator.pushReplacementNamed(this.context, '/home', arguments: idpersona);
                } else {
                    // Si falla, aún lo llevamos a home, pero la opción no estará configurada
                    Navigator.pushReplacementNamed(this.context, '/home', arguments: idpersona);
                }
              },
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ... (Tu código de título, subtítulo y logo) ...
                const Text(
                  'SICA-ESTUDIANTE',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'SISTEMA INTEGRADO DE CONTROL ACADÉMICO',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),

                Image.network(
                  'https://educaysoft.org/sica/images/logoeysutlvt.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 120, color: Colors.red),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const SizedBox(
                      height: 120,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),

                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Correo electrónico'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar sesión'),
                ),
                
                // 4. Agregar el botón de biometría si está disponible
                if (_canCheckBiometrics) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _authenticateBiometrics,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Iniciar con Huella Dactilar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      side: const BorderSide(color: Colors.blueAccent),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}
