// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  String _authorized = 'Esperando acción...'; // Mensaje inicial
  bool _isLoading = false; // Estado de carga para el botón

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final isDeviceSupported = await auth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _canCheckBiometrics = canCheck && isDeviceSupported;
          // Si es compatible, invita al usuario a autenticar
          if (_canCheckBiometrics) {
            _authorized = 'Toca el botón para usar tu Huella Dactilar.';
          } else {
            _authorized = 'Dispositivo no compatible con biometría.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _authorized = 'Error al verificar biometría.';
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (!_canCheckBiometrics) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu dispositivo no admite biometría o no está configurada.')),
      );
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Verifica tu identidad con la huella dactilar',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (mounted) {
        setState(() {
          _authorized = didAuthenticate ? 'Autenticación exitosa' : 'Falló la autenticación';
        });
      }

      if (didAuthenticate) {
        final prefs = await SharedPreferences.getInstance();
        final idpersona = prefs.getString('idpersona');
        final isBiometricsEnabled = prefs.getBool('biometrics_enabled') ?? false;

        if (idpersona != null && idpersona.isNotEmpty && isBiometricsEnabled) {
          // Redirigir y PASAR EL idpersona
          Navigator.pushReplacementNamed(context, '/home', arguments: idpersona);
        } else {
          // Si no hay sesión biométrica guardada
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron datos de sesión biométrica. Inicia con contraseña.')),
          );
          // Redirigir al login con credenciales.
          Navigator.pushReplacementNamed(context, '/loginx');
        }
      }
    } catch (e) {
      String errorMessage = 'Error de biometría: ${e.toString()}';

      // Captura errores específicos y evita el uso del diálogo del sistema si falló
      if (e.toString().contains('NotEnrolled')) {
        errorMessage = 'Debes registrar al menos una huella en tu dispositivo.';
      } else if (e.toString().contains('PermanentlyLockedOut') || e.toString().contains('NotAvailable')) {
         // Error crítico, redirigir al loginx
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
            Navigator.pushReplacementNamed(context, '/loginx');
            return; // Salir de la función
         }
      }

      if (mounted) {
        setState(() => _authorized = errorMessage);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
                    : Colors.blueGrey, // Color más neutro
              ),
              const SizedBox(height: 30),
              Text(
                _authorized,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Botón con indicador de carga
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _authenticate,
                icon: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Icon(Icons.lock_open),
                label: Text(_isLoading ? 'Autenticando...' : 'Usar huella dactilar'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 30),
              TextButton(
                onPressed: _isLoading ? null : () {
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
            ],
          ),
        ),
      ),
    );
  }
}
