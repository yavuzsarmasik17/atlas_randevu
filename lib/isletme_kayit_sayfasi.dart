
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class IsletmeKayitSayfasi extends StatefulWidget {
  const IsletmeKayitSayfasi({super.key});

  @override
  State<IsletmeKayitSayfasi> createState() =>
      _IsletmeKayitSayfasiState();
}

class _IsletmeKayitSayfasiState extends State<IsletmeKayitSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);

  final formKey = GlobalKey<FormState>();

  final isletmeAdi = TextEditingController();
  final yetkiliAdi = TextEditingController();
  final telefon = TextEditingController();
  final email = TextEditingController();
  final adres = TextEditingController();
  final sifre = TextEditingController();
  final sifreTekrar = TextEditingController();

  String kategori = 'Erkek Berberi';
  bool sifreGizli = true;
  bool aydinlatmaOkundu = false;
  bool kaydediliyor = false;
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'https://localhost:7042');

  final kategoriler = [
    'Erkek Berberi',
    'Kadın Kuaförü',
    'Güzellik Merkezi',
    'Diğer',
  ];

  @override
  void dispose() {
    isletmeAdi.dispose();
    yetkiliAdi.dispose();
    telefon.dispose();
    email.dispose();
    adres.dispose();
    sifre.dispose();
    sifreTekrar.dispose();
    super.dispose();
  }

  Widget alan(
    TextEditingController controller,
    String etiket,
    IconData ikon, {
    bool gizli = false,
    TextInputType? klavye,
    String? Function(String?)? kontrol,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        obscureText: gizli,
        keyboardType: klavye,
        decoration: InputDecoration(
          labelText: etiket,
          prefixIcon: Icon(ikon),
          filled: true,
          fillColor: const Color(0xFFF5F7FB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: kontrol ??
            (value) {
              if ((value ?? '').trim().isEmpty) {
                return '$etiket zorunludur.';
              }
              return null;
            },
      ),
    );
  }

  Future<void> kayitOl() async {
    if (kaydediliyor || !formKey.currentState!.validate()) return;
    if (!aydinlatmaOkundu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aydınlatma metnini okuduğunuzu onaylayın.')),
      );
      return;
    }
    setState(() => kaydediliyor = true);
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/api/isletme-kayit'),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'isletmeAdi': isletmeAdi.text.trim(),
          'yetkiliAdSoyad': yetkiliAdi.text.trim(),
          'kategori': kategori,
          'telefon': telefon.text.trim(),
          'email': email.text.trim(),
          'adres': adres.text.trim(),
          'sifre': sifre.text,
        }),
      ).timeout(const Duration(seconds: 20));
      Map<String, dynamic> veri = {};
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) veri = decoded;
      } catch (_) {}
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('İşletme Kaydı Başarılı'),
            content: const Text('İşletmeniz kaydedildi. Giriş ekranından hesabınızla oturum açabilirsiniz.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Tamam')),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        final hata = veri['mesaj']?.toString() ??
            (veri['errors']?.toString() ?? 'Kayıt yapılamadı (HTTP ${response.statusCode}).');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata)));
      }
    } on TimeoutException {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API zaman aşımına uğradı.')),
      );
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API bağlantısı kurulamadı. API çalışıyor mu?')),
      );
    } finally {
      if (mounted) setState(() => kaydediliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24, 20, 24, 65,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF101F43),
                      Color(0xFF1C428B),
                      Color(0xFF2563EB),
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Row(
                          children: [
                            Icon(
                              Icons.storefront,
                              color: Color(0xFF93C5FD),
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'OvoRandevu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'İşletmenizi Büyütün',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 29,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Ovo Randevu ailesine katılın. '
                          'İşletmenizi dijital ortamda yönetin.',
                          style: TextStyle(
                            color: Color(0xFFD5E3FA),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Transform.translate(
                offset: const Offset(0, -32),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x160F2855),
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Form(
                          key: formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'İşletme Kaydı',
                                style: TextStyle(
                                  color: lacivert,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),

                              alan(
                                isletmeAdi,
                                'İşletme Adı',
                                Icons.storefront_outlined,
                              ),

                              alan(
                                yetkiliAdi,
                                'Yetkili Ad Soyad',
                                Icons.person_outline,
                              ),

                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: kategori,
                                  decoration: InputDecoration(
                                    labelText: 'İşletme Kategorisi',
                                    prefixIcon: const Icon(
                                      Icons.category_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                    ),
                                  ),
                                  items: kategoriler.map((item) {
                                    return DropdownMenuItem(
                                      value: item,
                                      child: Text(item),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      kategori = value ?? kategori;
                                    });
                                  },
                                ),
                              ),

                              alan(
                                telefon,
                                'Telefon',
                                Icons.phone_outlined,
                                klavye: TextInputType.phone,
                              ),

                              alan(
                                email,
                                'E-posta',
                                Icons.email_outlined,
                                klavye:
                                    TextInputType.emailAddress,
                                kontrol: (value) {
                                  if (!RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch((value ?? '').trim())) {
                                    return 'Geçerli e-posta giriniz.';
                                  }
                                  return null;
                                },
                              ),

                              alan(
                                adres,
                                'İşletme Adresi',
                                Icons.location_on_outlined,
                              ),

                              alan(
                                sifre,
                                'Şifre',
                                Icons.lock_outline,
                                gizli: sifreGizli,
                                kontrol: (value) {
                                  if ((value ?? '').length < 8) {
                                    return 'En az 8 karakter giriniz.';
                                  }
                                  return null;
                                },
                              ),

                              alan(
                                sifreTekrar,
                                'Şifre Tekrar',
                                Icons.lock_reset,
                                gizli: sifreGizli,
                                kontrol: (value) {
                                  if (value != sifre.text) {
                                    return 'Şifreler eşleşmiyor.';
                                  }
                                  return null;
                                },
                              ),

                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    sifreGizli = !sifreGizli;
                                  });
                                },
                                icon: Icon(
                                  sifreGizli
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                label: Text(
                                  sifreGizli
                                      ? 'Şifreleri Göster'
                                      : 'Şifreleri Gizle',
                                ),
                              ),

                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                value: aydinlatmaOkundu,
                                onChanged: (value) {
                                  setState(() {
                                    aydinlatmaOkundu =
                                        value ?? false;
                                  });
                                },
                                title: const Text(
                                  'KVKK aydınlatma metnini okudum.',
                                  style: TextStyle(fontSize: 13),
                                ),
                                subtitle: const Text(
                                  'Gerçek kayıt öncesinde '
                                  'aydınlatma metni yayımlanacaktır.',
                                  style: TextStyle(fontSize: 11),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              ),

                              const SizedBox(height: 16),

                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: kaydediliyor ? null : kayitOl,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mavi,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: kaydediliyor
                                      ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text('İşletme Kaydı Oluştur'),
                                ),
                              ),

                              const SizedBox(height: 12),

                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context),
                                child: const Text(
                                  'Zaten hesabım var, giriş yap',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
