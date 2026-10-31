import 'package:flutter/material.dart';
import 'platform_admin_randevular_api.dart';

class PlatformAdminRandevularSayfasi extends StatefulWidget {
  const PlatformAdminRandevularSayfasi({super.key});
  @override
  State<PlatformAdminRandevularSayfasi> createState() =>
      _PlatformAdminRandevularSayfasiState();
}

class _PlatformAdminRandevularSayfasiState
    extends State<PlatformAdminRandevularSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);
  final _arama = TextEditingController();
  final _durumlar = ['Tumu', 'Onaylandi', 'IptalEdildi', 'Tamamlandi', 'Gelmedi'];
  String _durum = 'Tumu';
  DateTime? _tarih;
  int _sayfa = 1;
  int _toplam = 0;
  List<Map<String, dynamic>> _kayitlar = [];
  bool _yukleniyor = true;
  String? _hata;

  @override
  void initState() { super.initState(); _yukle(); }
  @override
  void dispose() { _arama.dispose(); super.dispose(); }

  Future<void> _yukle({bool ilkSayfa = false}) async {
    if (ilkSayfa) _sayfa = 1;
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final sonuc = await PlatformAdminRandevularApi.listele(
        arama: _arama.text, durum: _durum, tarih: _tarih, sayfa: _sayfa);
      if (!mounted) return;
      setState(() {
        _toplam = (sonuc['toplam'] as num?)?.toInt() ?? 0;
        _kayitlar = (sonuc['kayitlar'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    } catch (e) {
      if (mounted) setState(() => _hata = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  String _tarihSaat(dynamic deger) {
    final t = DateTime.tryParse('$deger');
    if (t == null) return 'Tarih belirtilmedi';
    String iki(int n) => n.toString().padLeft(2, '0');
    return '${iki(t.day)}.${iki(t.month)}.${t.year}  ${iki(t.hour)}:${iki(t.minute)}';
  }

  String _durumAdi(String d) => switch (d) {
    'Onaylandi' => 'Onaylandı',
    'IptalEdildi' => 'İptal edildi',
    'Tamamlandi' => 'Tamamlandı',
    'Gelmedi' => 'Gelmedi',
    _ => d,
  };

  Future<void> _tarihSec() async {
    final secilen = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _tarih ?? DateTime.now(),
    );
    if (secilen != null && mounted) {
      setState(() => _tarih = secilen);
      await _yukle(ilkSayfa: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sonSayfa = _toplam == 0 ? 1 : ((_toplam + 24) ~/ 25);
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Tüm Randevular'),
        actions: [IconButton(
          tooltip: 'Yenile', icon: const Icon(Icons.refresh),
          onPressed: _yukleniyor ? null : () => _yukle(),
        )],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(children: [
            TextField(
              controller: _arama,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _yukle(ilkSayfa: true),
              decoration: InputDecoration(
                hintText: 'Müşteri veya işletme ara',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _yukle(ilkSayfa: true),
                ),
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: DropdownButtonFormField<String>(
                value: _durum,
                decoration: const InputDecoration(
                  labelText: 'Durum', filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder()),
                items: _durumlar.map((d) => DropdownMenuItem(
                  value: d, child: Text(d == 'Tumu' ? 'Tümü' : _durumAdi(d)),
                )).toList(),
                onChanged: (d) {
                  if (d == null) return;
                  setState(() => _durum = d);
                  _yukle(ilkSayfa: true);
                },
              )),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Tarih seç',
                onPressed: _tarihSec,
                icon: const Icon(Icons.date_range),
              ),
              if (_tarih != null) IconButton(
                tooltip: 'Tarih filtresini kaldır',
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() => _tarih = null);
                  _yukle(ilkSayfa: true);
                },
              ),
            ]),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerLeft,
              child: Text('$_toplam randevu • Sayfa $_sayfa / $sonSayfa'
                '${_tarih == null ? '' : ' • ${_tarihSaat(_tarih).split('  ').first}'}',
                style: const TextStyle(color: lacivert, fontWeight: FontWeight.w600))),
          ]),
        ),
        Expanded(child: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
            ? Center(child: Padding(padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_hata!, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => _yukle(), child: const Text('Tekrar dene')),
                ])))
            : RefreshIndicator(
                onRefresh: () => _yukle(),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: _kayitlar.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _kayitlar.length) {
                      return Padding(padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          IconButton(
                            tooltip: 'Önceki sayfa',
                            onPressed: _sayfa > 1 ? () { _sayfa--; _yukle(); } : null,
                            icon: const Icon(Icons.chevron_left)),
                          Text('$_sayfa / $sonSayfa'),
                          IconButton(
                            tooltip: 'Sonraki sayfa',
                            onPressed: _sayfa < sonSayfa ? () { _sayfa++; _yukle(); } : null,
                            icon: const Icon(Icons.chevron_right)),
                        ]));
                    }
                    final r = _kayitlar[index];
                    final durum = '${r['durum'] ?? ''}';
                    return Card(
                      color: Colors.white, elevation: 0,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            const Icon(Icons.storefront, color: mavi),
                            const SizedBox(width: 8),
                            Expanded(child: Text('${r['isletme'] ?? 'İşletme'}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: lacivert))),
                            Text('#${r['id'] ?? ''}', style: const TextStyle(color: Colors.black54)),
                          ]),
                          const SizedBox(height: 10),
                          Text('Müşteri: ${r['musteriAd'] ?? 'Belirtilmedi'}'),
                          Text('Personel: ${r['personel'] ?? 'Belirtilmedi'}'),
                          Text('Tarih: ${_tarihSaat(r['baslangic'])}'),
                          Text('Tutar: ${r['toplamFiyat'] ?? 0} TL'),
                          const SizedBox(height: 8),
                          Align(alignment: Alignment.centerRight,
                            child: Chip(label: Text(_durumAdi(durum)))),
                        ])),
                    );
                  },
                ),
              )),
      ]),
    );
  }
}
