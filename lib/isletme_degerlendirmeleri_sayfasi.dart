import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'isletme_bilgileri_api.dart';

class IsletmeDegerlendirmeleriSayfasi extends StatefulWidget {
  const IsletmeDegerlendirmeleriSayfasi({super.key});

  @override
  State<IsletmeDegerlendirmeleriSayfasi> createState() =>
      _IsletmeDegerlendirmeleriSayfasiState();
}

class _IsletmeDegerlendirmeleriSayfasiState
    extends State<IsletmeDegerlendirmeleriSayfasi> {
  static const _apiUrl = String.fromEnvironment('API_URL');
  static const _storage = FlutterSecureStorage();
  static const _lacivert = Color(0xFF142D5C);
  static const _mavi = Color(0xFF2563EB);
  bool _yukleniyor = true;
  String? _hata;
  double _ortalama = 0;
  int _adet = 0;
  int _filtre = 0;
  List<Map<String, dynamic>> _yorumlar = [];

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  Future<void> _yukle() async {
    if (!mounted) return;
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      if (_apiUrl.isEmpty) throw Exception('API_URL tanımlı değil.');
      final token = await _storage.read(key: 'atlas_isletme_access_token');
      if (token == null || token.isEmpty) {
        throw Exception('İşletme oturumu bulunamadı.');
      }
      // İşletme kimliği müşteri tarafından değil, oturumun işletme
      // profilinden alınır. Bu yanıtın "id" alanını içerdiğini doğrulayın.
      final profil = await IsletmeBilgileriApi.getir();
      final id = int.tryParse((profil['id'] ?? profil['isletmeId'] ?? '').toString());
      if (id == null || id <= 0) {
        throw Exception('İşletme profil API yanıtında id/isletmeId yok. '
            'isletme_bilgileri_api.dart ve profil controller yanıtı kontrol edilmeli.');
      }
      final base = _apiUrl.replaceAll(RegExp(r'/+$'), '');
      final cevap = await http.get(
        Uri.parse('$base/api/isletmeler/$id/degerlendirmeler'),
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception('Yorumlar alınamadı (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map<String, dynamic>) {
        throw const FormatException('Değerlendirme yanıtı geçersiz.');
      }
      final liste = veri['yorumlar'];
      if (liste is! List) throw const FormatException('Yorum listesi bulunamadı.');
      if (!mounted) return;
      setState(() {
        _ortalama = (veri['ortalamaPuan'] as num?)?.toDouble() ?? 0;
        _adet = (veri['degerlendirmeSayisi'] as num?)?.toInt() ?? 0;
        _yorumlar = liste.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _hata = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Widget _yildizlar(int puan) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) => Icon(
      i < puan ? Icons.star_rounded : Icons.star_border_rounded,
      size: 19, color: const Color(0xFFF59E0B),
    )),
  );

  String _tarih(dynamic raw) {
    final d = DateTime.tryParse(raw?.toString() ?? '');
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = _yorumlar.where((x) {
      final puan = (x['puan'] as num?)?.toInt() ?? 0;
      return _filtre == 0 || (_filtre == 3 ? puan <= 3 : puan == _filtre);
    }).toList();
    final besYildiz = _yorumlar.where((x) => x['puan'] == 5).length;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _lacivert,
        title: const Text('Müşteri Değerlendirmeleri'),
        actions: [IconButton(onPressed: _yukleniyor ? null : _yukle,
          icon: const Icon(Icons.refresh))],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_hata!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: _yukle, child: const Text('Tekrar Dene')),
                  ]),
                ))
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_lacivert, _mavi]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Expanded(child: _istatistik('Ortalama Puan',
                              _adet == 0 ? '—' : _ortalama.toStringAsFixed(1), Icons.star_rounded)),
                          Expanded(child: _istatistik('Değerlendirme', '$_adet', Icons.reviews_rounded)),
                          Expanded(child: _istatistik('5 Yıldız', '$besYildiz', Icons.workspace_premium_outlined)),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      const Text('Müşteri Yorumları', style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800, color: _lacivert)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        _secenek('Tümü', 0), _secenek('5 yıldız', 5),
                        _secenek('4 yıldız', 4), _secenek('1–3 yıldız', 3),
                      ]),
                      const SizedBox(height: 12),
                      if (_adet == 0)
                        const Card(child: Padding(padding: EdgeInsets.all(24),
                          child: Center(child: Text('Henüz değerlendirme bulunmuyor.'))))
                      else if (filtreli.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(24),
                          child: Center(child: Text('Bu filtrede yorum bulunmuyor.'))))
                      else
                        ...filtreli.map((yorum) {
                          final puan = (yorum['puan'] as num?)?.toInt() ?? 0;
                          final ad = (yorum['musteriAdi'] ?? 'Müşteri').toString();
                          final metin = (yorum['yorum'] ?? '').toString().trim();
                          return Card(
                            color: Colors.white, elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(ad, style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: _lacivert))),
                                  Text(_tarih(yorum['olusturmaTarihi']),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ]),
                                const SizedBox(height: 8),
                                _yildizlar(puan),
                                if (metin.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(metin),
                                ],
                              ]),
                            ),
                          );
                        }),
                      if (_adet > _yorumlar.length) Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('Son ${_yorumlar.length} değerlendirme gösteriliyor '
                            '(toplam $_adet).',
                          style: const TextStyle(color: Colors.grey)),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _istatistik(String baslik, String deger, IconData ikon) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(ikon, color: const Color(0xFFFDE68A)),
        const SizedBox(height: 8),
        FittedBox(child: Text(deger, style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 23))),
        const SizedBox(height: 4),
        Text(baslik, textAlign: TextAlign.center, style: const TextStyle(
          color: Color(0xFFDCE8FF), fontSize: 11)),
      ]);

  Widget _secenek(String ad, int deger) => ChoiceChip(
    label: Text(ad), selected: _filtre == deger,
    onSelected: (_) => setState(() => _filtre = deger),
  );
}
