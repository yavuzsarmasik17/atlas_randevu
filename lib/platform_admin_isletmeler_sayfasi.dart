
import 'package:flutter/material.dart';

import 'platform_admin_isletmeler_api.dart';

class PlatformAdminIsletmelerSayfasi extends StatefulWidget {
  const PlatformAdminIsletmelerSayfasi({super.key});

  @override
  State<PlatformAdminIsletmelerSayfasi> createState() =>
      _PlatformAdminIsletmelerSayfasiState();
}

class _PlatformAdminIsletmelerSayfasiState
    extends State<PlatformAdminIsletmelerSayfasi> {
  static const lacivert = Color(0xFF142D5C);
  static const mavi = Color(0xFF2563EB);

  final _arama = TextEditingController();

  List<Map<String, dynamic>> _isletmeler = [];
  bool _yukleniyor = true;
  int? _islemYapilanId;
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
      final sonuc = await PlatformAdminIsletmelerApi.listele();

      if (!mounted) return;

      setState(() {
        _isletmeler = sonuc;
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

  Future<void> _durumDegistir(Map<String, dynamic> isletme) async {
    final id = int.tryParse('${isletme['id']}');
    if (id == null || _islemYapilanId != null) return;

    final aktif = isletme['aktifMi'] == true;

    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          aktif ? 'İşletmeyi pasif yap' : 'İşletmeyi aktif yap',
        ),
        content: Text(
          '${_metin(isletme, 'ad')} işletmesinin durumunu '
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
      await PlatformAdminIsletmelerApi.durumDegistir(
        id,
        !aktif,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            aktif
                ? 'İşletme pasif yapıldı.'
                : 'İşletme aktif yapıldı.',
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
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _islemYapilanId = null);
      }
    }
  }

  void _detayGoster(Map<String, dynamic> isletme) {
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
                'İşletme Bilgileri',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: lacivert,
                ),
              ),
              const SizedBox(height: 18),
              _detaySatiri('İşletme', _metin(isletme, 'ad')),
              _detaySatiri(
                'Sahibi',
                '${_metin(isletme, 'sahipAdi')} '
                '${_metin(isletme, 'sahipSoyadi')}',
              ),
              _detaySatiri(
                'E-posta',
                _metin(isletme, 'sahipEmail'),
              ),
              _detaySatiri(
                'Telefon',
                _metin(isletme, 'telefon'),
              ),
              _detaySatiri(
                'Kategori',
                _metin(isletme, 'kategori'),
              ),
              _detaySatiri(
                'Adres',
                _metin(isletme, 'adres'),
              ),
              _detaySatiri(
                'Şube',
                '${isletme['subeSayisi'] ?? 0}',
              ),
              _detaySatiri(
                'Randevu',
                '${isletme['randevuSayisi'] ?? 0}',
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
            width: 90,
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

  @override
  Widget build(BuildContext context) {
    final aranan = _arama.text.trim().toLowerCase();

    final filtreli = _isletmeler.where((x) {
      final metin = [
        x['ad'],
        x['sahipAdi'],
        x['sahipSoyadi'],
        x['sahipEmail'],
        x['telefon'],
      ].join(' ').toLowerCase();

      return metin.contains(aranan);
    }).toList();

    final aktifSayisi =
        _isletmeler.where((x) => x['aktifMi'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FC),
      appBar: AppBar(
        title: const Text('İşletme Yönetimi'),
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
                      Text(_hata!),
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
                            _isletmeler.length,
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
                            _isletmeler.length - aktifSayisi,
                            Colors.redAccent,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _arama,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'İşletme veya sahibi ara',
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
                            child: Text('İşletme bulunamadı.'),
                          ),
                        ),
                      ...filtreli.map((isletme) {
                        final aktif = isletme['aktifMi'] == true;
                        final id = int.tryParse('${isletme['id']}');

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
                                      Icons.storefront,
                                      color: mavi,
                                    ),
                                  ),
                                  title: Text(
                                    _metin(isletme, 'ad'),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${_metin(isletme, 'sahipAdi')} '
                                    '${_metin(isletme, 'sahipSoyadi')}',
                                  ),
                                  trailing: Chip(
                                    label: Text(
                                      aktif ? 'Aktif' : 'Pasif',
                                    ),
                                  ),
                                  onTap: () => _detayGoster(isletme),
                                ),
                                const Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Şube: ${isletme['subeSayisi'] ?? 0}'
                                        '  •  Randevu: ${isletme['randevuSayisi'] ?? 0}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Switch(
                                      value: aktif,
                                      onChanged:
                                          id == null ||
                                                  _islemYapilanId != null
                                              ? null
                                              : (_) =>
                                                  _durumDegistir(isletme),
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
}
