import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

class MovableSurface extends StatefulWidget {
  const MovableSurface({
    super.key,
    required this.child,
    required this.position,
    required this.itemSize,
    required this.onEnd,
    this.padding = 8,
    this.haptic = true,
    this.enabled = true,
    this.onStart,
    this.onCancel,
    this.longPressDuration = const Duration(milliseconds: 500),
    this.dragBorder = const Border.fromBorderSide(
      BorderSide(color: Color(0xFF65D9C2), width: 2),
    ),
    this.dragBorderRadius = const BorderRadius.all(Radius.circular(22)),
  });

  final Widget child;
  final Offset position;
  final Size itemSize;
  final double padding;
  final bool haptic;
  final bool enabled;
  final Duration longPressDuration;
  final Border? dragBorder;
  final BorderRadius dragBorderRadius;
  final ValueChanged<Offset> onEnd;
  final ValueChanged<Offset>? onStart;
  final void Function(Offset position, String reason)? onCancel;

  @override
  State<MovableSurface> createState() => _MovableSurfaceState();
}

class _MovableSurfaceState extends State<MovableSurface> {
  late final ValueNotifier<Offset> _position = ValueNotifier(widget.position);
  int? _pointerId;
  Offset? _pointerOrigin;
  Offset? _itemOrigin;
  Size _area = Size.zero;
  Size _item = Size.zero;
  Size? _viewport;
  bool _hasLayout = false;
  int _layoutEpoch = 0;

  Offset _bounded(Offset value) {
    final maxX = math.max(0.0, _area.width - _item.width);
    final maxY = math.max(0.0, _area.height - _item.height);
    final padX = math.min(widget.padding, maxX / 2);
    final padY = math.min(widget.padding, maxY / 2);
    return Offset(
      value.dx.clamp(padX, maxX - padX),
      value.dy.clamp(padY, maxY - padY),
    );
  }

  @override
  void didUpdateWidget(MovableSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled) {
      _cancel('disabled', rebuild: false);
    } else if (oldWidget.longPressDuration != widget.longPressDuration) {
      _cancel('configuration_changed', rebuild: false);
    }
    if (oldWidget.position != widget.position && _pointerOrigin == null) {
      _position.value = widget.position;
    }
  }

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _start(LongPressStartDetails details) {
    _pointerOrigin = details.globalPosition;
    _itemOrigin = _bounded(_position.value);
    if (widget.haptic) HapticFeedback.mediumImpact();
    setState(() {});
    widget.onStart?.call(_itemOrigin!);
  }

  void _cancel(
    String reason, {
    bool rebuild = true,
    bool deferNotification = false,
  }) {
    if (_pointerOrigin == null) return;
    final position = _bounded(_itemOrigin!);
    _pointerOrigin = null;
    _itemOrigin = null;
    _pointerId = null;
    _position.value = position;
    if (rebuild) setState(() {});
    if (deferNotification) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onCancel?.call(position, reason);
      });
    } else {
      widget.onCancel?.call(position, reason);
    }
  }

  void _move(LongPressMoveUpdateDetails details) {
    if (_pointerOrigin == null) return;
    _position.value = _bounded(
      _itemOrigin! + details.globalPosition - _pointerOrigin!,
    );
  }

  void _end(LongPressEndDetails details) {
    if (_pointerOrigin == null) return;
    final position = _bounded(
      _itemOrigin! + details.globalPosition - _pointerOrigin!,
    );
    _position.value = position;
    _pointerOrigin = null;
    _itemOrigin = null;
    setState(() {});
    widget.onEnd(position);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final area = constraints.biggest;
      if (!area.isFinite) {
        return const Text('Movable requires bounded width and height');
      }
      final item = Size(
        math.min(widget.itemSize.width, area.width),
        math.min(widget.itemSize.height, area.height),
      );
      final viewport = MediaQuery.maybeSizeOf(context);
      final changed =
          _hasLayout &&
          (_area != area || _item != item || _viewport != viewport);
      _area = area;
      _item = item;
      _viewport = viewport;
      _hasLayout = true;
      if (changed) {
        _layoutEpoch++;
        _cancel('layout_changed', rebuild: false, deferNotification: true);
        _pointerId = null;
      }
      return Stack(
        children: [
          ValueListenableBuilder<Offset>(
            valueListenable: _position,
            child: Listener(
              onPointerDown: (event) => _pointerId ??= event.pointer,
              onPointerUp: (event) {
                if (_pointerId == event.pointer) _pointerId = null;
              },
              onPointerCancel: (event) {
                if (_pointerId == event.pointer) {
                  _cancel('pointer_cancelled');
                  _pointerId = null;
                }
              },
              child: RawGestureDetector(
                key: ValueKey((widget.longPressDuration, _layoutEpoch)),
                behavior: HitTestBehavior.opaque,
                gestures: widget.enabled
                    ? {
                        LongPressGestureRecognizer:
                            GestureRecognizerFactoryWithHandlers<
                              LongPressGestureRecognizer
                            >(
                              () => LongPressGestureRecognizer(
                                duration: widget.longPressDuration,
                              ),
                              (recognizer) => recognizer
                                ..onLongPressStart = _start
                                ..onLongPressMoveUpdate = _move
                                ..onLongPressEnd = _end
                                ..onLongPressCancel = () =>
                                    _cancel('gesture_cancelled'),
                            ),
                      }
                    : {},
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: BoxDecoration(
                    borderRadius: widget.dragBorderRadius,
                    border: _pointerOrigin == null ? null : widget.dragBorder,
                  ),
                  child: RepaintBoundary(child: widget.child),
                ),
              ),
            ),
            builder: (context, position, child) {
              final bounded = _bounded(position);
              return Positioned(
                left: bounded.dx,
                top: bounded.dy,
                width: _item.width,
                height: _item.height,
                child: child!,
              );
            },
          ),
        ],
      );
    },
  );
}
