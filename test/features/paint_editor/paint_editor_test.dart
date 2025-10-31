// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:pro_image_editor/core/models/init_configs/paint_editor_init_configs.dart';
import 'package:pro_image_editor/features/paint_editor/paint_editor.dart';
import 'package:pro_image_editor/features/paint_editor/widgets/paint_canvas.dart';
import 'package:pro_image_editor/shared/widgets/color_picker/bar_color_picker.dart';

// Project imports:
import '../../fake/fake_image.dart';

void main() {
  group('PaintEditor Tests', () {
    testWidgets('Initializes with memory constructor',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      expect(find.byType(PaintEditor), findsOneWidget);
    });
    testWidgets('Initializes with network constructor',
        (WidgetTester tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(
          home: PaintEditor.network(
            fakeNetworkImage,
            initConfigs: PaintEditorInitConfigs(
              theme: ThemeData(),
            ),
          ),
        ));

        expect(find.byType(PaintEditor), findsOneWidget);
      });
    });

    testWidgets('should render BarColorPicker', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      expect(find.byType(BarColorPicker), findsOneWidget);
    });
    testWidgets('should render Canvas', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      expect(find.byType(PaintCanvas), findsOneWidget);
    });
    testWidgets('should change paint-mode', (WidgetTester tester) async {
      var key = GlobalKey<PaintEditorState>();
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          key: key,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      /// Test if paintModes will change correctly
      key.currentState!.setMode(PaintMode.freeStyle);
      expect(key.currentState!.paintMode, PaintMode.freeStyle);

      key.currentState!.setMode(PaintMode.dashLine);
      expect(key.currentState!.paintMode, PaintMode.dashLine);

      key.currentState!.setMode(PaintMode.dashDotLine);
      expect(key.currentState!.paintMode, PaintMode.dashDotLine);

      key.currentState!.setMode(PaintMode.arrow);
      expect(key.currentState!.paintMode, PaintMode.arrow);
    });
    testWidgets('should change stroke width', (WidgetTester tester) async {
      var key = GlobalKey<PaintEditorState>();
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          key: key,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      /// Test if paintModes will change correctly
      for (double i = 1; i <= 10; i++) {
        key.currentState!.setStrokeWidth(i);
        expect(key.currentState!.strokeWidth, i);
      }
    });
    testWidgets('should toggle fill state', (WidgetTester tester) async {
      var key = GlobalKey<PaintEditorState>();
      await tester.pumpWidget(MaterialApp(
        home: PaintEditor.memory(
          fakeMemoryImage,
          key: key,
          initConfigs: PaintEditorInitConfigs(
            theme: ThemeData(),
          ),
        ),
      ));

      bool filled = key.currentState!.fillBackground;

      key.currentState!.toggleFill();
      expect(key.currentState!.fillBackground, !filled);

      key.currentState!.toggleFill();
      expect(key.currentState!.fillBackground, filled);
    });
    testWidgets('should set fill via setFill', (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!;
      bool initialIsFilled = editor.fillBackground;

      editor.setFill(!initialIsFilled);

      expect(editor.fillBackground, isNot(initialIsFilled));
    });
    testWidgets('should set opacity via setOpacity',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!;
      double newOpacity = 0.21;

      editor.setOpacity(newOpacity);

      expect(editor.opacity, newOpacity);
    });
    testWidgets('should add custom paintings', (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!;

      /// The first history are the initial layers
      expect(editor.stateHistory.length, 1);

      editor.addPainting(
        PaintedModel(
          mode: PaintMode.rect,
          offsets: [const Offset(0, 0), const Offset(100, 100)],
          erasedOffsets: [],
          color: Colors.red,
          strokeWidth: 5,
          opacity: 1,
        ),
      );

      await tester.pump();

      expect(editor.stateHistory.length, 2);
      expect(find.byType(LayerWidget), findsAtLeast(1));
    });

    testWidgets('should undo the last action', (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!

        // Add a painting
        ..addPainting(
          PaintedModel(
            mode: PaintMode.rect,
            offsets: [const Offset(0, 0), const Offset(100, 100)],
            erasedOffsets: [],
            color: Colors.red,
            strokeWidth: 5,
            opacity: 1,
          ),
        );

      await tester.pump();

      // Verify the painting was added
      expect(editor.stateHistory.length, 2);
      expect(editor.canUndo, isTrue);

      // Perform undo
      editor.undoAction();
      await tester.pump();

      // Verify the painting was undone
      expect(editor.stateHistory.length, 2);
      expect(editor.historyPointer, 0);
      expect(editor.canUndo, isFalse);
    });

    testWidgets('should redo the last undone action',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!

        // Add a painting
        ..addPainting(
          PaintedModel(
            mode: PaintMode.rect,
            offsets: [const Offset(0, 0), const Offset(100, 100)],
            erasedOffsets: [],
            color: Colors.red,
            strokeWidth: 5,
            opacity: 1,
          ),
        );

      await tester.pump();

      // Perform undo
      editor.undoAction();
      await tester.pump();

      // Verify the painting was undone
      expect(editor.historyPointer, 0);
      expect(editor.canRedo, isTrue);

      // Perform redo
      editor.redoAction();
      await tester.pump();

      // Verify the painting was redone
      expect(editor.historyPointer, 1);
      expect(editor.canRedo, isFalse);
    });

    testWidgets('should not redo if no actions were undone',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!;

      // Verify initial state
      expect(editor.canRedo, isFalse);

      // Attempt redo
      editor.redoAction();
      await tester.pump();

      // Verify no changes occurred
      expect(editor.historyPointer, 0);
      expect(editor.canRedo, isFalse);
    });

    testWidgets('should not undo if no actions were performed',
        (WidgetTester tester) async {
      await pumpEditor(tester);

      final editor = key.currentState!;

      // Verify initial state
      expect(editor.canUndo, isFalse);

      // Attempt undo
      editor.undoAction();
      await tester.pump();

      // Verify no changes occurred
      expect(editor.historyPointer, 0);
      expect(editor.canUndo, isFalse);
    });
  });
}
