import 'package:flutter/material.dart';
import '../colors/app_palette.dart';
import '../spacing/app_spacing.dart';

class AppLoadingView extends StatelessWidget {
  final String? message;

  const AppLoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppPalette.primary),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.m),
            Text(message!, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
          ],
        ],
      ),
    );
  }
}

class AppEmptyView extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData icon;

  const AppEmptyView({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppPalette.textSecondaryLight),
            const SizedBox(height: AppSpacing.m),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.l),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorView({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppPalette.error),
            const SizedBox(height: AppSpacing.m),
            Text(message, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.l),
              FilledButton.tonal(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
