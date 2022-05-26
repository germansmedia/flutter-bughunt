import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Cropping Doesn\'t Work?'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ui.Image? _image;
  ui.Image? _croppedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: (_image != null)
            ? (_croppedImage != null)
                ? RawImage(image: _croppedImage)
                : RawImage(image: _image)
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (_image == null)
            ? () async {
                final picker = ImagePicker();
                XFile? result =
                    await picker.pickImage(source: ImageSource.gallery);
                if (result != null) {
                  final bytes = await result.readAsBytes();
                  final codec = await ui.instantiateImageCodec(bytes);
                  final frameInfo = await codec.getNextFrame();
                  final image = frameInfo.image;
                  debugPrint(
                      'picked image at ${image.width} x ${image.height}');
                  setState(() {
                    _image = image;
                  });
                }
              }
            : (_croppedImage == null)
                ? () async {
                    debugPrint('cropping corner to 512x512');

                    ui.PictureRecorder recorder = ui.PictureRecorder();
                    ui.Canvas canvas = ui.Canvas(recorder);
                    canvas.drawImageRect(
                      _image!,
                      ui.Rect.fromLTWH(0, 0, 64, 64),
                      ui.Rect.fromLTWH(0, 0, 512, 512),
                      ui.Paint(),
                    );
                    ui.Picture picture = recorder.endRecording();
                    final image = await picture.toImage(512, 512);

                    // also download to be sure
                    final pngByteData =
                        await image.toByteData(format: ui.ImageByteFormat.png);
                    final pngBytes = pngByteData!.buffer.asUint8List();
                    if (kIsWeb) {
                      final blob = html.Blob(
                          <dynamic>[pngBytes], 'application/octet-stream');
                      final anchorElement = html.AnchorElement(
                        href: html.Url.createObjectUrlFromBlob(blob),
                      )
                        ..setAttribute('download', 'cropped.png')
                        ..click();
                    }

                    setState(() {
                      _croppedImage = image;
                    });
                  }
                : () {
                    setState(() {
                      _image = null;
                      _croppedImage = null;
                    });
                  },
        child: Text((_image == null)
            ? 'open'
            : (_croppedImage == null)
                ? 'crop'
                : 'done'),
      ),
    );
  }
}
