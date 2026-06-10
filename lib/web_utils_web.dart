// Implementación real para la plataforma web.
// Este archivo SÍ puede usar dart:html con seguridad.

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';

/// Abre una URL en una nueva pestaña del navegador.
void openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
}

/// Muestra el selector de archivos nativo del navegador y retorna
/// los bytes de la imagen elegida, o null si el usuario cancela.
Future<Uint8List?> pickImageFromWeb() async {
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();
  await input.onChange.first;
  if (input.files == null || input.files!.isEmpty) return null;
  final reader = html.FileReader();
  reader.readAsArrayBuffer(input.files![0]);
  await reader.onLoad.first;
  final bytes = reader.result as List<int>;
  return Uint8List.fromList(bytes);
}
