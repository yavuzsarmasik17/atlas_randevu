
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MusteriKayitSayfasi extends StatefulWidget {
  const MusteriKayitSayfasi({super.key});

  @override
  State<MusteriKayitSayfasi> createState() =>
      _MusteriKayitSayfasiState();
}

class _MusteriKayitSayfasiState extends State<MusteriKayitSayfasi> {
  static const Color lacivert = Color(0xFF101F43);
  static const Color mavi = Color(0xFF2563EB);

  final formKey = GlobalKey<FormState>();

  final adController = TextEditingController();
  final telefonController = TextEditingController();
  final emailController = TextEditingController();
  final sifreController = TextEditingController();
  final sifreTekrarController = TextEditingController();

  bool sifreGizli = true;
  bool kvkkOnay = false;
  bool kaydediliyor = false;

  // API portunu Visual Studio'nun gerçek HTTPS adresinden alacağız.
  static const String apiBaseUrl = String.fromEnvironment('API_URL');

  @override
  void dispose() {
    adController.dispose();
    telefonController.dispose();
    emailController.dispose();
    sifreController.dispose();
    sifreTekrarController.dispose();
    super.dispose();
  }

  InputDecoration alanTasarimi({
    required String etiket,
    required IconData ikon,
    Widget? sagIkon,
  }) {
    OutlineInputBorder kenarlik(Color renk, double kalinlik) {
      return OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: renk,
          width: kalinlik,
        ),
      );
    }

    return InputDecoration(
      labelText: etiket,
      labelStyle: const TextStyle(
        color: Color(0xFF64748B),
      ),
      prefixIcon: Icon(
        ikon,
        color: const Color(0xFF64748B),
      ),
      suffixIcon: sagIkon,
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      enabledBorder: kenarlik(
        const Color(0xFFE2E8F0),
        1,
      ),
      focusedBorder: kenarlik(mavi, 1.7),
      errorBorder: kenarlik(Colors.red, 1),
      focusedErrorBorder: kenarlik(Colors.red, 1.7),
    );
  }

  Widget metinAlani({
    required TextEditingController controller,
    required String etiket,
    required IconData ikon,
    TextInputType? klavye,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: klavye,
        textInputAction: TextInputAction.next,
        decoration: alanTasarimi(
          etiket: etiket,
          ikon: ikon,
        ),
        validator: validator ??
            (value) {
              if ((value ?? '').trim().isEmpty) {
                return '$etiket alanını doldurun.';
              }
              return null;
            },
      ),
    );
  }

  Widget sifreAlani({
    required TextEditingController controller,
    required String etiket,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: sifreGizli,
        decoration: alanTasarimi(
          etiket: etiket,
          ikon: Icons.lock_outline,
          sagIkon: IconButton(
            icon: Icon(
              sifreGizli
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: () {
              setState(() {
                sifreGizli = !sifreGizli;
              });
            },
          ),
        ),
        validator: validator,
      ),
    );
  }

  void mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mesaj), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> kayitOl() async {
    if (kaydediliyor || !formKey.currentState!.validate()) return;

    if (!kvkkOnay) {
      mesajGoster('Lütfen aydınlatma metnini okuduğunuzu onaylayın.');
      return;
    }

    if (apiBaseUrl.trim().isEmpty) {
      mesajGoster('API adresi tanımlı değil. API_URL ayarını kontrol edin.');
      return;
    }

    final tamAd = adController.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    final parcalar = tamAd.split(' ');
    if (parcalar.length < 2) {
      mesajGoster('Lütfen adınızı ve soyadınızı girin.');
      return;
    }
    final soyad = parcalar.last;
    final ad = parcalar.sublist(0, parcalar.length - 1).join(' ');

    setState(() => kaydediliyor = true);
    try {
      final url = Uri.parse(
        '${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api/Auth/musteri-kayit',
      );
      final yanit = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'ad': ad,
          'soyad': soyad,
          'email': emailController.text.trim(),
          'telefon': telefonController.text.trim(),
          'sifre': sifreController.text,
        }),
      ).timeout(const Duration(seconds: 20));

      if (!mounted) return;
      dynamic veri;
      try {
        veri = jsonDecode(utf8.decode(yanit.bodyBytes));
      } catch (_) {
        veri = null;
      }

      if (yanit.statusCode >= 200 && yanit.statusCode < 300) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Kayıt Başarılı'),
            content: const Text(
              'Müşteri hesabınız oluşturuldu. Giriş ekranından devam edebilirsiniz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
      } else {
        String hata = 'Kayıt başarısız (HTTP ${yanit.statusCode}).';
        if (veri is Map) {
          if (veri['mesaj'] is String) {
            hata = veri['mesaj'] as String;
          } else if (veri['errors'] is Map) {
            final errors = veri['errors'] as Map;
            final aciklamalar = errors.values
                .whereType<List>()
                .expand((liste) => liste)
                .map((e) => e.toString())
                .toList();
            if (aciklamalar.isNotEmpty) hata = aciklamalar.join(' ');
          }
          if (veri['hatalar'] is List) {
            hata += ' ${(veri['hatalar'] as List).join(' ')}';
          }
        }
        mesajGoster(hata);
      }
    } catch (_) {
      if (mounted) {
        mesajGoster(
          'API bağlantısı kurulamadı. API adresini, HTTPS sertifikasını ve CORS ayarını kontrol edin.',
        );
      }
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
              // ÜST MARKA ALANI
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  24, 20, 24, 65,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Color(0xFF93C5FD),
                              size: 30,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'OvoRandevu',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Aramıza Katıl!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'Ücretsiz hesabını oluştur, '
                          'favori işletmelerini keşfet '
                          've randevularını kolayca yönet.',
                          style: TextStyle(
                            color: Color(0xFFD5E3FA),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // KAYIT FORMU
              Transform.translate(
                offset: const Offset(0, -32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 440,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
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
                                'Hesap Oluştur',
                                style: TextStyle(
                                  color: lacivert,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 7),
                              const Text(
                                'Başlamak için bilgilerinizi doldurun.',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),

                              metinAlani(
                                controller: adController,
                                etiket: 'Ad Soyad',
                                ikon: Icons.person_outline,
                              ),

                              metinAlani(
                                controller: telefonController,
                                etiket: 'Telefon Numarası',
                                ikon: Icons.phone_outlined,
                                klavye: TextInputType.phone,
                                validator: (value) {
                                  final rakamlar = (value ?? '')
                                      .replaceAll(RegExp(r'\D'), '');

                                  if (rakamlar.length != 10 &&
                                      !(rakamlar.length == 11 &&
                                          rakamlar.startsWith('0'))) {
                                    return 'Geçerli bir telefon giriniz.';
                                  }
                                  return null;
                                },
                              ),

                              metinAlani(
                                controller: emailController,
                                etiket: 'E-posta Adresi',
                                ikon: Icons.mail_outline,
                                klavye:
                                    TextInputType.emailAddress,
                                validator: (value) {
                                  final email =
                                      (value ?? '').trim();

                                  final uygun = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  ).hasMatch(email);

                                  if (!uygun) {
                                    return 'Geçerli e-posta giriniz.';
                                  }
                                  return null;
                                },
                              ),

                              sifreAlani(
                                controller: sifreController,
                                etiket: 'Şifre',
                                validator: (value) {
                                  if ((value ?? '').length < 8) {
                                    return 'Şifre en az 8 karakter olmalı.';
                                  }
                                  return null;
                                },
                              ),

                              sifreAlani(
                                controller: sifreTekrarController,
                                etiket: 'Şifre Tekrar',
                                validator: (value) {
                                  if (value != sifreController.text) {
                                    return 'Şifreler eşleşmiyor.';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 2),

                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                value: kvkkOnay,
                                onChanged: (value) {
                                  setState(() {
                                    kvkkOnay = value ?? false;
                                  });
                                },
                                title: const Text(
                                  'KVKK aydınlatma metnini okudum.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: lacivert,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Aydınlatma metni yayımlanmadan '
                                  'gerçek kayıt açılmayacaktır.',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ),

                              const SizedBox(height: 18),

                              SizedBox(
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: kaydediliyor ? null : kayitOl,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: mavi,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      if (kaydediliyor)
                                        const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2, color: Colors.white,
                                          ),
                                        )
                                      else const Text(
                                        'Hesap Oluştur',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      if (!kaydediliyor)
                                        const Icon(Icons.arrow_forward),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Zaten hesabınız var mı?',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'Giriş Yap',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: Text(
                  'ATLAS SOFT © 2026',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
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
