
import 'package:flutter/material.dart';

import 'platform_admin_musteriler_api.dart';

class PlatformAdminMusterilerSayfasi extends StatefulWidget {
  const PlatformAdminMusterilerSayfasi({super.key});

  @override
  State<PlatformAdminMusterilerSayfasi> createState() =>
      _PlatformAdminMusterilerSayfasiState();
}

class _PlatformAdminMusterilerSayfasiState
    extends State<PlatformAdminMusterilerSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);

  final _arama = TextEditingController();

  List<Map<String, dynamic>> _musteriler = [];
  bool _yukleniyor = true;
  String? _islemYapilanId;
  String? _hata;

  @override
  void initState() {
    super.initState();
    _listele();
  }

  @override
  void dispose() {
    _arama.dispose();
    super.dispose();
  }

  Future<void> _listele() async {
    setState(() {
      _yukleniyor = true;
      _hata = null;
    });

    try {
      final sonuc = await PlatformAdminMusterilerApi.listele();

      if (!mounted) return;

      setState(() {
        _musteriler = sonuc;
        _yukleniyor = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _yukleniyor = false;
      });
    }
  }

  String _metin(Map<String, dynamic> veri, String alan) {
    final deger = veri[alan]?.toString().trim() ?? '';
    return deger.isEmpty ? 'Belirtilmemiş' : deger;
  }

  Future<void> _durumDegistir(Map<String, dynamic> musteri) async {
    final id = musteri['id']?.toString() ?? '';
    if (id.isEmpty || _islemYapilanId != null) return;

    final aktif = musteri['aktifMi'] == true;

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          aktif ? 'Müşteriyi pasif yap' : 'Müşteriyi aktif yap',
        ),
        content: Text(
          '${_metin(musteri, 'ad')} '
          '${_metin(musteri, 'soyad')} hesabının durumunu '
          '${aktif ? 'pasif' : 'aktif'} yapmak istiyor musunuz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;

    setState(() => _islemYapilanId = id);

    try {
      await PlatformAdminMusterilerApi.durumDegistir(
        id,
        !aktif,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aktif
                ? 'Müşteri hesabı pasif yapıldı.'
                : 'Müşteri hesabı aktif yapıldı.',
          ),
        ),
      );

      await _listele();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _islemYapilanId = null);
      }
    }
  }

  void _detayGoster(Map<String, dynamic> musteri) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Müşteri Bilgileri',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: lacivert,
                ),
              ),
              const SizedBox(height: 18),
              _detaySatiri(
                'Ad Soyad',
                '${_metin(musteri, 'ad')} '
                '${_metin(musteri, 'soyad')}',
              ),
              _detaySatiri(
                'E-posta',
                _metin(musteri, 'email'),
              ),
              _detaySatiri(
                'Telefon',
                _metin(musteri, 'phoneNumber'),
              ),
              _detaySatiri(
                'Kayıt Tarihi',
                _metin(musteri, 'kayitTarihi'),
              ),
              _detaySatiri(
                'Randevu',
                '${musteri['randevuSayisi'] ?? 0}',
              ),
              _detaySatiri(
                'Değerlendirme',
                '${musteri['degerlendirmeSayisi'] ?? 0}',
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detaySatiri(String baslik, String deger) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              baslik,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              deger,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ozetKarti(String baslik, int sayi, Color renk) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              '$sayi',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: renk,
              ),
            ),
            Text(
              baslik,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aranan = _arama.text.trim().toLowerCase();

    final filtreli = _musteriler.where((x) {
      final metin = [
        x['ad'],
        x['soyad'],
        x['email'],
        x['phoneNumber'],
      ].join(' ').toLowerCase();

      return metin.contains(aranan);
    }).toList();

    final aktifSayisi =
        _musteriler.where((x) => x['aktifMi'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('Müşteri Yönetimi'),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            onPressed: _yukleniyor ? null : _listele,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _yukleniyor
          ? const Center(child: CircularProgressIndicator())
          : _hata != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_hata!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _listele,
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _listele,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          _ozetKarti(
                            'Toplam',
                            _musteriler.length,
                            mavi,
                          ),
                          const SizedBox(width: 8),
                          _ozetKarti(
                            'Aktif',
                            aktifSayisi,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _ozetKarti(
                            'Pasif',
                            _musteriler.length - aktifSayisi,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _arama,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Ad, e-posta veya telefon ara',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (filtreli.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('Müşteri bulunamadı.'),
                          ),
                        ),
                      ...filtreli.map((musteri) {
                        final aktif = musteri['aktifMi'] == true;
                        final id = musteri['id']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        mavi.withValues(alpha: 0.10),
                                    child: const Icon(
                                      Icons.person,
                                      color: mavi,
                                    ),
                                  ),
                                  title: Text(
                                    '${_metin(musteri, 'ad')} '
                                    '${_metin(musteri, 'soyad')}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _metin(musteri, 'email'),
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      aktif ? 'Aktif' : 'Pasif',
                                    ),
                                  ),
                                  onTap: () => _detayGoster(musteri),
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Randevu: '
                                        '${musteri['randevuSayisi'] ?? 0}'
                                        '  •  Değerlendirme: '
                                        '${musteri['degerlendirmeSayisi'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: aktif,
                                      onChanged:
                                          id.isEmpty ||
                                                  _islemYapilanId != null
                                              ? null
                                              : (_) =>
                                                  _durumDegistir(musteri),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
    );
  }
}
