
import 'package:flutter/material.dart';

import 'platform_admin_api.dart';
import 'platform_admin_giris_sayfasi.dart';
import 'platform_admin_isletmeler_sayfasi.dart';
import 'platform_admin_musteriler_sayfasi.dart';
import 'platform_admin_randevular_sayfasi.dart';

class PlatformAdminPanelSayfasi extends StatefulWidget {
  const PlatformAdminPanelSayfasi({super.key});

  @override
  State<PlatformAdminPanelSayfasi> createState() =>
      _PlatformAdminPanelSayfasiState();
}

class _PlatformAdminPanelSayfasiState
    extends State<PlatformAdminPanelSayfasi> {
  static const Color lacivert = Color(0xFF142D5C);
  static const Color mavi = Color(0xFF2563EB);
  static const Color arkaPlan = Color(0xFFF3F6FC);

  Map<String, dynamic> _ozet = {};

  bool _yukleniyor = true;
  bool _cikisYapiliyor = false;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _yenile();
  }

  Future<void> _yenile() async {
    if (!mounted) return;

    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final sonuc = await PlatformAdminApi.ozetGetir();

      if (!mounted) return;

      setState(() {
        _ozet = sonuc;
      });
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

  Future<void> _cikis() async {
    if (_cikisYapiliyor) return;

    setState(() {
      _cikisYapiliyor = true;
    });

    try {
      await PlatformAdminApi.cikis();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const PlatformAdminGirisSayfasi(),
        ),
        (route) => route.isFirst,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Çıkış yapılamadı: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _cikisYapiliyor = false;
        });
      }
    }
  }

  void _isletmeYonetiminiAc() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PlatformAdminIsletmelerSayfasi(),
      ),
    );
  }

  Widget _kart(
    String baslik,
    String alan,
    IconData ikon,
    Color renk,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              ikon,
              color: renk,
              size: 23,
            ),
          ),
          const Spacer(),
          Text(
            '${_ozet[alan] ?? 0}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: lacivert,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            baslik,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bolumBasligi(String baslik) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 12,
      ),
      child: Text(
        baslik,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: lacivert,
        ),
      ),
    );
  }

  Widget _yonetimMenusu({
    required String baslik,
    required String aciklama,
    required IconData ikon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: mavi.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            ikon,
            color: mavi,
          ),
        ),
        title: Text(
          baslik,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: lacivert,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            aciklama,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.black45,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _anaIcerik() {
    return RefreshIndicator(
      onRefresh: _yenile,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          // ==========================================
          // ÜST KARŞILAMA ALANI
          // ==========================================

          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  lacivert,
                  mavi,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 35,
                ),
                SizedBox(height: 14),
                Text(
                  'Platform Yönetim Merkezi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'Ovo Randevu Mobil platformunun '
                  'genel durumunu buradan takip edebilirsiniz.',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ==========================================
          // PLATFORM İSTATİSTİKLERİ
          // ==========================================

          _bolumBasligi('Platform İstatistikleri'),

          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.20,
            children: [
              _kart(
                'Toplam İşletme',
                'toplamIsletme',
                Icons.storefront,
                mavi,
              ),
              _kart(
                'Aktif İşletme',
                'aktifIsletme',
                Icons.verified,
                Colors.green,
              ),
              _kart(
                'Toplam Müşteri',
                'toplamMusteri',
                Icons.people,
                Colors.purple,
              ),
              _kart(
                'Toplam Randevu',
                'toplamRandevu',
                Icons.calendar_month,
                Colors.orange,
              ),
              _kart(
                'Bugünkü Randevular',
                'bugunkuRandevu',
                Icons.today,
                Colors.teal,
              ),
              _kart(
                'Tamamlanan',
                'tamamlanan',
                Icons.task_alt,
                Colors.green,
              ),
              _kart(
                'İptal Edilen',
                'iptalEdilen',
                Icons.event_busy,
                Colors.redAccent,
              ),
              _kart(
                'Değerlendirmeler',
                'degerlendirmeSayisi',
                Icons.star,
                Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ==========================================
          // ORTALAMA DEĞERLENDİRME
          // ==========================================

          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.star_rate_rounded,
                color: Colors.amber,
                size: 30,
              ),
              title: const Text(
                'Ortalama Değerlendirme Puanı',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: Text(
                '${_ozet['ortalamaPuan'] ?? 0} / 5',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: lacivert,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // YÖNETİM MENÜLERİ
          // ==========================================

          _bolumBasligi('Platform Yönetimi'),

          _yonetimMenusu(
            baslik: 'İşletme Yönetimi',
            aciklama:
                'İşletmeleri listele, detaylarını görüntüle '
                've aktif/pasif durumlarını yönet.',
            ikon: Icons.storefront_rounded,
            onTap: _isletmeYonetiminiAc,
          ),

          _yonetimMenusu(
            baslik: 'Müşteri Yönetimi',
            aciklama:
                'Müşterileri listele, bilgilerini incele '
                've hesaplarını aktif/pasif yönet.',
            ikon: Icons.people_alt_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlatformAdminMusterilerSayfasi(),
                ),
              );
            },
          ),

          _yonetimMenusu(
            baslik: 'Tüm Randevular',
            aciklama: 'Bütün işletmelerin randevularını görüntüle ve filtrele.',
            ikon: Icons.calendar_month_rounded,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PlatformAdminRandevularSayfasi(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: arkaPlan,
      appBar: AppBar(
        title: const Text(
          'ATLAS | Platform Admin',
        ),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukleniyor ? null : _yenile,
            icon: const Icon(
              Icons.refresh,
            ),
          ),
          IconButton(
            tooltip: 'Çıkış Yap',
            onPressed: _cikisYapiliyor ? null : _cikis,
            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _hata != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 45,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _hata!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _yenile,
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _anaIcerik(),
    );
  }
}
