// ignore_for_file: use_build_context_synchronously

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart'; 
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
  
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _canCheckBiometrics = false;
  
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
    // No llamamos a _tryBiometricLoginOnStart aquí para evitar doble login
    // si el usuario viene de LoginPage.dart después de un error.
    // El 'main.dart' decide si ir a '/login' o '/loginx'.
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isDeviceSupported = await _localAuthentication.isDeviceSupported();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isDeviceSupported;
        });
      }
    } on PlatformException catch (e) {
      print("Error al verificar biometría: $e");
    }
  }

  Future<bool> _authenticateBiometrics({bool allowAlternative = false}) async {
    bool authenticated = false;
    if (mounted) setState(() => _loading = true);

    try {
      authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Por favor, usa tu huella dactilar para iniciar sesión',
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: !allowAlternative, // true si viene del diálogo de setup
        ),
      );
    } on PlatformException catch (e) {
      print("Error de autenticación biométrica: $e");
      String specificError = _getBiometricErrorMessage(e.code);
      
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = specificError;  
        });
      }
      return false;
    }

    if (mounted) setState(() => _loading = false);

    if (authenticated) {
      final prefs = await SharedPreferences.getInstance();
      final idpersona = prefs.getString('idpersona');
      
      if (idpersona != null && idpersona.isNotEmpty) {
         Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = 'No se encontraron datos de sesión para la biometría. Inicia con contraseña.';
          });
        }
      }
    }
    return authenticated;
  }
  
  String _getBiometricErrorMessage(String code) {
      switch (code) {
        case 'NotEnrolled': return 'No hay huellas o rostro configurado en el dispositivo.';
        case 'NotAvailable': return 'La biometría no está disponible en este dispositivo.';
        case 'PasscodeNotSet': return 'Debes configurar un PIN/Contraseña en el dispositivo primero.';
        case 'LockedOut': return 'Demasiados intentos fallidos. Usa tu PIN/contraseña.';
        case 'PermanentlyLockedOut': return 'La biometría ha sido bloqueada. Reinicia o usa la contraseña.';
        case 'auth_failed': return 'Fallo al autenticar. Inténtalo de nuevo.';
        default: return 'Error de biometría: $code. Verifica tu configuración.';
      }
  }


  Future<void> _saveUserSession(String email, String idpersona, String idusuario, {bool biometricsEnabled = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email);
    await prefs.setString('idpersona', idpersona);
    await prefs.setString('idusuario', idusuario);
    await prefs.setBool('biometrics_enabled', biometricsEnabled);
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Introduce correo y contraseña.');
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final logins = await ApiService.login(
        _emailController.text,
        _passwordController.text,
      );
      
      if (logins.isNotEmpty) {
        final idpersona = logins[0].idpersona;
        final idusuario = logins[0].idusuario;
        
        // Guardamos la sesión inicial SIN habilitar biometría todavía.
        await _saveUserSession(_emailController.text.trim(), idpersona, idusuario, biometricsEnabled: false);

        if (mounted) setState(() => _loading = false);

        // Preguntar al usuario si desea habilitar la biometría
        if (_canCheckBiometrics) {
          _showBiometricSetupDialog(idpersona);
        } else {
          Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
        }

      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _errorMessage = 'Credenciales incorrectas o datos no disponibles.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString().contains('Exception:') ? e.toString().replaceFirst('Exception: ', '') : 'Error: ${e.toString()}';
        });
      }
    }
  }
  
  void _showBiometricSetupDialog(String idpersona) {
    showDialog(
      context: context,
      barrierDismissible: false, // Bloquea la salida con un toque fuera
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
                // Forzar una autenticación de confirmación para guardar la preferencia.
                final authenticated = await _authenticateBiometrics(allowAlternative: true); 
                
                if (authenticated) {
                    // Solo si la autenticación de confirmación es exitosa, guardamos 'biometrics_enabled: true'
                    await _saveUserSession(_emailController.text.trim(), idpersona, '', biometricsEnabled:true);
                    // El _authenticateBiometrics ya navega a /home si es exitoso.
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
                  keyboardType: TextInputType.emailAddress,
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
                    // 💥💥 CORRECCIÓN AQUÍ 💥💥: textAlign es propiedad de Text, no de TextStyle
                    textAlign: TextAlign.center, 
                    style: const TextStyle(color: Colors.red),
                  ),
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Iniciar sesión'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _loading ? null : () => Navigator.pushNamed(context, '/registro'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Colors.blueAccent),
                  ),
                  child: const Text('Registrarse'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _loading ? null : () => Navigator.pushNamed(context, '/registro'),
                  child: const Text(
                    '¿Olvidó su contraseña?',
                    style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline),
                  ),
                ),
                
                // Botón para volver al login de biometría
                const SizedBox(height: 24),
                 TextButton(
                  onPressed: _loading ? null : () {
                    // Si el loginx es el login principal, este botón redirige a la opción biométrica
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text(
                    'Usar Huella Dactilar',
                    style: TextStyle(
                      color: Colors.blueAccent,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),


                // Botón de biometría manual si está disponible (útil si la sesión ya está guardada pero falló el login automático)
                if (_canCheckBiometrics) ...[
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : () => _authenticateBiometrics(allowAlternative: false),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Iniciar con Huella Dactilar (Sesión Guardada)'),
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
