import 'package:flutter/material.dart';
import 'personel_izin_api.dart';

class PersonelIzinleriSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> personeller;
  const PersonelIzinleriSayfasi({super.key, required this.personeller});

  @override
  State<PersonelIzinleriSayfasi> createState() => _PersonelIzinleriSayfasiState();
}

class _PersonelIzinleriSayfasiState extends State<PersonelIzinleriSayfasi> {
  static const lacivert = Color(0xFF101F43);
  static const mavi = Color(0xFF2563EB);
  List<Map<String, dynamic>> izinler = [];
  bool yukleniyor = true;
  bool islemde = false;
  String? hata;

  @override
  void initState() {
    super.initState();
    yukle();
  }

  Future<void> yukle() async {
    setState(() { yukleniyor = true; hata = null; });
    try {
      final veri = await PersonelIzinApi.listele();
      if (!mounted) return;
      setState(() => izinler = veri);
    } catch (e) {
      if (mounted) setState(() => hata = e.toString());
    } finally {
      if (mounted) setState(() => yukleniyor = false);
    }
  }

  void mesaj(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
  }

  String tarihSaat(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Future<DateTime?> tarihSaatSec(BuildContext dialogContext, DateTime ilk) async {
    final tarih = await showDatePicker(
      context: dialogContext,
      initialDate: ilk,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      locale: const Locale('tr', 'TR'),
    );
    if (tarih == null || !dialogContext.mounted) return null;
    final saat = await showTimePicker(
      context: dialogContext,
      initialTime: TimeOfDay.fromDateTime(ilk),
    );
    if (saat == null) return null;
    return DateTime(tarih.year, tarih.month, tarih.day, saat.hour, saat.minute);
  }

  Future<void> izinEkle() async {
    final aktifler = widget.personeller.where((p) => p['aktif'] == true && p['id'] is int).toList();
    if (aktifler.isEmpty) {
      mesaj('Önce aktif personel ekleyin.');
      return;
    }
    int? personelId = aktifler.first['id'] as int;
    DateTime baslangic = DateTime.now().add(const Duration(days: 1));
    baslangic = DateTime(baslangic.year, baslangic.month, baslangic.day, 9);
    DateTime bitis = baslangic.add(const Duration(hours: 8));
    final aciklama = TextEditingController();
    final sonuc = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, yenile) => AlertDialog(
          title: const Text('Yeni Personel İzni', style: TextStyle(color: lacivert, fontWeight: FontWeight.bold)),
          content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                value: personelId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Personel', border: OutlineInputBorder()),
                items: aktifler.map((p) => DropdownMenuItem<int>(
                  value: p['id'] as int,
                  child: Text(p['ad']?.toString() ?? 'Personel', overflow: TextOverflow.ellipsis),
                )).toList(),
                onChanged: (v) => yenile(() => personelId = v),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final secim = await tarihSaatSec(dialogContext, baslangic);
                  if (secim != null) yenile(() => baslangic = secim);
                },
                icon: const Icon(Icons.event_available_outlined),
                label: Text('Başlangıç: ${tarihSaat(baslangic)}'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  final secim = await tarihSaatSec(dialogContext, bitis);
                  if (secim != null) yenile(() => bitis = secim);
                },
                icon: const Icon(Icons.event_busy_outlined),
                label: Text('Bitiş: ${tarihSaat(bitis)}'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: aciklama,
                maxLength: 250,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Açıklama (isteğe bağlı)',
                  hintText: 'Örn. Yıllık izin',
                  border: OutlineInputBorder(),
                ),
              ),
              if (!bitis.isAfter(baslangic))
                const Text('Bitiş başlangıçtan sonra olmalı.', style: TextStyle(color: Colors.red)),
            ],
          ))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Vazgeç')),
            FilledButton(
              onPressed: personelId == null || !bitis.isAfter(baslangic) || baslangic.isBefore(DateTime.now())
                  ? null
                  : () => Navigator.pop(dialogContext, {
                      'personelId': personelId!,
                      'baslangic': baslangic,
                      'bitis': bitis,
                      'aciklama': aciklama.text.trim(),
                    }),
              child: const Text('İzin Kaydet'),
            ),
          ],
        ),
      ),
    );
    // Diyalog kapanış animasyonu bitince temizle.
    WidgetsBinding.instance.addPostFrameCallback((_) => aciklama.dispose());
    if (sonuc == null || !mounted) return;
    setState(() => islemde = true);
    try {
      await PersonelIzinApi.ekle(
        personelId: sonuc['personelId'] as int,
        baslangic: sonuc['baslangic'] as DateTime,
        bitis: sonuc['bitis'] as DateTime,
        aciklama: sonuc['aciklama'] as String,
      );
      await yukle();
      mesaj('Personel izni kaydedildi.');
    } catch (e) {
      mesaj('İzin eklenemedi: $e');
    } finally {
      if (mounted) setState(() => islemde = false);
    }
  }

  Future<void> izinSil(Map<String, dynamic> izin) async {
    final onay = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('İzni Kaldır'),
      content: Text('${izin['personel'] ?? 'Personel'} için izin kaydı kaldırılsın mı?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        TextButton(onPressed: () => Navigator.pop(ctx, true),
          child: const Text('İzni Kaldır', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (onay != true || !mounted) return;
    setState(() => islemde = true);
    try {
      await PersonelIzinApi.sil(izin['id'] as int);
      await yukle();
      mesaj('İzin kaldırıldı.');
    } catch (e) {
      mesaj('İzin kaldırılamadı: $e');
    } finally {
      if (mounted) setState(() => islemde = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF1F5FB),
    appBar: AppBar(
      title: const Text('Personel İzinleri', style: TextStyle(color: lacivert, fontWeight: FontWeight.bold)),
      backgroundColor: Colors.white,
      actions: [IconButton(onPressed: yukleniyor || islemde ? null : yukle, icon: const Icon(Icons.refresh, color: mavi))],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: islemde ? null : izinEkle,
      backgroundColor: mavi,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Yeni İzin'),
    ),
    body: RefreshIndicator(
      onRefresh: yukle,
      child: ListView(padding: const EdgeInsets.fromLTRB(16, 18, 16, 100), children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [lacivert, mavi]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.event_busy_rounded, color: Colors.white, size: 30),
            const SizedBox(height: 12),
            Text('${izinler.length} izin kaydı', style: const TextStyle(
              color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Ekibinizin izinlerini yönetin.', style: TextStyle(color: Color(0xFFDBEAFE))),
          ]),
        ),
        const SizedBox(height: 20),
        if (yukleniyor) const Center(child: CircularProgressIndicator()),
        if (hata != null) Card(child: ListTile(
          title: const Text('İzinler yüklenemedi'),
          subtitle: Text(hata!),
          trailing: IconButton(onPressed: yukle, icon: const Icon(Icons.refresh)),
        )),
        if (!yukleniyor && hata == null && izinler.isEmpty)
          const Card(child: Padding(padding: EdgeInsets.all(24),
            child: Center(child: Text('Henüz izin kaydı bulunmuyor.')))),
        ...izinler.map((izin) {
          final bas = DateTime.tryParse(izin['baslangic']?.toString() ?? '');
          final bit = DateTime.tryParse(izin['bitis']?.toString() ?? '');
          return Card(
            color: Colors.white, elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(padding: const EdgeInsets.all(14), child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const CircleAvatar(backgroundColor: Color(0xFFDBEAFE),
                    child: Icon(Icons.person_outline, color: mavi)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(izin['personel']?.toString() ?? 'Personel',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: lacivert, fontSize: 16))),
                  IconButton(
                    tooltip: 'İzni kaldır',
                    onPressed: islemde ? null : () => izinSil(izin),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ]),
                const SizedBox(height: 8),
                Text('Başlangıç: ${bas == null ? '-' : tarihSaat(bas)}'),
                const SizedBox(height: 4),
                Text('Bitiş: ${bit == null ? '-' : tarihSaat(bit)}'),
                if ((izin['aciklama']?.toString() ?? '').isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(izin['aciklama'].toString(),
                    style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ],
            )),
          );
        }),
      ]),
    ),
  );
}
