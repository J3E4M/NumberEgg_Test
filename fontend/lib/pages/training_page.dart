// Training Page for custom egg detection model training
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/egg_training_service.dart';
import '../services/railway_api.dart';

class TrainingPage extends StatefulWidget {
  const TrainingPage({super.key});

  @override
  State<TrainingPage> createState() => _TrainingPageState();
}

class _TrainingPageState extends State<TrainingPage> {
  final List<File> _trainingImages = [];
  final List<Map<String, dynamic>> _annotations = [];
  final TextEditingController _modelNameController = TextEditingController();
  bool _isUploading = false;
  bool _isTraining = false;
  String? _trainingId;
  TrainingStatus? _trainingStatus;
  final List<TrainedModel> _availableModels = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    try {
      final models = await EggTrainingService.getAvailableModels();
      setState(() {
        _availableModels.clear();
        _availableModels.addAll(models);
      });
    } catch (e) {
      debugPrint('Error loading models: $e');
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (final pickedFile in pickedFiles) {
          _trainingImages.add(File(pickedFile.path));
          // Add empty annotation for each image
          _annotations.add({
            'image_path': pickedFile.path,
            'eggs': <Map<String, dynamic>>[],
          });
        }
      });
    }
  }

  Future<void> _pickImagesFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _trainingImages.add(File(pickedFile.path));
        _annotations.add({
          'image_path': pickedFile.path,
          'eggs': <Map<String, dynamic>>[],
        });
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _trainingImages.removeAt(index);
      _annotations.removeAt(index);
    });
  }

  void _addEggAnnotation(int imageIndex) {
    showDialog(
      context: context,
      builder: (context) => EggAnnotationDialog(
        onSave: (annotation) {
          setState(() {
            _annotations[imageIndex]['eggs'].add(annotation);
          });
        },
      ),
    );
  }

  Future<void> _startTraining() async {
    if (_modelNameController.text.isEmpty) {
      _showError('Please enter a model name');
      return;
    }

    if (_trainingImages.isEmpty) {
      _showError('Please add training images');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final result = await EggTrainingService.uploadTrainingData(
        images: _trainingImages,
        annotations: _annotations,
        modelName: _modelNameController.text,
      );

      if (result.success) {
        setState(() {
          _trainingId = result.trainingId;
          _isUploading = false;
          _isTraining = true;
        });

        _startTrainingProcess();
      } else {
        _showError(result.message);
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showError('Upload failed: $e');
    }
  }

  Future<void> _startTrainingProcess() async {
    if (_trainingId == null) return;

    try {
      final status = await EggTrainingService.startTraining(_trainingId!);
      setState(() {
        _trainingStatus = status;
      });
      _monitorTraining();
    } catch (e) {
      _showError('Failed to start training: $e');
    }
  }

  Future<void> _monitorTraining() async {
    if (_trainingId == null) return;

    while (_trainingStatus?.isRunning == true || _trainingStatus?.isPending == true) {
      await Future.delayed(const Duration(seconds: 5));
      
      try {
        final status = await EggTrainingService.checkTrainingStatus(_trainingId!);
        setState(() {
          _trainingStatus = status;
        });

        if (status.isCompleted) {
          _showSuccess('Training completed successfully!');
          _loadAvailableModels();
          break;
        } else if (status.isFailed) {
          _showError('Training failed: ${status.message}');
          break;
        }
      } catch (e) {
        debugPrint('Error checking training status: $e');
        break;
      }
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
        title: const Text('Egg Detection Training'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model Name Input
            TextField(
              controller: _modelNameController,
              decoration: const InputDecoration(
                labelText: 'Model Name',
                hintText: 'Enter a name for your custom model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Training Images Section
            const Text(
              'Training Images',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Images'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _pickImagesFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Images Grid
            if (_trainingImages.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _trainingImages.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 150,
                      margin: const EdgeInsets.only(right: 10),
                      child: Column(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Image.file(
                                  _trainingImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      color: Colors.red,
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Image ${index + 1}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          TextButton(
                            onPressed: () => _addEggAnnotation(index),
                            child: Text(
                              'Add Eggs (${_annotations[index]['eggs'].length})',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 20),

            // Training Status
            if (_isTraining && _trainingStatus != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Training Status: ${_trainingStatus!.status.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: _trainingStatus!.progress / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _trainingStatus!.isRunning ? Colors.blue : Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text('Progress: ${_trainingStatus!.progress.toStringAsFixed(1)}%'),
                      Text('Message: ${_trainingStatus!.message}'),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Available Models
            if (_availableModels.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Models',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._availableModels.map((model) => Card(
                    child: ListTile(
                      title: Text(model.name),
                      subtitle: Text(
                        'Accuracy: ${(model.accuracy * 100).toStringAsFixed(1)}%\n'
                        'Created: ${model.createdAt}',
                      ),
                      trailing: const Icon(Icons.download),
                      onTap: () {
                        // Implement model download/selection
                        _showSuccess('Model selected: ${model.name}');
                      },
                    ),
                  )),
                ],
              ),

            const SizedBox(height: 20),

            // Start Training Button
            if (!_isUploading && !_isTraining)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startTraining,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text(
                    'Start Training',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),

            // Loading Indicator
            if (_isUploading || _isTraining)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Processing...'),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EggAnnotationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const EggAnnotationDialog({super.key, required this.onSave});

  @override
  State<EggAnnotationDialog> createState() => _EggAnnotationDialogState();
}

class _EggAnnotationDialogState extends State<EggAnnotationDialog> {
  final TextEditingController _xController = TextEditingController();
  final TextEditingController _yController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _selectedGrade = 'medium';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Egg Annotation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _xController,
            decoration: const InputDecoration(labelText: 'X Position'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _yController,
            decoration: const InputDecoration(labelText: 'Y Position'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _widthController,
            decoration: const InputDecoration(labelText: 'Width'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _heightController,
            decoration: const InputDecoration(labelText: 'Height'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _selectedGrade,
            decoration: const InputDecoration(labelText: 'Egg Grade'),
            items: ['big', 'medium', 'small'].map((grade) {
              return DropdownMenuItem(
                value: grade,
                child: Text(grade.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedGrade = value!;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final annotation = {
              'x': double.tryParse(_xController.text) ?? 0,
              'y': double.tryParse(_yController.text) ?? 0,
              'width': double.tryParse(_widthController.text) ?? 0,
              'height': double.tryParse(_heightController.text) ?? 0,
              'grade': _selectedGrade,
            };
            widget.onSave(annotation);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
