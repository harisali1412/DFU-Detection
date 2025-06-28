import 'package:dfu/globals.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:typed_data';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  Uint8List? _imageData;
  bool _isLoading = false;
  String? _diagnosisResult;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final imageData = await pickedFile.readAsBytes();
      setState(() {
        _imageData = imageData;
        _diagnosisResult = null; // Reset diagnosis when new image is selected
      });
    }
  }

  Future<void> handleImageUpload() async {
    if (_imageData != null) {
      setState(() {
        _isLoading = true;
      });

      var prediction = await uploadImageAndGetUrl(_imageData!);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _diagnosisResult = prediction; // Set diagnosis result
        });
      }
    }
  }

  Future<String> uploadImageAndGetUrl(Uint8List imageBytes) async {
    var uri = Uri.parse('$API_URL/upload-image');
    var request = http.MultipartRequest('POST', uri);

    request.files.add(http.MultipartFile.fromBytes(
      'image',
      imageBytes,
      filename: 'upload.jpg',
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 201) {
        var responseString = await streamedResponse.stream.bytesToString();
        var jsonResponse = jsonDecode(responseString);
        return "${jsonResponse['label']} - ${jsonResponse['recommendation']}";
      } else {
        var error = await streamedResponse.stream.bytesToString();
        return 'Failed to upload image: $error';
      }
    } catch (e) {
      return 'Error connecting to server: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diabetic Foot Ulcer Diagnosis'),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Upload an image of your foot for diagnosis",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal)),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Pick Image from Gallery', style: TextStyle(color: Colors.white)),
              ),
              const SizedBox(height: 20),

              if (_imageData != null)
                Column(
                  children: [
                    Image.memory(
                      _imageData!,
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : handleImageUpload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            SizedBox(width: 10),
                            Text('Analyzing...'),
                        ],
                      )
                          : const Text('Analyze Image', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              if (_imageData == null)
                const Text("No image selected.",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),

              const SizedBox(height: 30),

              // Display Diagnosis Result
              if (_diagnosisResult != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diagnosis Result:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _diagnosisResult!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
