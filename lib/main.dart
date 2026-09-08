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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
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

  // Función para procesar la foto y extraer Nombre y Precio
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

        // Expresión regular para buscar montos de dinero ($ 1200, $1200.50, etc.)
        RegExp expPrecio = RegExp(r'\$?\s?(\d+[\.,]?\d*)');
        Iterable<RegExpMatch> matches = expPrecio.allMatches(textoCompleto);

        double precioDetectado = 0.0;
        for (var match in matches) {
          String valStr =
              match.group(1)?.replaceAll('.', '').replaceAll(',', '.') ?? '0';
          double? val = double.tryParse(valStr);
          if (val != null && val > precioDetectado) {
            // Asumimos que el número mayor suele ser el precio principal
            precioDetectado = val;
          }
        }

        // Extraer la primera línea como nombre del producto
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

  // Función para ingresar manualmente el precio
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
        if (_total < 0) _total = 0; // Evitar precios negativos
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Compras',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TARJETA DEL TOTAL A PAGAR
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green, width: 3),
              ),
              child: Column(
                children: [
                  const Text('TOTAL A PAGAR',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(
                    '\$${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Botón: ESCANEAR CARTEL
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesando ? null : _escanearCartel,
                icon:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.black),
                label: Text(
                  _procesando ? 'PROCESANDO...' : 'ESCANEAR CARTEL',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA2D2D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Botón: TIPEO MANUAL
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _ingresarManual,
                icon: const Icon(Icons.keyboard, size: 28, color: Colors.black),
                label: const Text(
                  'TIPEO MANUAL',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA2D2D2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // INFORMACIÓN DEL ÚLTIMO PRODUCTO DETECTADO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('Último Producto:',
                      style: TextStyle(fontSize: 18, color: Colors.grey[700])),
                  Text(
                    _ultimoProducto,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Precio: \$${_ultimoPrecio.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BOTONES MAS (+) Y MENOS (-)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _ultimoPrecio > 0 ? () => _modificarTotal(true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
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
