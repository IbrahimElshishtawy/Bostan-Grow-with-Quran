import 'package:flutter/material.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

class ProAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.onBack,
    this.showBack = true,
    this.height = 94,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final bool showBack;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final backButton = showBack
        ? Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: IconButton.filledTonal(
              tooltip: 'رجوع',
              onPressed:
                  onBack ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).maybePop();
                    } else {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppRoutes.home,
                        (route) => false,
                      );
                    }
                  },
              style: IconButton.styleFrom(
                backgroundColor: cs.surface.withValues(alpha: 0.82),
                foregroundColor: cs.primary,
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              icon: Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_back_rounded,
              ),
            ),
          )
        : null;

    return AppBar(
      toolbarHeight: height,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 10,
      flexibleSpace: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              cs.primary.withValues(alpha: 0.16),
              cs.tertiary.withValues(alpha: 0.08),
              cs.surface,
            ],
          ),
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
        ),
      ),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (actions != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
          ),
        if (backButton != null) backButton,
      ],
    );
  }
}
