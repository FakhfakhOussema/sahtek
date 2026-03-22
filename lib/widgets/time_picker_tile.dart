import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class TimePickerTile extends StatelessWidget {
  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onChanged;
  final IconData icon;
  final Color color;

  const TimePickerTile({super.key, required this.label, required this.time,
    required this.onChanged, required this.icon,
    this.color = AppTheme.primary});

  String _format(TimeOfDay? t) {
    if (t == null) return '--:--';
    return '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
          builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: ColorScheme.light(primary: color)),
            child: child!,
          ),
        );
        if (picked != null) onChanged(picked);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Column(crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: AppFonts.label(
                    color: color.withOpacity(0.75), size: 10)),
                Text(_format(time), style: AppFonts.bold(color: color, size: 15)
                    .copyWith(letterSpacing: 1)),
              ]),
        ]),
      ),
    );
  }
}