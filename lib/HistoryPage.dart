import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String selectedFilter = 'ทั้งหมด';

  final List<String> filters = [
    'ทั้งหมด',
    'วันที่ผ่านมา',
    'สัปดาห์ที่ผ่านมา',
  ];

  // Mock Data: ข้อมูลตัวอย่าง
  final List<Map<String, dynamic>> allHistoryData = [
    {
      "section": "TODAY",
      "date": "14 ธันวาคม, 2568 - 14:48",
      "count": 2,
      "isSuccess": true,
      "tags": ["1xใหญ่", "1xกลาง"]
    },
    {
      "section": "TODAY",
      "date": "14 ธันวาคม, 2568 - 13:31",
      "count": 5,
      "isSuccess": true,
      "tags": ["2xใหญ่", "3xกลาง"]
    },
    {
      "section": "YESTERDAY",
      "date": "13 ธันวาคม, 2568 - 11:02",
      "count": 9,
      "isSuccess": false,
      "tags": ["8xใหญ่", "1xกลาง"]
    },
    {
      "section": "LAST WEEK",
      "date": "7 ธันวาคม, 2568 - 09:15",
      "count": 12,
      "isSuccess": true,
      "tags": ["10xใหญ่", "2xเล็ก"]
    },
  ];

  // ฟังก์ชันช่วยเลือกสีตามขนาดไข่ (ให้ตรงกับ ResultPage)
  Color _getEggColor(String tag) {
    if (tag.contains('ใหญ่')) return const Color(0xFFA52A2A); // น้ำตาลเข้ม
    if (tag.contains('กลาง')) return const Color(0xFFFF8C00); // ส้มเข้ม
    if (tag.contains('เล็ก')) return const Color(0xFFFFC107); // เหลือง
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    // Logic Filter
    List<Map<String, dynamic>> displayList;
    if (selectedFilter == 'ทั้งหมด') {
      displayList = allHistoryData;
    } else if (selectedFilter == 'วันที่ผ่านมา') {
      displayList = allHistoryData.where((item) => item['section'] == 'YESTERDAY').toList();
    } else if (selectedFilter == 'สัปดาห์ที่ผ่านมา') {
      displayList = allHistoryData.where((item) => item['section'] == 'LAST WEEK').toList();
    } else {
      
      displayList = [];
    }

    // Group Data
    Map<String, List<Map<String, dynamic>>> groupedData = {};
    for (var item in displayList) {
      if (!groupedData.containsKey(item['section'])) {
        groupedData[item['section']] = [];
      }
      groupedData[item['section']]!.add(item);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
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

            // --- Filter Pills ---
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF8E1) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(25),
                        border: isSelected
                            ? Border.all(color: const Color(0xFFFFC107), width: 1.5)
                            : Border.all(color: Colors.transparent),
                      ),
                      child: Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF6D4C41) : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // --- List Data ---
            Expanded(
              child: groupedData.isEmpty
                  ? const Center(child: Text("ไม่พบข้อมูล"))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        ...groupedData.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTimelineHeader(entry.key),
                              ...entry.value.map((data) => Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildHistoryCard(context, data),
                              )),
                              const SizedBox(height: 10),
                            ],
                          );
                        }),
                        const SizedBox(height: 80),
                      ],
                    ),
            ),
          ],
        ),
      ),

      // FAB
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFFFC107),
        child: const Icon(Icons.camera_alt, color: Colors.black),
        onPressed: () {
          Navigator.pushNamed(context, '/camera');
        },
      ),

      // Bottom Navigation
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }

  Widget _buildTimelineHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey.shade300)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(text,
                style: TextStyle(
                    color: Colors.grey.shade400,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          Expanded(child: Divider(color: Colors.grey.shade300)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> data) {
    bool isSuccess = data['isSuccess'];
    
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
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.15),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Date & Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Text(data['date'],
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8,
                          color: isSuccess ? const Color(0xFF4CAF50) : const Color(0xFFFF5722)),
                      const SizedBox(width: 6),
                      Text(isSuccess ? "สำเร็จ" : "ตรวจสอบ",
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 16),
            
            // Image & Count Row
            Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset('assets/images/egg.jpg',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text("${data['count']}",
                              style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white)),
                          const SizedBox(width: 6),
                          const Text("ฟอง",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Tags (Chips)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: (data['tags'] as List).map<Widget>((tag) {
                          Color tagColor = _getEggColor(tag);
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 8, color: tagColor),
                                const SizedBox(width: 6),
                                Text(
                                  tag,
                                  style: const TextStyle(
                                    color: Colors.black87, 
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      )
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}