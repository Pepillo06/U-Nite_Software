// Stub para plataformas no-web (Windows, Android, iOS, macOS, Linux).
// Las funciones aquí nunca se llaman en tiempo de ejecución porque
// el código que las invoca siempre está dentro de `if (kIsWeb)`.

import 'dart:typed_data';

/// Abre una URL en una nueva pestaña. No-op en plataformas no-web.
void openUrlInNewTab(String url) {
  // No hace nada en Windows/Android/iOS/macOS/Linux.
}

/// Permite al usuario elegir una imagen desde el explorador de archivos web.
/// Siempre retorna null en plataformas no-web.
Future<Uint8List?> pickImageFromWeb() async {
  return null;
}
