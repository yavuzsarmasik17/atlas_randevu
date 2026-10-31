
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class PlatformAdminMusterilerApi {
  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://localhost:7042',
  );

  static const _storage = FlutterSecureStorage();

  static Future<Map<String, String>> _headers() async {
    final token = await _storage.read(
      key: 'atlas_platform_admin_access_token',
    );

    if (token == null || token.isEmpty) {
      throw Exception('Platform Admin oturumu bulunamadı.');
    }

    return {
      'Content-Type': 'application/json; charset=utf-8',
      'Authorization': 'Bearer $token',
    };
  }

  static String _hataMesaji(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['mesaj'] != null) {
        return data['mesaj'].toString();
      }
    } catch (_) {}

    if (response.statusCode == 401 ||
        response.statusCode == 403) {
      return 'Yönetici oturumunuz geçersiz veya yetkisiz.';
    }

    return 'HTTP ${response.statusCode}: İşlem başarısız.';
  }

  static Future<List<Map<String, dynamic>>> listele() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/platform-admin/musteriler'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(_hataMesaji(response));
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));

    if (data is! List) {
      throw Exception('Sunucudan geçersiz müşteri listesi geldi.');
    }

    return data
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> durumDegistir(
    String musteriId,
    bool aktifMi,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$_baseUrl/api/platform-admin/musteriler/'
        '${Uri.encodeComponent(musteriId)}/durum',
      ),
      headers: await _headers(),
      body: jsonEncode({'aktifMi': aktifMi}),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 ||
        response.statusCode >= 300) {
      throw Exception(_hataMesaji(response));
    }
  }
}
