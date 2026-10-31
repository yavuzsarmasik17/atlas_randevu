import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'musteri_giris_sayfasi.dart';

class HesabimSayfasi extends StatefulWidget {
  const HesabimSayfasi({super.key});

  @override
  State<HesabimSayfasi> createState() => _HesabimSayfasiState();
}

class _HesabimSayfasiState extends State<HesabimSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);
  static const _storage = FlutterSecureStorage();
  static const _apiUrl = String.fromEnvironment('API_URL');
  final _formKey = GlobalKey<FormState>();
  final _ad = TextEditingController();
  final _soyad = TextEditingController();
  final _telefon = TextEditingController();
  String _email = '';
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  bool _cikisYapiliyor = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _profiliYukle();
  }

  @override
  void dispose() {
    _ad.dispose();
    _soyad.dispose();
    _telefon.dispose();
    super.dispose();
  }

  Uri get _profilUri => Uri.parse(
      '${_apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/profil');

  Future<String> _token() async {
    if (_apiUrl.isEmpty) throw Exception('API_URL tanımlı değil.');
    final token = await _storage.read(key: 'atlas_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Müşteri oturumu bulunamadı. Yeniden giriş yapın.');
    }
    return token;
  }

  String _hataMesaji(Object hata) =>
      hata.toString().replaceFirst('Exception: ', '');

  String _apiMesaji(http.Response cevap) {
    try {
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is Map && veri['mesaj'] != null) {
        return veri['mesaj'].toString();
      }
      if (veri is Map && veri['errors'] is Map) {
        final errors = veri['errors'] as Map;
        final mesajlar = errors.values.expand((v) => v is List ? v : [v]);
        return mesajlar.join('\n');
      }
    } catch (_) {}
    return 'İşlem başarısız (HTTP ${cevap.statusCode}).';
  }

  Future<void> _profiliYukle() async {
    if (!mounted) return;
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final token = await _token();
      final cevap = await http.get(
        _profilUri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception(_apiMesaji(cevap));
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map<String, dynamic>) {
        throw Exception('Profil verisi geçersiz.');
      }
      if (!mounted) return;
      setState(() {
        _ad.text = (veri['ad'] ?? '').toString();
        _soyad.text = (veri['soyad'] ?? '').toString();
        _telefon.text = (veri['telefon'] ?? '').toString();
        _email = (veri['email'] ?? '').toString();
      });
    } catch (e) {
      if (mounted) setState(() => _hata = _hataMesaji(e));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor || !_formKey.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);
    try {
      final token = await _token();
      final cevap = await http.put(
        _profilUri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ad': _ad.text.trim(),
          'soyad': _soyad.text.trim(),
          'telefon': _telefon.text.trim(),
        }),
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception(_apiMesaji(cevap));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil başarıyla güncellendi.')),
      );
      await _profiliYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_hataMesaji(e))),
      );
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  Future<void> _cikisYap() async {
    if (_cikisYapiliyor) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Müşteri hesabınızdan çıkış yapmak istiyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çıkış Yap')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    setState(() => _cikisYapiliyor = true);
    try {
      // İşletme oturumu anahtarları silinmez.
      await _storage.delete(key: 'atlas_access_token');
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MusteriGirisSayfasi()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Çıkış yapılamadı: ${_hataMesaji(e)}')),
      );
      setState(() => _cikisYapiliyor = false);
    }
  }

  InputDecoration _alanStili(String baslik, IconData ikon) => InputDecoration(
        labelText: baslik,
        prefixIcon: Icon(ikon, color: mavi),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
                      const SizedBox(height: 12),
                      Text(_hata!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _profiliYukle, child: const Text('Tekrar Dene')),
                      TextButton(onPressed: _cikisYap, child: const Text('Çıkış Yap')),
                    ]),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _profiliYukle,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [lacivert, mavi]),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(children: [
                          const CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person_outline, color: Colors.white, size: 42),
                          ),
                          const SizedBox(height: 12),
                          Text('${_ad.text} ${_soyad.text}'.trim(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(_email, style: const TextStyle(color: Color(0xFFDBEAFE))),
                        ]),
                      ),
                      const SizedBox(height: 20),
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Form(
                            key: _formKey,
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('Kişisel Bilgilerim',
                                  style: TextStyle(fontSize: 19, color: lacivert, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: _ad,
                                textCapitalization: TextCapitalization.words,
                                decoration: _alanStili('Ad', Icons.person_outline),
                                validator: (v) => (v ?? '').trim().length < 2 ? 'Ad en az 2 karakter olmalı.' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _soyad,
                                textCapitalization: TextCapitalization.words,
                                decoration: _alanStili('Soyad', Icons.badge_outlined),
                                validator: (v) => (v ?? '').trim().length < 2 ? 'Soyad en az 2 karakter olmalı.' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _telefon,
                                keyboardType: TextInputType.phone,
                                decoration: _alanStili('Telefon', Icons.phone_outlined),
                                validator: (v) => (v ?? '').trim().isEmpty ? 'Telefon zorunludur.' : null,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                initialValue: _email,
                                readOnly: true,
                                decoration: _alanStili('E-posta (değiştirilemez)', Icons.email_outlined),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _kaydediliyor ? null : _kaydet,
                                  icon: _kaydediliyor
                                      ? const SizedBox(width: 18, height: 18,
                                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Icon(Icons.save_outlined),
                                  label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Bilgilerimi Kaydet'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: mavi,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                  ),
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _cikisYapiliyor ? null : _cikisYap,
                        icon: const Icon(Icons.logout),
                        label: const Text('Güvenli Çıkış Yap'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
    );
  }
}
