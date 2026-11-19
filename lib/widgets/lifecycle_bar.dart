import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

class LifecycleBar extends StatelessWidget {
  const LifecycleBar({
    super.key,
    required this.percent,
    required this.color,
    required this.ended,
    required this.todayLabel,
    required this.startLabel,
    required this.endLabel,
  });

  final int percent;
  final Color color;
  final bool ended;
  final String todayLabel;
  final String startLabel;
  final String endLabel;

  @override
  Widget build(BuildContext context) {
    final colors = StatusColors.of(context);
    final textTheme = Theme.of(context).textTheme;
    final fraction = percent.clamp(0, 100) / 100;
    final labelFraction = percent.clamp(12, 88) / 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 20,
              child: ended
                  ? null
                  : Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: width * labelFraction,
                          bottom: 0,
                          child: FractionalTranslation(
                            translation: const Offset(-0.5, 0),
                            child: Text(
                              '$todayLabel · $percent%',
                              maxLines: 1,
                              softWrap: false,
                              style: textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 10,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: ColoredBox(
                        color: Color.lerp(colors.accentedBg, color, 0.22)!,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: fraction,
                            heightFactor: 1,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (!ended)
                    Positioned(
                      left: width * fraction - 1,
                      top: -4,
                      bottom: -4,
                      width: 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.invertedBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            DefaultTextStyle.merge(
              style: textTheme.labelSmall?.copyWith(color: colors.muted),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: Text(startLabel)),
                  const SizedBox(width: 8),
                  Flexible(child: Text(endLabel, textAlign: TextAlign.end)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
