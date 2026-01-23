import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';
import '../database/egg_database.dart';
import 'dart:io';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'ทั้งหมด';

  late Future<List<Map<String, dynamic>>> _historyFuture;

  final List<String> filters = [
    'ทั้งหมด',
    'วันที่ผ่านมา',
    'สัปดาห์ที่ผ่านมา',
  ];

  @override
  void initState() {
    super.initState();
    debugPrint("INIT HISTORY PAGE");
    _historyFuture = EggDatabase.instance.getHistoryForUI();
  }

  // ฟังก์ชันช่วยเลือกสีตามขนาดไข่
  Color _getEggColor(String tag) {
    if (tag.contains('ใหญ่')) return const Color(0xFFA52A2A);
    if (tag.contains('กลาง')) return const Color(0xFFFF8C00);
    if (tag.contains('เล็ก')) return const Color(0xFFFFC107);
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- HEADER ----------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'History',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.search, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // ---------- FILTER ----------
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = filters[index];
                  final isSelected = selectedFilter == item;
                  return GestureDetector(
                    onTap: () => setState(() => selectedFilter = item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFFF8E1)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFFFFC107), width: 1.5)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xFF6D4C41)
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ---------- CONTENT ----------
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text("เกิดข้อผิดพลาด: ${snapshot.error}"),
                    );
                  }

                  final rawData = snapshot.data ?? [];

                  if (rawData.isEmpty) {
                    return const Center(child: Text("ยังไม่มีประวัติ"));
                  }

                  // 🔁 Filter logic
                  List<Map<String, dynamic>> displayList = rawData;
                  if (selectedFilter == 'วันที่ผ่านมา') {
                    displayList = rawData
                        .where((e) => e['section'] == 'YESTERDAY')
                        .toList();
                  } else if (selectedFilter == 'สัปดาห์ที่ผ่านมา') {
                    displayList = rawData
                        .where((e) => e['section'] == 'LAST WEEK')
                        .toList();
                  }

                  // 🔁 Group by section
                  final Map<String, List<Map<String, dynamic>>> groupedData =
                      {};
                  for (var item in displayList) {
                    final section = item['section']?.toString() ?? 'UNKNOWN';

                    groupedData.putIfAbsent(section, () => []);
                    groupedData[section]!.add(item);
                  }
                  debugPrint("HISTORY RAW DATA:");
                  for (var e in rawData) {
                    debugPrint(e.toString());
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      ...groupedData.entries.map((entry) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTimelineHeader(entry.key),
                            ...entry.value.map(
                              (data) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHistoryCard(context, data),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.camera_alt, color: Colors.black),
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  // ---------- UI COMPONENTS ----------
  Widget _buildTimelineHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data) {
    final String date = data['date']?.toString() ?? '-';
    final int count = data['count'] ?? 0;
    final bool isSuccess = data['isSuccess'] ?? true;
    final List<String> tags = List<String>.from(data['tags'] ?? []);
    final String? imagePath = data['imagePath'];

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/result',
          arguments: data,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDD865),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // ---------- IMAGE ----------
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imagePath != null && File(imagePath).existsSync()
                    ? Image.file(File(imagePath), fit: BoxFit.cover)
                    : const Icon(Icons.image, color: Colors.grey),
              ),
            ),

            const SizedBox(width: 16),

            // ---------- INFO ----------
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // วันที่
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // จำนวนไข่
                  Text(
                    "$count ฟอง",
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // ---------- TAGS (เกรดไข่) ----------
                  Wrap(
                    spacing: 6,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ---------- STATUS + ARROW ----------
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuccess ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSuccess ? "สำเร็จ" : "ตรวจสอบ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
