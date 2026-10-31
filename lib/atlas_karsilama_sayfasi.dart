import 'package:flutter/material.dart';

import 'musteri_giris_sayfasi.dart';
import 'musteri_kayit_sayfasi.dart';
import 'musteri_ana_sayfa.dart';
import 'isletme_giris_sayfasi.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AtlasKarsilamaSayfasi extends StatelessWidget {
  const AtlasKarsilamaSayfasi({super.key});

  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);
  static const FlutterSecureStorage _depo = FlutterSecureStorage();

  Future<void> _misafirDevam(BuildContext context) async {
    await _depo.delete(key: 'atlas_access_token');
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MusteriAnaSayfa()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ekran = MediaQuery.sizeOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: mavi,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: const Icon(Icons.calendar_month_rounded,
                              color: Colors.white, size: 25),
                        ),
                        const SizedBox(width: 11),
                        const Text('OvoRandevu',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .4,
                              color: lacivert,
                            )),
                      ],
                    ),
                  ),
                  SizedBox(height: ekran.height < 700 ? 30 : 60),
                  Container(
                    height: 224,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 24,
                          right: 35,
                          child: Icon(Icons.auto_awesome_rounded,
                              color: mavi.withValues(alpha: .35), size: 33),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 30,
                          child: Icon(Icons.check_circle_rounded,
                              color: mavi.withValues(alpha: .28), size: 34),
                        ),
                        Container(
                          width: 146,
                          height: 146,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x172563EB),
                                blurRadius: 28,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.event_available_rounded,
                              size: 86, color: mavi),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 34),
                  const Text('Randevu almak\nartık çok kolay.',
                      style: TextStyle(
                        fontSize: 34,
                        height: 1.17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.8,
                        color: lacivert,
                      )),
                  const SizedBox(height: 14),
                  const Text(
                    'Yakınındaki işletmeleri keşfet, sana uygun hizmeti seç ve dakikalar içinde randevunu oluştur.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: ekran.height < 700 ? 26 : 43),
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const MusteriGirisSayfasi()),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: mavi,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Giriş Yap',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 55,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const MusteriKayitSayfasi()),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: lacivert,
                        side: const BorderSide(color: Color(0xFFD9E3F1)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Ücretsiz Üye Ol',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => _misafirDevam(context),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Üye Olmadan Keşfet',
                            style: TextStyle(
                                color: mavi, fontWeight: FontWeight.w700)),
                        SizedBox(width: 6),
                        Icon(Icons.arrow_forward_rounded, color: mavi, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 14),
                  const Text('İşletme ve yönetim',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: lacivert)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _kurumsalButon(
                      context, Icons.storefront_outlined, 'İşletme Girişi',
                      () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => const IsletmeGirisSayfasi())),
                    )),
                    const SizedBox(width: 10),
                    Expanded(child: _kurumsalButon(
                      context, Icons.admin_panel_settings_outlined, 'Platform Admin',
                      () => Navigator.pushNamed(context, '/platform-admin-giris'),
                    )),
                  ]),
                  const SizedBox(height: 24),
                  const Text('ATLAS SOFT  •  2026',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _kurumsalButon(BuildContext context, IconData simge,
      String baslik, VoidCallback tikla) {
    return SizedBox(
      height: 58,
      child: OutlinedButton.icon(
        onPressed: tikla,
        icon: Icon(simge, size: 19),
        label: Text(baslik, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
        style: OutlinedButton.styleFrom(
          foregroundColor: lacivert,
          backgroundColor: const Color(0xFFF8FAFC),
          side: const BorderSide(color: Color(0xFFDCE5F0)),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

}
