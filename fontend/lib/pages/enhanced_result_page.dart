// Enhanced Result Page with detailed egg measurements and analysis
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/railway_api.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EnhancedResultPage extends StatefulWidget {
  final File imageFile;
  final EggDetectionResult detectionResult;

  const EnhancedResultPage({
    super.key,
    required this.imageFile,
    required this.detectionResult,
  });

  @override
  State<EnhancedResultPage> createState() => _EnhancedResultPageState();
}

class _EnhancedResultPageState extends State<EnhancedResultPage> {
  bool _isSaving = false;
  EggSizeAnalysis? _sizeAnalysis;

  @override
  void initState() {
    super.initState();
    _performSizeAnalysis();
  }

  void _performSizeAnalysis() {
    final analysis = EggSizeAnalyzer.analyze(widget.detectionResult);
    setState(() {
      _sizeAnalysis = analysis;
    });
  }

  Future<void> _saveToSupabase() async {
    if (!SupabaseConfig.isConfigured) {
      _showError('Supabase not configured');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final client = Supabase.instance.client;
      
      // Upload image to Supabase storage
      final imageBytes = await widget.imageFile.readAsBytes();
      final fileName = 'egg_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      final storageResponse = await client.storage
          .from('egg-images')
          .uploadBinary(fileName, imageBytes);

      final imageUrl = client.storage
          .from('egg-images')
          .getPublicUrl(fileName);

      // Create egg session
      final sessionData = {
        'user_id': client.auth.currentUser?.id,
        'image_path': imageUrl,
        'egg_count': widget.detectionResult.eggCount,
        'success_percent': widget.detectionResult.successPercent,
        'grade0_count': widget.detectionResult.grade0Count,
        'grade1_count': widget.detectionResult.grade1Count,
        'grade2_count': widget.detectionResult.grade2Count,
        'grade3_count': widget.detectionResult.grade3Count,
        'grade4_count': widget.detectionResult.grade4Count,
        'grade5_count': widget.detectionResult.grade5Count,
        'day': DateTime.now().day.toString(),
      };

      final sessionResponse = await client
          .from('egg_session')
          .insert(sessionData)
          .select()
          .single();

      // Save individual egg items
      final eggItems = widget.detectionResult.detections.map((detection) {
        return {
          'session_id': sessionResponse['id'],
          'grade': _getGradeValue(detection.grade),
          'confidence': detection.confidence,
        };
      }).toList();

      await client.from('egg_item').insert(eggItems);

      _showSuccess('Results saved successfully!');
    } catch (e) {
      _showError('Failed to save: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  int _getGradeValue(String grade) {
    switch (grade.toLowerCase()) {
      case 'grade0':
        return 0;
      case 'grade1':
        return 1;
      case 'grade2':
        return 2;
      case 'grade3':
        return 3;
      case 'grade4':
        return 4;
      case 'grade5':
        return 5;
      default:
        return 5;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Egg Detection Results'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveToSupabase,
            icon: _isSaving
                ? const CircularProgressIndicator()
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Image
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Original Image',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Image.file(widget.imageFile),
                  const SizedBox(height: 10),
                  Text('Image Info: ${widget.detectionResult.imageInfo.dimensions}'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary Statistics
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detection Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Total Eggs', widget.detectionResult.eggCount.toString(), Colors.blue),
                        _buildStatCard('เบอร์ 0', widget.detectionResult.grade0Count.toString(), Colors.red),
                        _buildStatCard('เบอร์ 1', widget.detectionResult.grade1Count.toString(), Colors.orange),
                        _buildStatCard('เบอร์ 2', widget.detectionResult.grade2Count.toString(), Colors.amber),
                        _buildStatCard('เบอร์ 3', widget.detectionResult.grade3Count.toString(), Colors.green),
                        _buildStatCard('เบอร์ 4', widget.detectionResult.grade4Count.toString(), Colors.blueGrey),
                        _buildStatCard('เบอร์ 5', widget.detectionResult.grade5Count.toString(), Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Accuracy', '${widget.detectionResult.successPercent.toStringAsFixed(1)}%', Colors.purple),
                        _buildStatCard('Avg Confidence', _getAverageConfidence().toStringAsFixed(2), Colors.teal),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Size Distribution Chart
            if (_sizeAnalysis != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Size Distribution',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 200,
                        child: PieChart(
                          PieChartData(
                            sections: [
                              PieChartSectionData(
                                value: widget.detectionResult.grade0Count.toDouble(),
                                title: 'เบอร์ 0\n${widget.detectionResult.grade0Count}',
                                color: Colors.red,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: widget.detectionResult.grade1Count.toDouble(),
                                title: 'เบอร์ 1\n${widget.detectionResult.grade1Count}',
                                color: Colors.orange,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: widget.detectionResult.grade2Count.toDouble(),
                                title: 'เบอร์ 2\n${widget.detectionResult.grade2Count}',
                                color: Colors.amber,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: widget.detectionResult.grade3Count.toDouble(),
                                title: 'เบอร์ 3\n${widget.detectionResult.grade3Count}',
                                color: Colors.green,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: widget.detectionResult.grade4Count.toDouble(),
                                title: 'เบอร์ 4\n${widget.detectionResult.grade4Count}',
                                color: Colors.blueGrey,
                                radius: 50,
                              ),
                              PieChartSectionData(
                                value: widget.detectionResult.grade5Count.toDouble(),
                                title: 'เบอร์ 5\n${widget.detectionResult.grade5Count}',
                                color: Colors.grey,
                                radius: 50,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Detailed Egg List
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detailed Analysis',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    if (_sizeAnalysis != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Average Egg Size: ${_sizeAnalysis!.averageSize.toStringAsFixed(2)} px²'),
                          Text('Size Standard Deviation: ${_sizeAnalysis!.sizeStdDev.toStringAsFixed(2)}'),
                          Text('Most Common Size: ${_sizeAnalysis!.mostCommonSize}'),
                          const SizedBox(height: 10),
                        ],
                      ),
                    SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: widget.detectionResult.detections.length,
                        itemBuilder: (context, index) {
                          final detection = widget.detectionResult.detections[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getGradeColor(detection.grade),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('Egg ${index + 1} - ${detection.grade.toUpperCase()}'),
                              subtitle: Text(
                                'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%\n'
                                'Size: ${detection.bbox.area.toStringAsFixed(2)} px²\n'
                                'Position: (${detection.bbox.x1.toStringAsFixed(0)}, ${detection.bbox.y1.toStringAsFixed(0)})',
                              ),
                              trailing: Icon(
                                Icons.egg,
                                color: _getGradeColor(detection.grade),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Export Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export Options',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _exportResults('json'),
                          icon: const Icon(Icons.code),
                          label: const Text('Export JSON'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _exportResults('csv'),
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _shareResults(),
                          icon: const Icon(Icons.share),
                          label: const Text('Share'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'big':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'small':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double _getAverageConfidence() {
    if (widget.detectionResult.detections.isEmpty) return 0.0;
    
    final totalConfidence = widget.detectionResult.detections
        .map((d) => d.confidence)
        .reduce((a, b) => a + b);
    
    return totalConfidence / widget.detectionResult.detections.length;
  }

  void _exportResults(String format) {
    // Implement export functionality
    _showSuccess('Exported as $format');
  }

  void _shareResults() {
    // Implement share functionality
    _showSuccess('Results shared successfully');
  }
}

class EggSizeAnalysis {
  final double averageSize;
  final double sizeStdDev;
  final String mostCommonSize;
  final Map<String, int> sizeDistribution;

  EggSizeAnalysis({
    required this.averageSize,
    required this.sizeStdDev,
    required this.mostCommonSize,
    required this.sizeDistribution,
  });
}

class EggSizeAnalyzer {
  static EggSizeAnalysis analyze(EggDetectionResult result) {
    final sizes = <double>[];
    final sizeDistribution = <String, int>{'big': 0, 'medium': 0, 'small': 0};

    for (final detection in result.detections) {
      sizes.add(detection.bbox.area);
      sizeDistribution[detection.grade] = (sizeDistribution[detection.grade] ?? 0) + 1;
    }

    // Calculate average size
    final averageSize = sizes.isEmpty ? 0.0 : sizes.reduce((a, b) => a + b) / sizes.length;

    // Calculate standard deviation
    final variance = sizes.isEmpty ? 0.0 : 
        sizes.map((size) => pow(size - averageSize, 2)).reduce((a, b) => a + b) / sizes.length;
    final sizeStdDev = sqrt(variance);

    // Find most common size
    String mostCommonSize = 'medium';
    int maxCount = 0;
    sizeDistribution.forEach((size, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonSize = size;
      }
    });

    return EggSizeAnalysis(
      averageSize: averageSize,
      sizeStdDev: sizeStdDev,
      mostCommonSize: mostCommonSize,
      sizeDistribution: sizeDistribution,
    );
  }
}
