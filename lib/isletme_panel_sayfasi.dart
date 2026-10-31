import 'isletme_galeri_sayfasi.dart';
import 'isletme_yeni_randevu_sayfasi.dart';
import 'isletme_degerlendirmeleri_sayfasi.dart';
import 'bildirim_merkezi_sayfasi.dart';
import 'personel_izinleri_sayfasi.dart';
import 'isletme_randevu_islem_api.dart';
import 'isletme_bilgileri_api.dart';
import 'isletme_rapor_sayfasi.dart';
import 'personel_api.dart';
import 'hizmet_api.dart';
import 'isletme_randevu_api.dart';
import 'randevu_takvimi_sayfasi.dart';
import 'isletme_bilgileri_sayfasi.dart';
import 'calisma_saatleri_sayfasi.dart';
import 'bildirim_merkezi_api.dart';




import 'package:flutter/material.dart';

class IsletmePanelSayfasi extends StatefulWidget {
  const IsletmePanelSayfasi({super.key, this.bildirimRandevuId});
  final int? bildirimRandevuId;

  @override
  State<IsletmePanelSayfasi> createState() =>
      _IsletmePanelSayfasiState();
}

class _IsletmePanelSayfasiState extends State<IsletmePanelSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  static const arkaPlan = Color(0xFFF1F5FB);

  int seciliMenu = 0;
  int okunmamisBildirim = 0;

  Future<void> bildirimSayisiniYukle() async {
    try {
      final sonuc = await BildirimMerkeziApi.listele(sayfaBoyutu: 1);
      if (mounted) setState(() => okunmamisBildirim = (sonuc['okunmamis'] as num?)?.toInt() ?? 0);
    } catch (_) { /* Bildirim servisi erişilemezse panel çalışmaya devam eder. */ }
  }

  Future<void> bildirimleriAc() async {
    final id = await Navigator.push<int>(context, MaterialPageRoute(
      builder: (_) => const BildirimMerkeziSayfasi(),
    ));
    if (!mounted) return;
    await bildirimSayisiniYukle();
    if (!mounted || id == null) return;
    setState(() { seciliMenu = 1; seciliBildirimRandevuId = id; });
    await randevulariYukle();
  }

  int? seciliBildirimRandevuId;
  final Map<String, String> isletmeBilgileri = {
    'ad': '', 'telefon': '', 'adres': '', 'aciklama': '', 'instagram': '',
  };

  Future<void> isletmeBilgileriniYukle() async {
    try {
      final veri = await IsletmeBilgileriApi.getir();
      if (!mounted) return;
      setState(() {
        for (final key in isletmeBilgileri.keys) {
          isletmeBilgileri[key] = veri[key]?.toString() ?? '';
        }
      });
    } catch (_) {
      // Profil ekranında ayrıntılı hata ve yeniden deneme gösterilir.
    }
  }

  final List<Map<String, dynamic>> randevular = [];
  Map<String, dynamic> gunlukOzet = {};
  bool randevularYukleniyor = false;
  String? randevuHatasi;
  final Set<int> islemdekiRandevular = {};

  Future<void> randevulariYukle() async {
    if (!mounted || randevularYukleniyor) return;
    setState(() { randevularYukleniyor = true; randevuHatasi = null; });
    try {
      final liste = await IsletmeRandevuApi.listele();
      final ozet = await IsletmeRandevuApi.gunlukOzet();
      if (!mounted) return;
      setState(() {
        randevular
          ..clear()
          ..addAll(liste.map((r) {
            final tarih = DateTime.tryParse(r['baslangic']?.toString() ?? '');
            final hizmetListesi = r['hizmetler'];
            final hizmetler = hizmetListesi is List ? hizmetListesi : [];
            return <String, dynamic>{
              ...r,
              'musteri': (r['musteri']?.toString().trim().isNotEmpty ?? false)
                  ? r['musteri'].toString() : 'Müşteri',
              'personel': r['personel']?.toString() ?? '',
              'hizmet': hizmetler.map((h) => h is Map ? (h['ad'] ?? '').toString() : '').join(', '),
              'saat': tarih == null ? '--:--' :
                  '${tarih.hour.toString().padLeft(2, '0')}:${tarih.minute.toString().padLeft(2, '0')}',
              'fiyat': r['toplamFiyat'] ?? 0,
            };
          }));
        gunlukOzet = ozet;
      });
    } catch (e) {
      if (mounted) setState(() => randevuHatasi = e.toString());
    } finally {
      if (mounted) setState(() => randevularYukleniyor = false);
    }
  }

 Future<void> yeniRandevuAc() async {
  try {
    // İşletmenin aktif personellerini getir.
    final personeller = await PersonelApi.listele();
    debugPrint('PERSONEL API SONUCU: $personeller');

    final aktifPersoneller = personeller.where(
      (p) => p['aktifMi'] == true && p['subeId'] != null,
    ).toList();

    if (!mounted) return;

    if (aktifPersoneller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Randevu oluşturmak için önce aktif personel eklemelisiniz.',
          ),
        ),
      );
      return;
    }

    // Personellerin bağlı olduğu şubeleri bul.
    final subeIdleri = aktifPersoneller
        .map((p) => (p['subeId'] as num).toInt())
        .toSet()
        .toList();

    int subeId = subeIdleri.first;

    // Birden fazla şube varsa kullanıcıya seçtir.
    if (subeIdleri.length > 1) {
      final secilen = await showDialog<int>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Şube Seçin'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: subeIdleri.map((id) {
              return ListTile(
                title: Text('Şube $id'),
                onTap: () => Navigator.pop(dialogContext, id),
              );
            }).toList(),
          ),
        ),
      );

      if (!mounted || secilen == null) return;
      subeId = secilen;
    }

    final sonuc = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => IsletmeYeniRandevuSayfasi(
          subeId: subeId,
        ),
      ),
    );

    if (!mounted || sonuc != true) return;

    setState(() => seciliMenu = 1);
    await randevulariYukle();
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Randevu ekranı açılamadı: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

  Future<void> randevuTamamla(int id) async {
    if (islemdekiRandevular.contains(id)) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      await IsletmeRandevuApi.tamamla(id);
      await randevulariYukle();
      if (randevuHatasi != null) {
        mesaj('Randevu tamamlandı ancak liste yenilenemedi: $randevuHatasi');
      } else {
        mesaj('Randevu başarıyla tamamlandı.');
      }
    } catch (e) {
      mesaj('Randevu tamamlanamadı: $e');
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  Future<void> randevuIptalEt(int id) async {
    if (islemdekiRandevular.contains(id)) return;
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Randevuyu İptal Et'),
        content: const Text('Bu randevu iptal edilecek. İşlemi onaylıyor musunuz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('İptal Et', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (!mounted || onay != true) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      await IsletmeRandevuIslemApi.iptal(id);
      await randevulariYukle();
      if (!mounted) return;
      mesaj(randevuHatasi == null ? 'Randevu iptal edildi.'
          : 'İptal edildi ancak liste yenilenemedi: $randevuHatasi');
    } catch (e) {
      mesaj('Randevu iptal edilemedi: $e');
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  Future<void> randevuErtele(int id, DateTime eskiBaslangic) async {
    if (islemdekiRandevular.contains(id)) return;
    final bugun = DateUtils.dateOnly(DateTime.now());
    final ilkGun = eskiBaslangic.isAfter(bugun) ? eskiBaslangic : bugun;
    final yeniGun = await showDatePicker(
      context: context,
      initialDate: ilkGun,
      firstDate: bugun,
      lastDate: bugun.add(const Duration(days: 365)),
    );
    if (!mounted || yeniGun == null) return;
    final saat = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(eskiBaslangic),
    );
    if (!mounted || saat == null) return;
    final yeniBaslangic = DateTime(yeniGun.year, yeniGun.month, yeniGun.day,
        saat.hour, saat.minute);
    if (!yeniBaslangic.isAfter(DateTime.now())) {
      mesaj('Lütfen gelecekte bir tarih ve saat seçin.');
      return;
    }
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Randevuyu Ertele'),
        content: Text('Randevu ${yeniGun.day.toString().padLeft(2, '0')}.'
            '${yeniGun.month.toString().padLeft(2, '0')}.${yeniGun.year} '
            '${saat.format(dialogContext)} saatine ertelensin mi?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ertele')),
        ],
      ),
    );
    if (!mounted || onay != true) return;
    setState(() => islemdekiRandevular.add(id));
    try {
      await IsletmeRandevuIslemApi.ertele(id, yeniBaslangic);
      await randevulariYukle();
      if (!mounted) return;
      mesaj(randevuHatasi == null ? 'Randevu başarıyla ertelendi.'
          : 'Ertelendi ancak liste yenilenemedi: $randevuHatasi');
    } catch (e) {
      mesaj('Randevu ertelenemedi: $e');
    } finally {
      if (mounted) setState(() => islemdekiRandevular.remove(id));
    }
  }

  @override
  void initState() {
    super.initState();
    seciliBildirimRandevuId = widget.bildirimRandevuId;
    if (widget.bildirimRandevuId != null) seciliMenu = 1;
    bildirimSayisiniYukle();
    randevulariYukle();
    isletmeBilgileriniYukle();
    hizmetleriYukle();
    personelleriYukle();
  }

  final List<Map<String, dynamic>> hizmetler = [];
  bool hizmetlerYukleniyor = false;
  String? hizmetHatasi;

  Future<void> hizmetleriYukle() async {
    if (!mounted) return;
    setState(() { hizmetlerYukleniyor = true; hizmetHatasi = null; });
    try {
      final kayitlar = await HizmetApi.listele();
      if (!mounted) return;
      setState(() {
        hizmetler
          ..clear()
          ..addAll(kayitlar.map((h) => <String, dynamic>{
            'id': h['id'],
            'ad': h['ad'],
            'fiyat': h['fiyat'],
            'sure': h['sureDakika'],
            'aktifMi': h['aktifMi'],
          }));
      });
    } catch (e) {
      if (mounted) setState(() => hizmetHatasi = e.toString());
    } finally {
      if (mounted) setState(() => hizmetlerYukleniyor = false);
    }
  }

  final List<Map<String, dynamic>> personeller = [];
  bool personellerYukleniyor = false;
  String? personelHatasi;

  Future<void> personelleriYukle() async {
    if (!mounted) return;
    setState(() { personellerYukleniyor = true; personelHatasi = null; });
    try {
      final kayitlar = await PersonelApi.listele();
      if (!mounted) return;
      setState(() {
        personeller
          ..clear()
          ..addAll(kayitlar.map((p) => <String, dynamic>{
            'id': p['id'],
            'ad': p['adSoyad'],
            'telefon': p['telefon'],
            'unvan': p['unvan'],
            'aktif': p['aktifMi'] == true,
          }));
      });
    } catch (e) {
      if (mounted) setState(() => personelHatasi = e.toString());
    } finally {
      if (mounted) setState(() => personellerYukleniyor = false);
    }
  }

  void mesaj(String icerik) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(icerik),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // HİZMET EKLEME VE DÜZENLEME FORMU
  Future<void> hizmetFormuAc({int? index}) async {
    final duzenleme = index != null;
    final mevcut = duzenleme ? hizmetler[index] : null;

    final formKey = GlobalKey<FormState>();

    final adController = TextEditingController(
      text: mevcut?['ad']?.toString() ?? '',
    );

    final fiyatController = TextEditingController(
      text: mevcut == null
          ? ''
          : mevcut['fiyat'].toString(),
    );

    final sureController = TextEditingController(
      text: mevcut == null
          ? ''
          : mevcut['sure'].toString(),
    );

    try {
      final sonuc = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              duzenleme ? 'Hizmet Düzenle' : 'Yeni Hizmet Ekle',
              style: const TextStyle(
                color: lacivert,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: adController,
                        textCapitalization:
                            TextCapitalization.words,
                        decoration: const InputDecoration(
                          labelText: 'Hizmet Adı',
                          prefixIcon:
                              Icon(Icons.content_cut),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Hizmet adını giriniz.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: fiyatController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Hizmet Fiyatı',
                          suffixText: '₺',
                          prefixIcon:
                              Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final fiyat = double.tryParse(
                            (value ?? '')
                                .trim()
                                .replaceAll(',', '.'),
                          );

                          if (fiyat == null || fiyat <= 0) {
                            return 'Geçerli fiyat giriniz.';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: sureController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Hizmet Süresi',
                          suffixText: 'dakika',
                          prefixIcon:
                              Icon(Icons.schedule_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final sure =
                              int.tryParse((value ?? '').trim());

                          if (sure == null || sure <= 0) {
                            return 'Geçerli süre giriniz.';
                          }

                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Vazgeç'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mavi,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  if (!formKey.currentState!.validate()) {
                    return;
                  }

                  Navigator.pop(dialogContext, {
                    'ad': adController.text.trim(),
                    'fiyat': double.parse(
                      fiyatController.text
                          .trim()
                          .replaceAll(',', '.'),
                    ),
                    'sure': int.parse(
                      sureController.text.trim(),
                    ),
                  });
                },
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  duzenleme ? 'Güncelle' : 'Kaydet',
                ),
              ),
            ],
          );
        },
      );

      if (!mounted || sonuc == null) return;

      try {
        final veri = <String, dynamic>{
          'ad': sonuc['ad'],
          'fiyat': sonuc['fiyat'],
          'sureDakika': sonuc['sure'],
        };
        if (duzenleme) {
          await HizmetApi.guncelle(mevcut!['id'] as int, veri);
        } else {
          await HizmetApi.ekle(veri);
        }
        await hizmetleriYukle();
        mesaj(duzenleme ? 'Hizmet güncellendi.' : 'Hizmet eklendi.');
      } catch (e) {
        mesaj('Hizmet kaydedilemedi: $e');
      }
    } finally {
      // Diyalog kapandıktan sonra controller'ları temizle.
      // Sonraki kareyi beklemek kapanış animasyonunu korur.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adController.dispose();
        fiyatController.dispose();
        sureController.dispose();
      });
    }
  }

  // HİZMET SİLME
  Future<void> hizmetSil(int index) async {
    final hizmetAdi = hizmetler[index]['ad'].toString();

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hizmeti Sil'),
          content: Text(
            '"$hizmetAdi" hizmetini silmek '
            'istediğinize emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );

    if (!mounted || onay != true) return;

    try {
      await HizmetApi.pasiflestir(hizmetler[index]['id'] as int);
      await hizmetleriYukle();
      mesaj('Hizmet pasifleştirildi.');
    } catch (e) {
      mesaj('İşlem başarısız: $e');
    }
  }

  // PERSONEL EKLEME / DÜZENLEME
  Future<void> personelFormuAc({int? index}) async {
    final duzenleme = index != null;
    final mevcut = duzenleme ? personeller[index] : null;
    final formKey = GlobalKey<FormState>();
    final adController = TextEditingController(text: mevcut?['ad'] ?? '');
    final telefonController =
        TextEditingController(text: mevcut?['telefon'] ?? '');
    final unvanController =
        TextEditingController(text: mevcut?['unvan'] ?? '');
    bool aktif = mevcut?['aktif'] ?? true;

    try {
    final sonuc = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            duzenleme ? 'Personel Düzenle' : 'Yeni Personel Ekle',
            style: const TextStyle(
              color: lacivert,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: adController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ad Soyad',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Personel adını giriniz.'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: telefonController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Telefon',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final rakamlar =
                            (value ?? '').replaceAll(RegExp(r'\D'), '');
                        if (rakamlar.length != 10 && rakamlar.length != 11) {
                          return '10 veya 11 haneli telefon giriniz.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: unvanController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Unvan (Örn. Usta Berber)',
                        prefixIcon: Icon(Icons.badge_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Personel unvanını giriniz.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Aktif Personel'),
                      subtitle: const Text('Randevu alabilen personel'),
                      value: aktif,
                      activeColor: mavi,
                      onChanged: (value) {
                        setDialogState(() => aktif = value);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Vazgeç'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: mavi,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(dialogContext, {
                  'ad': adController.text.trim(),
                  'telefon': telefonController.text.trim(),
                  'unvan': unvanController.text.trim(),
                  'aktif': aktif,
                });
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(duzenleme ? 'Güncelle' : 'Kaydet'),
            ),
          ],
        ),
      ),
    );

    // Kapanış animasyonu bittikten sonra form alanlarını temizle.
    if (!mounted || sonuc == null) return;
    try {
      final veri = <String, dynamic>{
        'adSoyad': sonuc['ad'],
        'telefon': sonuc['telefon'],
        'unvan': sonuc['unvan'],
        'aktifMi': sonuc['aktif'],
      };
      if (duzenleme) {
        await PersonelApi.guncelle(mevcut!['id'] as int, veri);
      } else {
        await PersonelApi.ekle(veri);
      }
      await personelleriYukle();
      mesaj(duzenleme ? 'Personel güncellendi.' : 'Yeni personel eklendi.');
    } catch (e) {
      mesaj('Personel kaydedilemedi: $e');
    }
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adController.dispose();
        telefonController.dispose();
        unvanController.dispose();
      });
    }
  }

  Future<void> personelSil(int index) async {
    final ad = personeller[index]['ad'].toString();
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Personeli Sil'),
        content: Text('"$ad" adlı personeli silmek istiyor musunuz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (!mounted || onay != true) return;
    try {
      await PersonelApi.pasiflestir(personeller[index]['id'] as int);
      await personelleriYukle();
      mesaj('Personel pasifleştirildi.');
    } catch (e) {
      mesaj('Personel pasifleştirilemedi: $e');
    }
  }

  Future<void> personelDurumDegistir(int index, bool aktif) async {
    try {
      await PersonelApi.durumDegistir(personeller[index]['id'] as int, aktif);
      await personelleriYukle();
      mesaj(aktif ? 'Personel aktif edildi.' : 'Personel pasif edildi.');
    } catch (e) {
      mesaj('Personel durumu değiştirilemedi: $e');
    }
  }

  Widget bilgiKarti({
    required String baslik,
    required String deger,
    required IconData ikon,
    required Color renk,
  }) {
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
          Icon(ikon, color: renk, size: 26),
          const SizedBox(height: 9),
          Text(
            deger,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
              color: lacivert,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            baslik,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget randevuKarti(Map<String, dynamic> randevu) {
    final durum = randevu['durum']?.toString() ?? '';
    final tamamlandi = durum == 'Tamamlandi';
    final onaylandi = durum == 'Onaylandi';
    final id = randevu['id'] as int;
    final musteri = randevu['musteri']?.toString() ?? 'Müşteri';
    final fiyat = (randevu['fiyat'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final baslangic = DateTime.tryParse(randevu['baslangic']?.toString() ?? '');
    final tarih = baslangic == null ? '' :
        '${baslangic.day.toString().padLeft(2, '0')}.${baslangic.month.toString().padLeft(2, '0')}.${baslangic.year}';
    final durumMetni = {
      'Onaylandi': 'Onaylandı', 'Tamamlandi': 'Tamamlandı',
      'IptalEdildi': 'İptal Edildi', 'Gelmedi': 'Gelmedi'
    }[durum] ?? durum;

    return Card(
      color: seciliBildirimRandevuId == id ? const Color(0xFFEFF6FF) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: seciliBildirimRandevuId == id ? mavi : const Color(0xFFE2E8F0),
          width: seciliBildirimRandevuId == id ? 2 : 1,
        ),
      ),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEFF4FF),
                child: Text(musteri.isEmpty ? '?' : musteri[0].toUpperCase(),
                    style: const TextStyle(color: mavi)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(musteri, style: const TextStyle(
                      fontWeight: FontWeight.bold, color: lacivert, fontSize: 16)),
                  Text(randevu['hizmet']?.toString() ?? '',
                      style: const TextStyle(color: Color(0xFF64748B))),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(randevu['saat']?.toString() ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: mavi)),
                Text(tarih, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ]),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.person_outline, size: 17, color: Color(0xFF64748B)),
              const SizedBox(width: 5),
              Expanded(child: Text('Personel: ${randevu['personel'] ?? ''}')),
              Text('$fiyat ₺', style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Chip(label: Text(durumMetni),
                backgroundColor: tamamlandi ? const Color(0xFFDCFCE7) :
                    onaylandi ? const Color(0xFFDBEAFE) :
                    durum == 'IptalEdildi' ? const Color(0xFFFEE2E2) :
                    const Color(0xFFF1F5F9),
                side: BorderSide.none),
              const Spacer(),
              if (onaylandi && baslangic != null &&
                  baslangic.isAfter(DateTime.now()))
                PopupMenuButton<String>(
                  tooltip: 'Randevu işlemleri',
                  icon: const Icon(Icons.more_vert, color: mavi),
                  enabled: !islemdekiRandevular.contains(id),
                  onSelected: (secim) {
                    if (secim == 'ertele') randevuErtele(id, baslangic);
                    if (secim == 'iptal') randevuIptalEt(id);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'ertele', child: Text('Ertele')),
                    PopupMenuItem(value: 'iptal', child: Text('İptal Et')),
                  ],
                ),
              if (onaylandi)
                TextButton(
                  onPressed: islemdekiRandevular.contains(id) ? null : () => randevuTamamla(id),
                  child: Text(islemdekiRandevular.contains(id) ? 'İşleniyor...' : 'Tamamla'),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget randevuDurumBilgisi() {
    if (randevularYukleniyor && randevular.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(20),
          child: CircularProgressIndicator()));
    }
    if (randevuHatasi != null) {
      return ListTile(
        title: Text('Randevular yüklenemedi: $randevuHatasi'),
        trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: randevulariYukle),
      );
    }
    if (randevular.isEmpty) {
      return const Padding(padding: EdgeInsets.all(20),
          child: Center(child: Text('Henüz randevu bulunmuyor.')));
    }
    return const SizedBox.shrink();
  }

  // Premium ana sayfa: mevcut API ve diğer yönetim ekranları korunur.
  Widget _ozetKutusu(String baslik, String deger, IconData ikon, Color vurgu) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: vurgu.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(ikon, color: vurgu, size: 20),
        ),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(deger, style: const TextStyle(
            color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800,
          )),
        ),
        const SizedBox(height: 5),
        Text(baslik, style: const TextStyle(
          color: Color(0xFFCCD8EE), fontSize: 12,
        )),
      ]),
    );
  }

  Widget _hizliIslem(String baslik, IconData ikon, Color renk, VoidCallback tikla) {
    return InkWell(
      onTap: tikla,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EBF5)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(ikon, color: renk, size: 24),
          ),
          const SizedBox(height: 9),
          Text(baslik, textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
              color: lacivert)),
        ]),
      ),
    );
  }

  Widget anaSayfa() {
    final simdi = DateTime.now();
    final bugun = DateUtils.dateOnly(simdi);
    final bugununRandevulari = randevular.where((r) {
      final baslangic = DateTime.tryParse(r['baslangic']?.toString() ?? '');
      return baslangic != null && DateUtils.isSameDay(baslangic, bugun);
    }).toList()
      ..sort((a, b) => (a['baslangic']?.toString() ?? '')
          .compareTo(b['baslangic']?.toString() ?? ''));
    final yaklasan = bugununRandevulari.where((r) {
      final baslangic = DateTime.tryParse(r['baslangic']?.toString() ?? '');
      return baslangic != null && !baslangic.isBefore(simdi) &&
          r['durum']?.toString() == 'Onaylandi';
    }).toList();
    final toplam = gunlukOzet['toplamRandevu'] ?? 0;
    final tamamlanan = gunlukOzet['tamamlanan'] ?? 0;
    final onaylanan = gunlukOzet['bekleyen'] ?? 0;
    final tutar = (gunlukOzet['gunlukCiro'] as num?)?.toStringAsFixed(2) ?? '0.00';
    final tarihMetni = '${bugun.day.toString().padLeft(2, '0')}.'
        '${bugun.month.toString().padLeft(2, '0')}.${bugun.year}';

    return RefreshIndicator(
      color: mavi,
      onRefresh: randevulariYukle,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0B1733), Color(0xFF172F62), Color(0xFF245AD4)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [BoxShadow(
                color: lacivert.withValues(alpha: 0.15),
                blurRadius: 20, offset: const Offset(0, 10),
              )],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.auto_awesome, size: 14, color: Color(0xFF93C5FD)),
                    SizedBox(width: 6),
                    Text('OVORANDEVU BUSINESS', style: TextStyle(
                      fontSize: 10, letterSpacing: 1.2,
                      color: Colors.white, fontWeight: FontWeight.w800,
                    )),
                  ]),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Verileri yenile',
                  onPressed: randevularYukleniyor ? null : randevulariYukle,
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                ),
              ]),
              const SizedBox(height: 17),
              Text(isletmeBilgileri['ad']?.trim().isNotEmpty == true
                  ? isletmeBilgileri['ad']! : 'İşletme Paneli',
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white,
                    fontSize: 25, fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('Bugünün işletme özeti  •  $tarihMetni',
                  style: const TextStyle(color: Color(0xFFC4D3ED), fontSize: 12)),
              const SizedBox(height: 20),
              LayoutBuilder(builder: (context, constraints) {
                final kutuGenisligi = (constraints.maxWidth - 10) / 2;
                return Wrap(spacing: 10, runSpacing: 10, children: [
                  SizedBox(width: kutuGenisligi, child: _ozetKutusu(
                      'Bugünkü Randevu', '$toplam', Icons.calendar_today_rounded,
                      const Color(0xFF93C5FD))),
                  SizedBox(width: kutuGenisligi, child: _ozetKutusu(
                      'Tamamlanan', '$tamamlanan', Icons.task_alt_rounded,
                      const Color(0xFF86EFAC))),
                  SizedBox(width: kutuGenisligi, child: _ozetKutusu(
                      'Onaylanan', '$onaylanan', Icons.schedule_rounded,
                      const Color(0xFFFDE68A))),
                  SizedBox(width: kutuGenisligi, child: _ozetKutusu(
                      'Hizmet Tutarı', '$tutar ₺', Icons.payments_outlined,
                      const Color(0xFFC4B5FD))),
                ]);
              }),
            ]),
          ),
          const SizedBox(height: 23),
          const Text('Hızlı İşlemler', style: TextStyle(
              color: lacivert, fontSize: 19, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _hizliIslem('Randevular', Icons.event_note_rounded,
                mavi, () => setState(() => seciliMenu = 1))),
            const SizedBox(width: 9),
            Expanded(child: _hizliIslem('Personel', Icons.groups_rounded,
                const Color(0xFF0D9488), () => setState(() => seciliMenu = 3))),
            const SizedBox(width: 9),
            Expanded(child: _hizliIslem('Hizmetler', Icons.content_cut_rounded,
                const Color(0xFF7C3AED), () => setState(() => seciliMenu = 2))),
            const SizedBox(width: 9),
            Expanded(
  child: _hizliIslem(
    'Gelir / Ciro',
    Icons.account_balance_wallet_outlined,
    const Color(0xFFEA580C),
    () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const IsletmeRaporSayfasi(),
      ),
    ),
  ),
),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: yeniRandevuAc,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Yeni Randevu Oluştur'),
              style: FilledButton.styleFrom(
                backgroundColor: mavi,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            child: ListTile(
              leading: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
              title: const Text('Müşteri Değerlendirmeleri',
                  style: TextStyle(fontWeight: FontWeight.w700, color: lacivert)),
              subtitle: const Text('Puanlarınızı ve yorumları inceleyin'),
              trailing: const Icon(Icons.chevron_right),
              onTap: degerlendirmeleriAc,
            ),
          ),
          const SizedBox(height: 24),
          Row(children: [
            const Expanded(child: Text('Yaklaşan Randevular',
                style: TextStyle(color: lacivert, fontSize: 19,
                    fontWeight: FontWeight.w800))),
            TextButton(
              onPressed: () => setState(() => seciliMenu = 1),
              child: const Text('Tümünü gör'),
            ),
          ]),
          const SizedBox(height: 5),
          if (randevularYukleniyor && randevular.isEmpty)
            const Padding(padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (randevuHatasi != null)
            Card(child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.redAccent),
              title: const Text('Randevular yüklenemedi'),
              subtitle: Text(randevuHatasi!),
              trailing: IconButton(icon: const Icon(Icons.refresh),
                  onPressed: randevulariYukle),
            ))
          else if (yaklasan.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white,
                  borderRadius: BorderRadius.circular(18)),
              child: const Column(children: [
                Icon(Icons.event_available_outlined, size: 35,
                    color: Color(0xFF94A3B8)),
                SizedBox(height: 9),
                Text('Bugün için yaklaşan onaylı randevu yok.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B))),
              ]),
            )
          else
            ...yaklasan.take(4).map(randevuKarti),
          const SizedBox(height: 19),
          Row(children: [
            const Expanded(child: Text('Bugünün Programı',
                style: TextStyle(color: lacivert, fontSize: 19,
                    fontWeight: FontWeight.w800))),
            Text('${bugununRandevulari.length} randevu',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          if (bugununRandevulari.isEmpty)
            const Card(child: ListTile(
              leading: Icon(Icons.calendar_month_outlined),
              title: Text('Bugün için randevu bulunmuyor.'),
            ))
          else
            ...bugununRandevulari.take(5).map(randevuKarti),
          if (bugununRandevulari.length > 5)
            TextButton.icon(
              onPressed: () => setState(() => seciliMenu = 1),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Diğer randevuları göster'),
            ),
        ],
      ),
    );
  }

  Widget randevularSayfasi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Randevu Yönetimi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: yeniRandevuAc,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Randevu Oluştur'),
            style: FilledButton.styleFrom(
              backgroundColor: mavi,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => RandevuTakvimiSayfasi(randevular: randevular))),
          icon: const Icon(Icons.calendar_view_week),
          label: const Text('Günlük / Haftalık Takvimi Aç'),
        )),
        const SizedBox(height: 14),
        randevuDurumBilgisi(),
        ...([...randevular]..sort((a, b) {
          final aId = a['id'];
          final bId = b['id'];
          if (aId == seciliBildirimRandevuId) return -1;
          if (bId == seciliBildirimRandevuId) return 1;
          return 0;
        })).map(randevuKarti),
      ],
    );
  }

  // GÜNCELLENEN HİZMET YÖNETİMİ
  Widget hizmetlerSayfasi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Hizmet Yönetimi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'İşletmenizin sunduğu hizmetleri '
          've fiyatlarını yönetin.',
          style: TextStyle(
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [lacivert, mavi],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.content_cut,
                color: Colors.white,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Aktif Hizmetler',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${hizmetler.where((h) => h['aktifMi'] == true).length} aktif hizmet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        if (hizmetlerYukleniyor)
          const Center(child: CircularProgressIndicator()),
        if (hizmetHatasi != null)
          ListTile(
            title: Text('Hizmetler yüklenemedi: $hizmetHatasi'),
            trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: hizmetleriYukle),
          ),
        if (hizmetler.isEmpty && !hizmetlerYukleniyor && hizmetHatasi == null)
          const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 35,
            ),
            child: Center(
              child: Text(
                'Henüz hizmet eklenmedi.',
                style: TextStyle(
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),

        ...List.generate(hizmetler.length, (index) {
          final hizmet = hizmetler[index];

          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor:
                        Color(0xFFEFF4FF),
                    child: Icon(
                      Icons.content_cut,
                      color: mavi,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          hizmet['aktifMi'] == false
                              ? '${hizmet['ad']} (Pasif)'
                              : hizmet['ad'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lacivert,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${hizmet['sure']} dakika • '
                          '${hizmet['fiyat']} ₺',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Düzenle',
                    onPressed: () {
                      hizmetFormuAc(index: index);
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: mavi,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Pasifleştir',
                    onPressed: hizmet['aktifMi'] == false ? null : () {
                      hizmetSil(index);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () {
              hizmetFormuAc();
            },
            icon: const Icon(Icons.add),
            label: const Text('Yeni Hizmet Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mavi,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget personelSayfasi() {
    final aktifSayisi = personeller.where((p) => p['aktif'] == true).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Personel Yönetimi',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ekibinizi ve personel durumlarını yönetin.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [lacivert, mavi]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.groups_outlined,
                  color: Colors.white, size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aktif Personel',
                        style: TextStyle(color: Colors.white70)),
                    Text('$aktifSayisi / ${personeller.length} personel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (personellerYukleniyor)
          const Center(child: CircularProgressIndicator()),
        if (personelHatasi != null)
          ListTile(
            title: Text('Personeller yüklenemedi: $personelHatasi'),
            trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: personelleriYukle),
          ),
        if (personeller.isEmpty && !personellerYukleniyor && personelHatasi == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 35),
            child: Center(child: Text('Henüz personel eklenmedi.')),
          ),
        ...List.generate(personeller.length, (index) {
          final personel = personeller[index];
          final aktif = personel['aktif'] == true;
          return Card(
            color: Colors.white,
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEFF4FF),
                        child: Text(
                          personel['ad'].toString().substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: mavi),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(personel['ad'].toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: lacivert,
                                  fontSize: 16,
                                )),
                            const SizedBox(height: 3),
                            Text(personel['unvan'].toString(),
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                )),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Düzenle',
                        onPressed: () => personelFormuAc(index: index),
                        icon: const Icon(Icons.edit_outlined, color: mavi),
                      ),
                      IconButton(
                        tooltip: 'Sil',
                        onPressed: () => personelSil(index),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(personel['telefon'].toString())),
                      Text(aktif ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            color: aktif ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          )),
                      Switch(
                        value: aktif,
                        activeColor: mavi,
                        onChanged: (value) =>
                            personelDurumDegistir(index, value),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        SizedBox(
          height: 54,
          child: ElevatedButton.icon(
            onPressed: () => personelFormuAc(),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Yeni Personel Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mavi,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void degerlendirmeleriAc() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => const IsletmeDegerlendirmeleriSayfasi(),
    ));
  }

  Widget ayarlarSayfasi() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'İşletme Ayarları',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        const SizedBox(height: 14),
        Card(
          color: Colors.white,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.star_rate_rounded, color: Color(0xFFF59E0B)),
                title: const Text('Müşteri Değerlendirmeleri'),
                subtitle: const Text('Yıldız puanları ve müşteri yorumları'),
                trailing: const Icon(Icons.chevron_right),
                onTap: degerlendirmeleriAc,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bar_chart_outlined, color: mavi),
                title: const Text('Raporlar ve İstatistikler'),
                subtitle: const Text('Günlük, haftalık ve aylık raporlar'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const IsletmeRaporSayfasi(),
                )),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.storefront,
                  color: mavi,
                ),
                title:
                    const Text('İşletme Bilgileri'),
                trailing:
                    const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => IsletmeBilgileriSayfasi(bilgiler: isletmeBilgileri),
                  )).then((_) { if (mounted) isletmeBilgileriniYukle(); });
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: mavi),
                title: const Text('İşletme Görselleri'),
                subtitle: const Text('Logo, kapak fotoğrafı ve galeri'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const IsletmeGaleriSayfasi(),
                )),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.event_busy_outlined, color: mavi),
                title: const Text('Personel İzinleri'),
                subtitle: const Text('İzin ekle, görüntüle ve kaldır'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PersonelIzinleriSayfasi(personeller: personeller),
                )),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.schedule,
                  color: mavi,
                ),
                title:
                    const Text('Çalışma Saatleri'),
                trailing:
                    const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CalismaSaatleriSayfasi(personeller: personeller),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sayfalar = [
      anaSayfa(),
      randevularSayfasi(),
      hizmetlerSayfasi(),
      personelSayfasi(),
      ayarlarSayfasi(),
    ];

    return Scaffold(
      backgroundColor: arkaPlan,
      appBar: AppBar(
        title: const Text(
          'OVO RANDEVU İŞLETME',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: okunmamisBildirim > 0 ? '$okunmamisBildirim okunmamış bildirim' : 'Bildirimler',
            onPressed: bildirimleriAc,
            icon: Badge(
              isLabelVisible: okunmamisBildirim > 0,
              label: Text(okunmamisBildirim > 99 ? '99+' : '$okunmamisBildirim'),
              child: const Icon(Icons.notifications_outlined, color: mavi),
            ),
          ),
          IconButton(
            tooltip: 'Randevuları yenile',
            icon: const Icon(Icons.refresh, color: mavi),
            onPressed: randevularYukleniyor ? null : randevulariYukle,
          ),
        ],
      ),
      body: sayfalar[seciliMenu],
      bottomNavigationBar: NavigationBar(
        selectedIndex: seciliMenu,
        onDestinationSelected: (index) {
          setState(() {
            seciliMenu = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.dashboard_outlined,
            ),
            label: 'Panel',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.calendar_month_outlined,
            ),
            label: 'Randevu',
          ),
          NavigationDestination(
            icon: Icon(Icons.content_cut),
            label: 'Hizmet',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.groups_outlined,
            ),
            label: 'Personel',
          ),
          NavigationDestination(
            icon: Icon(
              Icons.settings_outlined,
            ),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
