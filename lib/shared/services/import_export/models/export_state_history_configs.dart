// Project imports:
import '../enums/export_import_enum.dart';

/// Configuration options for exporting editor contents.
///
/// This class defines various options for exporting editor contents such as
/// paint, text, crop/rotate actions, filters, emojis, and stickers.
class ExportEditorConfigs {
  /// Creates an instance of the [ExportEditorConfigs]
  const ExportEditorConfigs({
    this.historySpan = ExportHistorySpan.all,
    this.exportPaint = true,
    this.exportText = true,
    this.exportCropRotate = true,
    this.exportFilter = true,
    this.exportTuneAdjustments = true,
    this.exportEmoji = true,
    this.exportBlur = true,
    this.exportWidgets = true,
    this.enableMinify = true,
  });

  /// The span of the export history to include in the export.
  ///
  /// By default, it includes the entire export history.
  final ExportHistorySpan historySpan;

  /// Whether to export the layers from the paint editor.
  ///
  /// Defaults to `true`.
  final bool exportPaint;

  /// Whether to export the text content.
  ///
  /// **Note:** If you do not set a `defaultTextStyle` within
  /// `textEditorConfigs`, the text size may change when you import the state
  /// history on other platforms, as their default text styles may vary.
  ///
  /// Defaults to `true`.
  final bool exportText;

  /// Whether to export the crop and rotate actions.
  ///
  /// Defaults to `true`.
  final bool exportCropRotate;

  /// Whether to export the applied filters.
  ///
  /// Defaults to `true`.
  final bool exportFilter;

  /// Whether to export the applied tune adjustments.
  ///
  /// Defaults to `true`.
  final bool exportTuneAdjustments;

  /// Whether to export the emojis.
  ///
  /// Defaults to `true`.
  final bool exportEmoji;

  /// Whether to export the blur state.
  ///
  /// Defaults to `true`.
  final bool exportBlur;

  /// The `enableMinify` flag controls whether the keys in the
  /// exported/imported data should be shortened (minified) to save space or
  /// remain in their original, more descriptive form.
  ///
  /// When `enableMinify` is `true`, the keys are converted to shorter
  /// representations.
  /// When `enableMinify` is `false`, the original keys are retained.
  ///
  /// This flag is typically used to toggle between optimized exports
  /// (smaller payloads) and more readable exports for debugging or development
  /// purposes.
  final bool enableMinify;

  /// Whether to export the widget layers.
  ///
  /// Defaults to `true`.
  ///
  /// Warning: Exporting widgets may result in a significantly increased file
  /// size if no `exportConfigs` are added to the `WidgetLayer`.
  final bool exportWidgets;
}
