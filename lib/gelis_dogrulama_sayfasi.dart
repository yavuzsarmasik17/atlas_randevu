import 'package:flutter/material.dart';

class GelisDogrulamaSayfasi extends StatefulWidget {
  final List<Map<String, dynamic>> randevular;
  const GelisDogrulamaSayfasi({super.key, required this.randevular});
  @override
  State<GelisDogrulamaSayfasi> createState() => _GelisDogrulamaSayfasiState();
}

class _GelisDogrulamaSayfasiState extends State<GelisDogrulamaSayfasi> {
  static const kod = 'ATLAS2026';
  final controller = TextEditingController();
  bool kodDogru = false;

  @override
  void dispose() { controller.dispose(); super.dispose(); }

  void kontrol() {
    setState(() => kodDogru = controller.text.trim().toUpperCase() == kod);
    if (!kodDogru) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kod hatalı.')));
  }

  @override
  Widget build(BuildContext context) {
    final uygunlar = widget.randevular.where((r) =>
      DateUtils.isSameDay(r['tarih'] as DateTime? ?? DateTime.now(), DateTime.now()) &&
      r['durum'] == 'Onaylandı' && r['geldi'] != true).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Müşteri Geliş Doğrulama')),
      backgroundColor: const Color(0xFFF1F5FB),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        const Card(color: Colors.white, child: Padding(padding: EdgeInsets.all(18), child: Column(children: [
          Icon(Icons.verified_user_outlined, size: 52, color: Color(0xFF2563EB)),
          SizedBox(height: 10),
          Text('Ortak İşletme Geliş Kodu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SelectableText(kod, style: TextStyle(fontSize: 30, letterSpacing: 3, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Bu ekran demo amaçlıdır. QR okutma ve gerçek müşteri kimliği doğrulaması API bağlantısından sonra etkinleştirilecektir.', textAlign: TextAlign.center),
        ]))),
        const SizedBox(height: 14),
        TextField(controller: controller, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Geliş Kodunu Gir', border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: kontrol, icon: const Icon(Icons.check), label: const Text('Kodu Kontrol Et')),
        if (kodDogru) ...[
          const SizedBox(height: 22),
          const Text('Bugünkü Onaylı Randevular', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (uygunlar.isEmpty) const Card(child: ListTile(title: Text('Gelişi doğrulanacak randevu yok.'))),
          ...uygunlar.map((r) => Card(color: Colors.white, child: ListTile(
            title: Text(r['musteri'].toString()),
            subtitle: Text('${r['saat']} • ${r['hizmet']} • ${r['personel']}'),
            trailing: FilledButton(onPressed: () {
              setState(() => r['geldi'] = true);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${r['musteri']} için geliş kaydedildi (demo).')));
            }, child: const Text('Geldi')),
          ))),
        ],
      ]),
    );
  }
}
