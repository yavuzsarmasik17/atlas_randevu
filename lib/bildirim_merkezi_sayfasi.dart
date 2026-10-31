import 'package:flutter/material.dart';
import 'bildirim_merkezi_api.dart';

class BildirimMerkeziSayfasi extends StatefulWidget {
  const BildirimMerkeziSayfasi({super.key});
  @override
  State<BildirimMerkeziSayfasi> createState() => _BildirimMerkeziSayfasiState();
}

class _BildirimMerkeziSayfasiState extends State<BildirimMerkeziSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  final List<Map<String, dynamic>> _kayitlar = [];
  bool _yukleniyor = false;
  bool _devamVar = true;
  int _sayfa = 1;
  int _okunmamis = 0;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yenile();
  }

  Future<void> _yenile() async {
    if (_yukleniyor) return;
    setState(() { _sayfa = 1; _devamVar = true; _kayitlar.clear(); });
    await _yukle();
  }

  Future<void> _yukle() async {
    if (_yukleniyor || !_devamVar) return;
    setState(() { _yukleniyor = true; _hata = null; });
    try {
      final sonuc = await BildirimMerkeziApi.listele(sayfa: _sayfa);
      final liste = (sonuc['kayitlar'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() {
        _kayitlar.addAll(liste);
        _okunmamis = (sonuc['okunmamis'] as num?)?.toInt() ?? 0;
        _devamVar = liste.length == 20;
        _sayfa++;
      });
    } catch (e) {
      if (mounted) setState(() => _hata = e.toString());
    } finally {
      if (mounted) setState(() => _yukleniyor = false);
    }
  }

  Future<void> _tumunuOku() async {
    try {
      await BildirimMerkeziApi.tumunuOkundu();
      if (!mounted) return;
      setState(() {
        _okunmamis = 0;
        for (final kayit in _kayitlar) { kayit['okunduMu'] = true; }
      });
    } catch (e) { _mesaj('$e'); }
  }

  void _mesaj(String mesaj) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  Future<void> _ac(Map<String, dynamic> kayit) async {
    final id = (kayit['id'] as num?)?.toInt();
    if (id == null) return;
    try {
      if (kayit['okunduMu'] != true) {
        await BildirimMerkeziApi.okundu(id);
        if (!mounted) return;
        setState(() {
          kayit['okunduMu'] = true;
          if (_okunmamis > 0) _okunmamis--;
        });
      }
      final randevuId = (kayit['randevuId'] as num?)?.toInt();
      if (randevuId != null && mounted) Navigator.pop(context, randevuId);
    } catch (e) { _mesaj('$e'); }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5FB),
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: lacivert,
      title: const Text('Bildirim Merkezi', style: TextStyle(fontWeight: FontWeight.w800)),
      actions: [
        if (_okunmamis > 0) TextButton(onPressed: _tumunuOku, child: const Text('Tümünü oku')),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _yenile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text('$_okunmamis okunmamış bildirim', style: const TextStyle(color: lacivert, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          if (_hata != null) Card(child: ListTile(
            leading: const Icon(Icons.error_outline, color: Colors.red),
            title: Text(_hata!),
            trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _yukle),
          )),
          if (_kayitlar.isEmpty && !_yukleniyor && _hata == null)
            const Card(child: ListTile(leading: Icon(Icons.notifications_none), title: Text('Henüz bildirim yok.'))),
          ..._kayitlar.map((kayit) {
            final okunmus = kayit['okunduMu'] == true;
            final tur = kayit['tur']?.toString().toLowerCase() ?? '';
            final icon = tur.contains('iptal') ? Icons.event_busy_outlined
                : tur.contains('ertel') ? Icons.update_outlined : Icons.event_available_outlined;
            final tarih = DateTime.tryParse(kayit['olusturmaTarihi']?.toString() ?? '');
            final tarihMetni = tarih == null ? '' : '${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year} ${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}';
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: okunmus ? Colors.white : const Color(0xFFEFF6FF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: okunmus ? const Color(0xFFE2E8F0) : mavi.withValues(alpha: 0.45))),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                leading: CircleAvatar(backgroundColor: const Color(0xFFDBEAFE), child: Icon(icon, color: mavi)),
                title: Text(kayit['baslik']?.toString() ?? 'Bildirim',
                  style: TextStyle(color: lacivert, fontWeight: okunmus ? FontWeight.w600 : FontWeight.w800)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 4),
                  Text(kayit['mesaj']?.toString() ?? ''),
                  const SizedBox(height: 6),
                  Text(tarihMetni, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ]),
                trailing: kayit['randevuId'] != null ? const Icon(Icons.chevron_right) :
                  (okunmus ? null : const Icon(Icons.circle, color: mavi, size: 9)),
                onTap: () => _ac(kayit),
              ),
            );
          }),
          if (_yukleniyor) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
          if (_devamVar && !_yukleniyor && _hata == null)
            TextButton(onPressed: _yukle, child: const Text('Daha fazla yükle')),
        ],
      ),
    ),
  );
}
