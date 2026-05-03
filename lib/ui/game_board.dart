import 'package:flutter/material.dart';

import '../game/game_config.dart';
import '../game/game_state.dart';
import 'tile_widget.dart';

class GameBoard extends StatelessWidget {
  const GameBoard({super.key, required this.state, required this.boardSize});

  final GameState state;
  final double boardSize;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    final n = state.size;
    final tileSize = (boardSize - gap * (n + 1)) / n;

    if (tileSize <= 0) return const SizedBox.shrink();

    return Container(
      width: boardSize,
      height: boardSize,
      decoration: BoxDecoration(
        color: boardColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Background empty cells
          for (var r = 0; r < n; r++)
            for (var c = 0; c < n; c++)
              Positioned(
                top: gap + r * (tileSize + gap),
                left: gap + c * (tileSize + gap),
                child: Container(
                  width: tileSize,
                  height: tileSize,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCDC1B4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
          // Tiles — keyed by stable tile ID so AnimatedPositioned animates moves
          for (final tile in state.tiles)
            AnimatedPositioned(
              key: ValueKey(tile.id),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeInOut,
              top: gap + tile.row * (tileSize + gap),
              left: gap + tile.col * (tileSize + gap),
              child: TileWidget(
                key: ValueKey(tile.id),
                value: tile.value,
                tileSize: tileSize,
              ),
            ),
        ],
      ),
    );
  }
}
