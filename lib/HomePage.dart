import 'package:flutter/material.dart';
import '/custom_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
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
              _resultCard(
                title: 'ผลการวิเคราะห์จำนวนไข่ตามเบอร์',
                subtitle: 'จำนวนไข่ตามเบอร์ (ประจำวัน)',
              ),

            const SizedBox(height: 16),

            // 📉 CARD 2
            if (selectedFilter == 'ทั้งหมด' ||
                selectedFilter == 'แนวโน้มผลผลิต')
              _resultCard(
                title: 'ผลการวิเคราะห์แนวโน้ม',
                subtitle: 'แนวโน้มผลผลิตไข่',
              ),

            const SizedBox(height: 16),

            // 📉 CARD 3
            if (selectedFilter == 'ทั้งหมด' || selectedFilter == 'รายงานสรุปผล')
              _resultCard(
                title: 'รายงานสรุปผล',
                subtitle: 'สรุปผลการวิเคราะห์',
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
  Widget _resultCard({required String title, required String subtitle}) {
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
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // 📊 Placeholder chart
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Chart / Graph',
              style: TextStyle(color: Colors.black54),
            ),
          ),

          const SizedBox(height: 12),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}