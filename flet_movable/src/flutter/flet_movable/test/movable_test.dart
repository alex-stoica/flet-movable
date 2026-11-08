import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flet_movable/src/movable_surface.dart';

void main() {
  testWidgets('moves locally, clamps, and reports only on release', (
    tester,
  ) async {
    final drops = <Offset>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: 600,
            child: MovableSurface(
              position: const Offset(20, 30),
              itemSize: const Size(120, 80),
              haptic: false,
              onEnd: drops.add,
              child: const ColoredBox(
                key: ValueKey('item'),
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ),
    );
    final item = find.byKey(const ValueKey('item'));
    expect(tester.getTopLeft(item), const Offset(20, 30));
    final gesture = await tester.startGesture(const Offset(50, 60));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(100, 150));
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(120, 180));
    expect(drops, isEmpty);
    await gesture.moveBy(const Offset(500, 700));
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(272, 512));
    await gesture.up();
    await tester.pump();
    expect(drops, [const Offset(272, 512)]);
  });

  testWidgets('content rebuilds preserve local position and child taps work', (
    tester,
  ) async {
    final drops = <Offset>[];
    var taps = 0;
    var tick = 0;
    late StateSetter refresh;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            refresh = setState;
            return SizedBox.expand(
              child: MovableSurface(
                position: const Offset(20, 30),
                itemSize: const Size(180, 80),
                haptic: false,
                onEnd: drops.add,
                child: TextButton(
                  key: const ValueKey('item'),
                  onPressed: () => taps++,
                  child: Text('$tick'),
                ),
              ),
            );
          },
        ),
      ),
    );
    final item = find.byKey(const ValueKey('item'));
    await tester.tap(item);
    expect(taps, 1);
    final gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(120, 140));
    await tester.pump();
    refresh(() => tick++);
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(140, 170));
    expect(drops, isEmpty);
    await gesture.up();
    await tester.pump();
    refresh(() => tick++);
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(140, 170));
    expect(drops.length, 1);
    expect(taps, 1);
  });

  testWidgets('custom delay, outline and runtime disabling', (tester) async {
    var enabled = true;
    Border? border = Border.all(color: Colors.orange, width: 4);
    late StateSetter refresh;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            refresh = setState;
            return SizedBox.expand(
              child: MovableSurface(
                position: const Offset(20, 30),
                itemSize: const Size(180, 80),
                longPressDuration: const Duration(milliseconds: 1200),
                dragBorder: border,
                dragBorderRadius: BorderRadius.circular(12),
                enabled: enabled,
                haptic: false,
                onEnd: (_) {},
                child: const ColoredBox(
                  key: ValueKey('item'),
                  color: Colors.blue,
                ),
              ),
            );
          },
        ),
      ),
    );
    final item = find.byKey(const ValueKey('item'));
    BoxDecoration decoration() =>
        tester
                .widget<DecoratedBox>(
                  find
                      .ancestor(of: item, matching: find.byType(DecoratedBox))
                      .first,
                )
                .decoration
            as BoxDecoration;
    var gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 700));
    expect(decoration().border, isNull);
    await gesture.up();
    await tester.pump();
    gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 1201));
    expect(decoration().border, border);
    expect(decoration().borderRadius, BorderRadius.circular(12));
    await gesture.moveBy(const Offset(50, 60));
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(70, 90));
    await gesture.up();
    await tester.pump();
    refresh(() => border = null);
    await tester.pump();
    gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump(const Duration(milliseconds: 1201));
    expect(decoration().border, isNull);
    await gesture.moveBy(const Offset(20, 30));
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(90, 120));
    refresh(() => enabled = false);
    await tester.pump();
    await gesture.moveBy(const Offset(50, 50));
    await tester.pump();
    expect(tester.getTopLeft(item), const Offset(70, 90));
    await gesture.up();
  });

  testWidgets(
    'start precedes end; taps and secondary cancellation are ignored',
    (tester) async {
      final events = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox.expand(
            child: MovableSurface(
              position: const Offset(20, 30),
              itemSize: const Size(180, 80),
              haptic: false,
              onStart: (p) => events.add('start:${p.dx},${p.dy}'),
              onEnd: (p) => events.add('end:${p.dx},${p.dy}'),
              onCancel: (p, reason) => events.add('cancel:$reason'),
              child: const ColoredBox(
                key: ValueKey('item'),
                color: Colors.blue,
              ),
            ),
          ),
        ),
      );
      final item = find.byKey(const ValueKey('item'));
      await tester.tap(item);
      await tester.pump();
      expect(events, isEmpty);
      final first = await tester.startGesture(
        tester.getCenter(item),
        pointer: 1,
      );
      await tester.pump(const Duration(milliseconds: 600));
      expect(events, ['start:20.0,30.0']);
      final second = await tester.startGesture(
        tester.getCenter(item),
        pointer: 2,
      );
      await second.cancel();
      await tester.pump();
      expect(events.length, 1);
      await first.moveBy(const Offset(50, 60));
      await tester.pump();
      expect(events.length, 1);
      await first.up();
      await tester.pump();
      expect(events, ['start:20.0,30.0', 'end:70.0,90.0']);
    },
  );

  for (final reason in [
    'pointer_cancelled',
    'disabled',
    'configuration_changed',
  ]) {
    testWidgets('cancellation restores origin exactly once: $reason', (
      tester,
    ) async {
      final events = <String>[];
      var enabled = true;
      var delay = const Duration(milliseconds: 500);
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return SizedBox.expand(
                child: MovableSurface(
                  position: const Offset(20, 30),
                  itemSize: const Size(180, 80),
                  haptic: false,
                  enabled: enabled,
                  longPressDuration: delay,
                  onStart: (_) => events.add('start'),
                  onEnd: (_) => events.add('end'),
                  onCancel: (p, why) => events.add('$why:${p.dx},${p.dy}'),
                  child: const ColoredBox(
                    key: ValueKey('item'),
                    color: Colors.blue,
                  ),
                ),
              );
            },
          ),
        ),
      );
      final item = find.byKey(const ValueKey('item'));
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(50, 60));
      await tester.pump();
      expect(tester.getTopLeft(item), const Offset(70, 90));
      if (reason == 'pointer_cancelled') {
        await gesture.cancel();
      } else {
        refresh(() {
          if (reason == 'disabled')
            enabled = false;
          else
            delay = const Duration(seconds: 1);
        });
        await tester.pump();
        await gesture.up();
      }
      await tester.pump();
      expect(tester.getTopLeft(item), const Offset(20, 30));
      expect(events, ['start', '$reason:20.0,30.0']);
      refresh(() {
        enabled = true;
      });
      await tester.pump();
      final next = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 1100));
      await next.moveBy(const Offset(10, 10));
      await next.up();
      await tester.pump();
      expect(events, ['start', '$reason:20.0,30.0', 'start', 'end']);
    });
  }

  for (final viewportOnly in [false, true]) {
    testWidgets('rotation cancels an active drag, viewportOnly=$viewportOnly', (
      tester,
    ) async {
      final events = <String>[];
      var landscape = false;
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              final area = landscape
                  ? const Size(600, 300)
                  : const Size(400, 600);
              return MediaQuery(
                data: MediaQueryData(size: area),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: viewportOnly ? 400 : area.width,
                    height: viewportOnly ? 300 : area.height,
                    child: MovableSurface(
                      position: const Offset(20, 30),
                      itemSize: const Size(180, 80),
                      haptic: false,
                      onStart: (_) => events.add('start'),
                      onEnd: (_) => events.add('end'),
                      onCancel: (p, reason) =>
                          events.add('$reason:${p.dx},${p.dy}'),
                      child: const ColoredBox(
                        key: ValueKey('item'),
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      final item = find.byKey(const ValueKey('item'));
      final gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(100, 100));
      await tester.pump();
      expect(tester.getTopLeft(item), const Offset(120, 130));
      refresh(() => landscape = true);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(item), const Offset(20, 30));
      expect(events, ['start', 'layout_changed:20.0,30.0']);
      await gesture.moveBy(const Offset(40, 40));
      await gesture.up();
      await tester.pump();
      expect(events.length, 2);
      expect(tester.getTopLeft(item), const Offset(20, 30));
      refresh(() => landscape = false);
      await tester.pump();
      expect(tester.getTopLeft(item), const Offset(20, 30));
      final next = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 600));
      await next.moveBy(const Offset(10, 10));
      await next.up();
      await tester.pump();
      expect(events, ['start', 'layout_changed:20.0,30.0', 'start', 'end']);
    });
  }

  testWidgets(
    'rotation clamps restored origin and cancels pending long press',
    (tester) async {
      var landscape = false;
      final cancelled = <Offset>[];
      var starts = 0;
      late StateSetter refresh;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: landscape ? 600 : 400,
                  height: landscape ? 300 : 600,
                  child: MovableSurface(
                    position: const Offset(20, 450),
                    itemSize: const Size(180, 80),
                    haptic: false,
                    onStart: (_) => starts++,
                    onEnd: (_) {},
                    onCancel: (p, _) => cancelled.add(p),
                    child: const ColoredBox(
                      key: ValueKey('item'),
                      color: Colors.blue,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      final item = find.byKey(const ValueKey('item'));
      var gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveBy(const Offset(50, -100));
      await tester.pump();
      refresh(() => landscape = true);
      await tester.pump();
      expect(tester.getTopLeft(item), const Offset(20, 212));
      expect(cancelled, [const Offset(20, 212)]);
      await gesture.up();
      await tester.pump();
      gesture = await tester.startGesture(tester.getCenter(item));
      await tester.pump(const Duration(milliseconds: 200));
      refresh(() => landscape = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await tester.pump();
      expect(starts, 1);
      expect(cancelled.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
