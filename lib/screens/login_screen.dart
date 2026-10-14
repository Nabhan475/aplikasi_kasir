import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'auth_style.dart';
import 'login_form.dart';
import 'register_form.dart';

/// Halaman Auth (Login + Register dalam satu halaman).
///
/// Header gradient tetap di tempat. Saat pindah Login <-> Register:
/// 1. panel form turun ke bawah,
/// 2. teks judul & isi form berganti,
/// 3. panel form naik lagi.
///
/// Total durasi intro = [introPlayDuration] + [exitDuration] = 4 detik.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  // ===== INTRO ANIMATION =====
  // Letakkan file Lottie di: assets/lottie.json
  static const String lottiePath = 'assets/lottie.json';

  // Durasi intro: Lottie diputar 3.4 detik + transisi keluar 0.6 detik = 4 detik
  static const Duration introPlayDuration = Duration(milliseconds: 3400);
  static const Duration exitDuration = Duration(milliseconds: 600);

  // Tinggi header setelah intro selesai
  static const double loginHeaderHeight = 300;
  static const double registerHeaderHeight = 260;

  static const String loginTitle = 'Selamat Datang di Nova Kasir';
  static const String registerTitle = 'Buat Akun';
  static const String subtitle =
      'Sistem manajemen produk & transaksi terpercaya';

  // Controller untuk memutar Lottie
  late final AnimationController _lottieController;

  // Controller animasi teks judul saat pertama kali muncul
  late final AnimationController _titleController;
  late final Animation<double> _titleFade;
  late final Animation<double> _titleScale;

  // Controller teks di bawah Lottie (fade in saat awal)
  late final AnimationController _subtitleController;
  late final Animation<double> _subtitleFadeIn;

  // Controller transisi keluar Lottie + subtitle (satu driver supaya smooth)
  late final AnimationController _exitController;

  // Controller untuk panel form (naik / turun)
  late final AnimationController _formController;
  late final Animation<Offset> _formSlide;

  // Composition Lottie di-load DULU sebelum animasi apa pun dimulai,
  // supaya tidak ada jank / layout melompat saat pertama kali masuk
  LottieComposition? _composition;
  bool _introReady = false;
  late final Animation<double> _lottieFadeIn;

  bool _introFinished = false;
  bool _showForm = false;

  // false = tampilkan Login, true = tampilkan Register
  bool _isRegister = false;
  bool _switching = false;

  double get _headerHeight =>
      _isRegister ? registerHeaderHeight : loginHeaderHeight;

  @override
  void initState() {
    super.initState();

    _lottieController = AnimationController(vsync: this);

    _titleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _titleFade = CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _titleScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _titleController, curve: Curves.easeOutBack),
    );

    _lottieFadeIn = CurvedAnimation(
      parent: _titleController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _subtitleFadeIn = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    );

    _exitController = AnimationController(vsync: this, duration: exitDuration);

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
      reverseDuration: const Duration(milliseconds: 350),
    );
    _formSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );

    _loadIntro();
  }

  // Load file Lottie sampai selesai (parse JSON dilakukan di sini, bukan
  // saat animasi berjalan), baru semua animasi intro dimulai bersamaan.
  Future<void> _loadIntro() async {
    LottieComposition? composition;
    try {
      composition = await AssetLottie(lottiePath).load();
    } catch (_) {
      composition = null; // lottie.json belum ada / gagal dimuat
    }
    if (!mounted) return;

    setState(() {
      _composition = composition;
      _introReady = true;
    });

    // Tunggu frame pertama selesai digambar supaya animasi mulai dari
    // frame yang bersih (tidak ikut terhenti oleh layout awal)
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    _titleController.forward();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _subtitleController.forward();
    });

    if (composition != null) {
      // Durasi dipaksa 3.4 detik, berapa pun durasi asli file Lottie
      _lottieController
        ..duration = introPlayDuration
        ..forward().whenComplete(_onIntroFinished);
    } else {
      Future.delayed(introPlayDuration, _onIntroFinished);
    }
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _exitController.dispose();
    _formController.dispose();
    super.dispose();
  }

  // Dipanggil saat animasi intro (Lottie / fallback) selesai
  void _onIntroFinished() {
    if (_introFinished || !mounted) return;
    _introFinished = true;

    setState(() {
      _showForm = true;
    });

    // Header mengecil + Lottie & subtitle memudar dalam satu transisi
    _exitController.forward();

    // Form mulai naik sedikit setelah header mulai bergerak
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _formController.forward();
    });
  }

  // Pindah Login <-> Register:
  // panel turun -> isi & judul berganti -> panel naik
  Future<void> _switchMode(bool toRegister) async {
    if (_switching || !_showForm || _isRegister == toRegister) return;
    _switching = true;

    FocusScope.of(context).unfocus();

    try {
      // 1. Form turun ke bawah
      await _formController.reverse();
      if (!mounted) return;

      // 2. Ganti judul + isi form (header ikut menyesuaikan tinggi)
      setState(() {
        _isRegister = toRegister;
      });
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // 3. Form baru naik dari bawah
      await _formController.forward();
    } finally {
      _switching = false;
    }
  }

  // ===== UI =====

  Widget _buildTitle() {
    return FadeTransition(
      opacity: _titleFade,
      child: ScaleTransition(
        scale: _titleScale,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            // Teks lama memudar dulu (paruh pertama), baru teks baru muncul
            // (paruh kedua), supaya kedua teks tidak bertumpuk
            switchOutCurve: const Interval(0.5, 1.0, curve: Curves.easeIn),
            switchInCurve: const Interval(0.5, 1.0, curve: Curves.easeOut),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.25),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              );
            },
            child: Text(
              _isRegister ? registerTitle : loginTitle,
              key: ValueKey<bool>(_isRegister),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final composition = _composition;
    if (composition == null) return const SizedBox.shrink();

    // Ukuran dipastikan dari awal (rasio asli file) -> layout tidak melompat
    final bounds = composition.bounds;
    final height = 300 * bounds.height / bounds.width;

    return RepaintBoundary(
      child: FadeTransition(
        opacity: _lottieFadeIn,
        child: SizedBox(
          width: 300,
          height: height,
          child: Lottie(
            composition: composition,
            controller: _lottieController,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  // Isi header: teks di atas, Lottie + subtitle di bawahnya.
  // Saat form muncul, Lottie & subtitle memudar (fade) sambil ruangnya
  // mengecil, sehingga hanya judul yang tersisa.
  Widget _buildHeaderContent() {
    // Sebelum Lottie selesai di-load, tampilkan gradient saja (sangat singkat)
    if (!_introReady) return const SizedBox.shrink();

    // Lottie & subtitle dibangun sekali di luar builder agar tidak
    // di-rebuild tiap frame (Lottie tetap berjalan mulus)
    final lottie = _buildIntro();
    const subtitleText = Text(
      subtitle,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white70, fontSize: 16),
    );

    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTitle(),
            AnimatedBuilder(
              animation: Listenable.merge([
                _exitController,
                _subtitleController,
              ]),
              builder: (context, _) {
                final t = _exitController.value;

                // Ruang mengecil halus mengikuti kurva yang sama dengan header
                final collapse = Curves.easeInOutCubic.transform(t);

                // Lottie memudar di paruh awal transisi
                final lottieOpacity =
                    1.0 -
                    const Interval(
                      0.0,
                      0.5,
                      curve: Curves.easeOut,
                    ).transform(t);

                // Subtitle memudar sedikit lebih cepat dari Lottie
                final subtitleOutOpacity =
                    1.0 -
                    const Interval(
                      0.0,
                      0.4,
                      curve: Curves.easeOut,
                    ).transform(t);
                final subtitleOpacity =
                    _subtitleFadeIn.value * subtitleOutOpacity;

                return ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: 1.0 - collapse,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Opacity(opacity: lottieOpacity, child: lottie),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: subtitleOpacity,
                            child: subtitleText,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Panel putih berisi form login / register
  Widget _buildPanel() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(42),
          topRight: Radius.circular(42),
        ),
      ),
      child:
          _isRegister
              ? RegisterForm(
                key: const ValueKey('register'),
                onLoginTap: () => _switchMode(false),
              )
              : LoginForm(
                key: const ValueKey('login'),
                onRegisterTap: () => _switchMode(true),
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tombol back di halaman Register -> kembali ke Login (bukan keluar app)
      canPop: !_isRegister,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _switchMode(false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF3F5F6),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // BACKGROUND: gradient ungu selalu memenuhi seluruh layar,
                  // jadi tidak ada area abu-abu saat panel form turun
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AuthStyle.lightColor,
                            AuthStyle.primaryColor,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // HEADER (teks + Lottie): awalnya memenuhi layar (intro),
                  // lalu mengecil ke area atas
                  AnimatedPositioned(
                    duration: exitDuration,
                    curve: Curves.easeInOutCubic,
                    top: 0,
                    left: 0,
                    right: 0,
                    height: _showForm ? _headerHeight : constraints.maxHeight,
                    child: _buildHeaderContent(),
                  ),

                  // FORM: naik dari bawah setelah intro, turun-naik saat ganti mode
                  AnimatedPositioned(
                    duration: exitDuration,
                    curve: Curves.easeInOutCubic,
                    top: _headerHeight - 32,
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: SlideTransition(
                      position: _formSlide,
                      child: _buildPanel(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
