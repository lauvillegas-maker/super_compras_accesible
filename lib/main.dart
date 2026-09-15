import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
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

  // Parsea un string simple (para cuando se ingresa manualmente)
  double _parsearPrecioTexto(String texto) {
    RegExp regexPrecio = RegExp(r'(\$\s*)?\d+([.,]\d+)?');
    Iterable<RegExpMatch> matches = regexPrecio.allMatches(texto);

    for (Match match in matches) {
      String bruto = match.group(0) ?? '';
      String limpio = bruto.replaceAll(RegExp(r'[^\d.,]'), '').trim();
      if (limpio.isEmpty) continue;

      double valor = _convertirANumero(limpio);
      if (valor > 0) return valor;
    }
    return 0.0;
  }

  // Convierte cadenas con formato de precio a número de tipo double
  static double _convertirANumero(String limpio) {
    if (limpio.contains('.') && limpio.contains(',')) {
      if (limpio.lastIndexOf(',') > limpio.lastIndexOf('.')) {
        limpio = limpio.replaceAll('.', '').replaceAll(',', '.');
      } else {
        limpio = limpio.replaceAll(',', '');
      }
    } else if (limpio.contains('.')) {
      List<String> partes = limpio.split('.');
      if (partes.last.length == 3) {
        limpio = limpio.replaceAll('.', '');
      }
    } else if (limpio.contains(',')) {
      List<String> partes = limpio.split(',');
      if (partes.last.length == 3) {
        limpio = limpio.replaceAll(',', '');
      } else {
        limpio = limpio.replaceAll(',', '.');
      }
    }
    return double.tryParse(limpio) ?? 0.0;
  }

  // Escáner de cámara en vivo
  void _abrirEscanerCamara() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PantallaEscaner(
          camera: cameras.first,
          onPrecioDetectado: (precio) {
            Navigator.pop(context);
            if (precio > 0) {
              setState(() {
                _ultimoProducto = 'Producto Escaneado';
                _ultimoPrecio = precio;
                _total += precio;
              });
            }
          },
        ),
      ),
    );
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
                double precio = _parsearPrecioTexto(controller.text);
                if (precio > 0) {
                  setState(() {
                    _ultimoProducto = 'Ingreso Manual';
                    _ultimoPrecio = precio;
                    _total += precio;
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

  void _reiniciarTotal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Reiniciar compra?'),
        content: const Text('El total acumulado volverá a \$0.00.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F)),
            onPressed: () {
              setState(() {
                _total = 0.0;
                _ultimoProducto = 'Ninguno';
                _ultimoPrecio = 0.0;
              });
              Navigator.pop(context);
            },
            child:
                const Text('REINICIAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
        backgroundColor: const Color(0xFF2196F3),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _abrirEscanerCamara,
                icon:
                    const Icon(Icons.camera_alt, size: 28, color: Colors.white),
                label: const Text(
                  'ESCANEAR CARTEL',
                  style: TextStyle(
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
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _ingresarManual,
                icon: const Icon(Icons.keyboard,
                    size: 28, color: Color(0xFF2196F3)),
                label: const Text(
                  'TIPEAR PRECIO MANUALMENTE',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF2196F3), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
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
            const SizedBox(height: 20),
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
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reiniciarTotal,
                icon: const Icon(Icons.refresh, size: 24, color: Colors.white),
                label: const Text(
                  'REINICIAR / LIMPIAR TOTAL',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF757575),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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

class PantallaEscaner extends StatefulWidget {
  final CameraDescription camera;
  final Function(double) onPrecioDetectado;

  const PantallaEscaner({
    super.key,
    required this.camera,
    required this.onPrecioDetectado,
  });

  @override
  State<PantallaEscaner> createState() => _PantallaEscanerState();
}

class _PantallaEscanerState extends State<PantallaEscaner> {
  late CameraController _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );
    _controller.initialize().then((_) {
      if (!mounted) return;
      _controller.startImageStream(_procesarImagenCamara);
      setState(() {});
    });
  }

  void _procesarImagenCamara(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final InputImage? inputImage = _prepararInputImage(image);
      if (inputImage != null) {
        final RecognizedText recognizedText =
            await _textRecognizer.processImage(inputImage);

        // Busca el texto con el mayor tamaño tipográfico/área en pantalla
        double precio = _extraerPrecioPorTamano(recognizedText);
        if (precio > 0) {
          await _controller.stopImageStream();
          widget.onPrecioDetectado(precio);
        }
      }
    } catch (_) {
      // Ignorar errores temporales en la lectura de frames
    } finally {
      _isProcessing = false;
    }
  }

  double _extraerPrecioPorTamano(RecognizedText recognizedText) {
    double precioDetectado = 0.0;
    double maxArea = 0.0;

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String text = line.text;

        RegExp regexPrecio = RegExp(r'(\$\s*)?\d+([.,]\d+)?');
        Iterable<RegExpMatch> matches = regexPrecio.allMatches(text);

        for (Match match in matches) {
          String bruto = match.group(0) ?? '';
          String limpio = bruto.replaceAll(RegExp(r'[^\d.,]'), '').trim();
          if (limpio.isEmpty) continue;

          // Ignorar secuencias largas de números que no son precios (ej. código de barras)
          if (!limpio.contains('.') &&
              !limpio.contains(',') &&
              limpio.length >= 7) {
            continue;
          }

          double valor = _PaginaPrincipalState._convertirANumero(limpio);
          if (valor <= 0) continue;

          // Calcula el área que ocupa el cuadro delimitador del texto
          Rect boundingBox = line.boundingBox;
          double area = boundingBox.width * boundingBox.height;

          // Selecciona el valor que ocupe mayor espacio visual en pantalla
          if (area > maxArea) {
            maxArea = area;
            precioDetectado = valor;
          }
        }
      }
    }

    return precioDetectado;
  }

  InputImage? _prepararInputImage(CameraImage image) {
    final sensorOrientation = widget.camera.sensorOrientation;
    InputImageRotation? rotation =
        InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null) return null;

    if (image.planes.length != 1) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Apunte al Cartel')),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
