import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() {
  runApp(const MiApp());
}

class MiApp extends StatelessWidget {
  const MiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Super Compras',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Fondo gris claro
      ),
      home: const PaginaPrincipal(),
    );
  }
}

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({super.key});

  @override
  State<PaginaPrincipal> createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  double _total = 0.0;
  String _ultimoProducto = 'Ninguno';
  double _ultimoPrecio = 0.0;
  bool _procesando = false;

  Future<void> _escanearCartel() async {
    var status = await Permission.camera.request();

    if (status.isGranted) {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null) {
        setState(() => _procesando = true);

        final inputImage = InputImage.fromFilePath(photo.path);
        final textRecognizer =
            TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText =
            await textRecognizer.processImage(inputImage);

        String textoCompleto = recognizedText.text;

        RegExp expPrecio = RegExp(r'\$?\s?(\d+[\.,]?\d*)');
        Iterable<RegExpMatch> matches = expPrecio.allMatches(textoCompleto);

        double precioDetectado = 0.0;
        for (var match in matches) {
          String valStr =
              match.group(1)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
          double? val = double.tryParse(valStr);
          if (val != null && val > precioDetectado) {
            precioDetectado = val;
          }
        }

        List<String> lineas = textoCompleto.split('\n');
        String nombreDetectado =
            lineas.isNotEmpty ? lineas.first : 'Producto Escaneado';

        setState(() {
          _ultimoProducto = nombreDetectado;
          _ultimoPrecio = precioDetectado;
          _procesando = false;
        });

        await textRecognizer.close();
      }
    } else if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
  }

  void _ingresarManual() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tipear Precio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            decoration: const InputDecoration(
              labelText: 'Ingrese el precio',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              onPressed: () {
                double? precio =
                    double.tryParse(controller.text.replaceAll(',', '.'));
                if (precio != null && precio > 0) {
                  setState(() {
                    _ultimoProducto = 'Ingreso Manual';
                    _ultimoPrecio = precio;
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('ACEPTAR',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _modificarTotal(bool sumar) {
    setState(() {
      if (sumar) {
        _total += _ultimoPrecio;
      } else {
        _total -= _ultimoPrecio;
        if (_total < 0) _total = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Compras',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: const Color(0xFF2196F3), // Azul de la imagen
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA DEL TOTAL A PAGAR (Verde)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC8E6C9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Column(
                children: [
                  const Text('TOTAL A PAGAR',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121))),
                  const SizedBox(height: 5),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4CAF50)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOTÓN PRINCIPAL: ESCANEAR CARTEL (Azul)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _escanearCartel,
                icon:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.white),
                label: Text(
                  _procesando ? 'PROCESANDO...' : 'ESCANEAR CARTEL',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // BOTÓN SECUNDARIO: TIPEAR PRECIO MANUALMENTE
            OutlinedButton.icon(
              onPressed: _ingresarManual,
              icon: const Icon(Icons.keyboard,
                  size: 24, color: Color(0xFF2196F3)),
              label: const Text(
                'TIPEAR PRECIO MANUALMENTE',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2196F3)),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // TARJETA ÚLTIMO PRODUCTO (Gris)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEEEEE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text('Último Producto:',
                      style: TextStyle(fontSize: 18, color: Color(0xFF616161))),
                  const SizedBox(height: 4),
                  Text(
                    _ultimoProducto,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF212121)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Precio: \$${_ultimoPrecio.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOTONES SUMAR (+) Y RESTAR (-)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _ultimoPrecio > 0 ? () => _modificarTotal(true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF9E9E9E),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('SUMAR (+)',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _ultimoPrecio > 0 ? () => _modificarTotal(false) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF44336),
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: const Color(0xFF9E9E9E),
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('RESTAR (-)',
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
