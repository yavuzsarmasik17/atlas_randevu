
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'personel_api.dart';
import 'hizmet_api.dart';

class IsletmeYeniRandevuSayfasi extends StatefulWidget {
  // Randevunun oluşturulacağı şube
  final int subeId;

  const IsletmeYeniRandevuSayfasi({
    super.key,
    required this.subeId,
  });

  @override
  State<IsletmeYeniRandevuSayfasi> createState() =>
      _IsletmeYeniRandevuSayfasiState();
}

class _IsletmeYeniRandevuSayfasiState
    extends State<IsletmeYeniRandevuSayfasi> {
  static const Color lacivert = Color(0xFF101F43);
  static const Color mavi = Color(0xFF2563EB);
  static const Color arkaPlan = Color(0xFFF1F5FB);

  static const String _baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://localhost:7042',
  );

  static const FlutterSecureStorage _storage =
      FlutterSecureStorage();

  final _formKey = GlobalKey<FormState>();

  final _adController = TextEditingController();
  final _telefonController = TextEditingController();

  List<Map<String, dynamic>> personeller = [];
  List<Map<String, dynamic>> hizmetler = [];

  final Set<int> secilenHizmetler = {};

  int? secilenPersonelId;
  DateTime secilenTarih = DateUtils.dateOnly(DateTime.now());
  TimeOfDay secilenSaat = const TimeOfDay(hour: 10, minute: 0);

  bool yukleniyor = true;
  bool kaydediliyor = false;
  String? hata;

  @override
  void initState() {
    super.initState();
    verileriYukle();
  }

  @override
  void dispose() {
    _adController.dispose();
    _telefonController.dispose();
    super.dispose();
  }

  int tamSayi(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  double ondalik(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  String para(dynamic value) {
    final n = ondalik(value);
    final parcalar = n.toStringAsFixed(2).split('.');

    final tam = parcalar[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );

    return '$tam,${parcalar[1]} ₺';
  }

  String tarihYaz(DateTime tarih) {
    return '${tarih.day.toString().padLeft(2, '0')}.'
        '${tarih.month.toString().padLeft(2, '0')}.'
        '${tarih.year}';
  }

  String saatYaz(TimeOfDay saat) {
    return '${saat.hour.toString().padLeft(2, '0')}:'
        '${saat.minute.toString().padLeft(2, '0')}';
  }

  int get toplamSure {
    return hizmetler
        .where((h) => secilenHizmetler.contains(tamSayi(h['id'])))
        .fold<int>(
          0,
          (toplam, h) => toplam + tamSayi(h['sureDakika']),
        );
  }

  double get toplamFiyat {
    return hizmetler
        .where((h) => secilenHizmetler.contains(tamSayi(h['id'])))
        .fold<double>(
          0,
          (toplam, h) => toplam + ondalik(h['fiyat']),
        );
  }

  Future<void> verileriYukle() async {
    setState(() {
      yukleniyor = true;
      hata = null;
    });

    try {
      final sonuclar = await Future.wait([
        PersonelApi.listele(),
        HizmetApi.listele(),
      ]);

      final gelenPersoneller = sonuclar[0];
      final gelenHizmetler = sonuclar[1];
      debugPrint('HIZMET API SONUCU: $gelenHizmetler');
debugPrint('SECILI SUBE ID: ${widget.subeId}');

      if (!mounted) return;

      setState(() {
        personeller = gelenPersoneller.where((p) {
          return tamSayi(p['subeId']) == widget.subeId &&
              p['aktifMi'] == true;
        }).toList();

        hizmetler = gelenHizmetler.where((h) {
          return tamSayi(h['subeId']) == widget.subeId &&
              h['aktifMi'] == true;
        }).toList();

        yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        hata = e.toString();
        yukleniyor = false;
      });
    }
  }

  Future<void> tarihSec() async {
    final tarih = await showDatePicker(
      context: context,
      initialDate: secilenTarih,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (!mounted || tarih == null) return;

    setState(() => secilenTarih = tarih);
  }

  Future<void> saatSec() async {
    final saat = await showTimePicker(
      context: context,
      initialTime: secilenSaat,
      helpText: 'Randevu başlangıç saati',
    );

    if (!mounted || saat == null) return;

    setState(() => secilenSaat = saat);
  }

  DateTime get randevuBaslangic {
    return DateTime(
      secilenTarih.year,
      secilenTarih.month,
      secilenTarih.day,
      secilenSaat.hour,
      secilenSaat.minute,
    );
  }

  String apiTarihYaz(DateTime tarih) {
    return '${tarih.year.toString().padLeft(4, '0')}-'
        '${tarih.month.toString().padLeft(2, '0')}-'
        '${tarih.day.toString().padLeft(2, '0')}T'
        '${tarih.hour.toString().padLeft(2, '0')}:'
        '${tarih.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> kaydet() async {
    if (kaydediliyor) return;

    if (!_formKey.currentState!.validate()) return;

    if (secilenPersonelId == null) {
      mesajGoster('Lütfen personel seçin.');
      return;
    }

    if (secilenHizmetler.isEmpty) {
      mesajGoster('En az bir hizmet seçmelisiniz.');
      return;
    }

    if (randevuBaslangic.isBefore(DateTime.now())) {
      mesajGoster('Geçmiş bir saate randevu oluşturulamaz.');
      return;
    }

    setState(() => kaydediliyor = true);

    try {
      final token = await _storage.read(
        key: 'atlas_isletme_access_token',
      );

      if (token == null || token.isEmpty) {
        throw Exception(
          'İşletme oturumu bulunamadı. Yeniden giriş yapın.',
        );
      }

      final uri = Uri.parse(
        '${_baseUrl.replaceAll(RegExp(r'/+$'), '')}'
        '/api/isletme/randevular/manuel',
      );

      final body = {
        'subeId': widget.subeId,
        'personelId': secilenPersonelId,
        'musteriAdSoyad': _adController.text.trim(),
        'musteriTelefon': _telefonController.text.trim(),
        'hizmetIdleri': secilenHizmetler.toList(),
        'baslangic': apiTarihYaz(randevuBaslangic),
      };

      final response = await http
          .post(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json; charset=utf-8',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      dynamic data;

      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final sunucuMesaji =
            data is Map ? data['mesaj']?.toString() : null;

        throw Exception(
          sunucuMesaji ??
              'Randevu oluşturulamadı. HTTP ${response.statusCode}',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Randevu başarıyla oluşturuldu.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      mesajGoster(
        e.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => kaydediliyor = false);
      }
    }
  }

  void mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mesaj),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Widget bolumBasligi(String baslik, IconData ikon) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 22,
        bottom: 12,
      ),
      child: Row(
        children: [
          Icon(ikon, color: mavi, size: 22),
          const SizedBox(width: 9),
          Text(
            baslik,
            style: const TextStyle(
              color: lacivert,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget kart({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: child,
    );
  }

  InputDecoration alanTasarimi(
    String etiket,
    IconData ikon,
  ) {
    return InputDecoration(
      labelText: etiket,
      prefixIcon: Icon(ikon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arkaPlan,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Yeni Randevu Oluştur',
          style: TextStyle(
            color: lacivert,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : hata != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hata!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: verileriYukle,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [lacivert, mavi],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'OVO RANDEVU • İŞLETME',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Manuel Randevu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Telefonla arayan veya işletmeye gelen müşterileriniz için randevu oluşturun.',
                              style: TextStyle(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),

                      bolumBasligi(
                        'Müşteri Bilgileri',
                        Icons.person_outline,
                      ),

                      kart(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _adController,
                              textCapitalization:
                                  TextCapitalization.words,
                              decoration: alanTasarimi(
                                'Müşteri Adı Soyadı',
                                Icons.badge_outlined,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Müşteri adı zorunludur.';
                                }
                                if (value.trim().length > 150) {
                                  return 'En fazla 150 karakter girilebilir.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _telefonController,
                              keyboardType: TextInputType.phone,
                              decoration: alanTasarimi(
                                'Telefon Numarası',
                                Icons.phone_outlined,
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty) {
                                  return 'Telefon numarası zorunludur.';
                                }
                                if (value.trim().length > 20) {
                                  return 'En fazla 20 karakter girilebilir.';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      bolumBasligi(
                        'Personel Seçimi',
                        Icons.groups_outlined,
                      ),

                      kart(
                        child: personeller.isEmpty
                            ? const Text(
                                'Bu şubede aktif personel bulunamadı.',
                              )
                            : DropdownButtonFormField<int>(
                                value: secilenPersonelId,
                                isExpanded: true,
                                decoration: alanTasarimi(
                                  'Personel',
                                  Icons.person_pin_outlined,
                                ),
                                items: personeller.map((p) {
                                  return DropdownMenuItem<int>(
                                    value: tamSayi(p['id']),
                                    child: Text(
                                      '${p['adSoyad'] ?? 'Personel'}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(
                                    () => secilenPersonelId = value,
                                  );
                                },
                              ),
                      ),

                      bolumBasligi(
                        'Hizmet Seçimi',
                        Icons.content_cut,
                      ),

                      kart(
                        child: hizmetler.isEmpty
                            ? const Text(
                                'Bu şubede aktif hizmet bulunamadı.',
                              )
                            : Column(
                                children: hizmetler.map((h) {
                                  final id = tamSayi(h['id']);
                                  final secili =
                                      secilenHizmetler.contains(id);

                                  return CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    value: secili,
                                    activeColor: mavi,
                                    title: Text(
                                      '${h['ad'] ?? 'Hizmet'}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${tamSayi(h['sureDakika'])} dk • '
                                      '${para(h['fiyat'])}',
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          secilenHizmetler.add(id);
                                        } else {
                                          secilenHizmetler.remove(id);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                      ),

                      bolumBasligi(
                        'Tarih ve Saat',
                        Icons.calendar_month_outlined,
                      ),

                      kart(
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.event,
                                color: mavi,
                              ),
                              title: const Text('Randevu Tarihi'),
                              subtitle: Text(tarihYaz(secilenTarih)),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: tarihSec,
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.access_time,
                                color: mavi,
                              ),
                              title: const Text('Başlangıç Saati'),
                              subtitle: Text(saatYaz(secilenSaat)),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: saatSec,
                            ),
                          ],
                        ),
                      ),

                      bolumBasligi(
                        'Randevu Özeti',
                        Icons.receipt_long_outlined,
                      ),

                      kart(
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Seçilen Hizmet'),
                              trailing: Text(
                                '${secilenHizmetler.length} adet',
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Toplam Süre'),
                              trailing: Text('$toplamSure dakika'),
                            ),
                            const Divider(),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(
                                'Toplam Hizmet Tutarı',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: Text(
                                para(toplamFiyat),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: mavi,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'Personel çalışma saatleri, izinleri ve '
                        'randevu çakışmaları kayıt sırasında '
                        'sunucu tarafından kontrol edilir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: kaydediliyor ? null : kaydet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mavi,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: kaydediliyor
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline,
                                ),
                          label: Text(
                            kaydediliyor
                                ? 'Kaydediliyor...'
                                : 'Randevuyu Kaydet',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),
                    ],
                  ),
                ),
    );
  }
}
