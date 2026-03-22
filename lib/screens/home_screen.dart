import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/meal_zone_card.dart';
import '../widgets/notification_toggle_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _calendarVisible = false;

  Future<void> _showAddMeasureDialog(
      BuildContext context, AppProvider provider) async {
    final nameCtrl = TextEditingController();
    TimeOfDay measureTime = TimeOfDay.now();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.sensors_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Text('Mesure capteur',
                style: AppFonts.title(size: 16)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              'Enregistre une mesure de glycémie prise par ton capteur, '
                  'à n\'importe quelle heure.',
              style: AppFonts.body(
                  color: Colors.grey.shade500, size: 13),
            ),
            const SizedBox(height: 18),

            // Nom optionnel
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Libellé (optionnel)',
                hintText: 'Ex: Avant sport, Réveil…',
                prefixIcon: Icon(Icons.label_outline_rounded,
                    size: 18, color: AppTheme.primary),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Heure de la mesure
            _TimeRow(
              label: 'Heure de la mesure',
              icon: Icons.access_time_rounded,
              time: measureTime,
              color: AppTheme.primary,
              onTap: () async {
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: measureTime,
                  builder: (c, child) => Theme(
                    data: Theme.of(c).copyWith(
                        colorScheme: const ColorScheme.light(
                            primary: AppTheme.primary)),
                    child: child!,
                  ),
                );
                if (t != null) setDlg(() => measureTime = t);
              },
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.15)),
              ),
              child: Row(children: [
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  'La valeur glycémie sera saisie dans la carte créée.',
                  style: AppFonts.label(
                      color: AppTheme.primary, size: 11),
                )),
              ]),
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annuler',
                  style: AppFonts.label(
                      color: Colors.grey, size: 14)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                provider.addSensorMeasure(
                  name: nameCtrl.text,
                  time: measureTime,
                );
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, provider, _) {
      final record = provider.currentRecord;
      final date   = provider.selectedDate;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Sahtek'),
          actions: [
            if (provider.syncing)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white70)),
              ),
            NotificationToggleButton(
                enabled: provider.notificationsEnabled,
                onTap: provider.toggleNotifications),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showAddMeasureDialog(context, provider),
          backgroundColor: AppTheme.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Ajouter une mesure',
              style: AppFonts.label(color: Colors.white, size: 13)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        body: Column(children: [
          _DateNavigator(date: date, calendarVisible: _calendarVisible,
              onToggleCalendar: () =>
                  setState(() => _calendarVisible = !_calendarVisible),
              onPrev: () => provider.selectDate(
                  date.subtract(const Duration(days: 1))),
              onNext: () => provider.selectDate(
                  date.add(const Duration(days: 1)))),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _calendarVisible
                ? _CalendarPanel(selected: date, onSelected: (d) {
              provider.selectDate(d);
              setState(() => _calendarVisible = false);
            })
                : const SizedBox.shrink(),
          ),
          _SummaryBar(totalDose: record.totalDose,
              avgGlycemie: record.averageGlycemieAffichee),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: record.entries.length,
            itemBuilder: (_, i) => MealZoneCard(
                key: ValueKey(record.entries[i].id),
                entry: record.entries[i], index: i),
          )),
        ]),
      );
    });
  }
}

// ── Date navigator ─────────────────────────────────────────────────────────────
class _DateNavigator extends StatelessWidget {
  final DateTime date;
  final bool calendarVisible;
  final VoidCallback onToggleCalendar, onPrev, onNext;
  const _DateNavigator({required this.date, required this.calendarVisible,
    required this.onToggleCalendar, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    return Container(
      color: AppTheme.primary,
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 14),
      child: Row(children: [
        IconButton(onPressed: onPrev,
            icon: const Icon(Icons.chevron_left_rounded,
                color: Colors.white, size: 28)),
        Expanded(child: GestureDetector(
          onTap: onToggleCalendar,
          child: Column(children: [
            Text(isToday ? "Aujourd'hui"
                : DateFormat('EEEE', 'fr_FR').format(date),
                style: AppFonts.label(color: Colors.white70, size: 12)),
            const SizedBox(height: 2),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(DateFormat('d MMMM yyyy', 'fr_FR').format(date),
                  style: AppFonts.title(color: Colors.white, size: 16)),
              const SizedBox(width: 6),
              Icon(calendarVisible ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded,
                  color: Colors.white70, size: 18),
            ]),
          ]),
        )),
        IconButton(onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 28)),
      ]),
    );
  }
}

// ── Calendar panel ─────────────────────────────────────────────────────────────
class _CalendarPanel extends StatelessWidget {
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  const _CalendarPanel({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: TableCalendar(
        firstDay: DateTime(2020), lastDay: DateTime(2030),
        focusedDay: selected, locale: 'fr_FR',
        selectedDayPredicate: (d) => DateUtils.isSameDay(d, selected),
        onDaySelected: (d, _) => onSelected(d),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.5),
              shape: BoxShape.circle),
          selectedDecoration: const BoxDecoration(
              color: AppTheme.primary, shape: BoxShape.circle),
          defaultTextStyle: AppFonts.body(size: 13),
          weekendTextStyle: AppFonts.body(color: const Color(0xFFE53935), size: 13),
          todayTextStyle: AppFonts.bold(color: Colors.white, size: 13),
          selectedTextStyle: AppFonts.bold(color: Colors.white, size: 13),
          outsideDaysVisible: false,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: AppFonts.title(color: AppTheme.primary, size: 15),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded,
              color: AppTheme.primary),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded,
              color: AppTheme.primary),
        ),
      ),
    );
  }
}

// ── Summary bar ────────────────────────────────────────────────────────────────
class _SummaryBar extends StatelessWidget {
  final double totalDose, avgGlycemie;
  const _SummaryBar({required this.totalDose, required this.avgGlycemie});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.secondary],
            begin: Alignment.centerLeft, end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.25),
            blurRadius: 14, offset: const Offset(0, 5))],
      ),
      child: Row(children: [
        _Stat(icon: Icons.medication_liquid_rounded,
            label: 'Doses totales',
            value: totalDose > 0 ? totalDose.toStringAsFixed(2) : '--',
            unit: 'UI'),
        Container(width: 1, height: 36,
            color: Colors.white.withOpacity(0.3)),
        _Stat(icon: Icons.show_chart_rounded,
            label: 'Glycémie moy.',
            value: avgGlycemie > 0 ? avgGlycemie.toStringAsFixed(1) : '--',
            unit: 'Mg/dl'),
      ]),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  const _Stat({required this.icon, required this.label,
    required this.value, required this.unit});

  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Icon(icon, color: Colors.white70, size: 17),
    const SizedBox(height: 3),
    Text(label, style: AppFonts.label(
        color: Colors.white.withOpacity(0.8), size: 11)),
    const SizedBox(height: 2),
    RichText(text: TextSpan(children: [
      TextSpan(text: value,
          style: AppFonts.bold(color: Colors.white, size: 19)),
      TextSpan(text: '  $unit',
          style: AppFonts.label(color: Colors.white70, size: 11)),
    ])),
  ]));
}
// ── Time row dans le dialog ────────────────────────────────────────────────────
class _TimeRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final TimeOfDay time;
  final Color color;
  final VoidCallback onTap;

  const _TimeRow({
    required this.label,
    required this.icon,
    required this.time,
    required this.color,
    required this.onTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label,
              style: AppFonts.body(color: Colors.grey.shade600, size: 13))),
          Text(_fmt(time),
              style: AppFonts.bold(color: color, size: 18)
                  .copyWith(letterSpacing: 1)),
          const SizedBox(width: 4),
          Icon(Icons.edit_rounded, size: 14, color: color.withOpacity(0.5)),
        ]),
      ),
    );
  }
}