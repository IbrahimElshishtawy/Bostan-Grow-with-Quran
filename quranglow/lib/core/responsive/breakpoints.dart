import 'package:flutter/material.dart';

enum WindowWidthClass {
  compact,
  medium,
  expanded;

  bool get isCompact => this == WindowWidthClass.compact;
  bool get isMedium => this == WindowWidthClass.medium;
  bool get isExpanded => this == WindowWidthClass.expanded;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double compactMaxWidth = 599.0;
  static const double mediumMaxWidth = 839.0;
  static const double expandedMinWidth = 840.0;

  static WindowWidthClass getWidthClass(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return WindowWidthClass.compact;
    } else if (width < 840) {
      return WindowWidthClass.medium;
    } else {
      return WindowWidthClass.expanded;
    }
  }

  static T valueByBreakpoint<T>({
    required BuildContext context,
    required T compact,
    T? medium,
    T? expanded,
  }) {
    final widthClass = getWidthClass(context);
    return switch (widthClass) {
      WindowWidthClass.compact => compact,
      WindowWidthClass.medium => medium ?? compact,
      WindowWidthClass.expanded => expanded ?? medium ?? compact,
    };
  }
}
