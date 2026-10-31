import 'package:flutter/material.dart';

/// Yalnızca Flutter demo oturumu için ortak veri.
/// Uygulama kapatıldığında kayıtlar sıfırlanır.
class RandevuDemoDeposu extends ChangeNotifier {
  RandevuDemoDeposu._();
  static final RandevuDemoDeposu instance = RandevuDemoDeposu._();

  final List<Map<String, dynamic>> randevular = [
    {'musteri': 'Ahmet Yılmaz', 'hizmet': 'Saç Kesimi', 'personel': 'Mehmet', 'saat': '09:30', 'fiyat': 350, 'sure': 30, 'durum': 'Onaylandı', 'tarih': DateUtils.dateOnly(DateTime.now()), 'geldi': false, 'isletme': 'ATLAS Erkek Berberi'},
    {'musteri': 'Murat Demir', 'hizmet': 'Saç + Sakal', 'personel': 'Ahmet', 'saat': '11:00', 'fiyat': 550, 'sure': 50, 'durum': 'Onaylandı', 'tarih': DateUtils.dateOnly(DateTime.now()), 'geldi': false, 'isletme': 'ATLAS Erkek Berberi'},
    {'musteri': 'Emre Kaya', 'hizmet': 'Sakal Tıraşı', 'personel': 'Mehmet', 'saat': '14:00', 'fiyat': 200, 'sure': 20, 'durum': 'Tamamlandı', 'tarih': DateUtils.dateOnly(DateTime.now()), 'geldi': true, 'isletme': 'ATLAS Erkek Berberi'},
  ];

  DateTime _baslangic(Map<String, dynamic> r) {
    final gun = r['tarih'] as DateTime;
    final parca = (r['saat'] as String).split(':');
    return DateTime(gun.year, gun.month, gun.day, int.parse(parca[0]), int.parse(parca[1]));
  }

  bool musaitMi({required String isletme, required String personel, required DateTime baslangic, required int sure}) {
    final bitis = baslangic.add(Duration(minutes: sure));
    for (final r in randevular) {
      if (r['isletme'] != isletme || r['personel'] != personel || r['durum'] == 'İptal Edildi') continue;
      final digerBaslangic = _baslangic(r);
      final digerBitis = digerBaslangic.add(Duration(minutes: (r['sure'] as num?)?.toInt() ?? 30));
      if (baslangic.isBefore(digerBitis) && bitis.isAfter(digerBaslangic)) return false;
    }
    return true;
  }

  bool ekle({required String isletme, required String personel, required DateTime baslangic, required int sure, required int fiyat, required List<Map<String, dynamic>> hizmetler}) {
    if (!baslangic.isAfter(DateTime.now()) || !musaitMi(isletme: isletme, personel: personel, baslangic: baslangic, sure: sure)) return false;
    randevular.add({
      'musteri': 'Demo Müşteri',
      'isletme': isletme,
      'hizmet': hizmetler.map((h) => h['ad'].toString()).join(', '),
      'personel': personel,
      'saat': '${baslangic.hour.toString().padLeft(2, '0')}:${baslangic.minute.toString().padLeft(2, '0')}',
      'tarih': DateUtils.dateOnly(baslangic),
      'sure': sure,
      'fiyat': fiyat,
      'durum': 'Onaylandı',
      'geldi': false,
    });
    notifyListeners();
    return true;
  }

  void yenile() => notifyListeners();
}
