import 'package:flutter/material.dart';

import '/core/models/editor_callbacks/text_editor_callbacks.dart';
import '/core/models/editor_configs/pro_image_editor_configs.dart';
import '/core/models/layers/layer.dart';
import '/plugins/rounded_background_text/src/rounded_background_text_field.dart';

/// A widget for managing the text input in the text editor, providing a
/// customizable input area with styling and configuration options.
class TextEditorInput extends StatelessWidget {
  /// Creates a `TextEditorInput` widget with the required configurations,
  /// callbacks, and styling for text input management.
  ///
  /// - [callbacks]: Optional callbacks for text editor interactions.
  /// - [configs]: Configuration settings for the text editor.
  /// - [i18n]: Localization strings for tooltips and labels.
  /// - [heroTag]: Optional tag for hero animations during transitions.
  /// - [selectedTextStyle]: The text style applied to the input text.
  /// - [align]: The alignment of the text in the input field.
  /// - [textFontSize]: The font size of the input text.
  /// - [textColor]: The color of the input text.
  /// - [backgroundColor]: The background color of the text input field.
  /// - [layer]: The text layer being edited, if applicable.
  /// - [focusNode]: The focus node for managing input focus.
  /// - [textCtrl]: The text editing controller for managing input content.
  const TextEditorInput({
    super.key,
    required this.callbacks,
    required this.configs,
    required this.heroTag,
    required this.focusNode,
    required this.i18n,
    required this.selectedTextStyle,
    required this.align,
    required this.textFontSize,
    required this.scaleFactor,
    required this.textColor,
    required this.backgroundColor,
  this.foregroundPaint,
  this.gradientColors,
    required this.layer,
    required this.textCtrl,
  });

  /// Optional callbacks for text editor interactions.
  final TextEditorCallbacks? callbacks;

  /// Configuration settings for the text editor.
  final TextEditorConfigs configs;

  /// Localization strings for tooltips and labels.
  final I18nTextEditor i18n;

  /// Optional tag for hero animations during transitions.
  final String? heroTag;

  /// The text style applied to the input text.
  final TextStyle selectedTextStyle;

  /// The alignment of the text in the input field.
  final TextAlign align;

  /// The font size of the input text.
  final double textFontSize;

  /// The scale factor to transform the textfield
  final double scaleFactor;

  /// The color of the input text. Nullable: when null we allow the
  /// input widget to render with a transparent color (painter may draw
  /// the visible foreground or gradient).
  final Color? textColor;

  /// The background color of the text input field. Null means transparent.
  final Color? backgroundColor;

  /// Optional explicit foreground Paint (e.g. gradient shader) passed from
  /// the editor so the input widget/plugin can apply it reliably.
  final Paint? foregroundPaint;

  /// Optional gradient colors (two entries: start and end). When provided
  /// the plugin will construct a shader sized to the laid-out text so the
  /// gradient maps correctly across the glyphs.
  final List<Color>? gradientColors;

  /// The text layer being edited, if applicable.
  final TextLayer? layer;

  /// The focus node for managing input focus.
  final FocusNode focusNode;

  /// The text editing controller for managing input content.
  final TextEditingController textCtrl;

  Widget _flightShuttleBuilder(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection flightDirection,
    BuildContext fromHeroContext,
    BuildContext toHeroContext,
  ) {
    if (flightDirection == HeroFlightDirection.pop) {
      return fromHeroContext.widget;
    }

    void animationStatusListener(AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          focusNode.requestFocus();
        });
        animation.removeStatusListener(animationStatusListener);
      }
    }

    animation.addStatusListener(animationStatusListener);

    return toHeroContext.widget;
  }

  // Returns a TextStyle that preserves an existing foreground paint (e.g.
  // a gradient shader). If there is no foreground paint, uses [fallbackColor]
  // as the plain color. Always applies [fontSize].
  TextStyle _effectiveStyleWithPossibleForeground(
    TextStyle base,
    Color? fallbackColor,
    double fontSize,
  ) {
    var style = base;

    // If there's no foreground paint (shader), set a regular color so the
    // EditableText shows a plain color. If a foreground is present we must
    // keep it (this is how gradients are preserved).
    if (style.foreground == null) {
      style = style.copyWith(color: fallbackColor ?? Colors.transparent);
    }

    // Ensure fontSize is applied and clear any background so the
    // RoundedBackgroundText painter controls the background rendering.
    style = style.copyWith(fontSize: fontSize, backgroundColor: null);
    return style;
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: configs.inputTextFieldAlign,

      ///  TODO: remove `IntrinsicWidth` after improve
      /// `RoundedBackgroundTextField` code
      child: IntrinsicWidth(
        child: Padding(
          padding: configs.style.textFieldMargin,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Hero(
                flightShuttleBuilder: _flightShuttleBuilder,
                tag: heroTag ?? 'Text-Image-Editor-Empty-Hero',
                createRectTween: (begin, end) =>
                    RectTween(begin: begin, end: end),
                child: _buildInputField(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField() {
    return Transform.scale(
      scale: scaleFactor,
      child: Builder(builder: (context) {
        // Debug log whether the passed selectedTextStyle has a foreground paint
        // (gradient). This helps determine if the shader reaches the input.
        debugPrint('[TextEditorInput] selectedTextStyle.foreground != null: ${selectedTextStyle.foreground != null}');

  return RoundedBackgroundTextField(
        key: const ValueKey('rounded-background-text-editor-field'),
        controller: textCtrl,
        focusNode: focusNode,
        onChanged: callbacks?.handleChanged,
        onEditingComplete: callbacks?.handleEditingComplete,
        onSubmitted: callbacks?.handleSubmitted,
        autocorrect: configs.enableAutocorrect,
        enableSuggestions: configs.enableSuggestions,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        textCapitalization: TextCapitalization.sentences,
        textAlign: textCtrl.text.isEmpty ? TextAlign.center : align,
        maxLines: null,
        cursorColor: configs.style.inputCursorColor,
        cursorHeight: textFontSize * 1.2,
        scrollPhysics: const NeverScrollableScrollPhysics(),
        hint: textCtrl.text.isEmpty ? i18n.inputHintText : '',
        hintStyle: selectedTextStyle.copyWith(
          color: configs.style.inputHintColor,
          fontSize: textFontSize,
          // do NOT override height/letterSpacing/shadows/decoration here
        ),
  backgroundColor: backgroundColor,
  foregroundPaint: foregroundPaint,
  gradientColors: gradientColors,
        // Preserve `foreground` (e.g. gradient paint) if provided by the
        // selectedTextStyle. Only set a plain color when no foreground is set.
        style: _effectiveStyleWithPossibleForeground(
          selectedTextStyle,
          textColor,
          textFontSize,
        ),

        /// If we edit an layer we focus to the textfield after the
        /// hero animation is done
        autofocus: layer == null,
        );
      }),
    );
  }
}
