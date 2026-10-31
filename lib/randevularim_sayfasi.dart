import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'isletme_detay_sayfasi.dart';

class RandevularimSayfasi extends StatefulWidget {
  const RandevularimSayfasi({super.key});

  @override
  State<RandevularimSayfasi> createState() => _RandevularimSayfasiState();
}

class _RandevularimSayfasiState extends State<RandevularimSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);
  static const _storage = FlutterSecureStorage();
  static const _apiUrl = String.fromEnvironment('API_URL');

  int seciliSekme = 0;
  bool yukleniyor = true;
  String? hata;
  List<Map<String, dynamic>> randevular = [];
  final Set<int> islemdekiRandevular = <int>{};
  final Map<int, bool> degerlendirmeDurumlari = <int, bool>{};
  final Set<int> degerlendirmeKontrolEdilenler = <int>{};
  final Set<int> degerlendirmeHatalari = <int>{};

  @override
  void initState() {
    super.initState();
    randevulariYukle();
  }

  Future<void> randevulariYukle() async {
    if (!mounted) return;
    setState(() {
      yukleniyor = true;
      hata = null;
    });
    try {
      final token = await _storage.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Müşteri oturumu bulunamadı. Yeniden giriş yapın.');
      }
      if (_apiUrl.isEmpty) {
        throw Exception('API_URL tanımlı değil.');
      }
      final uri = Uri.parse(
        '${_apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/randevular',
      );
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Oturum süresi dolmuş veya yetkiniz yok. Tekrar giriş yapın.');
      }
      if (response.statusCode != 200) {
        throw Exception('Randevular yüklenemedi (HTTP ${response.statusCode}).');
      }
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! List) {
        throw const FormatException('API randevu listesi döndürmedi.');
      }
      final kayitlar = decoded.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Randevu verisi geçersiz.');
        }
        return item;
      }).toList();
      if (!mounted) return;
      setState(() {
        randevular = kayitlar;
        degerlendirmeDurumlari.clear();
        degerlendirmeKontrolEdilenler.clear();
        degerlendirmeHatalari.clear();
      });
      for (final randevu in kayitlar) {
        if ((randevu['durum'] ?? '').toString().toLowerCase() == 'tamamlandi' &&
            randevu['id'] is int) {
          degerlendirmeDurumuGetir(randevu['id'] as int);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => hata = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  DateTime? tarih(Map<String, dynamic> r) =>
      DateTime.tryParse((r['baslangic'] ?? '').toString());

  String tarihYaz(DateTime? t) => t == null
      ? 'Tarih bilinmiyor'
      : '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';

  String saatYaz(DateTime? t) => t == null
      ? '--:--'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String durum(Map<String, dynamic> r) {
    switch ((r['durum'] ?? '').toString().toLowerCase()) {
      case 'onaylandi': return 'Onaylandı';
      case 'iptaledildi': return 'İptal Edildi';
      case 'tamamlandi': return 'Tamamlandı';
      case 'gelmedi': return 'Gelmedi';
      default: return (r['durum'] ?? 'Bilinmiyor').toString();
    }
  }

  bool yaklasanMi(Map<String, dynamic> r) {
    final t = tarih(r);
    return (r['durum'] ?? '').toString().toLowerCase() == 'onaylandi' &&
        t != null && t.isAfter(DateTime.now());
  }

  String fiyat(Map<String, dynamic> r) {
    final n = num.tryParse((r['toplamFiyat'] ?? 0).toString()) ?? 0;
    return '${n.toStringAsFixed(2).replaceAll('.', ',')} ₺';
  }

  Color durumRengi(Map<String, dynamic> r) {
    switch ((r['durum'] ?? '').toString().toLowerCase()) {
      case 'onaylandi': return const Color(0xFF047857);
      case 'tamamlandi': return const Color(0xFF2563EB);
      case 'iptaledildi': return const Color(0xFFDC2626);
      case 'gelmedi': return const Color(0xFFB45309);
      default: return const Color(0xFF64748B);
    }
  }

  String alan(Map<String, dynamic> r, String key) =>
      (r[key] ?? 'Belirtilmedi').toString();

  Widget detaySatiri(String baslik, String deger) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 95, child: Text(baslik, style: const TextStyle(color: Color(0xFF64748B)))),
            Expanded(child: Text(deger, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  void detayGoster(Map<String, dynamic> r) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Randevu Detayları', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: lacivert)),
              const SizedBox(height: 20),
              detaySatiri('İşletme', alan(r, 'isletme')),
              detaySatiri('Hizmet', alan(r, 'hizmet')),
              detaySatiri('Personel', alan(r, 'personel')),
              detaySatiri('Tarih', tarihYaz(tarih(r))),
              detaySatiri('Saat', saatYaz(tarih(r))),
              detaySatiri('Tutar', fiyat(r)),
              detaySatiri('Durum', durum(r)),
            ],
          ),
        ),
      ),
    );
  }


  bool islemYapilabilir(Map<String, dynamic> r) {
    final t = tarih(r);
    return t != null &&
        (r['durum'] ?? '').toString().toLowerCase() == 'onaylandi' &&
        t.isAfter(DateTime.now().add(const Duration(hours: 1)));
  }

  String? apiMesaji(http.Response response) {
    try {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['mesaj'] != null) return data['mesaj'].toString();
    } catch (_) {}
    return null;
  }

  Future<void> iptalEt(Map<String, dynamic> r) async {
    final id = r['id'];
    if (id is! int || islemdekiRandevular.contains(id) || !islemYapilabilir(r)) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevu iptali'),
        content: const Text('Bu randevuyu iptal etmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('İptal Et')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      final token = await _storage.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Lütfen giriş yapın.');
      final response = await http.put(
        Uri.parse('$_apiUrl/api/musteri/randevular/$id/iptal'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(apiMesaji(response) ?? 'İptal başarısız (HTTP ${response.statusCode}).');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu iptal edildi.')));
      await randevulariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  Future<void> ertele(Map<String, dynamic> r) async {
    final id = r['id'];
    final mevcut = tarih(r);
    if (id is! int || islemdekiRandevular.contains(id) || mevcut == null || !islemYapilabilir(r)) return;
    final gun = await showDatePicker(
      context: context,
      initialDate: mevcut.isAfter(DateTime.now()) ? mevcut : DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 183)),
      helpText: 'Yeni randevu tarihi',
    );
    if (gun == null || !mounted) return;
    final saat = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(mevcut),
      helpText: 'Yeni randevu saati',
    );
    if (saat == null || !mounted) return;
    final yeni = DateTime(gun.year, gun.month, gun.day, saat.hour, saat.minute);
    if (!yeni.isAfter(DateTime.now().add(const Duration(hours: 1)))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yeni saat en az 1 saat sonrası olmalı.')));
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevu erteleme'),
        content: Text('Randevu ${tarihYaz(yeni)} ${saatYaz(yeni)} saatine taşınsın mı?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Onayla')),
        ],
      ),
    );
    if (onay != true || !mounted) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      final token = await _storage.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Lütfen giriş yapın.');
      String iki(int sayi) => sayi.toString().padLeft(2, '0');
      final baslangic = '${yeni.year}-${iki(yeni.month)}-${iki(yeni.day)}T${iki(yeni.hour)}:${iki(yeni.minute)}:00';
      final response = await http.put(
        Uri.parse('$_apiUrl/api/musteri/randevular/$id/ertele'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'baslangic': baslangic}),
      ).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(apiMesaji(response) ?? 'Erteleme başarısız (HTTP ${response.statusCode}).');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu başarıyla ertelendi.')));
      await randevulariYukle();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  Future<void> tekrarRandevuAl(Map<String, dynamic> r) async {
    final id = int.tryParse((r['isletmeId'] ?? '').toString());
    if (id == null || id <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İşletme bilgisi eksik. API güncellemesini kontrol edin.')),
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsletmeDetaySayfasi(
          isletme: {
            'id': id.toString(),
            'ad': alan(r, 'isletme'),
            'konum': '',
            'aciklama': '',
          },
        ),
      ),
    );
    if (mounted) await randevulariYukle();
  }

  Future<void> degerlendirmeDurumuGetir(int randevuId) async {
    if (degerlendirmeKontrolEdilenler.contains(randevuId)) return;
    if (!mounted) return;
    setState(() {
      degerlendirmeKontrolEdilenler.add(randevuId);
      degerlendirmeHatalari.remove(randevuId);
    });
    try {
      final token = await _storage.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Oturum bulunamadı.');
      final cevap = await http.get(
        Uri.parse('${_apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/degerlendirmeler/durum/$randevuId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception(apiMesaji(cevap) ?? 'Değerlendirme durumu alınamadı (${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map || veri['degerlendirildi'] is! bool) {
        throw const FormatException('Değerlendirme durumu geçersiz.');
      }
      if (!mounted) return;
      setState(() => degerlendirmeDurumlari[randevuId] = veri['degerlendirildi'] as bool);
    } catch (_) {
      if (mounted) setState(() => degerlendirmeHatalari.add(randevuId));
    } finally {
      if (mounted) setState(() => degerlendirmeKontrolEdilenler.remove(randevuId));
    }
  }

  Future<void> degerlendir(Map<String, dynamic> r) async {
    final id = r['id'];
    if (id is! int || islemdekiRandevular.contains(id) ||
        degerlendirmeDurumlari[id] != false) return;

    int puan = 5;
    final yorumKontrol = TextEditingController();
    final sonuc = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, dialogSetState) => AlertDialog(
          title: const Text('Randevunu Değerlendir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alan(r, 'isletme'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                const Text('Aldığın hizmete kaç yıldız verirsin?'),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: List.generate(5, (index) => IconButton(
                    tooltip: '${index + 1} yıldız',
                    icon: Icon(index < puan ? Icons.star_rounded : Icons.star_border_rounded),
                    color: const Color(0xFFF59E0B),
                    onPressed: () => dialogSetState(() => puan = index + 1),
                  )),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yorumKontrol,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Yorumun (isteğe bağlı)',
                    hintText: 'Deneyimini paylaş...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, {
                'puan': puan,
                'yorum': yorumKontrol.text.trim(),
              }),
              child: const Text('Değerlendirmeyi Gönder'),
            ),
          ],
        ),
      ),
    );
    if (sonuc == null || !mounted) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      final token = await _storage.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Lütfen giriş yapın.');
      final cevap = await http.post(
        Uri.parse('${_apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/degerlendirmeler'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'randevuId': id,
          'puan': sonuc['puan'],
          'yorum': sonuc['yorum'],
        }),
      ).timeout(const Duration(seconds: 20));
      if (cevap.statusCode != 200) {
        throw Exception(apiMesaji(cevap) ?? 'Değerlendirme gönderilemedi (${cevap.statusCode}).');
      }
      if (!mounted) return;
      setState(() => degerlendirmeDurumlari[id] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değerlendirmen başarıyla kaydedildi.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      // 409 dahil belirsiz sonuçlarda sunucudaki gerçek durumu yeniden sorgula.
      setState(() => degerlendirmeDurumlari.remove(id));
      await degerlendirmeDurumuGetir(id);
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  Widget randevuKarti(Map<String, dynamic> r) {
    final t = tarih(r);
    final islemde = r['id'] is int && islemdekiRandevular.contains(r['id']);
    final renk = durumRengi(r);
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.storefront, color: mavi),
              const SizedBox(width: 9),
              Expanded(child: Text(alan(r, 'isletme'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: lacivert))),
            ]),
            const SizedBox(height: 12),
            Text(alan(r, 'hizmet'), style: const TextStyle(fontSize: 15)),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF64748B)),
              const SizedBox(width: 7),
              Flexible(child: Text(tarihYaz(t), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 17, color: Color(0xFF64748B)),
              const SizedBox(width: 7),
              Text(saatYaz(t)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
              const SizedBox(width: 7),
              Expanded(child: Text(alan(r, 'personel'))),
              Text(fiyat(r), style: const TextStyle(fontWeight: FontWeight.bold, color: lacivert)),
            ]),
            const SizedBox(height: 14),
            Chip(
              avatar: Icon(Icons.circle, size: 11, color: renk),
              label: Text(durum(r), style: TextStyle(color: renk, fontWeight: FontWeight.w700)),
              backgroundColor: renk.withValues(alpha: 0.09),
              side: BorderSide.none,
            ),
            if (islemYapilabilir(r)) ...[
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: islemde ? null : () => iptalEt(r),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('İptal Et'),
                )),
                const SizedBox(width: 10),
                Expanded(child: FilledButton.icon(
                  onPressed: islemde ? null : () => ertele(r),
                  icon: const Icon(Icons.edit_calendar_outlined),
                  label: const Text('Ertele'),
                )),
              ]),
            ],
            if ((r['durum'] ?? '').toString().toLowerCase() == 'tamamlandi' && r['id'] is int) ...[
              const SizedBox(height: 12),
              if (degerlendirmeDurumlari[r['id']] == true)
                const Chip(
                  avatar: Icon(Icons.check_circle_outline, color: Color(0xFF047857)),
                  label: Text('Değerlendirildi'),
                )
              else if (degerlendirmeDurumlari[r['id']] == false)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: islemde ? null : () => degerlendir(r),
                    icon: const Icon(Icons.star_rate_rounded),
                    label: const Text('Değerlendir'),
                  ),
                )
              else if (degerlendirmeHatalari.contains(r['id']))
                TextButton.icon(
                  onPressed: () => degerlendirmeDurumuGetir(r['id'] as int),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Değerlendirme durumunu tekrar kontrol et'),
                )
              else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                ),
            ],
            if (islemde) const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
            if (!yaklasanMi(r) && (r['durum'] ?? '').toString().toLowerCase() != 'onaylandi') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => tekrarRandevuAl(r),
                  icon: const Icon(Icons.replay_outlined),
                  label: const Text('Tekrar Randevu Al'),
                ),
              ),
            ],
            const Divider(height: 26),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => detayGoster(r),
                child: const Text('Detaylar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtreli = randevular.where((r) => seciliSekme == 0 ? yaklasanMi(r) : !yaklasanMi(r)).toList();
    filtreli.sort((a, b) {
      final ta = tarih(a) ?? DateTime(1970);
      final tb = tarih(b) ?? DateTime(1970);
      return seciliSekme == 0 ? ta.compareTo(tb) : tb.compareTo(ta);
    });
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Randevularım'),
        backgroundColor: Colors.white,
        foregroundColor: lacivert,
        actions: [IconButton(onPressed: yukleniyor ? null : randevulariYukle, icon: const Icon(Icons.refresh), tooltip: 'Yenile')],
      ),
      body: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF101F43), Color(0xFF2563EB)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            const Icon(Icons.event_note_rounded, color: Colors.white, size: 32),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Randevu Takibim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19)),
              const SizedBox(height: 5),
              Text('${randevular.where(yaklasanMi).length} yaklaşan  •  ${randevular.where((r) => !yaklasanMi(r)).length} geçmiş / iptal',
                  style: const TextStyle(color: Color(0xFFDCE8FF), fontSize: 12)),
            ])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Yaklaşan'), icon: Icon(Icons.event_available)),
              ButtonSegment(value: 1, label: Text('Geçmiş / İptal'), icon: Icon(Icons.history)),
            ],
            selected: {seciliSekme},
            onSelectionChanged: (secim) => setState(() => seciliSekme = secim.first),
          ),
        ),
        Expanded(
          child: yukleniyor
              ? const Center(child: CircularProgressIndicator())
              : hata != null
                  ? Center(child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(hata!, textAlign: TextAlign.center),
                        const SizedBox(height: 14),
                        ElevatedButton(onPressed: randevulariYukle, child: const Text('Tekrar Dene')),
                      ]),
                    ))
                  : RefreshIndicator(
                      onRefresh: randevulariYukle,
                      child: filtreli.isEmpty
                          ? ListView(children: const [
                              SizedBox(height: 140),
                              Center(child: Text('Bu bölümde randevu bulunmuyor.')),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filtreli.length,
                              itemBuilder: (context, index) => randevuKarti(filtreli[index]),
                            ),
                    ),
        ),
      ]),
    );
  }
}
