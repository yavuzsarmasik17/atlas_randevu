import 'package:flutter/material.dart';
import 'isletme_bilgileri_api.dart';

class IsletmeBilgileriSayfasi extends StatefulWidget {
  final Map<String, String> bilgiler;
  const IsletmeBilgileriSayfasi({super.key, required this.bilgiler});

  @override
  State<IsletmeBilgileriSayfasi> createState() => _IsletmeBilgileriSayfasiState();
}

class _IsletmeBilgileriSayfasiState extends State<IsletmeBilgileriSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  final _form = GlobalKey<FormState>();
  final Map<String, TextEditingController> _alanlar = {};
  bool _yukleniyor = true;
  bool _kaydediliyor = false;
  String? _hata;
  static const _etiketler = {
    'ad': 'İşletme Adı',
    'telefon': 'Telefon',
    'adres': 'Adres',
    'aciklama': 'Hakkımızda / Açıklama',
    'instagram': 'Instagram Kullanıcı Adı',
  };

  @override
  void initState() {
    super.initState();
    for (final key in _etiketler.keys) {
      _alanlar[key] = TextEditingController(text: widget.bilgiler[key] ?? '');
    }
    _bilgileriYukle();
  }

  Future<void> _bilgileriYukle() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final veri = await IsletmeBilgileriApi.getir();
      if (!mounted) return;
      setState(() {
        for (final key in _etiketler.keys) {
          _alanlar[key]!.text = veri[key]?.toString() ?? '';
          widget.bilgiler[key] = _alanlar[key]!.text;
        }
      });
    } catch (e) {
      if (mounted) setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _kaydet() async {
    if (_kaydediliyor || !_form.currentState!.validate()) return;
    setState(() => _kaydediliyor = true);
    try {
      final yeni = {for (final e in _alanlar.entries) e.key: e.value.text.trim()};
      final kayit = await IsletmeBilgileriApi.guncelle(yeni);
      if (!mounted) return;
      for (final key in _etiketler.keys) {
        widget.bilgiler[key] = kayit[key]?.toString() ?? '';
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('İşletme bilgileri kaydedildi.')));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => _kaydediliyor = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _alanlar.values) { controller.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5FB),
    appBar: AppBar(title: const Text('İşletme Bilgileri'),
      backgroundColor: Colors.white, foregroundColor: lacivert),
    body: _yukleniyor
      ? const Center(child: CircularProgressIndicator())
      : _hata != null
        ? Center(child: Padding(padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 12),
              Text('Bilgiler yüklenemedi:\n$_hata', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(onPressed: _bilgileriYukle,
                icon: const Icon(Icons.refresh), label: const Text('Tekrar Dene')),
            ])))
        : Form(key: _form, child: ListView(
            padding: const EdgeInsets.all(18), children: [
              Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [lacivert, mavi]),
                  borderRadius: BorderRadius.circular(22)),
                child: const Row(children: [
                  CircleAvatar(radius: 26, backgroundColor: Color(0xFF35599A),
                    child: Icon(Icons.storefront_rounded, color: Colors.white, size: 28)),
                  SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('İşletme Profiliniz', style: TextStyle(color: Colors.white,
                        fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 4),
                      Text('Müşterilerin gördüğü bilgileri düzenleyin.',
                        style: TextStyle(color: Color(0xFFD8E6FF))),
                    ])),
                ])),
              const SizedBox(height: 20),
              Container(padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
                child: Column(children: [
                  for (final e in _etiketler.entries)
                    Padding(padding: const EdgeInsets.only(bottom: 16),
                      child: TextFormField(
                        controller: _alanlar[e.key],
                        maxLines: e.key == 'adres' || e.key == 'aciklama' ? 3 : 1,
                        maxLength: switch (e.key) {
                          'ad' => 150, 'telefon' => 30, 'adres' => 500,
                          'aciklama' => 2000, _ => 150,
                        },
                        keyboardType: e.key == 'telefon' ? TextInputType.phone
                          : TextInputType.text,
                        decoration: InputDecoration(labelText: e.value,
                          prefixIcon: Icon(switch (e.key) {
                            'ad' => Icons.store_outlined,
                            'telefon' => Icons.phone_outlined,
                            'adres' => Icons.location_on_outlined,
                            'aciklama' => Icons.info_outline,
                            _ => Icons.alternate_email,
                          }, color: mavi),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                        validator: (v) => ['ad', 'telefon', 'adres'].contains(e.key)
                          && (v == null || v.trim().isEmpty)
                            ? '${e.value} boş olamaz.' : null,
                      )),
                ])),
              const SizedBox(height: 20),
              SizedBox(height: 54, child: FilledButton.icon(
                onPressed: _kaydediliyor ? null : _kaydet,
                style: FilledButton.styleFrom(backgroundColor: mavi,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                icon: _kaydediliyor
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
                label: Text(_kaydediliyor ? 'Kaydediliyor...' : 'Bilgileri Kaydet'),
              )),
              const SizedBox(height: 18),
            ])),
  );
}
