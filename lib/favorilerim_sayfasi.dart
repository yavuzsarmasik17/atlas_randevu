import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'isletme_detay_sayfasi.dart';

class FavorilerimSayfasi extends StatefulWidget {
  const FavorilerimSayfasi({super.key});

  @override
  State<FavorilerimSayfasi> createState() => _FavorilerimSayfasiState();
}

class _FavorilerimSayfasiState extends State<FavorilerimSayfasi> {
  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);
  static const FlutterSecureStorage _depo = FlutterSecureStorage();
  static const String _apiUrl = String.fromEnvironment('API_URL');

  List<Map<String, dynamic>> favoriler = [];
  bool yukleniyor = true;
  String? hata;
  int? silinenIsletmeId;

  @override
  void initState() {
    super.initState();
    favorileriYukle();
  }

  Uri _adres(String yol) {
    if (_apiUrl.isEmpty) {
      throw Exception('API_URL tanımlı değil.');
    }
    return Uri.parse('${_apiUrl.replaceAll(RegExp(r'/+$'), '')}$yol');
  }

  Future<String> _token() async {
    final token = await _depo.read(key: 'atlas_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Favorileri görmek için müşteri hesabınızla giriş yapın.');
    }
    return token;
  }

  String _hataMetni(Object e) => e.toString().replaceFirst('Exception: ', '');

  String? _apiMesaji(http.Response cevap) {
    try {
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is Map && veri['mesaj'] != null) return veri['mesaj'].toString();
    } catch (_) {}
    return null;
  }

  Future<void> favorileriYukle() async {
    if (!mounted) return;
    setState(() {
      yukleniyor = true;
      hata = null;
    });
    try {
      final token = await _token();
      final cevap = await http.get(
        _adres('/api/musteri/favoriler'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (cevap.statusCode == 401 || cevap.statusCode == 403) {
        throw Exception('Oturumunuz sona ermiş olabilir. Yeniden giriş yapın.');
      }
      if (cevap.statusCode != 200) {
        throw Exception(_apiMesaji(cevap) ?? 'Favoriler yüklenemedi (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! List) throw Exception('Sunucudan geçersiz favori listesi geldi.');
      final liste = veri.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() => favoriler = liste);
    } catch (e) {
      if (!mounted) return;
      setState(() => hata = _hataMetni(e));
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  Future<void> favoridenCikar(Map<String, dynamic> isletme) async {
    final id = (isletme['id'] as num?)?.toInt();
    if (id == null || silinenIsletmeId != null) return;
    final ad = (isletme['ad'] ?? 'Bu işletme').toString();
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Favorilerden çıkar'),
        content: Text('$ad favorilerinizden çıkarılsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkar')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    setState(() => silinenIsletmeId = id);
    try {
      final token = await _token();
      final cevap = await http.delete(
        _adres('/api/musteri/favoriler/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception(_apiMesaji(cevap) ?? 'Favori kaldırılamadı (HTTP ${cevap.statusCode}).');
      }
      if (!mounted) return;
      setState(() => favoriler.removeWhere((f) => f['id'] == id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$ad favorilerden çıkarıldı.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_hataMetni(e))));
    } finally {
      if (mounted) setState(() => silinenIsletmeId = null);
    }
  }

  Future<void> isletmeyiAc(Map<String, dynamic> isletme) async {
    final id = (isletme['id'] as num?)?.toInt();
    if (id == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsletmeDetaySayfasi(
          isletme: {
            'id': id.toString(),
            'ad': (isletme['ad'] ?? '').toString(),
            'konum': (isletme['konum'] ?? '').toString(),
            'aciklama': (isletme['aciklama'] ?? '').toString(),
          },
        ),
      ),
    );
    if (mounted) await favorileriYukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: RefreshIndicator(
        onRefresh: favorileriYukle,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [lacivert, mavi]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 35),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Favori İşletmelerim', style: TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text(
                            yukleniyor ? 'Yükleniyor...' : '${favoriler.length} favori işletme',
                            style: const TextStyle(color: Color(0xFFE2E8F0)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Yenile',
                      onPressed: yukleniyor ? null : favorileriYukle,
                      icon: const Icon(Icons.refresh, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            if (yukleniyor)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (hata != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_outlined, size: 48, color: Color(0xFF64748B)),
                        const SizedBox(height: 12),
                        Text(hata!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: favorileriYukle, child: const Text('Tekrar Dene')),
                      ],
                    ),
                  ),
                ),
              )
            else if (favoriler.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.favorite_border, size: 66, color: Color(0xFF94A3B8)),
                        SizedBox(height: 16),
                        Text('Henüz favori işletmeniz yok', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: lacivert)),
                        SizedBox(height: 8),
                        Text('İşletme detayındaki kalp simgesine dokunarak favorilerinize ekleyebilirsiniz.', textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList.builder(
                  itemCount: favoriler.length,
                  itemBuilder: (context, index) {
                    final isletme = favoriler[index];
                    final id = (isletme['id'] as num?)?.toInt();
                    final siliniyor = silinenIsletmeId == id;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(13),
                                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(13)),
                                  child: const Icon(Icons.content_cut, color: mavi, size: 27),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    (isletme['ad'] ?? 'İşletme').toString(),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: lacivert),
                                  ),
                                ),
                                siliniyor
                                    ? const SizedBox(width: 36, height: 36, child: Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2)))
                                    : IconButton(
                                        tooltip: 'Favorilerden çıkar',
                                        onPressed: silinenIsletmeId != null ? null : () => favoridenCikar(isletme),
                                        icon: const Icon(Icons.favorite, color: Color(0xFFDC2626)),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: silinenIsletmeId != null ? null : () => isletmeyiAc(isletme),
                                icon: const Icon(Icons.calendar_month_outlined),
                                label: const Text('İşletmeye Git / Randevu Al'),
                                style: FilledButton.styleFrom(backgroundColor: mavi, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
