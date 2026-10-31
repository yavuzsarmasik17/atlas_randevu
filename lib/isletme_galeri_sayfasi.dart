import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'isletme_fotograf_api.dart';

class IsletmeGaleriSayfasi extends StatefulWidget {
  const IsletmeGaleriSayfasi({super.key});
  @override
  State<IsletmeGaleriSayfasi> createState() => _IsletmeGaleriSayfasiState();
}

class _IsletmeGaleriSayfasiState extends State<IsletmeGaleriSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  final _picker = ImagePicker();
  Map<String, dynamic> _veri = {};
  bool _yukleniyor = true;
  bool _islemde = false;
  String? _hata;

  @override
  void initState() { super.initState(); _yenile(); }

  Future<void> _yenile() async {
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final sonuc = await IsletmeFotografApi.listele();
      if (mounted) setState(() => _veri = sonuc);
    } catch (e) {
      if (mounted) setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  void _mesaj(String mesaj) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _secVeYukle(String tur) async {
    if (_islemde) return;
    final dosya = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 82, maxWidth: 1800);
    if (dosya == null || !mounted) return;
    setState(() => _islemde = true);
    try {
      await IsletmeFotografApi.yukle(tur, dosya);
      _mesaj('Fotoğraf başarıyla yüklendi.');
      await _yenile();
    } catch (e) { _mesaj('Yükleme başarısız: $e'); }
    finally { if (mounted) setState(() => _islemde = false); }
  }

  Future<void> _sil(int id) async {
    if (_islemde) return;
    final onay = await showDialog<bool>(context: context, builder: (c) => AlertDialog(
      title: const Text('Fotoğrafı sil'),
      content: const Text('Bu galeri fotoğrafı silinsin mi?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Sil')),
      ],
    ));
    if (onay != true || !mounted) return;
    setState(() => _islemde = true);
    try { await IsletmeFotografApi.sil(id); await _yenile(); _mesaj('Fotoğraf silindi.'); }
    catch (e) { _mesaj('Silinemedi: $e'); }
    finally { if (mounted) setState(() => _islemde = false); }
  }

  Widget _gorsel(String? yol, {double yukseklik = 160}) {
    final url = IsletmeFotografApi.resimUrl(yol);
    if (url.isEmpty) return Container(height: yukseklik, color: const Color(0xFFEFF4FF),
      child: const Center(child: Icon(Icons.add_photo_alternate_outlined, size: 42, color: mavi)));
    return Image.network(url, height: yukseklik, width: double.infinity, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => SizedBox(height: yukseklik,
        child: const Center(child: Text('Görsel yüklenemedi'))));
  }

  Widget _bolum(String baslik, String? url, String tur) => Card(
    color: Colors.white,
    clipBehavior: Clip.antiAlias,
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(padding: const EdgeInsets.all(14), child: Text(baslik,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: lacivert))),
      _gorsel(url),
      Padding(padding: const EdgeInsets.all(12), child: OutlinedButton.icon(
        onPressed: _islemde ? null : () => _secVeYukle(tur),
        icon: const Icon(Icons.upload_rounded), label: Text('$baslik Seç / Değiştir'))),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    final galeri = (_veri['fotograflar'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(title: const Text('İşletme Görselleri'), backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _islemde ? null : _yenile, icon: const Icon(Icons.refresh))]),
      body: _yukleniyor ? const Center(child: CircularProgressIndicator())
        : _hata != null ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_hata!, textAlign: TextAlign.center),
            TextButton(onPressed: _yenile, child: const Text('Tekrar Dene'))]))
        : ListView(padding: const EdgeInsets.all(16), children: [
            if (_islemde) const LinearProgressIndicator(),
            _bolum('İşletme Logosu', _veri['logoUrl']?.toString(), 'logo'),
            const SizedBox(height: 12),
            _bolum('Kapak Fotoğrafı', _veri['kapakFotoUrl']?.toString(), 'kapak'),
            const SizedBox(height: 22),
            Row(children: [
              const Expanded(child: Text('Fotoğraf Galerisi', style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: lacivert))),
              Text('${galeri.length}/20'),
            ]),
            const SizedBox(height: 10),
            FilledButton.icon(onPressed: _islemde || galeri.length >= 20 ? null : () => _secVeYukle('galeri'),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Galeriye Fotoğraf Ekle')),
            const SizedBox(height: 12),
            if (galeri.isEmpty) const Padding(padding: EdgeInsets.all(24),
              child: Center(child: Text('Henüz galeri fotoğrafı yok.'))),
            ...galeri.whereType<Map>().map((f) => Card(
              color: Colors.white, clipBehavior: Clip.antiAlias,
              child: Column(children: [
                _gorsel(f['fotografUrl']?.toString(), yukseklik: 190),
                Align(alignment: Alignment.centerRight, child: TextButton.icon(
                  onPressed: _islemde ? null : () => _sil((f['id'] as num).toInt()),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Sil', style: TextStyle(color: Colors.red)))),
              ]),
            )),
          ]),
    );
  }
}
