
import 'package:flutter/material.dart';

import 'platform_admin_api.dart';
import 'platform_admin_panel_sayfasi.dart';

class PlatformAdminGirisSayfasi extends StatefulWidget {
  const PlatformAdminGirisSayfasi({super.key});

  @override
  State<PlatformAdminGirisSayfasi> createState() =>
      _PlatformAdminGirisSayfasiState();
}

class _PlatformAdminGirisSayfasiState
    extends State<PlatformAdminGirisSayfasi> {
  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sifre = TextEditingController();

  bool _yukleniyor = false;
  bool _sifreGizli = true;
  String? _hata;

  @override
  void dispose() {
    _email.dispose();
    _sifre.dispose();
    super.dispose();
  }

  Future<void> _giris() async {
    if (_yukleniyor) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      await PlatformAdminApi.giris(
        _email.text.trim(),
        _sifre.text,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const PlatformAdminPanelSayfasi(),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Platform Admin Girişi'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 65,
                        color: mavi,
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'ATLAS Yönetim Merkezi',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: lacivert,
                        ),
                      ),

                      const SizedBox(height: 6),

                      const Text(
                        'Yalnızca yetkili platform yöneticileri',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 26),

                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [
                          AutofillHints.email,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'E-posta',
                          prefixIcon: Icon(Icons.mail_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty) {
                            return 'E-posta gerekli';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _sifre,
                        obscureText: _sifreGizli,
                        autofillHints: const [
                          AutofillHints.password,
                        ],
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                          ),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _sifreGizli = !_sifreGizli;
                              });
                            },
                            icon: Icon(
                              _sifreGizli
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Şifre gerekli';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _giris(),
                      ),

                      if (_hata != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _hata!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ],

                      const SizedBox(height: 22),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed:
                              _yukleniyor ? null : _giris,
                          child: _yukleniyor
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Giriş Yap'),
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
    );
  }
}
