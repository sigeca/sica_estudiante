// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <<< AGREGAR


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  String _authorized = 'No autenticado';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      setState(() {
        _canCheckBiometrics = canCheck && isDeviceSupported;
      });
    } catch (e) {
      setState(() {
        _authorized = 'Error al verificar biometría: $e';
      });
    }
  }

  Future<void> _authenticate() async {
    if (!_canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu dispositivo no admite biometría o no está configurada.')),
      );
      return;
    }

    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Verifica tu identidad con la huella dactilar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      setState(() {
        _authorized = didAuthenticate ? 'Autenticación exitosa' : 'Falló la autenticación';
      });

      if (didAuthenticate) {
        // Aquí rediriges al usuario al HomeScreen u otra pantalla
    //    Navigator.pushReplacementNamed(context, '/home');
// 2. RECUPERAR DATOS DE SESIÓN
        final prefs = await SharedPreferences.getInstance();
        final idpersona = prefs.getString('idpersona'); 

        if (idpersona != null) {
          // 3. Redirigir y PASAR EL idpersona
          Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
        } else {
          // Si no hay idpersona guardado, informar al usuario que necesita un login completo
          setState(() {
            _authorized = 'Sesión expirada. Inicia con tu contraseña primero.';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron datos de sesión. Inicia con contraseña.')),
          );
        }








      }
    } catch (e) {
      // Captura errores específicos de Android 13/14
      if (e.toString().contains('NotEnrolled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes registrar al menos una huella en tu dispositivo.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de biometría: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login con Huella Dactilar'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.fingerprint,
                size: 100,
                color: _authorized == 'Autenticación exitosa'
                    ? Colors.green
                    : Colors.grey,
              ),
              const SizedBox(height: 30),
              Text(
                _authorized,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.lock_open),
                label: const Text('Usar huella dactilar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

// 🌟🌟🌟 INICIO DE LA NUEVA OPCIÓN DE LOGIN 🌟🌟🌟
              const SizedBox(height: 30),
              TextButton(
                onPressed: () {
                  // **IMPORTANTE:** // Debes usar aquí la ruta que configuraste para tu LoginPagex.dart
                  // o navegar directamente a la clase (si no usas rutas con nombre).
          //        Navigator.pushReplacementNamed(context, '/login_credenciales'); 
                 Navigator.pushReplacementNamed(context, '/loginx');
                },
                child: const Text(
                  'Iniciar sesión con contraseña',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              // 🌟🌟🌟 FIN DE LA NUEVA OPCIÓN DE LOGIN 🌟🌟🌟




            ],
          ),
        ),
      ),
    );
  }
}

