import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class BildirimlerSayfasi extends StatefulWidget {
  const BildirimlerSayfasi({super.key});
  @override
  State<BildirimlerSayfasi> createState() => _BildirimlerSayfasiState();
}

class _BildirimlerSayfasiState extends State<BildirimlerSayfasi> {
  static const apiUrl = String.fromEnvironment('API_URL');
  static const depo = FlutterSecureStorage();
  List<Map<String, dynamic>> bildirimler = [];
  bool yukleniyor = true;
  String? hata;

  @override
  void initState() { super.initState(); getir(); }

  Future<void> getir() async {
    setState(() { yukleniyor = true; hata = null; });
    try {
      final token = await depo.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Giriş yapmanız gerekiyor.');
      final cevap = await http.get(Uri.parse('$apiUrl/api/bildirim/liste'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      if (cevap.statusCode == 404) {
        throw Exception('Bildirim listesi API uç noktası henüz kurulmamış. '
          'API tarafındaki eklemeyi tamamlayın.');
      }
      if (cevap.statusCode != 200) throw Exception('Sunucu hatası: ${cevap.statusCode}');
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! List) throw const FormatException('Beklenmeyen bildirim verisi');
      if (!mounted) return;
      setState(() {
        bildirimler = veri.map((x) => Map<String, dynamic>.from(x as Map)).toList();
        yukleniyor = false;
      });
    } catch (e) {
      if (mounted) setState(() { hata = e.toString(); yukleniyor = false; });
    }
  }

  Future<void> okunduYap(Map<String, dynamic> bildirim) async {
    final id = bildirim['id'];
    if (id == null) return;
    final token = await depo.read(key: 'atlas_access_token');
    if (token == null) return;
    try {
      final cevap = await http.put(Uri.parse('$apiUrl/api/bildirim/$id/okundu'),
        headers: {'Authorization': 'Bearer $token'});
      if (cevap.statusCode == 200 || cevap.statusCode == 204) await getir();
    } catch (_) { /* Yenileme hareketiyle tekrar denenebilir. */ }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(title: const Text('Bildirimler'), actions: [
      IconButton(onPressed: getir, icon: const Icon(Icons.refresh))]),
    body: yukleniyor
      ? const Center(child: CircularProgressIndicator())
      : hata != null
        ? Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 46),
              const SizedBox(height: 12),
              Text(hata!, textAlign: TextAlign.center),
              TextButton(onPressed: getir, child: const Text('Tekrar Dene')),
            ])))
        : bildirimler.isEmpty
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min,
              children: [Icon(Icons.notifications_none, size: 68,
                color: Color(0xFF94A3B8)), SizedBox(height: 12),
                Text('Henüz bildiriminiz yok.')]))
          : RefreshIndicator(onRefresh: getir, child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: bildirimler.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final b = bildirimler[i];
                final okundu = b['okunduMu'] == true;
                return Card(color: Colors.white, child: ListTile(
                  leading: Icon(okundu ? Icons.notifications_none : Icons.notifications_active,
                    color: const Color(0xFF2563EB)),
                  title: Text((b['baslik'] ?? 'Bildirim').toString(),
                    style: TextStyle(fontWeight: okundu ? FontWeight.normal : FontWeight.bold)),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text((b['mesaj'] ?? '').toString()),
                      Text((b['olusturmaTarihi'] ?? '').toString(),
                        style: const TextStyle(fontSize: 11))]),
                  onTap: () => okunduYap(b),
                ));
              },
            )),
  );
}
