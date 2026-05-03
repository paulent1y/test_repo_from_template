# Flutter Runtime Wireframe Debug Overlay

Zero-dependency, zero-rebuild debug system. Toggle in-app. Shows exact dp sizes, zone labels, color-coded layers. No layout impact — `CustomPaint` foreground only.

---

## What You Get

- Colored border per zone (each zone gets its own color)
- Width/height in dp shown on border edges
- Zone label + percent in top-left corner
- Toggle button inside the UI — no hot restart needed
- Zero performance cost when off (`ValueNotifier` short-circuits)

---

## Step 1 — Create `wireframe_wrapper.dart`

```dart
// lib/debug/wireframe_wrapper.dart
import 'dart:math' show pi;
import 'package:flutter/material.dart';

final wireframeEnabled = ValueNotifier<bool>(false);

class WireframeWrapper extends StatelessWidget {
  const WireframeWrapper({
    super.key,
    required this.child,
    required this.label,
    this.color = const Color(0xFF2196F3),
  });

  final Widget child;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: wireframeEnabled,
      builder: (_, enabled, _) {
        if (!enabled) return child;
        return CustomPaint(
          foregroundPainter: _WireframePainter(label: label, color: color),
          child: child,
        );
      },
    );
  }
}

class _WireframePainter extends CustomPainter {
  _WireframePainter({required this.label, required this.color});

  final String label;
  final Color color;

  static final Map<Color, Paint> _borderCache = {};

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = _borderCache.putIfAbsent(
      color,
      () => Paint()
        ..color = color.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    canvas.drawRect(Offset.zero & size, borderPaint);

    final w = size.width;
    final h = size.height;

    // Width label — centered on top edge
    _label(canvas, '${w.round()}', Offset(w / 2, 7), color);

    // Height label — centered on right edge, rotated
    canvas.save();
    canvas.translate(w - 7, h / 2);
    canvas.rotate(-pi / 2);
    _label(canvas, '${h.round()}', Offset.zero, color);
    canvas.restore();

    // Zone name — top-left corner
    _label(canvas, label, const Offset(4, 4), color,
        align: TextAlign.left, anchor: Alignment.topLeft);
  }

  void _label(
    Canvas canvas,
    String text,
    Offset position,
    Color color, {
    TextAlign align = TextAlign.center,
    Alignment anchor = Alignment.center,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    final w = tp.width + 3;
    final h = tp.height + 2;
    final dx = position.dx - w * (anchor.x + 1) / 2;
    final dy = position.dy - h * (anchor.y + 1) / 2;

    final bg = Paint()..color = Colors.black.withAlpha(160);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, dy, w, h), const Radius.circular(2)),
      bg,
    );
    tp.paint(canvas, Offset(dx + 1.5, dy + 1));
  }

  @override
  bool shouldRepaint(_WireframePainter old) =>
      old.label != label || old.color != color;
}
```

---

## Step 2 — Create a Layout Constants Class

Centralize all sizes. **Never hardcode values in widgets.**

```dart
// lib/layout.dart  (or lib/my_feature/my_feature_layout.dart)
class AppLayout {
  // Zone heights as % of available screen height. Must sum to ≤ 100.
  static const double zoneHeaderPercent  = 8.0;
  static const double zoneContentPercent = 82.0;
  static const double zoneFooterPercent  = 10.0;

  // Concrete sizes (dp)
  static const double headerPadH = 16.0;
  static const double footerButtonHeight = 44.0;
  // ... add everything here
}
```

Benefits:
- Single source of truth — tweak one number, layout shifts everywhere
- Wireframe labels can embed the percent (`'header ${AppLayout.zoneHeaderPercent}%'`)
- Easy to diff layout across git history

---

## Step 3 — Wrap Zones in Your Screen

```dart
import '../debug/wireframe_wrapper.dart';
import 'app_layout.dart';

// One color per logical layer — pick a distinct palette
const _cHeader  = Color(0xFF2196F3); // blue
const _cContent = Color(0xFF4CAF50); // green
const _cFooter  = Color(0xFF9C27B0); // purple

// Inside LayoutBuilder:
final screenH = constraints.maxHeight;
final headerH  = screenH * AppLayout.zoneHeaderPercent  / 100;
final contentH = screenH * AppLayout.zoneContentPercent / 100;
final footerH  = screenH * AppLayout.zoneFooterPercent  / 100;

Column(
  children: [
    WireframeWrapper(
      label: 'header ${AppLayout.zoneHeaderPercent.toStringAsFixed(0)}%',
      color: _cHeader,
      child: SizedBox(height: headerH, child: MyHeader()),
    ),
    WireframeWrapper(
      label: 'content ${AppLayout.zoneContentPercent.toStringAsFixed(0)}%',
      color: _cContent,
      child: SizedBox(height: contentH, child: MyContent()),
    ),
    WireframeWrapper(
      label: 'footer ${AppLayout.zoneFooterPercent.toStringAsFixed(0)}%',
      color: _cFooter,
      child: SizedBox(height: footerH, child: MyFooter()),
    ),
  ],
)
```

Wrap individual widgets too — any `child:` argument accepts `WireframeWrapper`.

---

## Step 4 — Add a Toggle Button

Wire `wireframeEnabled` global notifier to any button:

```dart
import '../debug/wireframe_wrapper.dart';

ValueListenableBuilder<bool>(
  valueListenable: wireframeEnabled,
  builder: (_, enabled, _) => IconButton(
    onPressed: () => wireframeEnabled.value = !wireframeEnabled.value,
    icon: Icon(enabled ? Icons.grid_on : Icons.grid_off),
    tooltip: 'Wireframe',
  ),
)
```

Put this button in a persistent bar (app bar, bottom bar, FAB) so it's always reachable. The button itself can be wrapped in `WireframeWrapper` — it self-labels when overlay is on.

---

## Color Palette Reference

| Layer | Color | Hex |
|-------|-------|-----|
| Blue | Navigation / header | `0xFF2196F3` |
| Orange | Primary content zone | `0xFFFF9800` |
| Green | Board / canvas | `0xFF4CAF50` |
| Purple | Controls / footer | `0xFF9C27B0` |
| Cyan | Expanded / spacer | `0xFF00BCD4` |
| Red | Overlay / modal | `0xFFF44336` |

Pick distinct hues — zones must be identifiable at a glance.

---

## How It Works

```
WireframeWrapper
└── ValueListenableBuilder (off → returns child directly, zero overhead)
    └── CustomPaint (foregroundPainter — draws ON TOP, never shifts layout)
        └── child (your widget, untouched)
```

`CustomPaint` foreground painter runs after child layout. Child size is already final — labels show real dp values, not estimates. No `LayoutBuilder` needed inside the painter.

`_borderCache` avoids allocating a new `Paint` per frame per color.

---

## Checklist

- [ ] `lib/debug/wireframe_wrapper.dart` created
- [ ] Layout constants class created with `zoneXxxPercent` values
- [ ] `LayoutBuilder` drives zone heights from `constraints.maxHeight`
- [ ] Each zone wrapped in `WireframeWrapper` with label + distinct color
- [ ] Toggle button wired to `wireframeEnabled.value`
- [ ] Toggle button itself wrapped (self-documents in overlay)
- [ ] Verified: toggling does not trigger widget rebuild of children
- [ ] Verified: overlay does not shift layout (no added padding/size)

---

## Extending

**Show percent of parent, not screen** — pass `parentH` from outer `LayoutBuilder` and compute `size.height / parentH * 100` inside the painter. Requires a stateful wrapper or `InheritedWidget`.

**Persistent toggle across hot restart** — store `wireframeEnabled.value` in `SharedPreferences` and restore on init.

**Conditional compile-out** — guard the painter behind `kDebugMode` if you want zero dead code in release:

```dart
if (!enabled || !kDebugMode) return child;
```
