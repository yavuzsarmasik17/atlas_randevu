
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'musteri_giris_sayfasi.dart';
import 'musteri_kayit_sayfasi.dart';
import 'isletme_detay_sayfasi.dart';
import 'randevularim_sayfasi.dart';
import 'hesabim_sayfasi.dart';
import 'isletme_giris_sayfasi.dart';

class MusteriAnaSayfa extends StatefulWidget {
  const MusteriAnaSayfa({super.key});

  @override
  State<MusteriAnaSayfa> createState() => _MusteriAnaSayfaState();
}

class _MusteriAnaSayfaState extends State<MusteriAnaSayfa> {
  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);

  static const FlutterSecureStorage guvenliDepo = FlutterSecureStorage();
  bool oturumKontrolEdiliyor = true;
  bool girisYapildi = false;
  String musteriAdiSoyadi = '';
  bool favorilerAcik = false;
  bool favorilerYukleniyor = false;
  String? favorilerHatasi;
  List<Map<String, String>> favoriBerberler = [];

  int seciliMenu = 0;
  String seciliKategori = 'Tümü';
  String arama = '';

  List<String> get kategoriler {
    final mevcut = isletmeler.map((x) => (x['kategori'] ?? '').trim())
        .where((x) => x.isNotEmpty).toSet().toList()..sort();
    return ['Tümü', ...mevcut];
  }

  static const String apiUrl = String.fromEnvironment(
    'API_URL', defaultValue: 'https://localhost:7042');

  List<Map<String, String>> isletmeler = [];
  bool yukleniyor = true;
  String? yuklemeHatasi;

  @override
  void initState() {
    super.initState();
    isletmeleriGetir();
    oturumKontrol();
  }

  Future<void> oturumKontrol() async {
    if (mounted) setState(() => oturumKontrolEdiliyor = true);
    try {
      final token = await guvenliDepo.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) {
        if (mounted) setState(() { girisYapildi = false; musteriAdiSoyadi = ''; favoriBerberler = []; oturumKontrolEdiliyor = false; });
        return;
      }
      // Token'ın sadece varlığı değil, API tarafından kabul edilmesi kontrol edilir.
      final cevap = await http.get(
        Uri.parse('$apiUrl/api/musteri/profil'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 12));
      if (!mounted) return;
      if (cevap.statusCode == 401 || cevap.statusCode == 403) {
        await guvenliDepo.delete(key: 'atlas_access_token');
        if (mounted) setState(() { girisYapildi = false; musteriAdiSoyadi = ''; favoriBerberler = []; oturumKontrolEdiliyor = false; });
      } else if (cevap.statusCode == 200) {
        final profil = jsonDecode(utf8.decode(cevap.bodyBytes));
        String adSoyad = '';
        if (profil is Map) {
          final ad = (profil['ad'] ?? profil['adi'] ?? '').toString().trim();
          final soyad = (profil['soyad'] ?? profil['soyadi'] ?? '').toString().trim();
          adSoyad = (profil['adSoyad'] ?? profil['adiSoyadi'] ??
              profil['fullName'] ?? '$ad $soyad').toString().trim();
          if (profil['musteri'] is Map && adSoyad.isEmpty) {
            final m = profil['musteri'] as Map;
            adSoyad = (m['adSoyad'] ?? '${m['ad'] ?? ''} ${m['soyad'] ?? ''}').toString().trim();
          }
        }
        setState(() { girisYapildi = true; musteriAdiSoyadi = adSoyad; oturumKontrolEdiliyor = false; });
        if (favorilerAcik) favorileriGetir();
      } else {
        setState(() { girisYapildi = false; oturumKontrolEdiliyor = false; });
        mesajGoster('Oturum doğrulanamadı. Tekrar deneyin.');
      }
    } catch (_) {
      if (mounted) {
        setState(() { girisYapildi = false; oturumKontrolEdiliyor = false; });
        mesajGoster('Oturum kontrolü için API bağlantısı kurulamadı.');
      }
    }
  }

  
  Future<void> favorileriGetir() async {
    if (!girisYapildi) return;
    setState(() { favorilerYukleniyor = true; favorilerHatasi = null; });
    try {
      final token = await guvenliDepo.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) throw Exception('Giriş yapmanız gerekiyor.');
      final adres = '$apiUrl/api/isletmeler';

debugPrint('OVORANDEVU API ADRESI: $adres');

final cevap = await http.get(
  Uri.parse(adres),
).timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('Favoriler alınamadı (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      final List liste;
      if (veri is List) {
        liste = veri;
      } else if (veri is Map && veri['favoriler'] is List) {
        liste = veri['favoriler'] as List;
      } else if (veri is Map && veri['isletmeler'] is List) {
        liste = veri['isletmeler'] as List;
      } else {
        throw const FormatException('Favoriler yanıtı beklenen biçimde değil.');
      }
      final favoriler = <Map<String, String>>[];
      for (final eleman in liste) {
        if (eleman is! Map) continue;
        final x = eleman['isletme'] is Map ? eleman['isletme'] as Map : eleman;
        final id = (x['id'] ?? x['isletmeId'] ?? '').toString();
        if (id.isEmpty) continue;
        final mevcut = isletmeler.where((i) => i['id'] == id);
        if (mevcut.isNotEmpty) {
          favoriler.add(mevcut.first);
        } else {
          favoriler.add({
            'id': id,
            'ad': (x['ad'] ?? x['isletmeAdi'] ?? 'İşletme').toString(),
            'konum': (x['adres'] ?? '').toString(),
            'kategori': (x['kategori'] ?? '').toString(),
            'aciklama': (x['aciklama'] ?? '').toString(),
            'logoUrl': (x['logoUrl'] ?? '').toString(),
            'kapakFotoUrl': (x['kapakFotoUrl'] ?? '').toString(),
          });
        }
      }
      if (!mounted) return;
      setState(() { favoriBerberler = favoriler; favorilerYukleniyor = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        favorilerHatasi = e.toString().replaceFirst('Exception: ', '');
        favorilerYukleniyor = false;
      });
    }
  }

  Future<void> uyeMenusunuAc() async {
    final yukleme = favorileriGetir();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (altContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const CircleAvatar(backgroundColor: Color(0xFFEAF1FF),
                  child: Icon(Icons.person_rounded, color: lacivert)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Hesabım', style: TextStyle(fontSize: 12, color: Color(0xFF697586))),
                Text(musteriAdiSoyadi.isEmpty ? 'Üye hesabım' : musteriAdiSoyadi,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ])),
            ]),
            const SizedBox(height: 22),
            const Row(children: [
              Icon(Icons.favorite_rounded, color: Color(0xFFE64C69)),
              SizedBox(width: 9),
              Text('Favori Berberlerim', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 12),
            FutureBuilder<void>(
              future: yukleme,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()));
                }
                if (favorilerHatasi != null) {
                  return Column(children: [
                    Text(favorilerHatasi!, style: const TextStyle(color: Colors.redAccent)),
                    TextButton(onPressed: () { Navigator.pop(altContext); uyeMenusunuAc(); },
                        child: const Text('Tekrar dene')),
                  ]);
                }
                if (favoriBerberler.isEmpty) {
                  return const Padding(padding: EdgeInsets.symmetric(vertical: 18),
                      child: Text('Henüz favori berber eklemediniz.',
                          style: TextStyle(color: Color(0xFF697586))));
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .48),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: favoriBerberler.length,
                    itemBuilder: (_, index) {
                      final isletme = favoriBerberler[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.storefront_outlined, color: mavi),
                        title: Text(isletme['ad'] ?? 'İşletme'),
                        subtitle: Text(isletme['konum'] ?? ''),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          Navigator.pop(altContext);
                          await Navigator.push(context, MaterialPageRoute(
                            builder: (_) => IsletmeDetaySayfasi(isletme: isletme),
                          ));
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ]),
        ),
      ),
    );
  }

Widget uyelikGerekliEkrani(String baslik) {
  return Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 86,
              height: 86,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F0FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 44,
                color: mavi,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              baslik,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: lacivert,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Randevularınızı ve hesabınızı yönetmek için '
              'giriş yapın veya ücretsiz üye olun.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MusteriGirisSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.login),
                label: const Text('Giriş Yap'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mavi,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const MusteriKayitSayfasi(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Üye Ol'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


  void girisSecenekleriGoster() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (altContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('OvoRandevu', style: TextStyle(fontSize: 22,
                fontWeight: FontWeight.bold, color: lacivert)),
            const SizedBox(height: 6),
            const Text('Nasıl devam etmek istersiniz?',
                style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_outline, color: mavi),
              title: const Text('Müşteri Girişi'),
              onTap: () {
                Navigator.pop(altContext);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MusteriGirisSayfasi()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_alt_1_outlined, color: mavi),
              title: const Text('Ücretsiz Üye Ol'),
              onTap: () {
                Navigator.pop(altContext);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const MusteriKayitSayfasi()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.storefront_outlined, color: mavi),
              title: const Text('İşletme Girişi'),
              onTap: () {
                Navigator.pop(altContext);
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const IsletmeGirisSayfasi()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined, color: mavi),
              title: const Text('Platform Admin Girişi'),
              onTap: () {
                Navigator.pop(altContext);
                Navigator.pushNamed(context, '/platform-admin-giris');
              },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> isletmeleriGetir() async {
    if (mounted) setState(() { yukleniyor = true; yuklemeHatasi = null; });
    try {
      final cevap = await http.get(
        Uri.parse('$apiUrl/api/isletmeler'),
      ).timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('Sunucu yanıtı: ${cevap.statusCode}');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! List) throw const FormatException('Geçersiz işletme listesi');
      final liste = veri.map<Map<String, String>>((item) {
        final x = item as Map<String, dynamic>;
        return {
          'id': '${x['id'] ?? ''}',
          'ad': '${x['ad'] ?? ''}',
          'kategori': '${x['kategori'] ?? 'Diğer'}',
          'konum': '${x['adres'] ?? ''}',
          'aciklama': '${x['aciklama'] ?? ''}',
          'puan': '',
          'logoUrl': (x['logoUrl'] ?? '').toString(),
          'kapakFotoUrl': (x['kapakFotoUrl'] ?? '').toString(),
        };
      }).toList();
      if (!mounted) return;
      setState(() { isletmeler = liste; yukleniyor = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { yuklemeHatasi = 'İşletmeler yüklenemedi: $e'; yukleniyor = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          seciliMenu == 0
              ? 'OvoRandevu'
              : seciliMenu == 1
                  ? 'Randevularım'
                  : 'Hesabım',
          style: const TextStyle(
            color: lacivert,
            fontWeight: FontWeight.bold,
          ),
        ),
        
actions: [
  if (!oturumKontrolEdiliyor && girisYapildi)
    Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: uyeMenusunuAc,
        icon: const Icon(Icons.account_circle_outlined, color: lacivert, size: 23),
        label: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 112),
          child: Text(musteriAdiSoyadi.isEmpty ? 'Hesabım' : musteriAdiSoyadi,
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: lacivert, fontWeight: FontWeight.w700)),
        ),
      ),
    ),
  if (!oturumKontrolEdiliyor && !girisYapildi) ...[
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MusteriGirisSayfasi(),
          ),
        );
      },
      child: const Text('Giriş Yap'),
    ),
    TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MusteriKayitSayfasi(),
          ),
        );
      },
      child: const Text('Üye Ol'),
    ),
  ],

  PopupMenuButton<String>(
    tooltip: 'Diğer girişler',
    icon: const Icon(
      Icons.more_vert_rounded,
      color: lacivert,
    ),
    onSelected: (secim) {
      switch (secim) {
        case 'isletme':
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IsletmeGirisSayfasi(),
            ),
          );
          break;

        case 'admin':
          Navigator.pushNamed(
            context,
            '/platform-admin-giris',
          );
          break;
      }
    },
    itemBuilder: (context) => const [
      PopupMenuItem<String>(
        value: 'isletme',
        child: Row(
          children: [
            Icon(Icons.storefront_outlined),
            SizedBox(width: 12),
            Text('İşletme Girişi'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'admin',
        child: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined),
            SizedBox(width: 12),
            Text('Platform Admin Girişi'),
          ],
        ),
      ),
    ],
  ),
],

      ),

      body: IndexedStack(
        index: seciliMenu,
        children: [
          kesfetSayfasi(),
          oturumKontrolEdiliyor
              ? const Center(child: CircularProgressIndicator())
              : girisYapildi
                  ? const RandevularimSayfasi()
                  : uyelikGerekliEkrani('Randevularım'),
          // Hesabım ekranı kendi içinde misafir / giriş yapan ayrımını yapar.
          oturumKontrolEdiliyor
    ? const Center(child: CircularProgressIndicator())
    : girisYapildi
        ? const HesabimSayfasi()
        : uyelikGerekliEkrani('Hesabım'),
        ],
      ),

      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        selectedIndex: seciliMenu,
        onDestinationSelected: (index) {
          setState(() => seciliMenu = index);
          if (index != 0) oturumKontrol();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Randevularım',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hesabım',
          ),
        ],
      ),
    );
  }

  // YENİ KEŞFET: sade, randevu odaklı ve fotoğraflı.
  Widget kesfetSayfasi() {
    final filtreli = isletmeler.where((isletme) {
      final kategoriUygun = seciliKategori == 'Tümü' ||
          isletme['kategori'] == seciliKategori;
      final sorgu = arama.trim().toLowerCase();
      final aramaUygun = (isletme['ad'] ?? '').toLowerCase().contains(sorgu) ||
          (isletme['konum'] ?? '').toLowerCase().contains(sorgu) ||
          (isletme['kategori'] ?? '').toLowerCase().contains(sorgu);
      return kategoriUygun && aramaUygun;
    }).toList();

    return RefreshIndicator(
      onRefresh: () async {
        await isletmeleriGetir();
        if (girisYapildi && favorilerAcik) await favorileriGetir();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
        children: [
          const Text('Kendine iyi bak.',
              style: TextStyle(fontSize: 31, height: 1.15,
                  fontWeight: FontWeight.w800, color: Color(0xFF17212F))),
          const SizedBox(height: 7),
          const Text('En iyi hizmeti keşfet, sana uygun zamanı seç.',
              style: TextStyle(fontSize: 14, color: Color(0xFF697586))),
          const SizedBox(height: 22),
          TextField(
            onChanged: (deger) => setState(() => arama = deger),
            decoration: InputDecoration(
              hintText: 'İşletme, hizmet veya konum ara',
              hintStyle: const TextStyle(color: Color(0xFF8D98A7)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF697586)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 17),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFE4E8EE)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: mavi, width: 1.6),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kategoriler.length,
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final kategori = kategoriler[index];
                final secili = seciliKategori == kategori;
                return ChoiceChip(
                  label: Text(kategori),
                  selected: secili,
                  showCheckmark: false,
                  selectedColor: const Color(0xFF17212F),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: secili
                      ? const Color(0xFF17212F) : const Color(0xFFE4E8EE)),
                  labelStyle: TextStyle(
                    color: secili ? Colors.white : const Color(0xFF475467),
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (_) => setState(() => seciliKategori = kategori),
                );
              },
            ),
          ),
          const SizedBox(height: 29),
          Row(children: [
            const Expanded(
              child: Text('İşletmeleri keşfet',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800,
                      color: Color(0xFF17212F))),
            ),
            if (!yukleniyor && yuklemeHatasi == null)
              Text('${filtreli.length} işletme',
                  style: const TextStyle(fontSize: 13,
                      color: Color(0xFF697586), fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 16),
          if (yukleniyor)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (yuklemeHatasi != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(children: [
                const Icon(Icons.wifi_off_outlined, color: mavi, size: 32),
                const SizedBox(height: 10),
                Text(yuklemeHatasi!, textAlign: TextAlign.center),
                TextButton.icon(
                  onPressed: isletmeleriGetir,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar dene'),
                ),
              ]),
            ),
          if (!yukleniyor && yuklemeHatasi == null && filtreli.isEmpty)
            const Padding(
              padding: EdgeInsets.all(35),
              child: Center(child: Text('Aramana uygun işletme bulunamadı.')),
            ),
          if (!yukleniyor && yuklemeHatasi == null)
            ...filtreli.map(isletmeKarti),
        ],
      ),
    );
  }

  // API'deki /uploads/... yolunu telefonun erişebileceği tam adrese çevirir.
  String gorselAdresi(String? yol) {
    final temiz = (yol ?? '').trim();
    if (temiz.isEmpty) return '';
    final uri = Uri.tryParse(temiz);
    if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
      return temiz;
    }
    final kok = apiUrl.replaceFirst(RegExp(r'/+$'), '');
    return '$kok/${temiz.replaceFirst(RegExp(r'^/+'), '')}';
  }

  Widget isletmeGorseli(String url, {double? genislik, double? yukseklik,
      BoxFit fit = BoxFit.cover, double ikonBoyutu = 32}) {
    final varsayilan = Container(
      width: genislik,
      height: yukseklik,
      color: const Color(0xFFEAF1FF),
      alignment: Alignment.center,
      child: Icon(Icons.storefront_rounded, size: ikonBoyutu, color: lacivert),
    );
    if (url.isEmpty) return varsayilan;
    return Image.network(
      url,
      width: genislik,
      height: yukseklik,
      fit: fit,
      errorBuilder: (_, error, stackTrace) => varsayilan,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: genislik,
          height: yukseklik,
          color: const Color(0xFFEAF1FF),
          alignment: Alignment.center,
          child: const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
    );
  }

  // FOTOĞRAFLI İŞLETME KARTI: kapak, logo ve net randevu çağrısı.
  Widget isletmeKarti(Map<String, String> isletme) {
    final kapak = gorselAdresi(isletme['kapakFotoUrl']);
    final logo = gorselAdresi(isletme['logoUrl']);
    return Container(
      margin: const EdgeInsets.only(bottom: 17),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE8ECF1)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A17212F), blurRadius: 18,
              offset: Offset(0, 6)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => IsletmeDetaySayfasi(isletme: isletme),
        )),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(clipBehavior: Clip.none, children: [
            SizedBox(
              width: double.infinity,
              height: 170,
              child: isletmeGorseli(
                kapak,
                genislik: double.infinity,
                yukseklik: 170,
                ikonBoyutu: 48,
              ),
            ),
            Positioned(
              bottom: -27,
              left: 16,
              child: Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1B17212F), blurRadius: 9,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: isletmeGorseli(logo, genislik: 56, yukseklik: 56),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(17, 36, 17, 17),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(isletme['ad'] ?? '', maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 19,
                    fontWeight: FontWeight.w800, color: Color(0xFF17212F))),
              const SizedBox(height: 7),
              Wrap(spacing: 12, runSpacing: 7, children: [
                if ((isletme['kategori'] ?? '').trim().isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.cut_rounded, size: 15,
                        color: Color(0xFF697586)),
                    const SizedBox(width: 5),
                    Text(isletme['kategori']!,
                        style: const TextStyle(fontSize: 13,
                            color: Color(0xFF697586))),
                  ]),
                if ((isletme['konum'] ?? '').trim().isNotEmpty)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.location_on_outlined, size: 16,
                        color: Color(0xFF697586)),
                    const SizedBox(width: 4),
                    Text(isletme['konum']!,
                        style: const TextStyle(fontSize: 13,
                            color: Color(0xFF697586))),
                  ]),
              ]),
              if ((isletme['aciklama'] ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 11),
                Text(isletme['aciklama']!, maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13,
                        color: Color(0xFF697586), height: 1.45)),
              ],
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Hizmetleri Gör ve Randevu Al',
                        style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 18),
                  ],
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // HESABIM SAYFASI - SONRA GELİŞTİRECEĞİZ
  Widget hesapSayfasi() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_outline,
            size: 70,
            color: mavi,
          ),
          SizedBox(height: 15),
          Text(
            'Hesabım',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: lacivert,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Profil ve hesap işlemleri hazırlanacak.',
          ),
        ],
      ),
    );
  }

  void mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
