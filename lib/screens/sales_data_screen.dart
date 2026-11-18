import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'page_header.dart';
import 'utils.dart';

enum _Period { day, week, month, all }

class _MenuStat {
  int qty = 0;
  int total = 0;
}

class _Summary {
  int revenue = 0;
  int transactions = 0;
  int items = 0;
  final Map<String, _MenuStat> menus = {};
  List<int> buckets = [];
  List<String> labels = [];
  int labelEvery = 1;

  int get average => transactions == 0 ? 0 : (revenue / transactions).round();
}

class SalesDataScreen extends StatefulWidget {
  const SalesDataScreen({super.key});

  @override
  State<SalesDataScreen> createState() => _SalesDataScreenState();
}

class _SalesDataScreenState extends State<SalesDataScreen> {
  static const Color purple = Color(0xFF6952AE);
  static const Color lightPurple = Color(0xFFAC94F5);
  static const Color bg = Color(0xFFF7F7FA);
  static const Color ink = Color(0xFF26242B);
  static const Color border = Color(0xFFECE8F3);

  String? businessId;
  bool loadingBusiness = true;

  _Period period = _Period.day;
  DateTime anchor = DateTime.now();
  bool sortByQty = true;

  Stream<QuerySnapshot<Map<String, dynamic>>>? _stream;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final id = await getBusinessId();
      if (!mounted) return;
      setState(() {
        businessId = id;
        loadingBusiness = false;
        if (id != null) _rebuildStream();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => loadingBusiness = false);
    }
  }

  // ---------------------------------------------------------------
  // PERIODE & QUERY (hanya ambil data pada rentang yang dipilih)
  // ---------------------------------------------------------------
  DateTimeRange? get _range {
    final a = anchor;
    switch (period) {
      case _Period.day:
        final s = DateTime(a.year, a.month, a.day);
        return DateTimeRange(
          start: s,
          end: DateTime(a.year, a.month, a.day + 1),
        );
      case _Period.week:
        final s = DateTime(a.year, a.month, a.day - (a.weekday - 1));
        return DateTimeRange(
          start: s,
          end: DateTime(s.year, s.month, s.day + 7),
        );
      case _Period.month:
        return DateTimeRange(
          start: DateTime(a.year, a.month, 1),
          end: DateTime(a.year, a.month + 1, 1),
        );
      case _Period.all:
        return null;
    }
  }

  void _rebuildStream() {
    Query<Map<String, dynamic>> q = transactionsRef(businessId!);
    final r = _range;
    if (r != null) {
      q = q
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(r.start),
          )
          .where('createdAt', isLessThan: Timestamp.fromDate(r.end));
    }
    _stream = q.snapshots();
  }

  void _setPeriod(_Period p) {
    if (p == period) return;
    setState(() {
      period = p;
      anchor = DateTime.now();
      _rebuildStream();
    });
  }

  void _shift(int dir) {
    setState(() {
      switch (period) {
        case _Period.day:
          anchor = DateTime(anchor.year, anchor.month, anchor.day + dir);
          break;
        case _Period.week:
          anchor = DateTime(anchor.year, anchor.month, anchor.day + 7 * dir);
          break;
        case _Period.month:
          anchor = DateTime(anchor.year, anchor.month + dir, 1);
          break;
        case _Period.all:
          break;
      }
      _rebuildStream();
    });
  }

  void _goToday() {
    setState(() {
      anchor = DateTime.now();
      _rebuildStream();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: anchor.isAfter(DateTime.now()) ? DateTime.now() : anchor,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      anchor = picked;
      _rebuildStream();
    });
  }

  bool get _isCurrent {
    final r = _range;
    if (r == null) return true;
    final now = DateTime.now();
    return !now.isBefore(r.start) && now.isBefore(r.end);
  }

  bool get _canNext {
    final r = _range;
    return r != null && !r.end.isAfter(DateTime.now());
  }

  String _short(int v) {
    String trim(double d) {
      final s = d.toStringAsFixed(1);
      return (s.endsWith('.0') ? s.substring(0, s.length - 2) : s).replaceAll(
        '.',
        ',',
      );
    }

    if (v >= 1000000) return '${trim(v / 1000000)}jt';
    if (v >= 1000) return '${(v / 1000).round()}rb';
    return '$v';
  }

  String _dayShort(DateTime d) =>
      '${d.day} ${indonesianMonths[d.month - 1].substring(0, 3)}';

  String get _title {
    final r = _range;
    switch (period) {
      case _Period.day:
        return formatTanggalIndonesia(anchor);
      case _Period.week:
        final last = r!.end.subtract(const Duration(days: 1));
        return '${_dayShort(r.start)} - ${_dayShort(last)} ${last.year}';
      case _Period.month:
        return '${indonesianMonths[anchor.month - 1]} ${anchor.year}';
      case _Period.all:
        return 'Semua Waktu';
    }
  }

  String get _subtitle {
    if (period == _Period.all) return 'Seluruh transaksi yang tercatat';
    if (_isCurrent) {
      return period == _Period.day
          ? 'Hari ini'
          : period == _Period.week
          ? 'Minggu ini'
          : 'Bulan ini';
    }
    return 'Ketuk untuk pilih tanggal';
  }

  // ---------------------------------------------------------------
  // HITUNG RINGKASAN (satu kali jalan)
  // ---------------------------------------------------------------
  _Summary _summarize(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final s = _Summary();
    final r = _range;

    int bucketCount = 0;
    if (period == _Period.day) {
      bucketCount = 24;
      s.labels = List.generate(24, (i) => '$i');
      s.labelEvery = 4;
    } else if (period == _Period.week) {
      bucketCount = 7;
      s.labels = const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    } else if (period == _Period.month) {
      bucketCount = DateTime(anchor.year, anchor.month + 1, 0).day;
      s.labels = List.generate(bucketCount, (i) => '${i + 1}');
      s.labelEvery = 5;
    }
    s.buckets = List.filled(bucketCount, 0);

    for (final doc in docs) {
      final data = doc.data();
      final total = ((data['total'] as num?) ?? 0).toInt();
      s.revenue += total;
      s.transactions++;

      final ts = data['createdAt'];
      if (ts is Timestamp && r != null && bucketCount > 0) {
        final d = ts.toDate();
        int idx;
        if (period == _Period.day) {
          idx = d.hour;
        } else if (period == _Period.week) {
          idx = d.weekday - 1;
        } else {
          idx = d.day - 1;
        }
        if (idx >= 0 && idx < bucketCount) s.buckets[idx] += total;
      }

      final items = (data['items'] as List<dynamic>?) ?? const [];
      for (final raw in items) {
        if (raw is Map) {
          final name = (raw['name'] ?? 'Menu').toString();
          final qty = ((raw['qty'] as num?) ?? 0).toInt();
          final sub = ((raw['subtotal'] as num?) ?? 0).toInt();
          s.items += qty;
          final m = s.menus.putIfAbsent(name, _MenuStat.new);
          m.qty += qty;
          m.total += sub;
        }
      }
    }
    return s;
  }

  // ---------------------------------------------------------------
  // WIDGET
  // ---------------------------------------------------------------
  BoxDecoration get _cardDeco => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: border),
    boxShadow: [
      BoxShadow(
        color: purple.withValues(alpha: 0.04),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _periodChip(String label, _Period p) {
    final active = period == p;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setPeriod(p),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? purple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterCard(bool loading) {
    final showNav = period != _Period.all;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FA),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                _periodChip('Hari', _Period.day),
                _periodChip('Minggu', _Period.week),
                _periodChip('Bulan', _Period.month),
                _periodChip('Semua', _Period.all),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (showNav)
                IconButton(
                  onPressed: () => _shift(-1),
                  tooltip: 'Sebelumnya',
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: purple,
                )
              else
                const SizedBox(width: 48),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: showNav ? _pickDate : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ink,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (showNav)
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 13,
                                color: purple,
                              ),
                            if (showNav) const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _subtitle,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.grey.shade600,
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
              if (showNav)
                IconButton(
                  onPressed: _canNext ? () => _shift(1) : null,
                  tooltip: 'Berikutnya',
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: purple,
                )
              else
                const SizedBox(width: 48),
            ],
          ),
          if (showNav && !_isCurrent)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _goToday,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: Text(
                  period == _Period.day
                      ? 'Ke hari ini'
                      : period == _Period.week
                      ? 'Ke minggu ini'
                      : 'Ke bulan ini',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: purple,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          if (loading) ...[
            const SizedBox(height: 6),
            const ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(4)),
              child: LinearProgressIndicator(
                minHeight: 3,
                color: purple,
                backgroundColor: Color(0xFFEDE7FF),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _smallStat(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _cardDeco,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: lightPurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, size: 16, color: purple),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsSection(_Summary s) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF866FC9), purple],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: purple.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Colors.white70,
                    size: 18,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Total Pemasukan',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatRupiah(s.revenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _smallStat(
              Icons.receipt_long_outlined,
              'Transaksi',
              '${s.transactions}',
            ),
            const SizedBox(width: 10),
            _smallStat(
              Icons.restaurant_menu_rounded,
              'Porsi terjual',
              '${s.items}',
            ),
            const SizedBox(width: 10),
            _smallStat(
              Icons.trending_up_rounded,
              'Rata-rata/transaksi',
              formatRupiah(s.average),
            ),
          ],
        ),
      ],
    );
  }

  Widget _chartCard(_Summary s) {
    if (s.buckets.isEmpty) return const SizedBox.shrink();

    final maxV = s.buckets.fold<int>(0, (m, v) => v > m ? v : m);
    final peakIdx = maxV == 0 ? -1 : s.buckets.indexOf(maxV);
    final unit =
        period == _Period.day
            ? 'jam'
            : period == _Period.week
            ? 'hari'
            : 'tanggal';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: _cardDeco,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tren Pemasukan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            peakIdx < 0
                ? 'Belum ada pemasukan pada periode ini'
                : 'Puncak: $unit ${s.labels[peakIdx]} • ${formatRupiah(maxV)}',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < s.buckets.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: '${s.labels[i]}: ${formatRupiah(s.buckets[i])}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 1.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            heightFactor:
                                maxV == 0
                                    ? 0.03
                                    : (s.buckets[i] / maxV).clamp(0.03, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    i == peakIdx
                                        ? purple
                                        : lightPurple.withValues(
                                          alpha: s.buckets[i] == 0 ? 0.25 : 0.7,
                                        ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < s.buckets.length; i++)
                Expanded(
                  child: Center(
                    child: Text(
                      (period == _Period.week || i % s.labelEvery == 0)
                          ? s.labels[i]
                          : '',
                      softWrap: false,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (maxV > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Tertinggi ${_short(maxV)}',
              style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sortChip(String label, bool byQty) {
    final active = sortByQty == byQty;
    return GestureDetector(
      onTap: () => setState(() => sortByQty = byQty),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? purple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: active ? purple : const Color(0xFFE2DDEC)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _menuHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Rekap Menu Terjual',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ink,
                ),
              ),
            ),
            Text(
              '$count menu',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _sortChip('Terlaris', true),
            const SizedBox(width: 8),
            _sortChip('Pemasukan', false),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _menuTile(
    int index,
    String name,
    _MenuStat m,
    int topValue,
    int revenue,
  ) {
    final value = sortByQty ? m.qty : m.total;
    final progress = topValue == 0 ? 0.0 : value / topValue;
    final share = revenue == 0 ? 0 : (m.total * 100 / revenue).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: _cardDeco,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: index == 0 ? purple : lightPurple.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: index == 0 ? Colors.white : purple,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${m.qty} porsi',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: purple,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 5,
                    color: purple,
                    backgroundColor: const Color(0xFFEDE7FF),
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      formatRupiah(m.total),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$share% dari pemasukan',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMenu() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 20),
      decoration: _cardDeco,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 46,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 10),
          const Text(
            'Belum ada penjualan pada periode ini',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Transaksi kasir akan otomatis muncul di sini.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // Daftar menu sebagai sliver (hanya item terlihat yang dibangun)
  List<Widget> _menuSlivers(_Summary s) {
    final keys =
        s.menus.keys.toList()..sort((a, b) {
          final ma = s.menus[a]!, mb = s.menus[b]!;
          final c =
              sortByQty
                  ? mb.qty.compareTo(ma.qty)
                  : mb.total.compareTo(ma.total);
          return c != 0 ? c : a.compareTo(b);
        });

    final top =
        keys.isEmpty
            ? 0
            : (sortByQty
                ? s.menus[keys.first]!.qty
                : s.menus[keys.first]!.total);

    return [
      SliverToBoxAdapter(child: _menuHeader(keys.length)),
      if (keys.isEmpty)
        SliverToBoxAdapter(child: _emptyMenu())
      else
        SliverList.builder(
          itemCount: keys.length,
          itemBuilder:
              (_, i) =>
                  _menuTile(i, keys[i], s.menus[keys[i]]!, top, s.revenue),
        ),
    ];
  }

  // ---------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------
  PreferredSizeWidget _appBar() => slimAppBar('Data Penjualan');

  @override
  Widget build(BuildContext context) {
    if (loadingBusiness) {
      return const Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator(color: purple)),
      );
    }

    if (businessId == null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _appBar(),
        body: const Center(
          child: Text('Data usaha tidak ditemukan. Silakan login ulang.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat data penjualan.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final loading = !snapshot.hasData;
          final summary = _summarize(snapshot.data?.docs ?? const []);

          return LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 760;

              final top = <Widget>[
                _filterCard(loading),
                const SizedBox(height: 12),
                _statsSection(summary),
                const SizedBox(height: 12),
                _chartCard(summary),
              ];

              if (wide) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.only(bottom: 100),
                              child: Column(children: top),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 6,
                            child: CustomScrollView(
                              slivers: [
                                ..._menuSlivers(summary),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 100),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            children: [...top, const SizedBox(height: 20)],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        sliver: SliverMainAxisGroup(
                          slivers: _menuSlivers(summary),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
