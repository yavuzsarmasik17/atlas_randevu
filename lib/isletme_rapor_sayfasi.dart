
import 'package:flutter/material.dart';
import 'isletme_rapor_api.dart';

class IsletmeRaporSayfasi extends StatefulWidget {
  const IsletmeRaporSayfasi({super.key});

  @override
  State<IsletmeRaporSayfasi> createState() =>
      _IsletmeRaporSayfasiState();
}

class _IsletmeRaporSayfasiState extends State<IsletmeRaporSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  static const arkaPlan = Color(0xFFF1F5FB);

  DateTime seciliTarih = DateUtils.dateOnly(DateTime.now());
  String donem = 'aylik';

  Map<String, dynamic>? rapor;
  bool yukleniyor = false;
  String? hata;

  int _istekSirasi = 0;

  @override
  void initState() {
    super.initState();
    yukle();
  }

  Future<void> yukle() async {
    if (!mounted) return;

    final istek = ++_istekSirasi;
    final istenenDonem = donem;
    final istenenTarih = seciliTarih;

    setState(() {
      yukleniyor = true;
      hata = null;
      rapor = null;
    });

    try {
      final sonuc = await IsletmeRaporApi.getir(
        donem: istenenDonem,
        tarih: istenenTarih,
      );

      if (!mounted || istek != _istekSirasi) return;

      setState(() => rapor = sonuc);
    } catch (e) {
      if (!mounted || istek != _istekSirasi) return;

      setState(() => hata = e.toString());
    } finally {
      if (mounted && istek == _istekSirasi) {
        setState(() => yukleniyor = false);
      }
    }
  }

  String gunYaz(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}.'
        '${d.month.toString().padLeft(2, '0')}.'
        '${d.year}';
  }

  double sayisal(dynamic value) {
    if (value is num) return value.toDouble();

    return double.tryParse(
          value?.toString().replaceAll(',', '.') ?? '',
        ) ??
        0;
  }

  String para(dynamic value) {
    final n = sayisal(value);
    final parcalar = n.toStringAsFixed(2).split('.');

    final tam = parcalar[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );

    return '$tam,${parcalar[1]} ₺';
  }

  String yuzde(dynamic value) {
    return '%${sayisal(value).toStringAsFixed(1).replaceAll('.', ',')}';
  }

  int sayi(String key) {
    return sayisal(rapor?[key]).toInt();
  }

  List<Map<String, dynamic>> liste(String key) {
    final veri = rapor?[key];

    if (veri is! List) return [];

    return veri
        .whereType<Map>()
        .map((x) => Map<String, dynamic>.from(x))
        .toList();
  }

  double get toplamCiro => sayisal(rapor?['toplamCiro']);

  double get ortalamaRandevu {
    if (rapor?['ortalamaRandevuTutari'] != null) {
      return sayisal(rapor!['ortalamaRandevuTutari']);
    }

    final tamamlanan = sayi('tamamlanan');

    return tamamlanan > 0
        ? toplamCiro / tamamlanan
        : 0;
  }

  double get iptalOrani {
    if (rapor?['iptalOrani'] != null) {
      return sayisal(rapor!['iptalOrani']);
    }

    final toplam = sayi('toplamRandevu');

    return toplam > 0
        ? sayi('iptalEdilen') * 100 / toplam
        : 0;
  }

  double get gelmemeOrani {
    if (rapor?['gelmemeOrani'] != null) {
      return sayisal(rapor!['gelmemeOrani']);
    }

    final toplam = sayi('toplamRandevu');

    return toplam > 0
        ? sayi('gelmeyen') * 100 / toplam
        : 0;
  }

  Widget ozetKarti(
    String baslik,
    String deger,
    IconData ikon,
    Color renk,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              ikon,
              color: renk,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              deger,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: lacivert,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            baslik,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget bolumBasligi(
    String baslik, {
    String? aciklama,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 24,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            baslik,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: lacivert,
            ),
          ),
          if (aciklama != null) ...[
            const SizedBox(height: 4),
            Text(
              aciklama,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget ustBaslik() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B1733),
            Color(0xFF172F62),
            Color(0xFF245AD4),
          ],
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_graph_rounded,
                color: Color(0xFF93C5FD),
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'OVO RANDEVU • İŞLETME ANALİZİ',
                  style: TextStyle(
                    color: Color(0xFFDCE8FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Gelir ve Performans',
            style: TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Randevularınızı, hizmet tutarlarınızı ve personel performansını takip edin.',
            style: TextStyle(
              color: Color(0xFFC4D3ED),
              fontSize: 12,
            ),
          ),
          if (rapor != null) ...[
            const SizedBox(height: 20),
            const Text(
              'SEÇİLİ DÖNEM HİZMET TUTARI',
              style: TextStyle(
                color: Color(0xFFC4D3ED),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                para(toplamCiro),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget donemSecici() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'gunluk',
                label: Text('Günlük'),
              ),
              ButtonSegment(
                value: 'haftalik',
                label: Text('Haftalık'),
              ),
              ButtonSegment(
                value: 'aylik',
                label: Text('Aylık'),
              ),
            ],
            selected: {donem},
            onSelectionChanged: (secim) {
              setState(() => donem = secim.first);
              yukle();
            },
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              final gun = await showDatePicker(
                context: context,
                initialDate: seciliTarih,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );

              if (!mounted || gun == null) return;

              setState(() => seciliTarih = gun);
              yukle();
            },
            icon: const Icon(Icons.calendar_month_rounded),
            label: Text(
              'Rapor tarihi: ${gunYaz(seciliTarih)}',
            ),
          ),
        ),
      ],
    );
  }

  Widget ozetKartlari() {
    final kartlar = <Widget>[
      ozetKarti(
        'Toplam Randevu',
        '${sayi('toplamRandevu')}',
        Icons.event_note_rounded,
        mavi,
      ),
      ozetKarti(
        'Tamamlanan',
        '${sayi('tamamlanan')}',
        Icons.task_alt_rounded,
        Colors.green,
      ),
      ozetKarti(
        'Onaylanan',
        '${sayi('onaylanan')}',
        Icons.schedule_rounded,
        Colors.orange,
      ),
      ozetKarti(
        'İptal Edilen',
        '${sayi('iptalEdilen')}',
        Icons.cancel_outlined,
        Colors.red,
      ),
      ozetKarti(
        'Gelmeyen',
        '${sayi('gelmeyen')}',
        Icons.person_off_outlined,
        Colors.blueGrey,
      ),
      ozetKarti(
        'Hizmet Tutarı',
        para(toplamCiro),
        Icons.payments_outlined,
        Colors.purple,
      ),
      ozetKarti(
        'Ortalama Randevu',
        para(ortalamaRandevu),
        Icons.calculate_outlined,
        mavi,
      ),
      ozetKarti(
        'İptal Oranı',
        yuzde(iptalOrani),
        Icons.trending_down_rounded,
        Colors.redAccent,
      ),
      ozetKarti(
        'Gelmeme Oranı',
        yuzde(gelmemeOrani),
        Icons.person_off_rounded,
        Colors.deepOrange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final genislik = (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: kartlar
              .map(
                (kart) => SizedBox(
                  width: genislik,
                  height: 132,
                  child: kart,
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget gunlukCiroGrafigi() {
    final gunler = liste('gunlukCiroGrafigi');

    if (gunler.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.bar_chart_rounded,
              color: Color(0xFF94A3B8),
              size: 35,
            ),
            SizedBox(height: 10),
            Text(
              'Grafik verisi bulunamadı.',
              style: TextStyle(
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final tutarlar = gunler
        .map((g) => sayisal(g['ciro']))
        .toList();

    final enYuksek = tutarlar.reduce(
      (a, b) => a > b ? a : b,
    );

    final barGenisligi = donem == 'aylik' ? 30.0 : 45.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.bar_chart_rounded,
                color: mavi,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Günlük Hizmet Tutarları',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: lacivert,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Günlük sütunları incelemek için yatay kaydırabilirsiniz.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 205,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(gunler.length, (index) {
                  final kayit = gunler[index];
                  final tutar = tutarlar[index];

                  final oran = enYuksek > 0
                      ? tutar / enYuksek
                      : 0.0;

                  final tarih = DateTime.tryParse(
                    kayit['tarih']?.toString() ?? '',
                  );

                  final gunMetni = tarih != null
                      ? '${tarih.day}'
                      : '${index + 1}';

                  return SizedBox(
                    width: barGenisligi,
                    child: Tooltip(
                      message:
                          '${kayit['tarih']}\n'
                          '${para(tutar)}\n'
                          '${kayit['tamamlanan'] ?? 0} tamamlanan',
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: donem == 'aylik' ? 18 : 27,
                            height: 155 * oran + 3,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF60A5FA),
                                  mavi,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            gunMetni,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Tutarlar yalnızca tamamlanan randevular üzerinden hesaplanır.',
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget oranKarti(
    String baslik,
    double oran,
    Color renk,
    String aciklama,
  ) {
    final guvenliOran = oran.clamp(0.0, 100.0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  baslik,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: lacivert,
                  ),
                ),
              ),
              Text(
                yuzde(oran),
                style: TextStyle(
                  color: renk,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: guvenliOran / 100,
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: const Color(0xFFE2E8F0),
            color: renk,
          ),
          const SizedBox(height: 8),
          Text(
            aciklama,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget personelPerformansi() {
    final personeller = liste('personelPerformansi');

    if (personeller.isEmpty) {
      return const Card(
        child: ListTile(
          title: Text('Bu dönemde personel kaydı yok.'),
        ),
      );
    }

    return Column(
      children: personeller.map((p) {
        final ad = '${p['personel'] ?? 'Personel'}';

        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFEFF4FF),
                  child: Text(
                    ad.isEmpty ? '?' : ad[0].toUpperCase(),
                    style: const TextStyle(
                      color: mavi,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lacivert,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p['tamamlanan'] ?? 0} tamamlanan / '
                        '${p['toplamRandevu'] ?? 0} randevu',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  para(p['toplamCiro']),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: lacivert,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget hizmetIstatistikleri() {
    final hizmetler = liste('hizmetIstatistikleri');

    if (hizmetler.isEmpty) {
      return const Card(
        child: ListTile(
          title: Text('Bu dönemde hizmet kaydı yok.'),
        ),
      );
    }

    return Column(
      children: hizmetler.map((h) {
        return Card(
          color: Colors.white,
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 5,
            ),
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFEFF4FF),
              child: Icon(
                Icons.content_cut,
                color: mavi,
              ),
            ),
            title: Text(
              '${h['hizmet'] ?? 'Hizmet'}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: lacivert,
              ),
            ),
            subtitle: Text(
              '${h['tercihSayisi'] ?? 0} tercih • '
              '${h['tamamlanan'] ?? 0} tamamlanan',
            ),
            trailing: Text(
              para(h['toplamCiro']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: lacivert,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baslangic = DateTime.tryParse(
      rapor?['baslangic']?.toString() ?? '',
    );

    return Scaffold(
      backgroundColor: arkaPlan,
      appBar: AppBar(
        title: const Text(
          'Gelir ve İşletme Raporları',
          style: TextStyle(
            color: lacivert,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: yukleniyor ? null : yukle,
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: mavi,
        onRefresh: yukle,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            ustBaslik(),
            const SizedBox(height: 18),
            donemSecici(),

            if (yukleniyor)
              const Padding(
                padding: EdgeInsets.all(35),
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

            if (hata != null)
              Card(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.redAccent,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Rapor yüklenemedi:\n$hata',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: yukle,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),

            if (!yukleniyor && rapor != null) ...[
              if (baslangic != null)
                Padding(
                  padding: const EdgeInsets.only(
                    top: 16,
                    bottom: 4,
                  ),
                  child: Text(
                    'Dönem başlangıcı: ${gunYaz(baslangic)}',
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ),

              bolumBasligi('Genel Özet'),
              ozetKartlari(),

              bolumBasligi(
                'Gelir Grafiği',
                aciklama:
                    'Seçilen dönemde tamamlanan randevuların günlük hizmet tutarları.',
              ),
              gunlukCiroGrafigi(),

              bolumBasligi(
                'İptal ve Gelmeme Analizi',
              ),
              oranKarti(
                'İptal Oranı',
                iptalOrani,
                Colors.redAccent,
                '${sayi('iptalEdilen')} iptal edilen randevu',
              ),
              oranKarti(
                'Gelmeme Oranı',
                gelmemeOrani,
                Colors.deepOrange,
                '${sayi('gelmeyen')} gelmeyen müşteri kaydı',
              ),

              bolumBasligi('Personel Performansı'),
              personelPerformansi(),

              bolumBasligi('En Çok Tercih Edilen Hizmetler'),
              hizmetIstatistikleri(),

              const SizedBox(height: 20),
              const Text(
                'Gösterilen tutarlar tahsilat değildir. '
                'Tamamlanan randevuların kayıtlı hizmet '
                'bedelleri üzerinden hesaplanır. '
                'İptal ve gelmeme oranları toplam randevu '
                'sayısına göre hesaplanır.',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
