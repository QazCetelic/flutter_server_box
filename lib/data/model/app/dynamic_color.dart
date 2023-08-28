import 'package:flutter/widgets.dart';

import '../../../core/extension/context.dart';

class DynamicColor {
  /// 白天模式显示的颜色
  Color light;

  /// 暗黑模式显示的颜色
  Color dark;

  DynamicColor(this.light, this.dark);

  Color resolve(BuildContext context) => context.isDark ? dark : light;
}
