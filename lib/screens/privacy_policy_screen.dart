import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Text(
            'Privacy Policy',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text(
            'At Mansour Manufacturing & Distribution Group, we value your privacy. This policy outlines how we handle your data.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            '1. Information Collection: We collect information that you provide directly to us when you create an account or place an order.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            '2. Data Usage: Your data is used to process transactions, improve our services, and communicate with you.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            '3. Security: We implement variety of security measures to maintain the safety of your personal information.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 12),
          Text(
            '4. Third Parties: We do not sell, trade, or otherwise transfer your personally identifiable information to outside parties.',
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          SizedBox(height: 24),
          Text(
            'By using our application, you consent to our privacy policy.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
