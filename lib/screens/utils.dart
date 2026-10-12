/// Format angka menjadi Rupiah, contoh: 15000 -> Rp15.000
String formatRupiah(num value) {
  final s = value.toInt().toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return 'Rp$buf';
}