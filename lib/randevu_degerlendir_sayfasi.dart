import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class RandevuDegerlendirSayfasi extends StatefulWidget {
  final int randevuId;
  final String isletmeAdi;

  const RandevuDegerlendirSayfasi({
    super.key,
    required this.randevuId,
    required this.isletmeAdi,
  });

  @override
  State<RandevuDegerlendirSayfasi> createState() =>
      _RandevuDegerlendirSayfasiState();
}

class _RandevuDegerlendirSayfasiState
    extends State<RandevuDegerlendirSayfasi> {
  static const _lacivert = Color(0xFF142D5C);
  static const _mavi = Color(0xFF2563EB);
  static const _apiUrl = String.fromEnvironment('API_URL');
  static const _storage = FlutterSecureStorage();

  final _yorumController = TextEditingController();
  int _puan = 5;
  bool _kontrolEdiliyor = true;
  bool _kaydediliyor = false;
  bool _degerlendirilebilir = false;
  bool _degerlendirildi = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _durumKontrolEt();
  }

  @override
  void dispose() {
    _yorumController.dispose();
    super.dispose();
  }

  Uri _adres(String yol) {
    if (_apiUrl.trim().isEmpty) {
      throw Exception('API_URL tanımlı değil.');
    }
    return Uri.parse('${_apiUrl.replaceAll(RegExp(r'/+$'), '')}$yol');
  }

  Future<String> _tokenGetir() async {
    final token = await _storage.read(key: 'atlas_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }
    return token;
  }

  String _hataMesaji(http.Response cevap, String varsayilan) {
    try {
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is Map && veri['mesaj'] != null) {
        return veri['mesaj'].toString();
      }
    } catch (_) {}
    if (cevap.statusCode == 401 || cevap.statusCode == 403) {
      return 'Oturum süresi dolmuş veya yetkiniz yok. Tekrar giriş yapın.';
    }
    return '$varsayilan (HTTP ${cevap.statusCode}).';
  }

  Future<void> _durumKontrolEt() async {
    setState(() {
      _kontrolEdiliyor = true;
      _hata = null;
    });
    try {
      final token = await _tokenGetir();
      final cevap = await http.get(
        _adres('/api/musteri/degerlendirmeler/durum/${widget.randevuId}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));

      if (cevap.statusCode != 200) {
        throw Exception(_hataMesaji(cevap, 'Değerlendirme durumu alınamadı'));
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map) {
        throw const FormatException('Sunucudan geçersiz yanıt alındı.');
      }
      if (!mounted) return;
      setState(() {
        _degerlendirilebilir = veri['degerlendirilebilir'] == true;
        _degerlendirildi = veri['degerlendirildi'] == true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hata = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _kontrolEdiliyor = false);
    }
  }

  
Future<void> _kaydet() async {
  if (_kaydediliyor ||
      _kontrolEdiliyor ||
      !_degerlendirilebilir ||
      _degerlendirildi) {
    return;
  }

  // Klavyeyi kapat.
  FocusManager.instance.primaryFocus?.unfocus();

  setState(() => _kaydediliyor = true);

  try {
    final token = await _tokenGetir();

    final cevap = await http.post(
      _adres('/api/musteri/degerlendirmeler'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'randevuId': widget.randevuId,
        'puan': _puan,
        'yorum': _yorumController.text.trim(),
      }),
    ).timeout(const Duration(seconds: 20));

    if (cevap.statusCode != 200) {
      if (cevap.statusCode == 409 && mounted) {
        setState(() => _degerlendirildi = true);
      }

      throw Exception(
        _hataMesaji(
          cevap,
          'Değerlendirme kaydedilemedi',
        ),
      );
    }

    if (!mounted) return;

    // Başarılı sonucu önceki ekrana ilet.
    // SnackBar önceki ekranda gösterilecek.
    Navigator.of(context).pop(true);
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.toString().replaceFirst('Exception: ', ''),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _kaydediliyor = false);
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final kullanilabilir = _degerlendirilebilir && !_degerlendirildi;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Randevunu Değerlendir'),
        backgroundColor: Colors.white,
        foregroundColor: _lacivert,
      ),
      body: _kontrolEdiliyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_hata!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: _durumKontrolEt,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : !kullanilabilir
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _degerlendirildi
                                  ? Icons.check_circle_outline
                                  : Icons.info_outline,
                              size: 58,
                              color: _mavi,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _degerlendirildi
                                  ? 'Bu randevuyu zaten değerlendirdiniz.'
                                  : 'Yalnızca tamamlanmış randevular değerlendirilebilir.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_lacivert, _mavi],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.storefront,
                                  color: Colors.white, size: 32),
                              const SizedBox(height: 12),
                              Text(
                                widget.isletmeAdi,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Aldığınız hizmeti değerlendirin.',
                                style: TextStyle(color: Color(0xFFE2E8F0)),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        const Text(
                          'Kaç yıldız verirsiniz?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _lacivert,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final yildiz = index + 1;
                            return IconButton(
                              tooltip: '$yildiz yıldız',
                              onPressed: _kaydediliyor
                                  ? null
                                  : () => setState(() => _puan = yildiz),
                              icon: Icon(
                                yildiz <= _puan
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded,
                                size: 38,
                                color: const Color(0xFFF59E0B),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          controller: _yorumController,
                          enabled: !_kaydediliyor,
                          maxLines: 5,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText: 'Yorumunuz (isteğe bağlı)',
                            hintText: 'Hizmet hakkındaki düşünceleriniz...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _kaydediliyor ? null : _kaydet,
                          icon: _kaydediliyor
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(_kaydediliyor
                              ? 'Kaydediliyor...'
                              : 'Değerlendirmeyi Gönder'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _mavi,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ],
                    ),
    );
  }
}
