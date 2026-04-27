import 'package:flutter/material.dart';

class TalentsTab extends StatelessWidget {
  const TalentsTab({super.key});

  static const _items = [
    ('Power Surge', 'Bonus damage on boss hits', '⚡'),
    ('Quick Hands', 'Board starts with two 4-tiles', '🃏'),
    ('Treasure Hunter', '+1 coin reward per enemy', '🏴‍☠️'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final (name, desc, icon) = _items[i];
        return _LockedCard(name: name, desc: desc, icon: icon);
      },
    );
  }
}

class _LockedCard extends StatelessWidget {
  const _LockedCard({
    required this.name,
    required this.desc,
    required this.icon,
  });

  final String name;
  final String desc;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEE4DA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCDC1B4)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF776E65),
                    )),
                Text(desc,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFBBADA0),
                    )),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, color: Color(0xFFBBADA0), size: 20),
        ],
      ),
    );
  }
}
