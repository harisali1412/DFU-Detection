import 'package:flutter/material.dart';

class RecommendationScreen extends StatelessWidget {
  final String recommendation;

  const RecommendationScreen({super.key, required this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prediction and Recommendation'),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Diagnosis Result:',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              Text(recommendation,
                style: const TextStyle(fontSize: 16, color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
