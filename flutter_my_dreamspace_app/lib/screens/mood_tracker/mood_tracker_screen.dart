import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/services.dart';
import '../../models/dream.dart';
import '../../services/supabase_service.dart';
import '../../utils/app_config.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen>
    with SingleTickerProviderStateMixin {
  List<Dream> _dreams = [];
  bool _isLoading = false;
  String? _errorMessage;
  late TabController _tabController;
  String _selectedPeriod = 'Week';

  // Modern color palette for moods
  final Map<DreamMood, Color> _moodColors = {
    DreamMood.happy: const Color(0xFF4CAF50), // Modern Green
    DreamMood.sad: const Color(0xFF2196F3), // Modern Blue
    DreamMood.neutral: const Color(0xFF9E9E9E), // Modern Grey
    DreamMood.excited: const Color(0xFFFF9800), // Modern Orange
    DreamMood.anxious: const Color(0xFF9C27B0), // Modern Purple
    DreamMood.peaceful: const Color(0xFF009688), // Modern Teal
    DreamMood.confused: const Color(0xFFFFC107), // Modern Amber
    DreamMood.scared: const Color(0xFFF44336), // Modern Red
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDreams() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final dreams = await SupabaseService().getDreams();
      setState(() {
        _dreams = dreams;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Map<DreamMood, int> _getFilteredDreams() {
  //   final distribution = <DreamMood, int>{};
  //   for (final dream in _dreams) {
  //     distribution[dream.mood] = (distribution[dream.mood] ?? 0) + 1;
  //   }
  //   return distribution;
  // }

  List<Dream> _getFilteredDreams() {
    final now = DateTime.now();
    final startDate =
        _selectedPeriod == 'Week'
            ? now.subtract(const Duration(days: 7))
            : now.subtract(const Duration(days: 30));

    return _dreams.where((dream) {
      return dream.createdAt.isAfter(startDate) &&
          dream.createdAt.isBefore(now.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracker'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDreams),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Distribution'), Tab(text: 'Trends')],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadDreams,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(size.width * 0.04),
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Week', label: Text('Week')),
                          ButtonSegment(value: 'Month', label: Text('Month')),
                        ],
                        selected: {_selectedPeriod},
                        onSelectionChanged: (Set<String> newSelection) {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _selectedPeriod = newSelection.first;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(size.width * 0.04),
                              child: _buildPieChart(_getFilteredDreams()),
                            ),
                          ),
                          SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(size.width * 0.04),
                              child: _buildBarChart(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildPieChart(List<Dream> dreams) {
    if (dreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No dreams logged yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Log your dreams to see mood distribution',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final moodCounts = <DreamMood, int>{};
    for (final dream in dreams) {
      moodCounts[dream.mood] = (moodCounts[dream.mood] ?? 0) + 1;
    }

    final size = MediaQuery.of(context).size;
    final chartSize = size.width * 0.8;
    final radius = chartSize * 0.4;

    final sections =
        moodCounts.entries.map((entry) {
          final percentage = (entry.value / dreams.length * 100)
              .toStringAsFixed(1);
          return PieChartSectionData(
            value: entry.value.toDouble(),
            title: '$percentage%',
            titleStyle: TextStyle(
              fontSize: radius * 0.15,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            color: _getMoodColor(entry.key),
            radius: radius,
            titlePositionPercentageOffset: 0.5,
          );
        }).toList();

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mood Distribution',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          SizedBox(
            height: chartSize,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: radius * 0.4,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                    borderData: FlBorderData(show: false),
                    centerSpaceColor: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total Dreams',
                      style: TextStyle(
                        fontSize: size.width * 0.035,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: size.height * 0.005),
                    Text(
                      dreams.length.toString(),
                      style: TextStyle(
                        fontSize: size.width * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: size.height * 0.07),
          Wrap(
            spacing: size.width * 0.03,
            runSpacing: size.height * 0.01,
            alignment: WrapAlignment.center,
            children:
                moodCounts.entries.map((entry) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.03,
                      vertical: size.height * 0.008,
                    ),
                    decoration: BoxDecoration(
                      color: _getMoodColor(entry.key).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getMoodColor(entry.key).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getMoodEmoji(entry.key),
                          style: TextStyle(fontSize: size.width * 0.04),
                        ),
                        SizedBox(width: size.width * 0.02),
                        Flexible(
                          child: Text(
                            '${entry.key.toString().split('.').last}: ${entry.value}',
                            style: TextStyle(
                              fontSize: size.width * 0.035,
                              color: _getMoodColor(entry.key),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final filteredDreams = _getFilteredDreams();
    if (filteredDreams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No dreams in the selected period',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Log some dreams to see the mood trends',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final moodCounts = List.filled(DreamMood.values.length, 0);
    for (final dream in filteredDreams) {
      moodCounts[DreamMood.values.indexOf(dream.mood)]++;
    }

    final maxCount = moodCounts.reduce((a, b) => a > b ? a : b);
    final yAxisInterval =
        maxCount <= 3 ? 1.0 : (maxCount / 3).ceil().toDouble();
    final size = MediaQuery.of(context).size;
    final barWidth = (size.width - 80) / DreamMood.values.length;
    final emojiSize = barWidth * 0.6;

    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Mood Trends',
            style: TextStyle(
              fontSize: size.width * 0.05,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.height * 0.02),
          SizedBox(
            height: size.height * 0.4,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount + yAxisInterval,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey.withOpacity(0.9),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final mood = DreamMood.values[groupIndex];
                      return BarTooltipItem(
                        '${_getMoodEmoji(mood)} ${mood.toString().split('.').last}\n${rod.toY.toInt()} dreams',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: emojiSize * 2,
                      getTitlesWidget: (value, meta) {
                        final mood = DreamMood.values[value.toInt()];
                        return Padding(
                          padding: EdgeInsets.only(top: size.height * 0.01),
                          child: Text(
                            _getMoodEmoji(mood),
                            style: TextStyle(fontSize: emojiSize),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: size.width * 0.1,
                      interval: yAxisInterval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yAxisInterval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!),
                    left: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                barGroups: List.generate(
                  DreamMood.values.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: moodCounts[index].toDouble(),
                        color:
                            _moodColors[DreamMood.values[index]] ?? Colors.grey,
                        width: barWidth * 0.8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxCount + yAxisInterval,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodEmoji(DreamMood mood) {
    switch (mood) {
      case DreamMood.happy:
        return '😊';
      case DreamMood.sad:
        return '😢';
      case DreamMood.neutral:
        return '😐';
      case DreamMood.excited:
        return '🤩';
      case DreamMood.anxious:
        return '😰';
      case DreamMood.peaceful:
        return '😌';
      case DreamMood.confused:
        return '😕';
      case DreamMood.scared:
        return '😱';
    }
  }

  Color _getMoodColor(DreamMood mood) {
    return _moodColors[mood] ?? Colors.grey;
  }
}
