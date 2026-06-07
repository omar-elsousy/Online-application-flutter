import 'package:flutter/material.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(
            child: Icon(Icons.support_agent, size: 80, color: Colors.blue),
          ),
          const SizedBox(height: 24),
          const Text(
            'Get in Touch',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We are here to help you. Reach out via any of the channels below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          _ContactTile(
            icon: Icons.phone,
            title: 'Customer Service',
            subtitle: '01202195999',
            color: Colors.green,
          ),
          _ContactTile(
            icon: Icons.headset_mic,
            title: 'Hotline',
            subtitle: '16030',
            color: Colors.orange,
          ),
          _ContactTile(
            icon: Icons.email,
            title: 'Email',
            subtitle: 'info@mansour.com',
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 16)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // You could add launchUrl functionality here if needed
        },
      ),
    );
  }
}
