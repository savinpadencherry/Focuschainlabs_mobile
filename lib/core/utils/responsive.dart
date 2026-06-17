import 'package:flutter/widgets.dart';

/// Device size class derived from the available width. Drives adaptive
/// navigation (bottom bar vs rail), content max-width and column counts so the
/// same code renders well on phone, tablet and web.
enum DeviceType { mobile, tablet, desktop }

abstract final class Breakpoints {
  static const double tablet = 600;
  static const double desktop = 1024;

  /// Content is centred and capped on wide screens so lines stay readable.
  static const double contentMaxWidth = 1100;
  static const double readableMaxWidth = 720;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  DeviceType get deviceType {
    final double w = screenWidth;
    if (w >= Breakpoints.desktop) return DeviceType.desktop;
    if (w >= Breakpoints.tablet) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  bool get isMobile => deviceType == DeviceType.mobile;
  bool get isTablet => deviceType == DeviceType.tablet;
  bool get isDesktop => deviceType == DeviceType.desktop;
  bool get isWide => deviceType != DeviceType.mobile;

  /// Number of grid columns for card lists at the current width.
  int get gridColumns {
    switch (deviceType) {
      case DeviceType.desktop:
        return 3;
      case DeviceType.tablet:
        return 2;
      case DeviceType.mobile:
        return 1;
    }
  }

  /// Pick a value per breakpoint with a mobile fallback.
  T responsive<T>({required T mobile, T? tablet, T? desktop}) {
    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// Builds different widget trees per [DeviceType] without sprinkling
/// MediaQuery checks through feature code.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    switch (context.deviceType) {
      case DeviceType.desktop:
        return (desktop ?? tablet ?? mobile)(context);
      case DeviceType.tablet:
        return (tablet ?? mobile)(context);
      case DeviceType.mobile:
        return mobile(context);
    }
  }
}

/// Centres and caps page content on large screens.
class ContentBounds extends StatelessWidget {
  const ContentBounds({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
