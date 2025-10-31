import 'package:flutter/gestures.dart';

/// Class that holds interactions for a layer item.
class LayerItemInteractions {
  /// Constructor for LayerItemInteractions.
  ///
  /// Requires all callbacks to be provided.
  LayerItemInteractions({
    required this.edit,
    required this.remove,
    required this.scaleRotateDown,
    required this.scaleRotateUp,
  });

  /// Callback function for editing the layer.
  final Function() edit;

  /// Callback function for removing the layer.
  final Function() remove;

  /// Callback function triggered when a scale/rotate gesture starts.
  ///
  /// This function is required to initiate the scaling and rotation
  /// operations on the layer.
  final Function(PointerDownEvent event) scaleRotateDown;

  /// Callback function triggered when a scale/rotate gesture ends.
  ///
  /// This function is required to finalize the scaling and rotation
  /// operations on the layer, applying the changes.
  final Function(PointerUpEvent event) scaleRotateUp;
}
