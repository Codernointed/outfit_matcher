import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vestiq/core/models/walkthrough_step.dart';

/// Animated overlay that spotlights widgets identified by [GlobalKey]s.
class WalkthroughOverlay extends StatefulWidget {
  const WalkthroughOverlay({
    super.key,
    required this.steps,
    required this.onFinish,
    required this.onSkip,
  });

  final List<WalkthroughStep> steps;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  @override
  State<WalkthroughOverlay> createState() => _WalkthroughOverlayState();
}

class _WalkthroughOverlayState extends State<WalkthroughOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Rect? _targetRect;
  int _index = 0;

  WalkthroughStep get _step => widget.steps[_index];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureRect());
  }

  @override
  void didUpdateWidget(covariant WalkthroughOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureRect());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _captureRect() {
    final targetContext = _step.targetKey.currentContext;
    final overlayBox = context.findRenderObject() as RenderBox?;

    if (targetContext == null || overlayBox == null || !overlayBox.attached) {
      return;
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final offset = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    setState(() {
      _targetRect = offset & renderBox.size;
    });
  }

  void _next() {
    if (_index >= widget.steps.length - 1) {
      widget.onFinish();
      return;
    }
    setState(() {
      _index += 1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureRect());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    return IgnorePointer(
      ignoring: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildOverlay(context, key: ValueKey(_index)),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, {required Key key}) {
    final size = MediaQuery.of(context).size;
    final overlayColor = Colors.black.withValues(alpha: 0.75);

    final target =
        _targetRect ??
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.2,
          size.width * 0.8,
          80,
        );

    final tooltip = _buildTooltip(context, target);

    return Stack(
      key: key,
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: 1,
            child: CustomPaint(
              painter: _SpotlightPainter(
                target: target,
                overlayColor: overlayColor,
                pulse: _pulseController,
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextButton(
                    onPressed: widget.onSkip,
                    child: const Text('Skip'),
                  ),
                ),
              ),
              const Spacer(),
              tooltip,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTooltip(BuildContext context, Rect target) {
    final theme = Theme.of(context);
    final padding = _step.tooltipPadding;

    final size = MediaQuery.of(context).size;

    Offset anchor;
    Alignment alignment;
    EdgeInsets margin = const EdgeInsets.all(16);

    switch (_step.position) {
      case TooltipPosition.above:
        anchor = Offset(target.center.dx, target.top - 12);
        alignment = Alignment.bottomCenter;
        margin = EdgeInsets.only(
          left: math.max(0, target.left - 12),
          right: math.max(0, (size.width - target.right) - 12),
          bottom: math.max(0, size.height - target.top + 8),
        );
        break;
      case TooltipPosition.below:
        anchor = Offset(target.center.dx, target.bottom + 12);
        alignment = Alignment.topCenter;
        margin = EdgeInsets.only(
          left: math.max(0, target.left - 12),
          right: math.max(0, (size.width - target.right) - 12),
          top: math.max(0, target.bottom + 12),
          bottom: 80, // More bottom margin to prevent overflow
        );
        break;
      case TooltipPosition.left:
        anchor = Offset(target.left - 12, target.center.dy);
        alignment = Alignment.centerRight;
        margin = EdgeInsets.only(
          right: math.max(0, size.width - target.left + 12),
          left: 20,
          top: math.max(0, target.top),
          bottom: 24,
        );
        break;
      case TooltipPosition.right:
        anchor = Offset(target.right + 12, target.center.dy);
        alignment = Alignment.centerLeft;
        margin = EdgeInsets.only(
          left: math.max(0, target.right + 12),
          right: 20,
          top: math.max(0, target.top),
          bottom: 24,
        );
        break;
    }

    return Container(
      margin: margin,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: padding,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _step.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_index + 1}/${widget.steps.length}',
                      style: theme.textTheme.labelMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _step.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: widget.onSkip,
                      child: const Text('Skip'),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: FilledButton(
                        onPressed: _next,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _index == widget.steps.length - 1
                                  ? 'Done'
                                  : 'Next',
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              _index == widget.steps.length - 1
                                  ? Icons.check_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.target,
    required this.overlayColor,
    required this.pulse,
  }) : super(repaint: pulse);

  final Rect target;
  final Color overlayColor;
  final Animation<double> pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = overlayColor;
    final background = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final padded = target.inflate(12);
    final hole = Path()
      ..addRRect(RRect.fromRectAndRadius(padded, const Radius.circular(16)));

    final overlayPath = Path.combine(
      PathOperation.difference,
      background,
      hole,
    );
    canvas.drawPath(overlayPath, paint);

    final pulseValue = (math.sin(pulse.value * 2 * math.pi) + 1) / 2;
    final ringRect = padded.inflate(8 + (pulseValue * 6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(ringRect, const Radius.circular(18)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = overlayColor.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.target != target ||
        oldDelegate.overlayColor != overlayColor;
  }
}
