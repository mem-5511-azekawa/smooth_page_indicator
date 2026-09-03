import 'package:flutter/widgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

/// Holds default colors for an indicator.
class DefaultIndicatorColors {
  /// The color for active dots.
  final Color active;

  /// The color for inactive dots.
  final Color inactive;

  /// Creates an [DefaultIndicatorColors] instance
  const DefaultIndicatorColors({
    required this.active,
    required this.inactive,
  });

  /// Resolves [dotColor] using the provided [DefaultIndicatorColors] if null
  Color resolveInactiveColor(BasicIndicatorEffect effect) {
    return effect.dotColor ?? inactive;
  }

  /// Resolves [activeDotColor] using the provided [DefaultIndicatorColors] if null
  Color resolveActiveColor(BasicIndicatorEffect effect) {
    return effect.activeDotColor ?? active;
  }

  /// Fallback colors used when no [SmoothPageIndicatorTheme] supplies colors.
  static const defaults = DefaultIndicatorColors(
    active: Color(0xFF3F51B5),
    inactive: Color(0xFF9E9E9E),
  );

  /// Linearly interpolates between two [DefaultIndicatorColors].
  DefaultIndicatorColors lerp(DefaultIndicatorColors? other, double t) {
    if (other == null) return this;
    return DefaultIndicatorColors(
      active: Color.lerp(active, other.active, t)!,
      inactive: Color.lerp(inactive, other.inactive, t)!,
    );
  }
}

/// An [InheritedTheme] that provides default configuration to descendant
/// [SmoothPageIndicator] and [AnimatedSmoothIndicator] widgets.
///
/// Usage:
/// ```dart
/// MaterialApp(
///   home: SmoothPageIndicatorTheme(
///     effect: ExpandingDotsEffect(),
///     defaultColors: DefaultIndicatorColors(
///       active: Colors.blue,
///       inactive: Colors.grey,
///     ),
///     child: MyPage(),
///   ),
/// )
/// ```
class SmoothPageIndicatorTheme extends InheritedTheme {
  /// The default effect to use when none is specified.
  /// If null, [WormEffect] will be used as the fallback.
  final IndicatorEffect? effect;

  /// Default colors for the indicator.
  /// If null, [DefaultIndicatorColors.defaults] will be used.
  final DefaultIndicatorColors? defaultColors;

  /// Creates a [SmoothPageIndicatorTheme] instance
  const SmoothPageIndicatorTheme({
    super.key,
    this.effect,
    this.defaultColors,
    required super.child,
  });

  /// Creates a copy of this theme, replacing non-null arguments.
  SmoothPageIndicatorTheme copyWith({
    IndicatorEffect? effect,
    DefaultIndicatorColors? colors,
    Widget? child,
  }) {
    return SmoothPageIndicatorTheme(
      effect: effect ?? this.effect,
      defaultColors: colors ?? defaultColors,
      child: child ?? this.child,
    );
  }

  /// Linearly interpolates this theme's values with [other].
  SmoothPageIndicatorTheme lerp(
    SmoothPageIndicatorTheme? other,
    double t,
  ) {
    if (other is! SmoothPageIndicatorTheme) {
      return this;
    }

    // Lerp effects if both are non-null and same type
    IndicatorEffect? lerpedEffect;
    if (effect != null &&
        other.effect != null &&
        effect.runtimeType == other.effect.runtimeType) {
      lerpedEffect = effect!.lerp(other.effect, t);
    } else {
      lerpedEffect = t < 0.5 ? effect : other.effect;
    }

    // Lerp colors if both are non-null
    final lerpedColors = defaultColors?.lerp(other.defaultColors, t) ??
        (t < 0.5 ? null : other.defaultColors);

    return SmoothPageIndicatorTheme(
      effect: lerpedEffect,
      defaultColors: lerpedColors,
      child: t < 0.5 ? child : other.child,
    );
  }

  @override

  /// Returns whether dependents should rebuild after this theme changes.
  bool updateShouldNotify(SmoothPageIndicatorTheme oldWidget) {
    return effect != oldWidget.effect ||
        defaultColors != oldWidget.defaultColors;
  }

  @override

  /// Wraps [child] with this theme when it is moved to a new subtree.
  Widget wrap(BuildContext context, Widget child) {
    return SmoothPageIndicatorTheme(
      effect: effect,
      defaultColors: defaultColors,
      child: child,
    );
  }

  /// Retrieves the [SmoothPageIndicatorTheme] from the given [BuildContext].
  /// Returns null if no ancestor theme is found.
  static SmoothPageIndicatorTheme? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SmoothPageIndicatorTheme>();
  }

  /// Resolves the [IndicatorEffect] and [DefaultIndicatorColors] from the
  /// nearest theme, or provides fallbacks.
  /// If no effect is specified in the theme, defaults to [WormEffect].
  /// If no colors are specified, uses [DefaultIndicatorColors.defaults].
  /// Returns a record of (effect, colors).
  static (IndicatorEffect effect, DefaultIndicatorColors colors)
      resolveDefaults(
    BuildContext context,
  ) {
    final theme = SmoothPageIndicatorTheme.of(context);
    final effect = theme?.effect ?? const WormEffect();
    final colors = theme?.defaultColors ?? DefaultIndicatorColors.defaults;
    return (effect, colors);
  }
}
