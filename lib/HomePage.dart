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
      insights.add('⚠️ พบว่าไข่ขนาดเล็กมีจำนวนมาก ควรปรับปรุงการเลี้ยงหรือโภชนาการ');
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

    return SingleChildScrollView( // ⭐ แก้ overflow
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

  const EggTrendLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final values = data.map((e) => (e['total'] as num).toDouble()).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: values.reduce((a, b) => a < b ? a : b) - 10,
        maxY: values.reduce((a, b) => a > b ? a : b) + 10,
        titlesData: FlTitlesData(show: false),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), values[i]),
            ),
            isCurved: true,
            barWidth: 4,
            color: Colors.orange,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}

class TodayEggPieChart extends StatelessWidget {
  final int big;
  final int medium;
  final int small;

  const TodayEggPieChart({
    super.key,
    required this.big,
    required this.medium,
    required this.small,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: big.toDouble(),
            color: Colors.orange,
            title: 'ใหญ่\n$big',
            radius: 50,
          ),
          PieChartSectionData(
            value: medium.toDouble(),
            color: Colors.amber,
            title: 'กลาง\n$medium',
            radius: 50,
          ),
          PieChartSectionData(
            value: small.toDouble(),
            color: Colors.yellow,
            title: 'เล็ก\n$small',
            radius: 50,
          ),
        ],
      ),
    );
  }
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
                    chart: TodayEggPieChart(
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
                  duration: const Duration(milliseconds: 200),
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
            height: 180,
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
