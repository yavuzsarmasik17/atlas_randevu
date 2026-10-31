import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'randevu_olustur_sayfasi.dart';
import 'musteri_giris_sayfasi.dart';
import 'musteri_kayit_sayfasi.dart';

class IsletmeDetaySayfasi extends StatefulWidget {
  final Map<String, String> isletme;
  const IsletmeDetaySayfasi({super.key, required this.isletme});

  @override
  State<IsletmeDetaySayfasi> createState() => _IsletmeDetaySayfasiState();
}

class _IsletmeDetaySayfasiState extends State<IsletmeDetaySayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);
  static const apiUrl = String.fromEnvironment('API_URL');
  static const FlutterSecureStorage guvenliDepo = FlutterSecureStorage();

  final Set<int> seciliHizmetIdleri = {};
  List<Map<String, dynamic>> hizmetler = [];
  List<Map<String, dynamic>> personeller = [];
  int? subeId;
  bool yukleniyor = true;
  bool devamEdiliyor = false;
  bool favoriMi = false;
  bool favoriYukleniyor = false;
  bool favoriIslemde = false;
  String? hata;

  bool yorumlarYukleniyor = true;
  String? yorumHatasi;
  double ortalamaPuan = 0;
  int degerlendirmeSayisi = 0;
  List<Map<String, dynamic>> yorumlar = [];

  String? logoUrl;
  String? kapakFotoUrl;
  List<Map<String, dynamic>> galeriFotograflari = [];
  bool gorsellerYukleniyor = true;
  String? gorselHatasi;

  String? tamGorselUrl(String? yol) {
    if (yol == null || yol.trim().isEmpty || apiUrl.isEmpty) return null;
    final kok = Uri.tryParse(apiUrl);
    if (kok == null || !kok.hasScheme || kok.host.isEmpty) return null;
    final adres = kok.resolve(yol);
    if ((adres.scheme != 'http' && adres.scheme != 'https') ||
        adres.host != kok.host || adres.port != kok.port) {
      return null;
    }
    return adres.toString();
  }

  Future<void> gorselleriYukle() async {
    final id = int.tryParse(widget.isletme['id'] ?? '');
    if (id == null || apiUrl.isEmpty) {
      if (mounted) {
        setState(() {
        gorsellerYukleniyor = false;
        gorselHatasi = 'İşletme ID veya API adresi eksik.';
      });
      }
      return;
    }
    if (mounted) {
      setState(() {
      gorsellerYukleniyor = true;
      gorselHatasi = null;
    });
    }
    try {
      final cevap = await http.get(Uri.parse(
        "${apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/isletmeler/$id/fotograflar",
      )).timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('Görseller yüklenemedi (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map<String, dynamic>) {
        throw const FormatException('Görsel yanıtı geçersiz.');
      }
      final liste = (veri['fotograflar'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        logoUrl = veri['logoUrl']?.toString();
        kapakFotoUrl = veri['kapakFotoUrl']?.toString();
        galeriFotograflari = liste.whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)).toList();
        gorsellerYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        gorselHatasi = e.toString().replaceFirst('Exception: ', '');
        gorsellerYukleniyor = false;
      });
    }
  }

  // Yeni sade vitrin: işletme kimliği üstte, fotoğraflar tanıtımda.
  Widget isletmeGorselleri() {
    final kapak = tamGorselUrl(kapakFotoUrl ?? widget.isletme['kapakFotoUrl']);
    final logo = tamGorselUrl(logoUrl ?? widget.isletme['logoUrl']);
    final kategori = (widget.isletme['kategori'] ?? '').trim();
    final konum = (widget.isletme['konum'] ?? '').trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(22),
        child: SizedBox(height: 168, width: double.infinity,
          child: Stack(fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xFFE8EDF4),
              child: Icon(Icons.storefront_outlined, size: 65, color: Color(0xFF94A3B8))),
            if (kapak != null) Image.network(kapak, fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const SizedBox.shrink()),
          ]))),
      const SizedBox(height: 16),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Container(width: 58, height: 58, clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: logo == null
            ? const Icon(Icons.storefront, color: mavi)
            : Image.network(logo, fit: BoxFit.cover,
                errorBuilder: (context, error, stack) =>
                  const Icon(Icons.storefront, color: mavi))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.isletme['ad'] ?? '',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
              color: Color(0xFF172033))),
          if (kategori.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4),
            child: Text(kategori, style: const TextStyle(
              color: Color(0xFF64748B), fontSize: 13))),
        ])),
      ]),
      if (konum.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 12),
        child: Row(children: [
          const Icon(Icons.location_on_outlined, size: 17, color: Color(0xFF64748B)),
          const SizedBox(width: 5),
          Expanded(child: Text(konum,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))),
        ])),
      if (!yorumlarYukleniyor && yorumHatasi == null && degerlendirmeSayisi > 0)
        Padding(padding: const EdgeInsets.only(top: 9), child: Row(children: [
          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 19),
          const SizedBox(width: 4),
          Text('${ortalamaPuan.toStringAsFixed(1)}  ($degerlendirmeSayisi yorum)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        ])),
    ]);
  }

  Widget tanitimBolumu() {
    final aciklama = (widget.isletme['aciklama'] ?? '').trim();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('İşletmeyi tanıyın', style: TextStyle(
        fontSize: 21, fontWeight: FontWeight.w800, color: Color(0xFF172033))),
      if (aciklama.isNotEmpty) ...[
        const SizedBox(height: 10),
        Text(aciklama, style: const TextStyle(
          color: Color(0xFF64748B), height: 1.5)),
      ],
      if (gorsellerYukleniyor) const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator()),
      if (gorselHatasi != null) TextButton.icon(
        onPressed: gorselleriYukle,
        icon: const Icon(Icons.refresh),
        label: const Text('Fotoğrafları yeniden yükle')),
      if (galeriFotograflari.isNotEmpty) ...[
        const SizedBox(height: 16),
        SizedBox(height: 132, child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: galeriFotograflari.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final url = tamGorselUrl(
              galeriFotograflari[index]['fotografUrl']?.toString());
            return GestureDetector(
              onTap: url == null ? null : () => showDialog<void>(
                context: context,
                builder: (dialogContext) => Dialog(
                  backgroundColor: Colors.black,
                  child: Stack(children: [
                    SizedBox(height: 420, width: double.infinity,
                      child: InteractiveViewer(child: Center(
                        child: Image.network(url, fit: BoxFit.contain)))),
                    Positioned(top: 0, right: 0, child: IconButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      icon: const Icon(Icons.close, color: Colors.white))),
                  ]))),
              child: ClipRRect(borderRadius: BorderRadius.circular(14),
                child: Container(width: 145, color: const Color(0xFFE2E8F0),
                  child: url == null
                    ? const Icon(Icons.broken_image_outlined)
                    : Image.network(url, fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) =>
                        const Icon(Icons.broken_image_outlined)))),
            );
          })),
      ],
    ]);
  }

  Widget _bilgiEtiketi(IconData ikon, String yazi) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFFEAF1FF),
      borderRadius: BorderRadius.circular(12)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ikon, color: mavi, size: 16),
      const SizedBox(width: 6),
      Text(yazi, style: const TextStyle(color: lacivert,
        fontWeight: FontWeight.w700, fontSize: 12)),
    ]),
  );

  Widget personelBolumu() {
    if (personeller.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Ekibimiz', style: TextStyle(color: lacivert,
        fontSize: 21, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Text('Hizmet veren uzmanlarımızı tanıyın.',
        style: TextStyle(color: Color(0xFF64748B))),
      const SizedBox(height: 12),
      SizedBox(height: 125, child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: personeller.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final p = personeller[index];
          final ad = (p['adSoyad'] ?? 'Personel').toString();
          final unvan = (p['unvan'] ?? '').toString();
          return Container(width: 160,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: const Color(0xFFE2E8F0))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const CircleAvatar(radius: 19,
                backgroundColor: Color(0xFFEAF1FF),
                child: Icon(Icons.person_outline_rounded, color: mavi)),
              const SizedBox(height: 9),
              Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: lacivert,
                  fontWeight: FontWeight.w800)),
              if (unvan.isNotEmpty) Text(unvan, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ]),
          );
        },
      )),
    ]);
  }

  Widget hizmetKarti(Map<String, dynamic> hizmet) {
    final id = (hizmet['id'] as num).toInt();
    final secili = seciliHizmetIdleri.contains(id);
    return Padding(padding: const EdgeInsets.only(bottom: 9),
      child: Material(color: secili ? const Color(0xFFF0F7FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() {
            if (secili) { seciliHizmetIdleri.remove(id); }
            else { seciliHizmetIdleri.add(id); }
          }),
          child: Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
              border: Border.all(color: secili
                ? const Color(0xFF2563EB) : const Color(0xFFE5EAF0),
                width: secili ? 1.5 : 1)),
            child: Row(children: [
              Icon(secili ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: secili ? mavi : const Color(0xFFCBD5E1), size: 25),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${hizmet['ad']}', style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15,
                    color: Color(0xFF172033))),
                  const SizedBox(height: 5),
                  Text('${hizmet['sure']} dakika', style: const TextStyle(
                    fontSize: 12, color: Color(0xFF64748B))),
                ])),
              Text('${hizmet['fiyat']} ₺', style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16,
                color: Color(0xFF172033))),
            ])),
        )));
  }

  @override
  void initState() {
    super.initState();
    bilgileriGetir();
    favoriDurumunuYukle();
    degerlendirmeleriYukle();
    gorselleriYukle();
  }


  Future<void> degerlendirmeleriYukle() async {
    final id = int.tryParse(widget.isletme['id'] ?? '');
    if (id == null || apiUrl.isEmpty) {
      if (mounted) {
        setState(() {
        yorumlarYukleniyor = false;
        yorumHatasi = 'İşletme veya API adresi bulunamadı.';
      });
      }
      return;
    }
    if (mounted) {
      setState(() {
      yorumlarYukleniyor = true;
      yorumHatasi = null;
    });
    }
    try {
      final cevap = await http.get(
        Uri.parse("${apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/isletmeler/$id/degerlendirmeler"),
      ).timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('Yorumlar alınamadı (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! Map<String, dynamic>) {
        throw const FormatException('Değerlendirme verisi geçersiz.');
      }
      final liste = (veri['yorumlar'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        ortalamaPuan = (veri['ortalamaPuan'] as num?)?.toDouble() ?? 0;
        degerlendirmeSayisi = (veri['degerlendirmeSayisi'] as num?)?.toInt() ?? 0;
        yorumlar = liste.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        yorumlarYukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        yorumHatasi = e.toString().replaceFirst('Exception: ', '');
        yorumlarYukleniyor = false;
      });
    }
  }

  Widget yildizlar(int puan, {double boyut = 17}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (index) => Icon(
      index < puan ? Icons.star_rounded : Icons.star_border_rounded,
      color: const Color(0xFFF59E0B), size: boyut,
    )),
  );

  Widget degerlendirmeBolumu() {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Müşteri Değerlendirmeleri',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: lacivert))),
          IconButton(onPressed: yorumlarYukleniyor ? null : degerlendirmeleriYukle,
              tooltip: 'Yorumları yenile', icon: const Icon(Icons.refresh, color: mavi)),
        ]),
        if (yorumlarYukleniyor)
          const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
        else if (yorumHatasi != null) ...[
          Text(yorumHatasi!, style: const TextStyle(color: Colors.redAccent)),
          TextButton(onPressed: degerlendirmeleriYukle, child: const Text('Tekrar dene')),
        ] else ...[
          Row(children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 29),
            const SizedBox(width: 5),
            Text(ortalamaPuan.toStringAsFixed(1),
                style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: lacivert)),
            const SizedBox(width: 10),
            Expanded(child: Text('$degerlendirmeSayisi değerlendirme',
                style: const TextStyle(color: Color(0xFF64748B)))),
          ]),
          const SizedBox(height: 12),
          if (yorumlar.isEmpty)
            const Text('Bu işletme için henüz değerlendirme yapılmamış.',
                style: TextStyle(color: Color(0xFF64748B)))
          else
            ...yorumlar.map((yorum) {
              final puan = (yorum['puan'] as num?)?.toInt().clamp(1, 5) ?? 1;
              final ad = (yorum['musteriAdi'] ?? 'Müşteri').toString();
              final metin = (yorum['yorum'] ?? '').toString().trim();
              final tarih = DateTime.tryParse((yorum['olusturmaTarihi'] ?? '').toString());
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(children: [
                    CircleAvatar(radius: 17, backgroundColor: const Color(0xFFEAF1FF),
                        child: Text(ad.isNotEmpty ? ad[0].toUpperCase() : 'M',
                            style: const TextStyle(color: lacivert, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 9),
                    Expanded(child: Text(ad, style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (tarih != null) Text('${tarih.day.toString().padLeft(2, '0')}.${tarih.month.toString().padLeft(2, '0')}.${tarih.year}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  ]),
                  const SizedBox(height: 7),
                  yildizlar(puan),
                  if (metin.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(metin),
                  ],
                ]),
              );
            }),
        ],
      ]),
    );
  }

  Future<void> favoriDurumunuYukle() async {
    final id = int.tryParse(widget.isletme['id'] ?? '');
    if (id == null || apiUrl.isEmpty) return;
    final token = await guvenliDepo.read(key: 'atlas_access_token');
    if (token == null || token.isEmpty || !mounted) return;
    setState(() => favoriYukleniyor = true);
    try {
      final cevap = await http.get(
        Uri.parse('${apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/favoriler/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (cevap.statusCode == 200) {
        final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
        if (veri is Map && veri['favoriMi'] is bool) {
          setState(() => favoriMi = veri['favoriMi'] as bool);
        }
      } else if (cevap.statusCode != 401 && cevap.statusCode != 403) {
        debugPrint('Favori durumu alınamadı: HTTP ${cevap.statusCode}');
      }
    } catch (e) {
      debugPrint('Favori durumu hatası: $e');
    } finally {
      if (mounted) setState(() => favoriYukleniyor = false);
    }
  }

  Future<void> favoriDegistir() async {
    if (favoriIslemde || favoriYukleniyor) return;
    final id = int.tryParse(widget.isletme['id'] ?? '');
    if (id == null || apiUrl.isEmpty) {
      mesaj('İşletme bilgisi veya API adresi eksik.');
      return;
    }
    final token = await guvenliDepo.read(key: 'atlas_access_token');
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      await uyelikUyarisi();
      return;
    }
    setState(() => favoriIslemde = true);
    try {
      final uri = Uri.parse('${apiUrl.replaceAll(RegExp(r'/+$'), '')}/api/musteri/favoriler/$id');
      final cevap = favoriMi
          ? await http.delete(uri, headers: {'Authorization': 'Bearer $token'})
              .timeout(const Duration(seconds: 15))
          : await http.post(uri, headers: {'Authorization': 'Bearer $token'})
              .timeout(const Duration(seconds: 15));
      if (!mounted) return;
      if (cevap.statusCode == 401 || cevap.statusCode == 403) {
        mesaj('Oturum geçersiz. Lütfen tekrar giriş yapın.');
        return;
      }
      if (cevap.statusCode < 200 || cevap.statusCode >= 300) {
        mesaj('Favori işlemi başarısız (HTTP ${cevap.statusCode}).');
        return;
      }
      setState(() => favoriMi = !favoriMi);
      mesaj(favoriMi ? 'İşletme favorilerine eklendi.' : 'İşletme favorilerinden çıkarıldı.');
    } catch (e) {
      mesaj('Favori işlemi sırasında bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => favoriIslemde = false);
    }
  }

  int get toplamFiyat => hizmetler
      .where((h) => seciliHizmetIdleri.contains(h['id']))
      .fold<int>(0, (toplam, h) => toplam + (h['fiyat'] as num).round());

  int get toplamSure => hizmetler
      .where((h) => seciliHizmetIdleri.contains(h['id']))
      .fold<int>(0, (toplam, h) => toplam + (h['sure'] as num).toInt());

  void mesaj(String metin) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(metin)));
  }

  Future<void> bilgileriGetir() async {
    final isletmeId = int.tryParse(widget.isletme['id'] ?? '');
    if (isletmeId == null) {
      setState(() { yukleniyor = false; hata = 'İşletme ID bulunamadı.'; });
      return;
    }
    try {
      final cevap = await http.get(
        Uri.parse('$apiUrl/api/isletmeler/$isletmeId/randevu-bilgileri'),
      ).timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('Sunucu yanıtı: ${cevap.statusCode}');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes)) as Map<String, dynamic>;
      final subeler = (veri['subeler'] as List?) ?? [];
      if (subeler.isEmpty) throw Exception('Bu işletmenin aktif şubesi bulunamadı.');
      // Mevcut uygulama akışında ilk aktif şube kullanılıyor.
      final sube = Map<String, dynamic>.from(subeler.first as Map);
      final gelenHizmetler = ((sube['hizmetler'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      final gelenPersoneller = ((sube['personeller'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (!mounted) return;
      setState(() {
        subeId = (sube['id'] as num).toInt();
        hizmetler = gelenHizmetler;
        personeller = gelenPersoneller;
        seciliHizmetIdleri.clear();
        yukleniyor = false;
        hata = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { yukleniyor = false; hata = 'Bilgiler yüklenemedi: $e'; });
    }
  }

  Future<void> uyelikUyarisi() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Üyelik Gerekli'),
        content: const Text('İşletmeleri, hizmetleri ve fiyatları üyelik olmadan inceleyebilirsiniz. Randevu almak için giriş yapmanız veya ücretsiz üye olmanız gerekiyor.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MusteriKayitSayfasi()));
            },
            child: const Text('Üye Ol'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MusteriGirisSayfasi()));
            },
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> randevuyaDevamEt() async {
    if (devamEdiliyor) return;
    if (seciliHizmetIdleri.isEmpty) {
      mesaj('Lütfen en az bir hizmet seçin.');
      return;
    }
    setState(() => devamEdiliyor = true);
    try {
      final token = await guvenliDepo.read(key: 'atlas_access_token');
      if (!mounted) return;
      if (token == null || token.isEmpty) {
        await uyelikUyarisi();
        return;
      }
      // Süresi dolmuş veya yetkisiz token ile randevu ekranına geçilmesin.
      final kontrol = await http.get(
        Uri.parse('$apiUrl/api/musteri/profil'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (kontrol.statusCode == 401 || kontrol.statusCode == 403) {
        await guvenliDepo.delete(key: 'atlas_access_token');
        if (mounted) await uyelikUyarisi();
        return;
      }
      if (kontrol.statusCode != 200) {
        mesaj('Oturum doğrulanamadı (${kontrol.statusCode}). Tekrar deneyin.');
        return;
      }
      if (personeller.isEmpty) {
        mesaj('Bu şubede aktif personel bulunamadı.');
        return;
      }
      final secilenler = hizmetler
          .where((h) => seciliHizmetIdleri.contains(h['id']))
          .toList();
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RandevuOlusturSayfasi(
            isletmeAdi: widget.isletme['ad'] ?? '',
            secilenHizmetler: secilenler,
            personeller: personeller,
            toplamFiyat: toplamFiyat,
            toplamSure: toplamSure,
          ),
        ),
      );
    } catch (e) {
      mesaj('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => devamEdiliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('İşletme', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: const Color(0xFF172033),
        actions: [
          IconButton(
            tooltip: favoriMi ? 'Favorilerden çıkar' : 'Favorilere ekle',
            onPressed: favoriIslemde || favoriYukleniyor ? null : favoriDegistir,
            icon: favoriIslemde || favoriYukleniyor
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(favoriMi ? Icons.favorite : Icons.favorite_border,
                  color: favoriMi ? Colors.redAccent : const Color(0xFF172033)),
          ),
        ],
      ),
      body: yukleniyor
        ? const Center(child: CircularProgressIndicator())
        : hata != null
          ? Center(child: Padding(padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(hata!, textAlign: TextAlign.center),
                TextButton(onPressed: () {
                  setState(() => yukleniyor = true);
                  bilgileriGetir();
                }, child: const Text('Tekrar dene')),
              ])))
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  bilgileriGetir(), gorselleriYukle(),
                  degerlendirmeleriYukle(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 30),
                children: [
                  isletmeGorselleri(),
                  const SizedBox(height: 28),
                  Row(children: [
                    const Expanded(child: Text('Hizmet seçin',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800,
                        color: Color(0xFF172033)))),
                    if (seciliHizmetIdleri.isNotEmpty)
                      Text('${seciliHizmetIdleri.length} seçildi',
                        style: const TextStyle(color: mavi,
                          fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 6),
                  const Text('Bir veya birden fazla hizmet seçebilirsiniz.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 15),
                  if (hizmetler.isEmpty)
                    const Text('Henüz aktif hizmet bulunmuyor.'),
                  ...hizmetler.map(hizmetKarti),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 18),
                  tanitimBolumu(),
                  const SizedBox(height: 28),
                  personelBolumu(),
                  const SizedBox(height: 28),
                  degerlendirmeBolumu(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: yukleniyor || hata != null ? null : SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
          decoration: const BoxDecoration(color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5EAF0)))),
          child: Row(children: [
            Expanded(child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$toplamFiyat ₺', style: const TextStyle(
                  fontSize: 23, fontWeight: FontWeight.w800,
                  color: Color(0xFF172033))),
                Text('$toplamSure dk • ${seciliHizmetIdleri.length} hizmet',
                  style: const TextStyle(fontSize: 12,
                    color: Color(0xFF64748B))),
              ])),
            const SizedBox(width: 12),
            SizedBox(height: 52, child: FilledButton(
              onPressed: seciliHizmetIdleri.isEmpty || devamEdiliyor
                ? null : randevuyaDevamEt,
              style: FilledButton.styleFrom(backgroundColor: mavi,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14))),
              child: devamEdiliyor
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2,
                      color: Colors.white))
                : const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Randevu Al', style: TextStyle(
                      fontWeight: FontWeight.w800)),
                    SizedBox(width: 7),
                    Icon(Icons.arrow_forward_rounded, size: 18),
                  ]),
            )),
          ]),
        ),
      ),
    );
  }
}
