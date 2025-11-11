import 'package:flutter/material.dart';

import '/core/models/editor_configs/text_editor_configs.dart';
import '/core/models/layers/text_layer.dart';
import '/plugins/rounded_background_text/src/rounded_background_text.dart';

/// A widget representing a text layer in the sticker editor.
class LayerWidgetTextItem extends StatelessWidget {
  /// Creates a [LayerWidgetTextItem] with the given text layer and editor
  /// configurations.
  const LayerWidgetTextItem({
    super.key,
    required this.layer,
    required this.textEditorConfigs,
    required this.showMoveCursor,
    required this.onHitChanged,
  });

  /// The text layer represented by this widget.
  final TextLayer layer;

  /// Configuration settings for the text editor.
  final TextEditorConfigs textEditorConfigs;

  /// Notifies whether the move cursor should be shown.
  final ValueNotifier<bool> showMoveCursor;

  /// Callback function that is triggered when a hit status changes.
  ///
  /// The [onHitChanged] function takes a boolean parameter [hasHit] which
  /// indicates whether a hit has occurred (true) or not (false).
  final Function(bool hasHit) onHitChanged;

  @override
  Widget build(BuildContext context) {
    var fontSize = textEditorConfigs.initFontSize * layer.scale;
    var baseStyle = TextStyle(
      fontSize: fontSize * layer.fontScale,
      overflow: TextOverflow.ellipsis,
    );

    // If the layer stored a custom secondary color, it represents a
    // gradient (primary: layer.color, secondary: layer.background). Build
    // a Paint shader sized heuristically to the text so short strings get
    // a visible gradient span.
    TextStyle style;
    if (layer.customSecondaryColor) {
      final primary = layer.color;
      // Secondary gradient color was stored in meta['secondaryGradientColor']
      // for layers saved after the fix; fall back to layer.background for
      // backward compatibility.
      Color secondary;
      final metaSec = layer.meta != null ? layer.meta!['secondaryGradientColor'] : null;
      if (metaSec is int) {
        secondary = Color(metaSec);
      } else if (metaSec is String) {
        try {
          secondary = Color(int.parse(metaSec));
        } catch (_) {
          secondary = layer.background;
        }
      } else {
        secondary = layer.background;
      }

      // Heuristic width: base on glyph count and font size, with a sensible
      // minimum so very short strings still show a gradient.
      final estimatedWidth = (baseStyle.fontSize! * layer.text.length * 0.6).clamp(120.0, 2000.0);
      final shaderRect = Rect.fromLTWH(0, 0, estimatedWidth, (baseStyle.fontSize ?? 16) * 1.4);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [primary, secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(shaderRect);

      style = baseStyle.copyWith(foreground: paint, color: null);
    } else {
      style = baseStyle.copyWith(color: layer.color);
    }

    return HeroMode(
      enabled: false,
      child: RoundedBackgroundText(
        onHitTestResult: (hasHit) {
          // Update hit detection and cursor visibility state.
          if (layer.hit != hasHit || showMoveCursor.value != hasHit) {
            layer.hit = hasHit;
            showMoveCursor.value = hasHit;
          }
          layer.hit = hasHit;
          onHitChanged(hasHit);
        },
        layer.text.toString(),
  // Use the stored background color for the rounded pill. After the
  // fix we store the secondary gradient color in `meta['secondaryGradientColor']`
  // and preserve `background` for the actual pill color, so it's safe to
  // render here regardless of gradient usage.
  backgroundColor: layer.background,
    textAlign: layer.align,
    // Merge saved textStyle with the computed style. Important: if
    // `style` contains a `foreground` Paint (gradient), preserve it
    // when copying/merging so gradients persist in the composed view.
    style: (layer.textStyle ?? const TextStyle()).copyWith(
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      color: style.color,
      fontFamily: style.fontFamily,
              foreground: style.foreground,
    ),
      ),
    );
  }
}
