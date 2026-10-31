import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class IsletmeFotografApi {
  static const String _baseUrl = String.fromEnvironment('API_URL');
  static const _storage = FlutterSecureStorage();
  static const _yol = '/api/isletme/fotograflar';

  static String resimUrl(String? yol) {
    if (yol == null || yol.isEmpty) return '';
    if (yol.startsWith('http://') || yol.startsWith('https://')) return yol;
    return '$_baseUrl${yol.startsWith('/') ? '' : '/'}$yol';
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) throw Exception('Oturum bulunamadı. Tekrar giriş yapın.');
    return {'Authorization': 'Bearer $token'};
  }

  static void _kontrol(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    String mesaj = 'İşlem başarısız (${response.statusCode})';
    try {
      final veri = jsonDecode(response.body);
      if (veri is Map && veri['mesaj'] != null) mesaj = veri['mesaj'].toString();
    } catch (_) {}
    throw Exception(mesaj);
  }

  static Future<Map<String, dynamic>> listele() async {
    final response = await http.get(Uri.parse('$_baseUrl$_yol'), headers: await _headers());
    _kontrol(response);
    return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
  }

  static Future<void> yukle(String tur, XFile dosya) async {
    if (!['logo', 'kapak', 'galeri'].contains(tur)) throw ArgumentError('Geçersiz görsel türü');
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl$_yol/$tur'));
    request.headers.addAll(await _headers());
    final bytes = await dosya.readAsBytes();
    if (bytes.length > 5 * 1024 * 1024) throw Exception('Fotoğraf 5 MB sınırını aşıyor.');
    request.files.add(http.MultipartFile.fromBytes('dosya', bytes, filename: dosya.name));
    final stream = await request.send();
    final response = await http.Response.fromStream(stream);
    _kontrol(response);
  }

  static Future<void> sil(int id) async {
    final response = await http.delete(Uri.parse('$_baseUrl$_yol/galeri/$id'), headers: await _headers());
    _kontrol(response);
  }
}
