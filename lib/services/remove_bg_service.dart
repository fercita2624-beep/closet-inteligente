import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class RemoveBgService {
  static const String _apiKey = 'gMHGX5XjQL6nq4q4FtGLYcgb';

  static Future<String?> quitarFondo(String imagePath) async {
    try {
      final dio = Dio();
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);

      final formData = FormData.fromMap({
        'image_file': await MultipartFile.fromFile(
          imagePath,
          filename: 'prenda.jpg',
        ),
        'size': 'auto',
        'format': 'png',
      });

      final response = await dio.post(
        'https://api.remove.bg/v1.0/removebg',
        data: formData,
        options: Options(
          headers: {
            'X-Api-Key': _apiKey,
          },
          responseType: ResponseType.bytes,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final fileName = 'prenda_${DateTime.now().millisecondsSinceEpoch}.png';
        final filePath = '${dir.path}/$fileName';
        final file = File(filePath);
        await file.writeAsBytes(response.data as Uint8List);
        if (await file.exists()) {
          return file.path;
        }
      }
      // Si falla Remove.bg, regresa la imagen original
      return imagePath;
    } catch (e) {
      // Si hay cualquier error, regresa la imagen original sin fondo quitado
      return imagePath;
    }
  }
}