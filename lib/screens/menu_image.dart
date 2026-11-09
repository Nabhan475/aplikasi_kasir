import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Menampilkan gambar menu dari base64 (`imageBase64`) atau,
/// untuk data lama, dari URL (`imageUrl`).
class MenuImage extends StatefulWidget {
  final String imageBase64;
  final String imageUrl;
  final Widget placeholder;
  final BoxFit fit;

  const MenuImage({
    super.key,
    required this.imageBase64,
    required this.imageUrl,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  /// Helper: bangun dari data dokumen Firestore.
  factory MenuImage.fromData(
    Map<String, dynamic> data, {
    required Widget placeholder,
    BoxFit fit = BoxFit.cover,
  }) {
    return MenuImage(
      imageBase64: (data['imageBase64'] ?? '').toString(),
      imageUrl: (data['imageUrl'] ?? '').toString(),
      placeholder: placeholder,
      fit: fit,
    );
  }

  @override
  State<MenuImage> createState() => _MenuImageState();
}

class _MenuImageState extends State<MenuImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant MenuImage old) {
    super.didUpdateWidget(old);
    if (old.imageBase64 != widget.imageBase64) _decode();
  }

  // Decode sekali saja (bukan di setiap build) supaya ringan.
  void _decode() {
    if (widget.imageBase64.isEmpty) {
      _bytes = null;
      return;
    }
    try {
      _bytes = base64Decode(widget.imageBase64);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => widget.placeholder,
      );
    }
    if (widget.imageUrl.isNotEmpty) {
      return Image.network(
        widget.imageUrl,
        fit: widget.fit,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => widget.placeholder,
      );
    }
    return widget.placeholder;
  }
}