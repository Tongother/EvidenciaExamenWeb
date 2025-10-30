// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://miapiunach.somee.com';
  static const String productosPath = '/api/Productos';

  static Map<String, String> _headers() => {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
      };

  static dynamic _jsonDecode(String s) => json.decode(s);
  static Map<String, dynamic> _decodeMap(String s) =>
      s.isEmpty ? <String, dynamic>{} : (_jsonDecode(s) as Map<String, dynamic>);
  static List<dynamic> _decodeList(String s) =>
      s.isEmpty ? <dynamic>[] : (_jsonDecode(s) as List<dynamic>);

  // GET /api/Productos
  static Future<List<Map<String, dynamic>>> getProductos() async {
    final res = await http.get(Uri.parse('$baseUrl$productosPath'), headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final list = _decodeList(res.body);
      return list.cast<Map<String, dynamic>>();
    }
    throw Exception('Error GET productos: ${res.statusCode} ${res.body}');
  }

  // GET /api/Productos/{id}
  static Future<Map<String, dynamic>> getProductoById(String id) async {
    final res = await http.get(Uri.parse('$baseUrl$productosPath/$id'), headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return _decodeMap(res.body);
    }
    throw Exception('Error GET producto: ${res.statusCode} ${res.body}');
  }

  // DELETE /api/Productos/{id}
  static Future<void> deleteProducto(String id) async {
    final res = await http.delete(Uri.parse('$baseUrl$productosPath/$id'), headers: _headers());
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Error DELETE: ${res.statusCode} ${res.body}');
  }

  // POST /api/Productos
  static Future<Map<String, dynamic>> createProducto({
    required String nombre,
    required num precio,
    required int existencia,
    String? fechaRegistro,
  }) async {
    final payloads = <Map<String, dynamic>>[
      {
        "Nombre": nombre,
        "Precio": precio,
        "Existencia": existencia,
        if (fechaRegistro != null) "FechaRegistro": fechaRegistro,
      },
    ];

    final errors = <String>[];

    for (final p in payloads) {
      final res = await http.post(
        Uri.parse('$baseUrl$productosPath'),
        headers: _headers(),
        body: json.encode(p),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final body = res.body.isEmpty ? '{}' : res.body;
        return _decodeMap(body);
      } else {
        errors.add('[${res.statusCode}] ${res.body}');
      }
    }

    throw Exception('Error POST. Intentos fallidos:\n${errors.join('\n')}');
  }
}
