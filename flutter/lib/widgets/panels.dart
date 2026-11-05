import 'package:flutter/material.dart';

import '../app/octobot_theme.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({required this.children, super.key});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i != 0) const SizedBox(height: 18),
              children[i],
            ],
          ],
        ),
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading({required this.title, required this.subtitle, super.key});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 5),
      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding = const EdgeInsets.all(18), super.key});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: OctoColors.paper,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: OctoColors.line),
    ),
    child: child,
  );
}

class Overline extends StatelessWidget {
  const Overline(this.label, {this.color = OctoColors.muted, super.key});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      color: color, fontWeight: FontWeight.w800,
      letterSpacing: 1.4, fontSize: 10,
    ),
  );
}

class RowInfo extends StatelessWidget {
  const RowInfo({required this.label, required this.value, this.trailing, super.key});
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 11),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: OctoColors.muted, fontSize: 13))),
      if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
      Flexible(child: Text(value, textAlign: TextAlign.right,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
    ]),
  );
}

class GroupLegend extends StatelessWidget {
  const GroupLegend({this.onDark = false, super.key});
  final bool onDark;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 14,
    runSpacing: 8,
    alignment: WrapAlignment.center,
    children: [
      _LegendDot(color: OctoColors.blue, label: 'L1 / R1  ·  L3 / R3', onDark: onDark),
      _LegendDot(color: OctoColors.orange, label: 'L2 / R2  ·  L4 / R4', onDark: onDark),
    ],
  );
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.onDark});
  final Color color;
  final String label;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(height: 9, width: 9,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 7),
      Text(label, style: TextStyle(fontSize: 11,
        color: onDark ? const Color(0xFFD1DFDE) : OctoColors.muted)),
    ],
  );
}
