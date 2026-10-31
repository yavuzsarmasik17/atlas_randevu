import 'package:flutter/material.dart';

class RandevuTakvimiSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> randevular;

  const RandevuTakvimiSayfasi({
    super.key,
    required this.randevular,
  });

  @override
  State<RandevuTakvimiSayfasi> createState() => _RandevuTakvimiSayfasiState();
}

class _RandevuTakvimiSayfasiState extends State<RandevuTakvimiSayfasi> {
  static const Color lacivert = Color(0xFF101F43);
  static const Color mavi = Color(0xFF2563EB);
  static const Color arkaPlan = Color(0xFFF1F5FB);

  DateTime seciliGun = DateUtils.dateOnly(DateTime.now());
  bool haftalik = false;
  String personel = 'Tümü';

  DateTime? _baslangic(Map<String, dynamic> randevu) {
    final deger = randevu['baslangic'] ?? randevu['tarih'];
    if (deger is DateTime) return deger;
    if (deger is String) return DateTime.tryParse(deger);
    return null;
  }

  String _saat(Map<String, dynamic> randevu) {
    final baslangic = _baslangic(randevu);
    if (baslangic != null) {
      return '${baslangic.hour.toString().padLeft(2, '0')}:'
          '${baslangic.minute.toString().padLeft(2, '0')}';
    }
    return randevu['saat']?.toString() ?? '--:--';
  }

  String _tarihYaz(DateTime tarih) =>
      '${tarih.day.toString().padLeft(2, '0')}.'
      '${tarih.month.toString().padLeft(2, '0')}.${tarih.year}';

  String _para(dynamic tutar) {
    final sayi = tutar is num
        ? tutar.toDouble()
        : double.tryParse(tutar?.toString() ?? '') ?? 0;
    return sayi.toStringAsFixed(sayi == sayi.roundToDouble() ? 0 : 2)
        .replaceAll('.', ',');
  }

  List<DateTime> get gunler {
    if (!haftalik) return [seciliGun];
    final pazartesi = seciliGun.subtract(
      Duration(days: seciliGun.weekday - DateTime.monday),
    );
    return List.generate(7, (index) => pazartesi.add(Duration(days: index)));
  }

  String _durumYaz(String durum) {
    switch (durum) {
      case 'Onaylandi':
      case 'Onaylandı':
        return 'Onaylandı';
      case 'Tamamlandi':
      case 'Tamamlandı':
        return 'Tamamlandı';
      case 'IptalEdildi':
      case 'İptal Edildi':
        return 'İptal Edildi';
      case 'Gelmedi':
        return 'Gelmedi';
      default:
        return durum.isEmpty ? 'Bilinmiyor' : durum;
    }
  }

  Color _durumRengi(String durum) {
    switch (durum) {
      case 'Tamamlandi':
      case 'Tamamlandı':
        return const Color(0xFF15803D);
      case 'IptalEdildi':
      case 'İptal Edildi':
        return const Color(0xFFB91C1C);
      case 'Gelmedi':
        return const Color(0xFFB45309);
      default:
        return mavi;
    }
  }

  List<Map<String, dynamic>> _gununRandevulari(DateTime gun) {
    final sonuc = widget.randevular.where((randevu) {
      final baslangic = _baslangic(randevu);
      if (baslangic == null || !DateUtils.isSameDay(baslangic, gun)) {
        return false;
      }
      return personel == 'Tümü' ||
          randevu['personel']?.toString() == personel;
    }).toList();
    sonuc.sort((a, b) => _baslangic(a)!.compareTo(_baslangic(b)!));
    return sonuc;
  }

  Widget _randevuKarti(Map<String, dynamic> randevu) {
    final durum = randevu['durum']?.toString() ?? '';
    final renk = _durumRengi(durum);
    final hizmetler = randevu['hizmetler'];
    final hizmetAdi = (randevu['hizmet']?.toString().isNotEmpty ?? false)
        ? randevu['hizmet'].toString()
        : hizmetler is List
            ? hizmetler
                .whereType<Map>()
                .map((h) => h['ad']?.toString() ?? '')
                .where((ad) => ad.isNotEmpty)
                .join(', ')
            : '';

    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 57,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _saat(randevu),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: mavi,
                  fontSize: 12,
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
                    randevu['musteri']?.toString() ?? 'Müşteri',
                    style: const TextStyle(
                      color: lacivert,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (hizmetAdi.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(hizmetAdi),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Personel: ${randevu['personel'] ?? '-'}',
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: renk.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _durumYaz(durum),
                          style: TextStyle(
                            color: renk,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Text(
                        '${_para(randevu['toplamFiyat'] ?? randevu['fiyat'])} ₺',
                        style: const TextStyle(
                          color: lacivert,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final personeller = <String>{
      'Tümü',
      ...widget.randevular
          .map((r) => r['personel']?.toString() ?? '')
          .where((p) => p.isNotEmpty),
    }.toList();
    final seciliPersonel = personeller.contains(personel) ? personel : 'Tümü';

    return Scaffold(
      backgroundColor: arkaPlan,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Randevu Takvimi',
          style: TextStyle(color: lacivert, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Günlük'),
                      icon: Icon(Icons.today),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Haftalık'),
                      icon: Icon(Icons.date_range),
                    ),
                  ],
                  selected: {haftalik},
                  onSelectionChanged: (deger) =>
                      setState(() => haftalik = deger.first),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Önceki',
                      onPressed: () => setState(() {
                        seciliGun = seciliGun.subtract(
                          Duration(days: haftalik ? 7 : 1),
                        );
                      }),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final gun = await showDatePicker(
                            context: context,
                            initialDate: seciliGun,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (gun != null && mounted) {
                            setState(() => seciliGun = gun);
                          }
                        },
                        icon: const Icon(Icons.calendar_month),
                        label: Text(
                          haftalik
                              ? '${_tarihYaz(gunler.first)} - ${_tarihYaz(gunler.last)}'
                              : _tarihYaz(seciliGun),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sonraki',
                      onPressed: () => setState(() {
                        seciliGun = seciliGun.add(
                          Duration(days: haftalik ? 7 : 1),
                        );
                      }),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(seciliPersonel),
                  initialValue: seciliPersonel,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Personel filtresi',
                    border: OutlineInputBorder(),
                  ),
                  items: personeller
                      .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                      .toList(),
                  onChanged: (deger) =>
                      setState(() => personel = deger ?? 'Tümü'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: gunler.length,
              itemBuilder: (context, index) {
                final gun = gunler[index];
                final liste = _gununRandevulari(gun);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(14, 3, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_tarihYaz(gun)} • ${liste.length} randevu',
                        style: const TextStyle(
                          color: lacivert,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (liste.isEmpty)
                        const Card(
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(Icons.event_busy_outlined),
                            title: Text('Bu gün için randevu bulunmuyor.'),
                          ),
                        ),
                      ...liste.map(_randevuKarti),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
