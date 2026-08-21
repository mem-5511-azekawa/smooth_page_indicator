import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'effects/indicator_effect.dart';
import 'effects/worm_effect.dart';
import 'painters/indicator_painter.dart';
import 'theme_defaults.dart';

/// Signature for a callback function used to report
/// dot tap-events
typedef OnDotClicked = void Function(int index);

/// A widget that draws a representation of pages count
/// Inside of a  [PageView]
///
/// Uses the [PageController.offset] to animate the active dot
class SmoothPageIndicator extends StatefulWidget {
  /// The page view controller
  final PageController controller;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  /// If null, the effect will be read from [SmoothPageIndicatorTheme] or default to [WormEffect]
  final IndicatorEffect? effect;

  /// Layout direction vertical || horizontal
  ///
  /// This will only rotate the canvas in which the dots are drawn.
  ///
  /// It will not affect [effect.dotWidth] and [effect.dotHeight]
  final Axis axisDirection;

  /// The number of pages
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page direction will be flipped
  final TextDirection? textDirection;

  /// Reports dot taps
  final OnDotClicked? onDotClicked;

  /// Default constructor
  const SmoothPageIndicator({
    super.key,
    required this.controller,
    required this.count,
    this.axisDirection = Axis.horizontal,
    this.textDirection,
    this.onDotClicked,
    this.effect,
  });

  @override
  State<SmoothPageIndicator> createState() => _SmoothPageIndicatorState();
}

mixin _SizeAndRotationCalculatorMixin {
  /// The size of canvas
  late Size size;

  /// Rotation quarters of canvas
  int quarterTurns = 0;

  BuildContext get context;

  TextDirection? get textDirection;

  Axis get axisDirection;

  int get count;

  IndicatorEffect get effect;

  void updateSizeAndRotation() {
    size = effect.calculateSize(count);

    /// if textDirection is not provided use the nearest directionality up the widgets tree;
    final isRTL =
        (textDirection ?? Directionality.maybeOf(context)) == TextDirection.rtl;
    if (axisDirection == Axis.vertical) {
      quarterTurns = 1;
    } else {
      quarterTurns = isRTL ? 2 : 0;
    }
  }
}

class _SmoothPageIndicatorState extends State<SmoothPageIndicator>
    with _SizeAndRotationCalculatorMixin {
  late IndicatorEffect _effect;

  late ValueListenable<double> _offset =
      _PageOffsetNotifier(widget.controller, widget.count);

  @override
  void didUpdateWidget(covariant SmoothPageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.effect != oldWidget.effect) {
      _updateEffect();
      updateSizeAndRotation();
    }

    if (oldWidget.controller != widget.controller ||
        oldWidget.count != widget.count) {
      _offset = _PageOffsetNotifier(widget.controller, widget.count);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEffect();
    updateSizeAndRotation();
  }

  void _updateEffect() {
    _effect = widget.effect ??
        SmoothPageIndicatorTheme.of(context)?.effect ??
        const WormEffect();
  }

  @override
  Widget build(BuildContext context) {
    return SmoothIndicator(
      offset: _offset,
      count: count,
      effect: effect,
      onDotClicked: widget.onDotClicked,
      size: size,
      quarterTurns: quarterTurns,
    );
  }

  @override
  int get count => widget.count;

  @override
  IndicatorEffect get effect => _effect;

  @override
  Axis get axisDirection => widget.axisDirection;

  @override
  TextDirection? get textDirection => widget.textDirection;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
    properties.add(DiagnosticsProperty<IndicatorEffect>('effect', effect));
    properties.add(DiagnosticsProperty<Size>('size', size));
    properties.add(IntProperty('quarterTurns', quarterTurns));
  }
}

/// Draws dot-ish representation of pages by
/// the number of [count] and animates the active
/// page using [offset]
class SmoothIndicator extends StatelessWidget {
  /// The active page offset
  final ValueListenable<double> offset;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  final IndicatorEffect effect;

  /// The number of pages
  final int count;

  /// Reports dot-taps
  final OnDotClicked? onDotClicked;

  /// The size of canvas
  final Size size;

  /// The rotation of cans based on
  /// text directionality and [axisDirection]
  final int quarterTurns;

  /// Default constructor
  const SmoothIndicator({
    super.key,
    required this.offset,
    required this.count,
    required this.size,
    this.quarterTurns = 0,
    this.effect = const WormEffect(),
    this.onDotClicked,
  });

  @override
  Widget build(BuildContext context) {
    final (_, indicatorColors) =
        SmoothPageIndicatorTheme.resolveDefaults(context);
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: GestureDetector(
        onTapUp: _onTap,
        child: CustomPaint(
          size: size,
          // rebuild the painter with the new offset every time it updates
          painter: effect.buildPainter(count, offset, indicatorColors),
        ),
      ),
    );
  }

  void _onTap(TapUpDetails details) {
    if (onDotClicked != null) {
      final rawOffset = offset.value;
      var index =
          effect.hitTestDots(details.localPosition.dx, count, rawOffset);
      if (index != -1 && index != rawOffset.toInt()) {
        onDotClicked?.call(index);
      }
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('offset', offset.value));
    properties.add(IntProperty('count', count));
    properties.add(DiagnosticsProperty<IndicatorEffect>('effect', effect));
    properties.add(DiagnosticsProperty<Size>('size', size));
    properties.add(IntProperty('quarterTurns', quarterTurns));
  }
}

/// Unlike [SmoothPageIndicator] this indicator is self-animated
/// and it only needs to know active index
///
/// Useful for paging widgets that does not use [PageController]
class AnimatedSmoothIndicator extends StatefulWidget {
  /// The index of active page
  final int activeIndex;

  /// Holds effect configuration to be used in the [BasicIndicatorPainter]
  /// If null, the effect will be read from [SmoothPageIndicatorTheme] or default to [WormEffect]
  final IndicatorEffect? effect;

  /// layout direction vertical || horizontal
  final Axis axisDirection;

  /// The number of children in [PageView]
  final int count;

  /// If [textDirection] is [TextDirection.rtl], page direction will be flipped
  final TextDirection? textDirection;

  /// Reports dot-taps
  final Function(int index)? onDotClicked;

  /// The curve used to animate between active indices.
  final Curve curve;

  /// The duration of the animation between active indices.
  final Duration duration;

  /// Called when an active-index animation completes.
  final VoidCallback? onEnd;

  /// Default constructor
  const AnimatedSmoothIndicator({
    super.key,
    required this.activeIndex,
    required this.count,
    this.axisDirection = Axis.horizontal,
    this.textDirection,
    this.onDotClicked,
    this.effect,
    this.curve = Curves.easeInOut,
    this.duration = const Duration(milliseconds: 300),
    this.onEnd,
  });

  @override
  State<AnimatedSmoothIndicator> createState() =>
      _AnimatedSmoothIndicatorState();
}

class _AnimatedSmoothIndicatorState extends State<AnimatedSmoothIndicator>
    with SingleTickerProviderStateMixin, _SizeAndRotationCalculatorMixin {
  late final AnimationController _animationController;
  late Animation<double> _offsetAnimation;
  late IndicatorEffect _effect;

  int _previousActiveIndex = 0;
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..addStatusListener(_handleAnimationStatus);
    _offsetAnimation = AlwaysStoppedAnimation(_targetOffset);
  }

  @override
  void didUpdateWidget(covariant AnimatedSmoothIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.effect != oldWidget.effect) {
      _updateEffect();
      updateSizeAndRotation();
    }

    _animationController.duration = widget.duration;

    if (widget.activeIndex != oldWidget.activeIndex ||
        widget.count != oldWidget.count) {
      _animateToTarget();
    }
    _previousActiveIndex = widget.activeIndex;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateEffect();
    updateSizeAndRotation();
  }

  void _updateEffect() {
    _effect = widget.effect ??
        SmoothPageIndicatorTheme.of(context)?.effect ??
        const WormEffect();
  }

  void _animateToTarget() {
    _offsetAnimation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    ).drive(
      _ModuloTween(
        begin: _previousActiveIndex.toDouble(),
        end: _targetOffset,
        max: widget.count,
      ),
    );
    _animationController.forward(from: 0);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onEnd?.call();
    }
  }

  @override
  void dispose() {
    _animationController
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  int get count => widget.count;

  @override
  IndicatorEffect get effect => _effect;

  @override
  Axis get axisDirection => widget.axisDirection;

  @override
  TextDirection? get textDirection => widget.textDirection;

  double get _targetOffset => widget.activeIndex.toDouble();

  @override
  Widget build(BuildContext context) {
    return SmoothIndicator(
      offset: _offsetAnimation,
      count: widget.count,
      effect: effect,
      onDotClicked: widget.onDotClicked,
      size: size,
      quarterTurns: quarterTurns,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
    properties.add(IntProperty('activeIndex', widget.activeIndex));
    properties.add(DiagnosticsProperty<IndicatorEffect>('effect', effect));
    properties.add(DiagnosticsProperty<Size>('size', size));
    properties.add(IntProperty('quarterTurns', quarterTurns));
  }
}

/// A [ValueListenable] that listens to [PageController.page] and returns the current page offset
class _PageOffsetNotifier extends ValueListenable<double> {
  /// Default constructor
  _PageOffsetNotifier(this.controller, this.count) : assert(count > 0);
  final int count;
  final PageController controller;

  @override
  double get value {
    try {
      final initialPage = controller.initialPage.toDouble();
      if (!controller.hasClients) {
        return initialPage;
      }
      final offset = controller.page;
      if (offset == null || offset.isNaN) {
        return initialPage;
      }
      return offset % count;
    } catch (_) {
      return controller.initialPage.toDouble();
    }
  }

  @override
  void addListener(VoidCallback listener) {
    controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    controller.removeListener(listener);
  }
}

// Wraps the already-interpolated offset (not the curve progress) so it loops back into [0, max).
class _ModuloTween extends Tween<double> {
  _ModuloTween({super.begin, super.end, required this.max});

  final int max;

  @override
  double transform(double t) => super.transform(t) % max;
}
