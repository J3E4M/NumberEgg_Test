import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '/custom_bottom_nav.dart';
import '../database/egg_database.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class SummaryReportCard extends StatelessWidget {
  final int totalEgg;
  final double avgSuccess;
  final int big;
  final int medium;
  final int small;

  const SummaryReportCard({
    super.key,
    required this.totalEgg,
    required this.avgSuccess,
    required this.big,
    required this.medium,
    required this.small,
  });

  List<String> _buildAutoInsight() {
    final List<String> insights = [];

    if (big > medium && big > small) {
      insights.add('📈 พบไข่เบอร์ใหญ่มีสัดส่วนสูง แสดงว่าผลผลิตอยู่ในเกณฑ์ดี');
    }

    if (medium >= big && medium >= small) {
      insights.add('🟡 พบไข่ขนาดกลางเป็นสัดส่วนมากที่สุด');
    }

    if (small > big) {
      insights.add(
          '⚠️ พบว่าไข่ขนาดเล็กมีจำนวนมาก ควรปรับปรุงการเลี้ยงหรือโภชนาการ');
    }

    if (avgSuccess < 70) {
      insights.add('⚠️ อัตราความสำเร็จยังไม่สูง ควรปรับกระบวนการคัดแยก');
    } else {
      insights.add('✅ อัตราความสำเร็จอยู่ในระดับที่ดี');
    }

    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildAutoInsight();

    return SingleChildScrollView(
      // ⭐ แก้ overflow
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔢 SUMMARY
          Center(
            child: Column(
              children: [
                const Text('ไข่ทั้งหมด', style: TextStyle(color: Colors.grey)),
                Text(
                  '$totalEgg ฟอง',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'อัตราความสำเร็จเฉลี่ย ${avgSuccess.toStringAsFixed(1)}%',
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(),

          // 🥚 BREAKDOWN
          const Text(
            'สัดส่วนขนาดไข่',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          _buildRow('ใหญ่ (เบอร์ 0)', big, Colors.orange),
          _buildRow('กลาง (เบอร์ 1)', medium, Colors.amber),
          _buildRow('เล็ก (เบอร์ 2)', small, Colors.yellow),

          const SizedBox(height: 16),
          const Divider(),

          // 🧠 INSIGHT
          const Text(
            'สรุปผลการวิเคราะห์ (beta)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          ...insights.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(e),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text('$value ฟอง'),
        ],
      ),
    );
  }
}

class EggTrendLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;

  const EggTrendLineChart({
    super.key,
    required this.data,
  });

  // ---------- UTIL ----------
  double _calculateGrowthPercent(List<double> values) {
    if (values.length < 2 || values.first == 0) return 0;
    return ((values.last - values.first) / values.first) * 100;
  }

  Color _trendColor(double percent) {
    if (percent >= 10) return Colors.green;
    if (percent >= 0) return Colors.orange;
    return Colors.red;
  }

  IconData _trendIcon(double percent) {
    if (percent >= 10) return Icons.trending_up;
    if (percent >= 0) return Icons.trending_flat;
    return Icons.trending_down;
  }

  String _trendLabel(double percent) {
    if (percent >= 10) return 'GOOD';
    if (percent >= 0) return 'WARNING';
    return 'ALERT';
  }

  String _formatDay(String rawDay) {
    final d = DateTime.parse(rawDay);
    return '${d.day}/${d.month}';
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูล'));
    }

    final values =
        data.map((e) => (e['total'] as num).toDouble()).toList();

    final growthPercent = _calculateGrowthPercent(values);
    final color = _trendColor(growthPercent);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------- HEADER (ย้าย GOOD ลงล่าง) ----------
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(_trendIcon(growthPercent),
                      size: 14, color: color),
                  const SizedBox(width: 4),
                  Text(
                    _trendLabel(growthPercent),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '${growthPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // ---------- LINE CHART ----------
        SizedBox(
          height: 145, // ⭐ ลดขนาดกราฟ
          child: LineChart(
            LineChartData(
              clipData: FlClipData.none(),
              minX: 0,
              maxX: values.length - 1,

              minY: values.reduce((a, b) => a < b ? a : b) - 2,
              maxY: values.reduce((a, b) => a > b ? a : b) + 2,

              borderData: FlBorderData(show: false),

              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 5,
              ),

              // ---------- X AXIS (DATE) ----------
              titlesData: FlTitlesData(
                topTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 22,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _formatDay(data[index]['day']),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // ---------- TOOLTIP ----------
              lineTouchData: LineTouchData(
                handleBuiltInTouches: true,
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.black87,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      final index = spot.x.toInt();
                      final day = _formatDay(data[index]['day']);
                      final total = data[index]['total'];

                      return LineTooltipItem(
                        '$day\n$total ฟอง',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),

              // ---------- LINE ----------
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    values.length,
                    (i) => FlSpot(i.toDouble(), values[i]),
                  ),
                  isCurved: true,
                  barWidth: 3,
                  color: color,

                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, __, ___, ____) =>
                        FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeWidth: 2,
                      strokeColor: color,
                    ),
                  ),

                  belowBarData: BarAreaData(
                    show: true,
                    color: color.withOpacity(0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}


class TodayEggDonutChart extends StatelessWidget {
  final int big;
  final int medium;
  final int small;

  const TodayEggDonutChart({
    super.key,
    required this.big,
    required this.medium,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    final total = big + medium + small;

    final items = [
      _EggItem('ใหญ่', big, const Color(0xFFFF9800)),
      _EggItem('กลาง', medium, const Color(0xFFFFC107)),
      _EggItem('เล็ก', small, const Color(0xFFFFF176)),
    ];

    final maxItem = items.reduce((a, b) => a.count >= b.count ? a : b);

    PieChartSectionData section(_EggItem e, bool highlight) {
      return PieChartSectionData(
        value: e.count.toDouble(),
        color: e.color,
        radius: highlight ? 48 : 42,
        title: e.count == 0 ? '' : '${e.label}\n${e.count}',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.2,
        ),
        titlePositionPercentageOffset: 0.6,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ---------- LEFT (DONUT) ----------
          Expanded(
            flex: 5,
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        centerSpaceRadius: 46,
                        sectionsSpace: 3,
                        sections:
                            items.map((e) => section(e, e == maxItem)).toList(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'วันนี้',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'ฟอง',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- SPACE ----------
          const SizedBox(width: 12),

          // ---------- RIGHT (INFO) ----------
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'สรุปผลวันนี้',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 10),
                ...items.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _infoRow(
                      'ไข่${e.label}',
                      '${e.count} ฟอง',
                      e.color,
                      bold: e == maxItem,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value,
    Color color, {
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _EggItem {
  final String label;
  final int count;
  final Color color;

  _EggItem(this.label, this.count, this.color);
}

class _HomePageState extends State<HomePage> {
  String selectedFilter = 'ทั้งหมด';

  final List<String> filters = [
    'ทั้งหมด',
    'ไข่วันนี้',
    'แนวโน้มผลผลิต',
    'รายงานสรุปผล',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8C6),

      // 🔝 AppBar (Logo)
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Image.asset(
          'assets/images/number_egg_logo.png',
          height: 50,
        ),
      ),

      // 📊 BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ FILTER (ทั้งหมด / ไข่วันนี้ / แนวโน้ม / รายงาน)
            _buildAnalysisFilter(),

            const SizedBox(height: 20),

            // 📈 CARD 1
            if (selectedFilter == 'ทั้งหมด' || selectedFilter == 'ไข่วันนี้')
              FutureBuilder<Map<String, int>>(
                future: EggDatabase.instance.getTodayEggSummary(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _resultCard(
                      title: 'ผลการวิเคราะห์จำนวนไข่ตามเบอร์',
                      subtitle: 'จำนวนไข่ตามเบอร์ (ประจำวัน)',
                    );
                  }

                  final data = snapshot.data!;
                  return _resultCard(
                    title: 'ผลการวิเคราะห์จำนวนไข่ตามเบอร์',
                    subtitle: 'จำนวนไข่ตามเบอร์ (ประจำวัน)',
                    chart: TodayEggDonutChart(
                      big: data['big'] ?? 0,
                      medium: data['medium'] ?? 0,
                      small: data['small'] ?? 0,
                    ),
                  );
                },
              ),

            const SizedBox(height: 16),

            // 📉 CARD 2
            if (selectedFilter == 'ทั้งหมด' ||
                selectedFilter == 'แนวโน้มผลผลิต')
              FutureBuilder<List<Map<String, dynamic>>>(
                future: EggDatabase.instance.getWeeklyTrend(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _resultCard(
                      title: 'ผลการวิเคราะห์แนวโน้ม',
                      subtitle: 'แนวโน้มผลผลิตไข่',
                    );
                  }

                  return _resultCard(
                    title: 'ผลการวิเคราะห์แนวโน้ม',
                    subtitle: 'แนวโน้มผลผลิตไข่',
                    chart: EggTrendLineChart(data: snapshot.data!),
                  );
                },
              ),

            const SizedBox(height: 16),

            // 📉 CARD 3
            if (selectedFilter == 'ทั้งหมด' || selectedFilter == 'รายงานสรุปผล')
              FutureBuilder<Map<String, dynamic>>(
                future: EggDatabase.instance.getSummaryReport(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return _resultCard(
                      title: 'รายงานสรุปผล',
                      subtitle: 'สรุปผลการวิเคราะห์',
                    );
                  }

                  final data = snapshot.data!;
                  return _resultCard(
                    title: 'รายงานสรุปผล',
                    subtitle: 'สรุปผลการวิเคราะห์',
                    chart: SummaryReportCard(
                      totalEgg: (data['totalEgg'] ?? 0).toInt(),
                      avgSuccess: (data['avgSuccess'] ?? 0).toDouble(),
                      big: (data['big'] ?? 0).toInt(),
                      medium: (data['medium'] ?? 0).toInt(),
                      small: (data['small'] ?? 0).toInt(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),

      // 📸 Floating Camera Button
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.camera_alt, color: Colors.black),
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
      ),

      // ⬇️ Bottom Navigation
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }

  Widget _buildAnalysisFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ผลการวิเคราะห์',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final item = filters[index];
              final isSelected = selectedFilter == item;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedFilter = item;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF212121)
                        : const Color(0xFFE0E0E0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black38,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---------- RESULT CARD ----------
  Widget _resultCard({
    required String title,
    required String subtitle,
    Widget? chart,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: chart ?? const Center(child: Text('Chart / Graph')),
          ),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
