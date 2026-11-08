import 'dart:convert';
import 'package:flet/flet.dart';
import 'package:material_ui/material_ui.dart';
import 'movable_surface.dart';

class Extension extends FletExtension {
  @override
  Widget? createWidget(Key? key, Control control) {
    if (control.type != 'movable') return null;
    return LayoutControl(
      key: key,
      control: control,
      child: Builder(
        builder: (context) => MovableSurface(
          position: Offset(
            control.getDouble('x', 16)!,
            control.getDouble('y', 16)!,
          ),
          itemSize: Size(
            control.getDouble('item_width', 232)!,
            control.getDouble('item_height', 72)!,
          ),
          padding: control.getDouble('edge_padding', 8)!,
          haptic: control.getBool('haptic', true)!,
          enabled: !control.disabled,
          longPressDuration: Duration(
            microseconds:
                (control.getDouble('long_press_duration', 0.5)! * 1000000)
                    .round(),
          ),
          dragBorder: control.getBorder('drag_border', Theme.of(context)),
          dragBorderRadius:
              control.getBorderRadius('drag_border_radius') ??
              BorderRadius.zero,
          onStart: (position) => control.triggerEvent(
            'move_start',
            jsonEncode({'x': position.dx, 'y': position.dy}),
          ),
          onCancel: (position, reason) {
            control.updateProperties({'x': position.dx, 'y': position.dy});
            control.triggerEvent(
              'move_cancel',
              jsonEncode({
                'x': position.dx,
                'y': position.dy,
                'reason': reason,
              }),
            );
          },
          onEnd: (position) {
            control.updateProperties({'x': position.dx, 'y': position.dy});
            control.triggerEvent(
              'move_end',
              jsonEncode({'x': position.dx, 'y': position.dy}),
            );
          },
          child: control.buildWidget('content') ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
