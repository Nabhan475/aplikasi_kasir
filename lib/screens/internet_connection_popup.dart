import 'dart:async';

import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class InternetConnectionPopup extends StatefulWidget {
  const InternetConnectionPopup({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  State<InternetConnectionPopup> createState() =>
      _InternetConnectionPopupState();
}

class _InternetConnectionPopupState extends State<InternetConnectionPopup> {
  late final InternetConnection _internetConnection =
      InternetConnection.createInstance();
  StreamSubscription<InternetStatus>? _statusSubscription;

  bool? _isConnected;
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startMonitoring();
    });
  }

  void _startMonitoring() {
    _statusSubscription = _internetConnection.onStatusChange.listen(
      _handleStatusChange,
      onError: (Object error, StackTrace stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'internet connection monitoring',
          ),
        );
      },
    );
    unawaited(_readInitialStatus());
  }

  Future<void> _readInitialStatus() async {
    final status = await _internetConnection.internetStatus;
    if (mounted) _handleStatusChange(status);
  }

  void _handleStatusChange(InternetStatus status) {
    final wasConnected = _isConnected;
    _isConnected = status == InternetStatus.connected;

    if (_isConnected!) {
      if (_dialogOpen) _dismissDialog();
    } else if (wasConnected != false) {
      _showDialog();
    }
  }

  void _showDialog() {
    final dialogContext = widget.navigatorKey.currentContext;
    if (_dialogOpen || dialogContext == null) return;

    _dialogOpen = true;
    showDialog<void>(
      context: dialogContext,
      useRootNavigator: true,
      barrierDismissible: false,
      builder:
          (context) => _OfflineConnectionDialog(
            onRetry: () => _internetConnection.hasInternetAccess,
            onClose: _dismissDialog,
          ),
    ).whenComplete(() {
      _dialogOpen = false;
    });
  }

  void _dismissDialog() {
    if (!_dialogOpen) return;
    _dialogOpen = false;
    widget.navigatorKey.currentState?.pop();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    unawaited(_internetConnection.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _OfflineConnectionDialog extends StatefulWidget {
  const _OfflineConnectionDialog({
    required this.onRetry,
    required this.onClose,
  });

  final Future<bool> Function() onRetry;
  final VoidCallback onClose;

  @override
  State<_OfflineConnectionDialog> createState() =>
      _OfflineConnectionDialogState();
}

class _OfflineConnectionDialogState extends State<_OfflineConnectionDialog> {
  bool _isChecking = false;
  String? _retryMessage;

  Future<void> _retryConnection() async {
    setState(() {
      _isChecking = true;
      _retryMessage = null;
    });

    try {
      if (await widget.onRetry()) {
        widget.onClose();
        return;
      }
      if (mounted) {
        setState(() {
          _retryMessage =
              'Koneksi belum tersedia. Nyalakan internet atau cari koneksi yang lebih baik.';
        });
      }
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'internet connection retry',
        ),
      );
      if (mounted) {
        setState(() {
          _retryMessage = 'Koneksi belum dapat diperiksa. Silakan coba lagi.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.deepOrange,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Koneksi internet terputus',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Nyalakan Wi-Fi atau data seluler. Jika sudah tersambung, '
              'cari koneksi internet yang lebih baik, lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            if (_retryMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _retryMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.deepOrange, fontSize: 13),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isChecking ? null : _retryConnection,
                child:
                    _isChecking
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text('Coba lagi'),
              ),
            ),
            TextButton(
              onPressed: _isChecking ? null : widget.onClose,
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }
}
