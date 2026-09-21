import 'package:flutter/material.dart';
import '../../controllers/app_scope.dart';
import '../favourites_screen.dart';
import '../privacy_policy_screen.dart';
import '../contact_us_screen.dart';
import 'target_tab.dart';
import 'orders_tab.dart';
import '../points_screen.dart';
import '../notifications_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          child: ListTile(
            title: Text(state.userMobile ?? 'Sales user'),
            subtitle: null,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileTile(
          icon: Icons.stars_rounded,
          title: 'My Points (نقاطي)',
          color: Colors.amber.shade800,
          onTap: () => Navigator.of(
            context,
            rootNavigator: true,
          ).push(MaterialPageRoute(builder: (_) => const PointsScreen())),
        ),
        _ProfileTile(
          icon: Icons.track_changes,
          title: 'My Target',
          color: Colors.orange,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('My Target')),
                body: const TargetTab(),
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.receipt_long,
          title: 'My Orders',
          color: Colors.green,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('My Orders')),
                body: const OrdersTab(),
              ),
            ),
          ),
        ),
        _ProfileTile(
          icon: Icons.notifications_outlined,
          title: 'الإشعارات',
          color: Colors.teal,
          trailing: Badge.count(
            count: state.unreadNotificationsCount,
            isLabelVisible: state.unreadNotificationsCount > 0,
            child: const Icon(Icons.chevron_right, size: 20),
          ),
          onTap: () => Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => const NotificationsScreen()),
          ),
        ),
        _ProfileTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          color: Colors.blue,
          onTap: () => _showChangePasswordDialog(context),
        ),
        _ProfileTile(
          icon: Icons.favorite,
          title: 'My Favourites',
          color: Colors.red,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const FavouritesScreen())),
        ),
        const Divider(height: 32),
        _ProfileTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy & Policy',
          color: Colors.blueGrey,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
        ),
        _ProfileTile(
          icon: Icons.contact_support_outlined,
          title: 'Contact Us',
          color: Colors.teal,
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const ContactUsScreen())),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: state.isLoading ? null : state.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Logout'),
        ),
      ],
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final state = AppScope.of(context);
        return AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                    ),
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                    ),
                    validator: (v) => v!.length < 8 ? 'Min 8 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                    ),
                    validator: (v) => v != newPasswordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await state.changePassword(
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                    confirmPassword: confirmPasswordController.text,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error ?? 'Password updated'),
                      ),
                    );
                    if (state.error == null || !state.error!.contains('غلط')) {
                      Navigator.pop(context);
                    }
                  }
                }
              },
              child: const Text('UPDATE'),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }
}
