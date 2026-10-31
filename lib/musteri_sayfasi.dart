import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'favorilerim_sayfasi.dart';
import 'hesabim_sayfasi.dart';
import 'isletme_detay_sayfasi.dart';
import 'randevularim_sayfasi.dart';

class MusteriSayfasi extends StatefulWidget {
  const MusteriSayfasi({super.key});

  @override
  State<MusteriSayfasi> createState() => _MusteriSayfasiState();
}

class _MusteriSayfasiState extends State<MusteriSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);
  static const apiUrl = String.fromEnvironment('API_URL');

  int seciliSayfa = 0;
  final TextEditingController aramaController = TextEditingController();
  List<Map<String, dynamic>> isletmeler = [];
  bool yukleniyor = true;
  String? hata;
  String arama = '';

  String get temelUrl => apiUrl.replaceAll(RegExp(r'/+$'), '');

  @override
  void initState() {
    super.initState();
    isletmeleriYukle();
  }

  @override
  void dispose() {
    aramaController.dispose();
    super.dispose();
  }

  Future<void> isletmeleriYukle() async {
    if (apiUrl.isEmpty) {
      if (mounted) setState(() {
        yukleniyor = false;
        hata = 'API_URL tanımlanmamış.';
      });
      return;
    }
    setState(() {
      yukleniyor = true;
      hata = null;
    });
    try {
      final cevap = await http
          .get(Uri.parse('$temelUrl/api/isletmeler'))
          .timeout(const Duration(seconds: 15));
      if (cevap.statusCode != 200) {
        throw Exception('İşletmeler alınamadı (HTTP ${cevap.statusCode}).');
      }
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (veri is! List) {
        throw const FormatException('İşletme listesi beklenen biçimde değil.');
      }
      final liste = veri
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        isletmeler = liste;
        yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hata = e.toString().replaceFirst('Exception: ', '');
        yukleniyor = false;
      });
    }
  }

  String? gorselAdresi(dynamic deger) {
    final yol = deger?.toString().trim() ?? '';
    if (yol.isEmpty) return null;
    final uri = Uri.tryParse(yol);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return (uri.scheme == 'https' || uri.scheme == 'http') ? yol : null;
    }
    return '$temelUrl/${yol.replaceFirst(RegExp(r'^/+'), '')}';
  }

  void detayaGit(Map<String, dynamic> isletme) {
    final id = isletme['id'];
    if (id == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => IsletmeDetaySayfasi(
          isletme: {
            'id': id.toString(),
            'ad': (isletme['ad'] ?? '').toString(),
            'konum': (isletme['adres'] ?? '').toString(),
            'aciklama': (isletme['aciklama'] ?? '').toString(),
            'kategori': (isletme['kategori'] ?? '').toString(),
            'logoUrl': (isletme['logoUrl'] ?? '').toString(),
            'kapakFotoUrl': (isletme['kapakFotoUrl'] ?? '').toString(),
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('OvoRandevu',
            style: TextStyle(color: lacivert, fontWeight: FontWeight.bold, fontSize: 20)),
        actions: [
          IconButton(
            tooltip: 'Bildirimler',
            icon: const Icon(Icons.notifications_none, color: lacivert),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Henüz bildiriminiz yok.')),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: seciliSayfa,
        children: [
          kesfetSayfasi(),
          const RandevularimSayfasi(),
          seciliSayfa == 2 ? const FavorilerimSayfasi() : const SizedBox.shrink(),
          seciliSayfa == 3 ? const HesabimSayfasi() : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFDBEAFE),
        selectedIndex: seciliSayfa,
        onDestinationSelected: (index) => setState(() => seciliSayfa = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore, color: mavi), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month, color: mavi), label: 'Randevularım'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite, color: Colors.red), label: 'Favorilerim'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: mavi), label: 'Hesabım'),
        ],
      ),
    );
  }

  Widget kesfetSayfasi() {
    final sorgu = arama.trim().toLowerCase();
    final filtreli = isletmeler.where((i) {
      if (sorgu.isEmpty) return true;
      return ['ad', 'adres', 'kategori', 'aciklama'].any((alan) =>
          (i[alan] ?? '').toString().toLowerCase().contains(sorgu));
    }).toList();

    return RefreshIndicator(
      onRefresh: isletmeleriYukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [lacivert, mavi]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kendine zaman ayır.',
                    style: TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('İşletmeleri keşfet, randevunu kolayca oluştur.',
                    style: TextStyle(color: Color(0xFFDFE8FA), fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          TextField(
            controller: aramaController,
            onChanged: (deger) => setState(() => arama = deger),
            decoration: InputDecoration(
              hintText: 'İşletme, kategori veya konum ara...',
              prefixIcon: const Icon(Icons.search, color: mavi),
              suffixIcon: arama.isEmpty ? null : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  aramaController.clear();
                  setState(() => arama = '');
                },
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: Text('İşletmeleri Keşfet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: lacivert))),
              if (!yukleniyor) Text('${filtreli.length} işletme',
                  style: const TextStyle(color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 14),
          if (yukleniyor)
            const Padding(padding: EdgeInsets.all(35),
                child: Center(child: CircularProgressIndicator()))
          else if (hata != null)
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                Text(hata!, textAlign: TextAlign.center),
                const SizedBox(height: 10),
                TextButton.icon(onPressed: isletmeleriYukle,
                    icon: const Icon(Icons.refresh), label: const Text('Tekrar dene')),
              ]),
            ))
          else if (filtreli.isEmpty)
            const Padding(padding: EdgeInsets.all(30),
                child: Center(child: Text('Aramanıza uygun işletme bulunamadı.')))
          else
            ...filtreli.map(isletmeKarti),
        ],
      ),
    );
  }

  Widget isletmeKarti(Map<String, dynamic> isletme) {
    final ad = (isletme['ad'] ?? 'İşletme').toString();
    final adres = (isletme['adres'] ?? '').toString();
    final kategori = (isletme['kategori'] ?? 'Diğer').toString();
    final kapak = gorselAdresi(isletme['kapakFotoUrl']);
    final logo = gorselAdresi(isletme['logoUrl']);

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => detayaGit(isletme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 145,
              width: double.infinity,
              child: kapak == null
                  ? const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [lacivert, mavi]),
                      ),
                      child: Center(child: Icon(Icons.storefront_rounded,
                          size: 58, color: Colors.white)),
                    )
                  : Image.network(kapak, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFEAF1FF),
                        child: Center(child: Icon(Icons.storefront_rounded,
                            size: 58, color: mavi)),
                      )),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: logo == null
                        ? const Icon(Icons.store, color: mavi, size: 29)
                        : Image.network(logo, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.store, color: mavi, size: 29)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ad, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17,
                                fontWeight: FontWeight.w800, color: lacivert)),
                        const SizedBox(height: 5),
                        Text(kategori, style: const TextStyle(color: mavi,
                            fontWeight: FontWeight.w600, fontSize: 12)),
                        if (adres.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(children: [
                            const Icon(Icons.location_on_outlined,
                                size: 15, color: Color(0xFF64748B)),
                            const SizedBox(width: 3),
                            Expanded(child: Text(adres, maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12,
                                    color: Color(0xFF64748B)))),
                          ]),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: mavi),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
