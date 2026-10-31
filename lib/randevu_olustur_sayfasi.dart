
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class RandevuOlusturSayfasi extends StatefulWidget {
  final String isletmeAdi;
  final List<Map<String, dynamic>> secilenHizmetler;
  final List<Map<String, dynamic>> personeller;
  final int toplamFiyat;
  final int toplamSure;

  const RandevuOlusturSayfasi({
    super.key,
    required this.isletmeAdi,
    required this.secilenHizmetler,
    required this.personeller,
    required this.toplamFiyat,
    required this.toplamSure,
  });

  @override
  State<RandevuOlusturSayfasi> createState() =>
      _RandevuOlusturSayfasiState();
}

class _RandevuOlusturSayfasiState
    extends State<RandevuOlusturSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);

  static const String apiUrl = String.fromEnvironment('API_URL');
  static const FlutterSecureStorage guvenliDepo =
      FlutterSecureStorage();

  int? seciliPersonelId;
  String? seciliPersonel;
  DateTime? seciliTarih;
  String? seciliSaat;

  bool kaydediliyor = false;
  bool saatlerYukleniyor = false;
  String? saatHatasi;
  List<String> saatler = [];
  int _saatIstekNo = 0;

  String apiGunYazisi(DateTime tarih) {
    String iki(int deger) => deger.toString().padLeft(2, '0');
    return '${tarih.year}-${iki(tarih.month)}-${iki(tarih.day)}';
  }

  Future<void> musaitSaatleriYukle() async {
    final istekNo = ++_saatIstekNo;
    final personelId = seciliPersonelId;
    final tarih = seciliTarih;
    setState(() {
      seciliSaat = null;
      saatler = [];
      saatHatasi = null;
      saatlerYukleniyor = personelId != null && tarih != null;
    });
    if (personelId == null || tarih == null) return;

    try {
      final token = await guvenliDepo.read(key: 'atlas_access_token');
      if (token == null || token.isEmpty) {
        throw Exception('Oturum bulunamadı. Yeniden giriş yapın.');
      }
      if (apiUrl.isEmpty) {
        throw Exception('API_URL tanımlanmamış. Uygulamayı --dart-define ile başlatın.');
      }
      final uri = Uri.parse('$apiUrl/api/musteri/musait-saatler').replace(
        queryParameters: {
          'personelId': '$personelId',
          'tarih': apiGunYazisi(tarih),
          'sureDakika': '${widget.toplamSure}',
        },
      );
      final cevap = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 20));
      final veri = jsonDecode(utf8.decode(cevap.bodyBytes));
      if (cevap.statusCode != 200) {
        final aciklama = veri is Map ? veri['mesaj'] : null;
        throw Exception(aciklama?.toString() ?? 'HTTP ${cevap.statusCode}');
      }
      if (veri is! Map || veri['saatler'] is! List) {
        throw const FormatException('Müsait saat yanıtı geçersiz.');
      }
      final gelen = (veri['saatler'] as List)
          .whereType<String>()
          .where((s) => RegExp(r'^\d{2}:\d{2}$').hasMatch(s))
          .toList()..sort();
      if (!mounted || istekNo != _saatIstekNo) return;
      setState(() => saatler = gelen);
    } catch (e) {
      if (!mounted || istekNo != _saatIstekNo) return;
      setState(() => saatHatasi = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted && istekNo == _saatIstekNo) {
        setState(() => saatlerYukleniyor = false);
      }
    }
  }

  String tarihYazisi(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  DateTime baslangicOlustur(String saat) {
    final parcalar = saat.split(':');
    final tarih = seciliTarih!;

    return DateTime(
      tarih.year,
      tarih.month,
      tarih.day,
      int.parse(parcalar[0]),
      int.parse(parcalar[1]),
    );
  }

  // API'ye saat dilimi dönüşümü olmadan yerel tarih gönderilir.
  String apiTarihYazisi(DateTime tarih) {
    String iki(int deger) => deger.toString().padLeft(2, '0');

    return '${tarih.year}-${iki(tarih.month)}-${iki(tarih.day)}'
        'T${iki(tarih.hour)}:${iki(tarih.minute)}:00';
  }

  // Liste API'den gelir; kayıt sırasında API yeniden kontrol eder.
  bool saatSecilebilir(String saat) =>
      !saatlerYukleniyor && saatHatasi == null &&
      saatler.contains(saat) && seciliPersonelId != null &&
      seciliTarih != null &&
      baslangicOlustur(saat).isAfter(DateTime.now().add(const Duration(minutes: 2)));

  void mesaj(String metin) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(metin)),
    );
  }

  Future<void> tarihSec() async {
    final bugun = DateUtils.dateOnly(DateTime.now());

    final secilen = await showDatePicker(
      context: context,
      initialDate: seciliTarih ?? bugun,
      firstDate: bugun,
      lastDate: bugun.add(const Duration(days: 60)),
      helpText: 'Randevu Tarihi Seç',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );

    if (secilen != null && mounted) {
      setState(() {
        seciliTarih = secilen;
        seciliSaat = null;
      });
      await musaitSaatleriYukle();
    }
  }

  Future<void> randevuKontrol() async {
    if (kaydediliyor) return;

    if (seciliPersonelId == null ||
        seciliTarih == null ||
        seciliSaat == null) {
      mesaj('Personel, tarih ve saat seçiniz.');
      return;
    }

    if (!saatSecilebilir(seciliSaat!)) {
      setState(() => seciliSaat = null);
      mesaj('Bu saat uygun değil. Başka saat seçiniz.');
      return;
    }

    final baslangic = baslangicOlustur(seciliSaat!);
    final bitis = baslangic.add(
      Duration(minutes: widget.toplamSure),
    );

    final onay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randevu Özeti'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('İşletme: ${widget.isletmeAdi}'),
              Text('Personel: $seciliPersonel'),
              Text('Tarih: ${tarihYazisi(seciliTarih!)}'),
              Text(
                'Saat: $seciliSaat - '
                '${bitis.hour.toString().padLeft(2, '0')}:'
                '${bitis.minute.toString().padLeft(2, '0')}',
              ),
              Text(
                'Hizmetler: '
                '${widget.secilenHizmetler.map((h) => h['ad']).join(', ')}',
              ),
              Text('Toplam süre: ${widget.toplamSure} dk'),
              Text('Toplam tutar: ${widget.toplamFiyat} ₺'),
              const SizedBox(height: 12),
              const Text(
                'Randevunuz işletmenin sistemine kaydedilecektir.',
                style: TextStyle(color: Colors.green),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Geri Dön'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (!mounted || onay != true) return;

    await gercekRandevuOlustur(baslangic);
  }

  Future<void> gercekRandevuOlustur(DateTime baslangic) async {
    if (kaydediliyor) return;

    final hizmetIdleri = <int>[];

    for (final hizmet in widget.secilenHizmetler) {
      final id = int.tryParse('${hizmet['id'] ?? ''}');

      if (id == null || id <= 0) {
        mesaj('Hizmet bilgileri eksik. Lütfen yeniden seçiniz.');
        return;
      }

      hizmetIdleri.add(id);
    }

    if (hizmetIdleri.isEmpty || seciliPersonelId == null) {
      mesaj('Hizmet ve personel seçimi zorunludur.');
      return;
    }

    setState(() => kaydediliyor = true);

    try {
      final token = await guvenliDepo.read(
        key: 'atlas_access_token',
      );

      if (token == null || token.isEmpty) {
        mesaj('Oturum bulunamadı. Lütfen tekrar giriş yapınız.');
        return;
      }

      final cevap = await http.post(
        Uri.parse('$apiUrl/api/musteri/randevular'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'personelId': seciliPersonelId,
          'baslangic': apiTarihYazisi(baslangic),
          'hizmetIdleri': hizmetIdleri,
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;

      if (cevap.statusCode == 200 ||
          cevap.statusCode == 201) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Randevunuz Oluşturuldu'),
            content: const Text(
              'Randevunuz başarıyla kaydedildi. '
              'Randevularım bölümünden görüntüleyebilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );

        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        String hataMesaji =
            'Randevu oluşturulamadı (${cevap.statusCode}).';

        try {
          final veri = jsonDecode(
            utf8.decode(cevap.bodyBytes),
          );

          if (veri is Map) {
            final aciklama =
                veri['mesaj'] ?? veri['message'] ?? veri['title'];

            if (aciklama != null) {
              hataMesaji = aciklama.toString();
            }
          }
        } catch (_) {
          // Sunucu JSON dışında bir cevap göndermiş olabilir.
        }

        mesaj(hataMesaji);
        if (cevap.statusCode == 409) {
          await musaitSaatleriYukle();
        }
      }
    } catch (e) {
      mesaj('Sunucu bağlantı hatası: $e');
    } finally {
      if (mounted) {
        setState(() => kaydediliyor = false);
      }
    }
  }

  Widget bolumBasligi(String baslik) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        baslik,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: lacivert,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Randevu Oluştur'),
        backgroundColor: Colors.white,
        foregroundColor: lacivert,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lacivert,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SEÇİLEN İŞLETME',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isletmeAdi,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${widget.secilenHizmetler.length} hizmet • '
                  '${widget.toplamSure} dakika • '
                  '${widget.toplamFiyat} ₺',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          bolumBasligi('1. Personel Seçimi'),

          if (widget.personeller.isEmpty)
            const Text(
              'Bu işletmede aktif personel bulunamadı.',
              style: TextStyle(color: Colors.red),
            ),

          ...widget.personeller.map((p) {
            final id = (p['id'] as num).toInt();
            final ad = p['adSoyad']?.toString() ?? '';

            return Card(
              color: Colors.white,
              child: RadioListTile<int>(
                title: Text(ad),
                secondary: const Icon(
                  Icons.person_outline,
                  color: mavi,
                ),
                value: id,
                groupValue: seciliPersonelId,
                onChanged: (v) {
                  setState(() {
                    seciliPersonelId = v;
                    seciliPersonel = ad;
                    seciliSaat = null;
                  });
                  musaitSaatleriYukle();
                },
              ),
            );
          }),

          bolumBasligi('2. Randevu Tarihi'),

          Card(
            color: Colors.white,
            child: ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: mavi,
              ),
              title: Text(
                seciliTarih == null
                    ? 'Tarih Seçiniz'
                    : tarihYazisi(seciliTarih!),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: tarihSec,
            ),
          ),

          bolumBasligi('3. Randevu Saati'),

          if (seciliTarih == null || seciliPersonelId == null)
            const Text('Önce personel ve tarih seçiniz.',
                style: TextStyle(color: Color(0xFF64748B)))
          else if (saatlerYukleniyor)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (saatHatasi != null)
            Card(child: ListTile(
              leading: const Icon(Icons.error_outline, color: Colors.red),
              title: const Text('Müsait saatler yüklenemedi'),
              subtitle: Text(saatHatasi!),
              trailing: IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: musaitSaatleriYukle,
              ),
            ))
          else if (saatler.isEmpty)
            const Card(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bu gün için uygun randevu saati bulunamadı. '
                  'Başka bir gün veya personel seçiniz.'),
            ))
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: saatler.map((saat) {
                return ChoiceChip(
                  label: Text(saat),
                  selected: seciliSaat == saat,
                  selectedColor: const Color(0xFFDBEAFE),
                  onSelected: saatSecilebilir(saat)
                      ? (_) => setState(() => seciliSaat = saat)
                      : null,
                );
              }).toList(),
            ),

          const SizedBox(height: 28),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: kaydediliyor ? null : randevuKontrol,
              style: ElevatedButton.styleFrom(
                backgroundColor: mavi,
                foregroundColor: Colors.white,
              ),
              child: kaydediliyor
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Randevuyu Kontrol Et',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
