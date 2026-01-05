import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../config/api_config.dart';
import '../utils/app_colors.dart';
import '../services/api_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

/// Pantalla para configurar la IP del servidor manualmente
class ServerConfigScreen extends StatefulWidget {
  const ServerConfigScreen({super.key});

  @override
  State<ServerConfigScreen> createState() => _ServerConfigScreenState();
}

class _ServerConfigScreenState extends State<ServerConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  bool _isTesting = false;
  String? _currentIp;
  String? _detectedIp;

  @override
  void initState() {
    super.initState();
    _loadCurrentIp();
    _tryAutoDetect();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentIp() async {
    await ApiConfig.loadSavedManualIp();
    setState(() {
      _currentIp = ApiConfig.baseUrl.replaceAll('http://', '').replaceAll('/api', '').replaceAll(':3000', '');
      _ipController.text = _currentIp ?? '';
    });
  }

  Future<void> _tryAutoDetect() async {
    setState(() {
      _isTesting = true;
      _detectedIp = null;
    });

    try {
      await ApiConfig.detectLocalIp();
      // Esperar un poco para que termine la detección
      await Future.delayed(const Duration(seconds: 3));
      
      final baseUrl = ApiConfig.baseUrl;
      final detected = baseUrl.replaceAll('http://', '').replaceAll('/api', '').replaceAll(':3000', '');
      
      if (detected != '10.0.2.2' && detected != 'localhost') {
        setState(() {
          _detectedIp = detected;
        });
      }
    } catch (e) {
      print('Error en detección automática: $e');
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _testConnection(String ip) async {
    setState(() {
      _isTesting = true;
    });

    try {
      // Guardar temporalmente la IP para probar
      await ApiConfig.saveManualIp(ip);
      
      // Probar conexión
      final apiService = ApiService();
      final connected = await apiService.checkConnection();
      
      if (connected) {
        Fluttertoast.showToast(
          msg: '✅ Conexión exitosa con $ip',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
        // La IP ya está guardada, volver atrás
        if (mounted) {
          context.pop(true); // Retornar true indica que se configuró correctamente
        }
      } else {
        Fluttertoast.showToast(
          msg: '❌ No se pudo conectar a $ip',
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: '❌ Error: ${e.toString()}',
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveIp() async {
    if (!_formKey.currentState!.validate()) return;

    final ip = _ipController.text.trim();
    await _testConnection(ip);
  }

  Future<void> _useDetectedIp() async {
    if (_detectedIp != null) {
      _ipController.text = _detectedIp!;
      await _testConnection(_detectedIp!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        title: const Text('Configurar Servidor'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary),
                            const SizedBox(width: 8),
                            const Text(
                              'Configuración del Servidor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Ingresa la IP de tu laptop donde está corriendo el backend.',
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ejemplo: 192.168.1.24',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'IP del Servidor',
                    hintText: '192.168.1.24',
                    prefixIcon: const Icon(Icons.computer),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa la IP del servidor';
                    }
                    // Validar formato básico de IP
                    final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                    if (!ipRegex.hasMatch(value)) {
                      return 'Formato de IP inválido (ej: 192.168.1.24)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (_detectedIp != null) ...[
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'IP detectada automáticamente',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  _detectedIp!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _isTesting ? null : _useDetectedIp,
                            icon: const Icon(Icons.check),
                            label: const Text('Usar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_isTesting) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: _isTesting ? null : _saveIp,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar y Probar Conexión'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _isTesting ? null : _tryAutoDetect,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Detectar Automáticamente'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.blue),
                            const SizedBox(width: 8),
                            const Text(
                              'Ayuda',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• Asegúrate de que tu celular esté en la misma red WiFi que tu laptop',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• El backend debe estar corriendo en el puerto 3000',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '• Para encontrar la IP de tu laptop, ejecuta: ipconfig (Windows)',
                          style: TextStyle(fontSize: 12),
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

