import 'package:flutter/material.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';

class AppBootstrapScope extends StatefulWidget {
  const AppBootstrapScope({super.key, required this.child});

  final Widget child;

  @override
  State<AppBootstrapScope> createState() => _AppBootstrapScopeState();
}

class _AppBootstrapScopeState extends State<AppBootstrapScope>
    with WidgetsBindingObserver {
  bool _asked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAsk());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tryAsk();
  }

  Future<void> _tryAsk() async {
    if (!mounted || _asked) return;
    _asked = true;
    await NotificationService.instance.requestPermissionsIfNeededFromUI(
      context,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
