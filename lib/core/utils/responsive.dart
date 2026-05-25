import 'package:flutter/widgets.dart';

class Responsive {
  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width < 380;
  static double maxContentWidth(BuildContext context) => MediaQuery.sizeOf(context).width.clamp(0, 480).toDouble();
}

