import 'package:flutter/material.dart';

/// Positioning hint for tooltip placement relative to the target.
enum TooltipPosition { above, below, left, right }

/// Immutable description of a single walkthrough step.
class WalkthroughStep {
  const WalkthroughStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.position = TooltipPosition.below,
    this.tooltipPadding = const EdgeInsets.all(12),
  });

  final GlobalKey targetKey;
  final String title;
  final String description;
  final TooltipPosition position;
  final EdgeInsets tooltipPadding;
}
