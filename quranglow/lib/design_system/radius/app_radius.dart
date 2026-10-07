import 'package:flutter/widgets.dart';

class AppRadius {
  AppRadius._();

  static const double s = 6.0;
  static const double m = 12.0;
  static const double l = 16.0;
  static const double xl = 24.0;
  static const double full = 999.0;

  static const BorderRadius roundedS = BorderRadius.all(Radius.circular(s));
  static const BorderRadius roundedM = BorderRadius.all(Radius.circular(m));
  static const BorderRadius roundedL = BorderRadius.all(Radius.circular(l));
  static const BorderRadius roundedXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(full));
}
