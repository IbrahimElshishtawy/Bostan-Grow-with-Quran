import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:quranglow/core/service/sync/firebase_guard.dart';
import 'package:quranglow/core/widgets/restart_app.dart';

class GlobalErrorBoundary extends StatefulWidget {
  final Widget child;

  const GlobalErrorBoundary({super.key, required this.child});

  @override
  State<GlobalErrorBoundary> createState() => _GlobalErrorBoundaryState();
}

class _GlobalErrorBoundaryState extends State<GlobalErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  bool _rebuildScheduled = false;
  FlutterExceptionHandler? _previousOnError;

  void _setError(Object error) {
    if (!mounted) return;

    void apply() {
      if (!mounted) return;
      _rebuildScheduled = false;
      setState(() {
        _hasError = true;
        _error = error;
      });
    }

    final phase = WidgetsBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      apply();
      return;
    }

    if (_rebuildScheduled) return;
    _rebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => apply());
  }

  @override
  void initState() {
    super.initState();
    _previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (FirebaseGuard.isReady) {
        FirebaseCrashlytics.instance.recordFlutterError(details);
      }
      _setError(details.exception);
      _previousOnError?.call(details);
    };
  }

  @override
  void dispose() {
    FlutterError.onError = _previousOnError;
    super.dispose();
  }

  static Widget _defaultErrorBuilder(BuildContext context, Object error) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'عذرًا، حدث خطأ غير متوقع',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => RestartApp.restartApp(context),
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _defaultErrorBuilder(context, _error!);
    }
    return widget.child;
  }
}

extension ErrorBoundaryExtension on Widget {
  Widget withErrorBoundary() => GlobalErrorBoundary(child: this);
}
