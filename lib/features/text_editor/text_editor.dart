// Dart imports:
import 'dart:async';

import 'package:flutter/material.dart';

import '/core/mixins/converted_callbacks.dart';
import '/core/mixins/converted_configs.dart';
import '/core/mixins/editor_configs_mixin.dart';
import '/features/text_editor/widgets/text_editor_appbar.dart';
import '/features/text_editor/widgets/text_editor_color_picker.dart';
import '/features/text_editor/widgets/text_editor_input.dart';
import '/pro_image_editor.dart';
import '/shared/extensions/color_extension.dart';
import '/shared/widgets/slider_bottom_sheet.dart';
import 'widgets/text_editor_bottom_bar.dart';

/// A StatefulWidget that provides a text editing interface for adding and
/// editing text layers.
class TextEditor extends StatefulWidget with SimpleConfigsAccess {
  /// Creates a `TextEditor` widget.
  ///
  /// The [heroTag], [layer], [i18n], [customWidgets], and [imageEditorTheme]
  /// parameters are required.
  const TextEditor({
    super.key,
    this.heroTag,
    this.layer,
    this.callbacks = const ProImageEditorCallbacks(),
    this.configs = const ProImageEditorConfigs(),
    this.scaleFactor = 1.0,
    required this.theme,
  });
  @override
  final ProImageEditorConfigs configs;

  @override
  final ProImageEditorCallbacks callbacks;

  /// A unique hero tag for the image.
  final String? heroTag;

  /// The theme configuration for the editor.
  final ThemeData theme;

  /// The text layer data to be edited, if any.
  final TextLayer? layer;

  /// A factor by which the textfield is scaled.
  ///
  /// This value is used to adjust the size of the text in the editor.
  /// A value of 1.0 means no scaling, while values greater than 1.0
  /// increase the size and values less than 1.0 decrease the size.
  final double scaleFactor;

  @override
  createState() => TextEditorState();
}

/// The state class for the `TextEditor` widget.
class TextEditorState extends State<TextEditor>
    with
        ImageEditorConvertedConfigs,
        ImageEditorConvertedCallbacks,
        SimpleConfigsAccessState {
  late final StreamController<void> _rebuildController;

  /// Controller for managing text input.
  final TextEditingController textCtrl = TextEditingController();

  /// Node for managing focus on the text input.
  final FocusNode focusNode = FocusNode();

  /// Alignment of the text.
  late TextAlign align;

  /// Style applied to the selected text.
  late TextStyle selectedTextStyle;

  /// Mode for managing the background color of the text layer.
  late LayerBackgroundMode backgroundColorMode;

  /// Position of the color picker.
  double colorPosition = 0;

  /// Represents the dimensions of the body.
  Size editorBodySize = Size.infinite;

  late double _fontScale;

  Color _primaryColor = Colors.black;

  /// Gets the primary color.
  Color get primaryColor => _primaryColor;

  /// Sets the primary color.
  set primaryColor(Color color) {
    setState(() {
      _primaryColor = color;
      textEditorCallbacks?.handleColorChanged(color.toHex());
      // Invalidate any cached gradient paint when the primary color
      // changes so the shader can be recomputed with the new color.
      _invalidateGradientCache();
    });
  }

  Color? _secondaryColor;

  /// Gets the secondary color.
  Color get secondaryColor => _secondaryColor ?? getContrastColor(primaryColor);

  /// Sets the secondary color. Accepts null to clear a previously set
  /// secondary (gradient) color.
  set secondaryColor(Color? color) {
    setState(() {
      _secondaryColor = color;
      _invalidateGradientCache();
    });
  }

  Color? _backgroundColor;

  /// Gets the actual background color for text.
  Color? get backgroundColor => _backgroundColor;

  /// Sets the background color for text.
  set backgroundColor(Color? color) {
    setState(() {
      _backgroundColor = color;
    });
  }

  // Cached gradient paint to avoid recreating shader Paint objects on
  // every build. We only recreate when primary or secondary colors or
  // the available width changes.
  Paint? _cachedGradientPaint;
  List<Color>? _cachedGradientColors;
  double? _cachedShaderWidth;

  void _invalidateGradientCache() {
    _cachedGradientPaint = null;
    _cachedGradientColors = null;
    _cachedShaderWidth = null;
  }

  @override
  void initState() {
    super.initState();
    _rebuildController = StreamController.broadcast();
    align = textEditorConfigs.initialTextAlign;
    _fontScale = textEditorConfigs.initFontScale;
    backgroundColorMode = textEditorConfigs.initialBackgroundColorMode;

    selectedTextStyle = widget.layer?.textStyle ??
        textEditorConfigs.customTextStyles?.first ??
        textEditorConfigs.defaultTextStyle;
    _initializeFromLayer();

    textEditorCallbacks?.onInit?.call();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      textEditorCallbacks?.onAfterViewInit?.call();
    });
    // Ensure styles (especially gradients) are applied after the first frame
    // when opening the editor from the main canvas (hero animation path).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Invalidate any cached gradient paint and trigger a rebuild so the
      // RoundedBackgroundTextField can measure the laid-out text and create
      // a shader sized correctly for the current editor constraints.
      _invalidateGradientCache();
      _rebuildController.add(null);
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _rebuildController.close();
    textCtrl.dispose();
    focusNode.dispose();
    super.dispose();
  }

  @override
  void setState(void Function() fn) {
    _rebuildController.add(null);
    textEditorCallbacks?.handleUpdateUI();
    super.setState(fn);
  }

  /// Initializes the text editor from the provided text layer data.
  void _initializeFromLayer() {
    if (widget.layer != null) {
      textCtrl.text = widget.layer!.text;
      align = widget.layer!.align;
      _fontScale = widget.layer!.fontScale;
      backgroundColorMode = widget.layer!.colorMode!;
      if (widget.layer!.customSecondaryColor) {
        // Gradient mode: primaryColor and secondaryColor are gradient colors
        _primaryColor = widget.layer!.color;
        _secondaryColor = widget.layer!.background;
        // Background color should be transparent when using gradient
        _backgroundColor = null;
      } else {
        // Normal mode: use color mode to determine colors
        _primaryColor = backgroundColorMode == LayerBackgroundMode.background
            ? widget.layer!.background
            : widget.layer!.color;
        _secondaryColor = null;
        _backgroundColor = null;
      }
      colorPosition = widget.layer!.colorPickerPosition ?? 0;
    }
  }

  /// Calculates the contrast color for a given color.
  Color getContrastColor(Color color) {
    int d = color.computeLuminance() > 0.5 ? 0 : 255;

    return Color.fromRGBO(d, d, d, color.a);
  }

  /// Gets the text color based on the selected color mode.
  Color get _textColor {
    // When using custom secondary color (gradient), always use primary for text color
  if (_secondaryColor != null) {
      return primaryColor;
    }
    
    switch (backgroundColorMode) {
      case LayerBackgroundMode.onlyColor:
      case LayerBackgroundMode.backgroundAndColor:
        return primaryColor;
      case LayerBackgroundMode.background:
        return secondaryColor;
      default:
        return primaryColor;
    }
  }

  /// Gets the background color based on the selected color mode.
  Color get _layerBackgroundColor {
    // When using custom secondary color (gradient), background should be from backgroundColor field
    if (_secondaryColor != null) {
      return _backgroundColor ?? Colors.transparent;
    }
    
    switch (backgroundColorMode) {
      case LayerBackgroundMode.onlyColor:
        return Colors.transparent;
      case LayerBackgroundMode.backgroundAndColor:
        return secondaryColor;
      case LayerBackgroundMode.background:
        return primaryColor;
      default:
        return secondaryColor.withValues(alpha: 0.5);
    }
  }

  /// Gets the text font size based on the selected font scale.
  double get _textFontSize {
    return textEditorConfigs.initFontSize * _fontScale;
  }

  /// Toggles the text alignment between left, center, and right.
  void toggleTextAlign() {
    TextAlign nextTextAlign(TextAlign currentAlign) {
      switch (currentAlign) {
        case TextAlign.left:
          return TextAlign.center;
        case TextAlign.center:
          return TextAlign.right;
        case TextAlign.right:
        default:
          return TextAlign.left;
      }
    }

    align = nextTextAlign(align);
    textEditorCallbacks?.handleTextAlignChanged(align);
    setState(() {});
  }

  /// Toggles the background mode between various color modes.
  void toggleBackgroundMode() {
    LayerBackgroundMode nextBackgroundMode(LayerBackgroundMode currentMode) {
      switch (currentMode) {
        case LayerBackgroundMode.onlyColor:
          return LayerBackgroundMode.backgroundAndColor;
        case LayerBackgroundMode.backgroundAndColor:
          return LayerBackgroundMode.background;
        case LayerBackgroundMode.background:
          return LayerBackgroundMode.backgroundAndColorWithOpacity;
        case LayerBackgroundMode.backgroundAndColorWithOpacity:
          return LayerBackgroundMode.onlyColor;
      }
    }

    backgroundColorMode = nextBackgroundMode(backgroundColorMode);
    textEditorCallbacks?.handleBackgroundModeChanged(backgroundColorMode);
    setState(() {});
  }

  /// Gets the current font scale.
  double get fontScale => _fontScale;

  /// Sets the font scale to a new value.
  ///
  /// The new value is adjusted to one decimal place before being set.
  /// After setting the new value, the state is updated and the
  /// [textEditorCallbacks] are notified of the change.
  ///
  /// [value] - The new font scale value.
  set fontScale(double value) {
    _fontScale = (value * 10).ceilToDouble() / 10;
    setState(() {});
    textEditorCallbacks?.handleFontScaleChanged(value);
  }

  /// Displays a range slider for adjusting the line width of the paint tool.
  ///
  /// This method shows a range slider in a modal bottom sheet for adjusting the
  /// line width of the paint tool.
  void openFontScaleBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: textEditorConfigs.style.fontScaleBottomSheetBackground,
      builder: (BuildContext context) => SliderBottomSheet<TextEditorState>(
        value: _fontScale,
        title: i18n.textEditor.fontScale,
        headerTextStyle: textEditorConfigs.style.fontSizeBottomSheetTitle,
        resetIcon: textEditorConfigs.icons.resetFontScale,
        max: textEditorConfigs.maxFontScale,
        min: textEditorConfigs.minFontScale,
        divisions:
            (textEditorConfigs.maxFontScale - textEditorConfigs.minFontScale) ~/
                0.1,
        state: this,
        showFactorInTitle: true,
        closeButton: textEditorConfigs.widgets.fontSizeCloseButton,
        customSlider: textEditorConfigs.widgets.sliderFontSize,
        designMode: designMode,
        theme: widget.theme,
        rebuildController: _rebuildController,
        onValueChanged: (value) {
          fontScale = value;
        },
      ),
    );
  }

   /// Update the current text style.
 void setTextStyle(TextStyle style) {
  selectedTextStyle = style;
  _rebuildController.add(null);   // preview listeners
  if (mounted) setState(() {});   // ensure TextField rebuilds right away
}

  /// Closes the editor without applying changes.
  void close() {
    Navigator.pop(context);
    textEditorCallbacks?.handleCloseEditor();
  }

  /// Handles the "Done" action, either by applying changes or closing the
  /// editor.
  void done() {
    if (textCtrl.text.trim().isNotEmpty) {
      Navigator.of(context).pop(
        TextLayer(
          text: textCtrl.text.trim(),
          // When a custom secondary color (gradient) is used, persist
          // the gradient pair into the layer as: color=primary, background=secondary
          // so we can rehydrate the gradient on reopen. Otherwise persist
          // the usual color/background mapping.
          background: _secondaryColor != null ? _secondaryColor! : _layerBackgroundColor,
          color: _textColor,
          align: align,
          fontScale: _fontScale,
          colorMode: backgroundColorMode,
          colorPickerPosition: colorPosition,
          textStyle: selectedTextStyle,
          customSecondaryColor: _secondaryColor != null,
          // Preserve the width constraint used by the editor so the saved
          // layer wraps text the same way when rendered in the main canvas.
          // Subtract paddings used in the input layout (approx 32.0) to get
          // the effective text area width.
          boxConstraints: BoxConstraints(
            maxWidth: (editorBodySize.isFinite && editorBodySize.width > 0)
                ? (editorBodySize.width - 32.0).clamp(0.0, double.infinity)
                : 1200.0,
          ),
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
    textEditorCallbacks?.handleDone();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ExtendedPopScope(
          child: Theme(
            data: widget.theme.copyWith(
                tooltipTheme:
                    widget.theme.tooltipTheme.copyWith(preferBelow: true)),
            child: SafeArea(
              top: textEditorConfigs.safeArea.top,
              bottom: textEditorConfigs.safeArea.bottom,
              left: textEditorConfigs.safeArea.left,
              right: textEditorConfigs.safeArea.right,
              child: Scaffold(
                backgroundColor: textEditorConfigs.style.background,
                appBar: _buildAppBar(constraints),
                body: _buildBody(),
                bottomNavigationBar: _buildBottomBar(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the app bar for the text editor.
  PreferredSizeWidget? _buildAppBar(BoxConstraints constraints) {
    if (textEditorConfigs.widgets.appBar != null) {
      return textEditorConfigs.widgets.appBar!
          .call(this, _rebuildController.stream);
    }

    return TextEditorAppBar(
      textEditorConfigs: textEditorConfigs,
      i18n: i18n.textEditor,
      onClose: close,
      onDone: done,
      align: align,
      onToggleTextAlign: toggleTextAlign,
      onOpenFontScaleBottomSheet: openFontScaleBottomSheet,
      onToggleBackgroundMode: toggleBackgroundMode,
      designMode: designMode,
      constraints: constraints,
    );
  }

  /// Builds the bottom navigation bar of the paint editor.
  /// Returns a [Widget] representing the bottom navigation bar.
  Widget? _buildBottomBar() {
    if (textEditorConfigs.widgets.bottomBar != null) {
      return textEditorConfigs.widgets.bottomBar!
          .call(this, _rebuildController.stream);
    }

    if (isDesktop &&
        widget.configs.textEditor.customTextStyles?.isNotEmpty == false) {
      return const SizedBox(height: kBottomNavigationBarHeight);
    }

    return null;
  }

  /// Builds the body of the text editor.
  Widget _buildBody() {
    return LayoutBuilder(builder: (_, constraints) {
      editorBodySize = constraints.biggest;

      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: done,
        child: Stack(
          children: [
            if (textEditorConfigs.widgets.bodyItems != null)
              ...textEditorConfigs.widgets.bodyItems!(
                this,
                _rebuildController.stream,
              ),
            _buildTextField(),
            // _buildColorPicker(), commented thid to hide default color picker
            if (textEditorConfigs.showSelectFontStyleBottomBar)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: kBottomNavigationBarHeight,
                child: TextEditorBottomBar(
                  configs: widget.configs,
                  selectedStyle: selectedTextStyle,
                  onFontChange: setTextStyle,
                ),
              ),
          ],
        ),
      );
    });
  }

  // The color picker builder may be unused depending on configuration; silence
  // analyzer warnings about an unused private function.
  // ignore: unused_element
  Widget _buildColorPicker() {
    return TextEditorColorPicker(
        state: this,
        configs: configs,
        colorPosition: colorPosition,
        primaryColor: primaryColor,
        rebuildController: _rebuildController,
        selectedTextStyle: selectedTextStyle,
        onUpdateColor: (color) {
          primaryColor = color;
        },
        onPositionChange: (value) {
          colorPosition = value;
        });
  }

  /// Builds the text field for text input.
  Widget _buildTextField() {
    // If a secondary color is provided (custom secondary), render text with a horizontal gradient.
    TextStyle effectiveSelectedTextStyle = selectedTextStyle;
  Paint? gradientPaint;
  List<Color>? gradientColors;
  if (_secondaryColor != null) {
    // Determine available width for the shader. Use editorBodySize if
    // available, otherwise fall back to a wide default.
    final availWidth = (editorBodySize.isFinite && editorBodySize.width > 0)
        ? editorBodySize.width
        : 1200.0;

    // Recompute cached paint only when inputs changed (colors or width).
    final newColors = [primaryColor, _secondaryColor!];
    if (_cachedGradientPaint == null ||
        _cachedGradientColors == null ||
        _cachedShaderWidth == null ||
        _cachedGradientColors!.length != newColors.length ||
        _cachedGradientColors!.first != newColors.first ||
        _cachedGradientColors!.last != newColors.last ||
        (_cachedShaderWidth! - availWidth).abs() > 0.5) {
      final shaderRect = Rect.fromLTWH(0, 0, availWidth, _textFontSize * 1.4);
      final shader = LinearGradient(
        colors: newColors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(shaderRect);
      _cachedGradientPaint = Paint()..shader = shader;
      _cachedGradientColors = List.from(newColors);
      _cachedShaderWidth = availWidth;
    }

    gradientPaint = _cachedGradientPaint;
    gradientColors = _cachedGradientColors;
    effectiveSelectedTextStyle = selectedTextStyle.copyWith(foreground: gradientPaint);
  }
    // Debug: log whether a foreground Paint was attached to the effective style
    // so we can trace gradient propagation.
    debugPrint('[TextEditor] effectiveSelectedTextStyle has foreground: ${effectiveSelectedTextStyle.foreground != null}');

    return TextEditorInput(
      callbacks: textEditorCallbacks,
      configs: textEditorConfigs,
      heroTag: widget.heroTag,
      align: align,
      backgroundColor: _layerBackgroundColor,
      textCtrl: textCtrl,
      scaleFactor: widget.scaleFactor,
      focusNode: focusNode,
      i18n: i18n.textEditor,
      layer: widget.layer,
      selectedTextStyle: effectiveSelectedTextStyle,
      textColor: _textColor,
      foregroundPaint: gradientPaint,
      gradientColors: gradientColors,
      textFontSize: _textFontSize,
    );
  }
}
