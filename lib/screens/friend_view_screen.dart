import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/day_record.dart';
import '../models/meal_entry.dart';
import '../services/supabase_service.dart';
import '../utils/app_theme.dart';

class FriendViewScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  const FriendViewScreen({
    super.key,
    required this.friendId,
    required this.friendName,
  });
  @override
  State<FriendViewScreen> createState() => _FriendViewScreenState();
}

class _FriendViewScreenState extends State<FriendViewScreen> {
  List<DayRecord> _records = [];
  bool _loading = true;
  int _selectedIdx = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await SupabaseService.instance.fetchFriendRecords(widget.friendId);
      setState(() {
        _records = r;
        _loading = false;
        _selectedIdx = r.isNotEmpty ? r.length - 1 : 0;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(children: [
          Text(widget.friendName),
          const Text('Lecture seule',
              style: TextStyle(fontSize: 11, color: Colors.white70)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: const Text('👁 Lecture seule',
                  style: TextStyle(fontSize: 10, color: Colors.white)),
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: EdgeInsets.zero,
              side: BorderSide.none,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
          ? _buildEmpty()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          _buildCharts(),
          const SizedBox(height: 16),
          _buildDateSelector(),
          const SizedBox(height: 12),
          _buildDayDetail(),
        ]),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.no_accounts_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text('Aucune donnée disponible',
            style: AppFonts.title(color: Colors.grey.shade500, size: 16)),
        const SizedBox(height: 6),
        Text('${widget.friendName} n\'a pas encore de données.',
            style: AppFonts.body(color: Colors.grey.shade400, size: 13)),
      ],
    ));
  }

  Widget _buildCharts() {
    final doseSpots  = <FlSpot>[];
    final glycSpots  = <FlSpot>[];
    for (var i = 0; i < _records.length; i++) {
      if (_records[i].totalDose > 0)
        doseSpots.add(FlSpot(i.toDouble(), _records[i].totalDose));
      if (_records[i].averageGlycemieAffichee > 0)
        glycSpots.add(FlSpot(i.toDouble(), _records[i].averageGlycemieAffichee));
    }
    return Column(children: [
      _MiniChart(title: 'Doses', spots: doseSpots,
          color: AppTheme.primary, unit: 'UI', total: _records.length),
      const SizedBox(height: 12),
      _MiniChart(title: 'Glycémie moyenne', spots: glycSpots,
          color: AppTheme.secondary, unit: 'Mg/dl', total: _records.length),
    ]);
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _records.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final parts = _records[i].dateKey.split('-');
          final label = '${parts[2]}/${parts[1]}';
          final sel   = i == _selectedIdx;
          return GestureDetector(
            onTap: () => setState(() => _selectedIdx = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: sel
                    ? AppTheme.primary : Colors.grey.shade200),
                boxShadow: sel ? [BoxShadow(
                    color: AppTheme.primary.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Text(label, style: AppFonts.label(
                  color: sel ? Colors.white : Colors.grey.shade600,
                  size: 13).copyWith(
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayDetail() {
    if (_records.isEmpty || _selectedIdx >= _records.length) {
      return const SizedBox();
    }
    final rec = _records[_selectedIdx];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header de la journée
          Row(children: [
            const Icon(Icons.calendar_today_rounded,
                size: 16, color: AppTheme.primary),
            const SizedBox(width: 8),
            Text(rec.dateKey, style: AppFonts.title(
                color: AppTheme.primary, size: 14)),
            const Spacer(),
            _StatPill(label: 'Doses',
                value: rec.totalDose.toStringAsFixed(1),
                unit: 'UI', color: AppTheme.primary),
            const SizedBox(width: 8),
            _StatPill(label: 'Glycémie moy.',
                value: rec.averageGlycemieAffichee.toStringAsFixed(1),
                unit: 'Mg/dl', color: AppTheme.secondary),
          ]),
          const Divider(height: 20),
          // Liste des repas
          ...rec.entries.map((e) => _EntryRow(entry: e)),
        ]),
      ),
    );
  }
}

// ── Mini chart ─────────────────────────────────────────────────────────────────
class _MiniChart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color color;
  final String unit;
  final int total;

  const _MiniChart({required this.title, required this.spots,
    required this.color, required this.unit, required this.total});

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(title, style: AppFonts.title(size: 13)),
          const Spacer(),
          Text(unit, style: AppFonts.unit(color: color)),
        ]),
        const SizedBox(height: 10),
        spots.isEmpty
            ? SizedBox(height: 80, child: Center(
            child: Text('Pas de données',
                style: AppFonts.body(
                    color: Colors.grey.shade400, size: 12))))
            : SizedBox(
          height: 80,
          child: LineChart(LineChartData(
            minX: 0,
            maxX: (total - 1).toDouble(),
            minY: 0,
            maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.3,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: const FlTitlesData(
              topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles:   AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            lineBarsData: [LineChartBarData(
              spots: spots, isCurved: true,
              color: color, barWidth: 2.5, isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                  show: true, color: color.withOpacity(0.12)),
            )],
          )),
        ),
      ]),
    ));
  }
}

// ── Entry row (read-only) ──────────────────────────────────────────────────────
class _EntryRow extends StatelessWidget {
  final MealEntry entry;
  const _EntryRow({required this.entry});

  Color get _color {
    switch (entry.type) {
      case MealType.breakfast: return AppTheme.breakfastColor;
      case MealType.lunch:     return AppTheme.lunchColor;
      case MealType.dinner:    return AppTheme.dinnerColor;
      case MealType.snack:     return AppTheme.snackColor;
      case MealType.mesure:    return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Ligne principale
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: _color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: _color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.name,
                  style: AppFonts.title(size: 13)),
              if (entry.doseTime != null)
                Text(
                    'Dose : ${entry.doseTime!.hour.toString().padLeft(2, '0')}:'
                        '${entry.doseTime!.minute.toString().padLeft(2, '0')}',
                    style: AppFonts.body(
                        color: Colors.grey.shade500, size: 11)),
            ],
          )),
          if (entry.glycemieAffichee != null)
            _Pill('${entry.glycemieAffichee} Mg/dl', _color),
          const SizedBox(width: 6),
          if (entry.hasDose)
            _Pill('${entry.dose} UI', AppTheme.primary),
        ]),
        // Observation (si présente)
        if (entry.observation != null && entry.observation!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 48, top: 4),
            child: Row(children: [
              Icon(Icons.notes_rounded,
                  size: 13, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Expanded(child: Text(entry.observation!,
                  style: AppFonts.body(
                      color: Colors.grey.shade500, size: 12))),
            ]),
          ),
      ]),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  final String text;
  final Color color;
  const _Pill(this.text, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25))),
      child: Text(text, style: AppFonts.label(color: color, size: 11)
          .copyWith(fontWeight: FontWeight.w600)),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatPill({required this.label, required this.value,
    required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(label, style: AppFonts.label(size: 10)),
      RichText(text: TextSpan(children: [
        TextSpan(text: value,
            style: AppFonts.bold(color: color, size: 15)),
        TextSpan(text: ' $unit',
            style: AppFonts.label(
                color: color.withOpacity(0.6), size: 10)),
      ])),
    ]);
  }
}