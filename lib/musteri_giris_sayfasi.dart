
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'musteri_ana_sayfa.dart';
import 'musteri_kayit_sayfasi.dart';

class MusteriGirisSayfasi extends StatefulWidget {
  const MusteriGirisSayfasi({super.key});

  @override
  State<MusteriGirisSayfasi> createState() =>
      _MusteriGirisSayfasiState();
}

class _MusteriGirisSayfasiState extends State<MusteriGirisSayfasi> {
  static const Color lacivert = Color(0xFF101F43);
  static const Color mavi = Color(0xFF2563EB);

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final sifreController = TextEditingController();

  bool sifreGizli = true;
  bool girisYapiliyor = false;
  static const String apiBaseUrl = String.fromEnvironment('API_URL');
  static const FlutterSecureStorage guvenliDepo = FlutterSecureStorage();

  @override
  void dispose() {
    emailController.dispose();
    sifreController.dispose();
    super.dispose();
  }

  Future<void> girisYap() async {
    if (girisYapiliyor || !formKey.currentState!.validate()) return;
    if (apiBaseUrl.isEmpty) {
      mesajGoster('API_URL tanımlanmamış.');
      return;
    }
    setState(() => girisYapiliyor = true);
    try {
      final yanit = await http.post(
        Uri.parse('${apiBaseUrl.replaceAll(RegExp(r'/+$'), '')}/api/Auth/giris'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text.trim(),
          'sifre': sifreController.text,
        }),
      ).timeout(const Duration(seconds: 20));
      final veri = jsonDecode(utf8.decode(yanit.bodyBytes));
      if (yanit.statusCode == 200 && veri is Map && veri['token'] is String) {
        await guvenliDepo.write(key: 'atlas_access_token', value: veri['token'] as String);
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MusteriAnaSayfa()),
        );
      } else {
        if (!mounted) return;
        mesajGoster(veri is Map && veri['mesaj'] is String
            ? veri['mesaj'] as String
            : 'Giriş başarısız. Bilgilerinizi kontrol edin.');
      }
    } catch (_) {
      if (mounted) mesajGoster('API bağlantısı kurulamadı. API çalışıyor mu?');
    } finally {
      if (mounted) setState(() => girisYapiliyor = false);
    }
  }

  void mesajGoster(String mesaj) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj)));
  }

  
Future<void> misafirDevamEt() async {
  // Misafir modunda önceki müşteri oturumu kullanılmamalı.
  await guvenliDepo.delete(key: 'atlas_access_token');

  if (!mounted) return;

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => const MusteriAnaSayfa(),
    ),
  );
}


  InputDecoration alanTasarimi({
    required String etiket,
    required IconData ikon,
    Widget? sagIkon,
  }) {
    return InputDecoration(
      labelText: etiket,
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIcon: Icon(ikon, color: const Color(0xFF64748B)),
      suffixIcon: sagIkon,
      filled: true,
      fillColor: const Color(0xFFF5F7FB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 19,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFE2E8F0),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: mavi,
          width: 1.7,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5FB),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  // ÜST MARKA ALANI
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(
                      24, 20, 24, 68,
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
                        constraints:
                            const BoxConstraints(maxWidth: 440),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                           IconButton(
  onPressed: () {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MusteriAnaSayfa(),
        ),
        (route) => false,
      );
    }
  },
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
                            const SizedBox(height: 26),
                            const Text(
                              'Tekrar Hoş Geldiniz!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 29,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Favori işletmelerinize ulaşın, '
                              'randevularınızı kolayca yönetin.',
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

                  // GİRİŞ KARTI
                  Transform.translate(
                    offset: const Offset(0, -34),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(25),
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
                                    'Hesabınıza Giriş Yapın',
                                    style: TextStyle(
                                      color: lacivert,
                                      fontSize: 21,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  const Text(
                                    'Devam etmek için bilgilerinizi girin.',
                                    style: TextStyle(
                                      color: Color(0xFF64748B),
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 25),

                                  TextFormField(
                                    controller: emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    decoration: alanTasarimi(
                                      etiket: 'E-posta Adresi',
                                      ikon: Icons.mail_outline,
                                    ),
                                    validator: (value) {
                                      final email =
                                          value?.trim() ?? '';
                                      if (email.isEmpty ||
                                          !email.contains('@')) {
                                        return 'Geçerli e-posta giriniz.';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: sifreController,
                                    obscureText: sifreGizli,
                                    decoration: alanTasarimi(
                                      etiket: 'Şifre',
                                      ikon: Icons.lock_outline,
                                      sagIkon: IconButton(
                                        icon: Icon(
                                          sifreGizli
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            sifreGizli =
                                                !sifreGizli;
                                          });
                                        },
                                      ),
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').isEmpty) {
                                        return 'Şifrenizi giriniz.';
                                      }
                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 24),

                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: girisYapiliyor ? null : girisYap,
                                      style:
                                          ElevatedButton.styleFrom(
                                        backgroundColor: mavi,
                                        foregroundColor:
                                            Colors.white,
                                        elevation: 0,
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(
                                                  15),
                                        ),
                                      ),
                                      child: girisYapiliyor
                                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                                          : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Giriş Yap',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                          SizedBox(width: 10),
                                          Icon(Icons.arrow_forward),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  OutlinedButton.icon(
                                    onPressed: misafirDevamEt,
                                    icon: const Icon(
                                      Icons.explore_outlined,
                                    ),
                                    label: const Text(
                                      'Üye Olmadan Keşfet',
                                    ),
                                    style:
                                        OutlinedButton.styleFrom(
                                      foregroundColor: lacivert,
                                      minimumSize:
                                          const Size(
                                              double.infinity, 52),
                                      side: const BorderSide(
                                        color:
                                            Color(0xFFD7E1EF),
                                      ),
                                      shape:
                                          RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(
                                                15),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 24),

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      const Text(
                                        'Henüz hesabınız yok mu?',
                                        style: TextStyle(
                                          color:
                                              Color(0xFF64748B),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const MusteriKayitSayfasi(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Kayıt Ol',
                                          style: TextStyle(
                                            fontWeight:
                                                FontWeight.bold,
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
                    padding: EdgeInsets.only(
                      bottom: 25,
                    ),
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
            );
          },
        ),
      ),
    );
  }
}
