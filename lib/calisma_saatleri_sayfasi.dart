import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class CalismaSaatleriSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> personeller;
  const CalismaSaatleriSayfasi({super.key, required this.personeller});

  @override
  State<CalismaSaatleriSayfasi> createState() => _CalismaSaatleriSayfasiState();
}

class _CalismaSaatleriSayfasiState extends State<CalismaSaatleriSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  static const gunler = ['Pazartesi','Salı','Çarşamba','Perşembe','Cuma','Cumartesi','Pazar'];
  static const _depo = FlutterSecureStorage();
  static const _base = String.fromEnvironment('API_URL');

  Map<String, dynamic>? seciliPersonel;
  List<Map<String, dynamic>> program = [];
  List<Map<String, dynamic>> izinler = [];
  bool yukleniyor = false;
  bool kaydediliyor = false;
  String? hata;

  @override
  void initState() {
    super.initState();
    if (widget.personeller.isNotEmpty) {
      seciliPersonel = widget.personeller.first;
      _yukle();
    }
  }

  int get personelId => (seciliPersonel!['id'] as num).toInt();
  String get _adres => '${_base.replaceAll(RegExp(r'/+$'), '')}/api/isletme/personeller/$personelId/calisma';

  Future<dynamic> _istek(String method, String yol, [Object? veri]) async {
    if (_base.isEmpty) throw Exception('API_URL tanımlanmamış.');
    final token = await _depo.read(key: 'atlas_isletme_access_token');
    if (token == null || token.isEmpty) {
      throw Exception('Oturum bulunamadı. İşletme hesabınızla giriş yapın.');
    }
    final uri = Uri.parse('$_adres$yol');
    final headers = {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
    final body = veri == null ? null : jsonEncode(veri);
    late http.Response cevap;
    switch (method) {
      case 'GET': cevap = await http.get(uri, headers: headers).timeout(const Duration(seconds: 20)); break;
      case 'PUT': cevap = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 20)); break;
      case 'POST': cevap = await http.post(uri, headers: headers, body: body).timeout(const Duration(seconds: 20)); break;
      case 'DELETE': cevap = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 20)); break;
      default: throw Exception('Geçersiz istek.');
    }
    dynamic json;
    try { json = jsonDecode(utf8.decode(cevap.bodyBytes)); } catch (_) {}
    if (cevap.statusCode >= 200 && cevap.statusCode < 300) return json;
    if (cevap.statusCode == 401) throw Exception('Oturum süresi dolmuş. Tekrar giriş yapın.');
    if (cevap.statusCode == 403) throw Exception('İşletme sahibi yetkisi gerekli.');
    throw Exception(json is Map && json['mesaj'] != null ? json['mesaj'] : 'HTTP ${cevap.statusCode}');
  }

  List<Map<String, dynamic>> _varsayilanProgram() => List.generate(7, (i) => {
    'gun': (i + 1) % 7,
    'calisiyorMu': i < 6,
    'baslangicSaati': '09:00',
    'bitisSaati': '19:00',
  });

  Future<void> _yukle() async {
    if (seciliPersonel == null) return;
    setState(() { yukleniyor = true; hata = null; program = []; izinler = []; });
    try {
      final sonuc = Map<String, dynamic>.from(await _istek('GET', '') as Map);
      final gunKayitlari = (sonuc['gunler'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final yeniProgram = _varsayilanProgram();
      for (final kayit in gunKayitlari) {
        final i = ((kayit['gun'] as num).toInt() + 6) % 7;
        yeniProgram[i] = kayit;
      }
      final yeniIzinler = (sonuc['izinler'] as List? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() { program = yeniProgram; izinler = yeniIzinler; });
    } catch (e) {
      if (mounted) setState(() => hata = e.toString());
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  void bildir(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  TimeOfDay _saatOku(String s) {
    final p = s.split(':');
    return TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
  }

  String _saatYaz(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  int _dakika(TimeOfDay t) => t.hour * 60 + t.minute;
  String _tarihYaz(DateTime d) => '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  Future<void> _saatSec(int index, bool baslangic) async {
    final gun = program[index];
    final alan = baslangic ? 'baslangicSaati' : 'bitisSaati';
    final secim = await showTimePicker(context: context, initialTime: _saatOku(gun[alan] as String));
    if (secim == null || !mounted) return;
    final bas = baslangic ? secim : _saatOku(gun['baslangicSaati'] as String);
    final bit = baslangic ? _saatOku(gun['bitisSaati'] as String) : secim;
    if (_dakika(bas) >= _dakika(bit)) {
      bildir('Bitiş saati başlangıç saatinden sonra olmalı.');
      return;
    }
    setState(() => gun[alan] = _saatYaz(secim));
  }

  Future<void> _kaydet() async {
    setState(() => kaydediliyor = true);
    try {
      await _istek('PUT', '/gunler', program);
      bildir('Çalışma saatleri veritabanına kaydedildi.');
      await _yukle();
    } catch (e) {
      bildir('Kaydedilemedi: $e');
    } finally {
      if (mounted) setState(() => kaydediliyor = false);
    }
  }

  Future<void> _izinEkle() async {
    final simdi = DateTime.now();
    final aralik = await showDateRangePicker(
      context: context, firstDate: DateTime(simdi.year, simdi.month, simdi.day),
      lastDate: DateTime(simdi.year + 3), initialDateRange: DateTimeRange(start: simdi, end: simdi),
      helpText: 'Personel izin tarihleri', saveText: 'Kaydet',
    );
    if (aralik == null || !mounted) return;
    try {
      String iso(DateTime d) => '${d.year.toString().padLeft(4,'0')}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}T00:00:00';
      await _istek('POST', '/izinler', {
        'baslangic': iso(aralik.start), 'bitis': iso(aralik.end), 'aciklama': 'İzinli',
      });
      bildir('İzin kaydedildi.');
      await _yukle();
    } catch (e) { bildir('İzin eklenemedi: $e'); }
  }

  Future<void> _izinSil(int id) async {
    try {
      await _istek('DELETE', '/izinler/$id');
      bildir('İzin silindi.');
      await _yukle();
    } catch (e) { bildir('İzin silinemedi: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      appBar: AppBar(backgroundColor: Colors.white, foregroundColor: lacivert,
        title: const Text('Çalışma Saatleri ve İzinler')),
      body: widget.personeller.isEmpty
          ? const Center(child: Text('Önce işletme panelinden personel ekleyin.'))
          : ListView(padding: const EdgeInsets.all(16), children: [
              const Text('Personel Seçin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lacivert)),
              const SizedBox(height: 8),
              DropdownButtonFormField<Map<String, dynamic>>(
                value: seciliPersonel, isExpanded: true,
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                items: widget.personeller.map((p) => DropdownMenuItem(
                  value: p, child: Text('${p['ad']} (${p['unvan']})'),
                )).toList(),
                onChanged: (p) {
                  if (p == null) return;
                  setState(() => seciliPersonel = p);
                  _yukle();
                },
              ),
              const SizedBox(height: 20),
              if (yukleniyor) const Center(child: CircularProgressIndicator()),
              if (hata != null) ListTile(
                title: Text('Veriler yüklenemedi: $hata'),
                trailing: IconButton(onPressed: _yukle, icon: const Icon(Icons.refresh)),
              ),
              if (!yukleniyor && hata == null) ...[
                const Text('Haftalık Çalışma Programı',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: lacivert)),
                const SizedBox(height: 6),
                const Text('Günleri ve saatleri ayarladıktan sonra Kaydet düğmesine basın.',
                  style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                ...List.generate(7, (i) {
                  final gun = program[i];
                  final acik = gun['calisiyorMu'] == true;
                  return Card(color: Colors.white, margin: const EdgeInsets.only(bottom: 9),
                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Column(children: [
                        Row(children: [
                          Expanded(child: Text(gunler[i], style: const TextStyle(fontWeight: FontWeight.w600))),
                          Text(acik ? 'Açık' : 'Kapalı',
                            style: TextStyle(color: acik ? Colors.green : Colors.grey)),
                          Switch(value: acik, activeColor: mavi,
                            onChanged: (v) => setState(() => gun['calisiyorMu'] = v)),
                        ]),
                        if (acik) Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _saatSec(i, true),
                            icon: const Icon(Icons.login, size: 18),
                            label: Text(gun['baslangicSaati'] as String),
                          )),
                          const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('–')),
                          Expanded(child: OutlinedButton.icon(
                            onPressed: () => _saatSec(i, false),
                            icon: const Icon(Icons.logout, size: 18),
                            label: Text(gun['bitisSaati'] as String),
                          )),
                        ]),
                      ]),
                    ),
                  );
                }),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: kaydediliyor ? null : _kaydet,
                  style: FilledButton.styleFrom(backgroundColor: mavi),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(kaydediliyor ? 'Kaydediliyor...' : 'Haftalık Programı Kaydet'),
                ),
                const SizedBox(height: 22),
                Row(children: [
                  const Expanded(child: Text('Personel İzinleri',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: lacivert))),
                  FilledButton.icon(
                    onPressed: _izinEkle,
                    style: FilledButton.styleFrom(backgroundColor: mavi),
                    icon: const Icon(Icons.add), label: const Text('İzin Ekle'),
                  ),
                ]),
                const SizedBox(height: 10),
                if (izinler.isEmpty) const Card(color: Colors.white,
                  child: Padding(padding: EdgeInsets.all(20), child: Text('Henüz izin kaydı yok.'))),
                ...izinler.map((izin) {
                  final bas = DateTime.parse(izin['baslangic'] as String);
                  final bit = DateTime.parse(izin['bitis'] as String);
                  return Card(color: Colors.white, child: ListTile(
                    leading: const Icon(Icons.event_busy, color: mavi),
                    title: Text('${_tarihYaz(bas)} – ${_tarihYaz(bit)}'),
                    subtitle: const Text('İzinli'),
                    trailing: IconButton(
                      tooltip: 'İzni sil',
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _izinSil((izin['id'] as num).toInt()),
                    ),
                  ));
                }),
              ],
              const SizedBox(height: 30),
            ]),
    );
  }
}
