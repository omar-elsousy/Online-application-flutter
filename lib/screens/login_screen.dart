import 'package:flutter/material.dart';

import '../controllers/app_scope.dart';
import '../widgets/app_error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      height: 96,
                      width: 96,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.storefront,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Mansour',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Everything your sales team needs in one calm mobile app.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  if (state.error != null) ...[
                    AppErrorBanner(message: state.error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _mobileController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Mobile number is required'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Password is required'
                        : null,
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: state.isLoading ? null : _openRegisterDialog,
                    child: const Text('Create account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final mobile = _mobileController.text.trim();
    final password = _passwordController.text;
    final state = AppScope.of(context);
    final customers = await state.findLoginCustomers(
      mobile: mobile,
      password: password,
    );
    if (!mounted || customers.isEmpty) return;

    final selectedPosCode = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Choose customer'),
        content: SizedBox(
          width: 380,
          height: (customers.length * 72.0).clamp(72.0, 360.0).toDouble(),
          child: ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final code = customer['pos_code']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.store_outlined),
                title: Text(customer['name']?.toString() ?? 'Customer'),
                subtitle: Text('Customer code: $code'),
                onTap: () => Navigator.pop(dialogContext, code),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (!mounted || selectedPosCode == null) return;
    await state.login(
      mobile: mobile,
      password: password,
      posCode: selectedPosCode,
    );
  }

  Future<void> _openRegisterDialog() async {
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    var isRegistering = false;
    String? registerError;
    ModalRoute<void>? registerDialogRoute;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            registerDialogRoute ??= ModalRoute.of(context);

            Future<void> createAccount() async {
              final mobile = mobileController.text.trim();
              final password = passwordController.text;
              if (mobile.isEmpty) {
                setDialogState(() => registerError = 'Enter a mobile number.');
                return;
              }
              if (password.length < 6) {
                setDialogState(
                  () =>
                      registerError = 'Password must be at least 6 characters.',
                );
                return;
              }
              if (password != confirmationController.text) {
                setDialogState(
                  () => registerError = 'Password confirmation does not match.',
                );
                return;
              }

              setDialogState(() {
                isRegistering = true;
                registerError = null;
              });
              final state = AppScope.of(context);
              final registered = await state.register(
                mobile: mobile,
                password: password,
                passwordConfirmation: confirmationController.text,
              );
              if (!context.mounted) return;
              setDialogState(() {
                isRegistering = false;
                if (!registered) {
                  registerError =
                      state.error ?? 'Could not create the account.';
                }
              });

              if (registered) {
                Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text('Account created. You can login now.'),
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: const Text('Create account'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                  minWidth: 280,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Mobile'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: confirmationController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password confirmation',
                        ),
                      ),
                      if (registerError != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          registerError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isRegistering
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isRegistering ? null : createAccount,
                  child: isRegistering
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Create'),
                ),
              ],
            );
          },
        ),
      );
      final route = registerDialogRoute;
      if (route != null) await route.completed;
    } finally {
      mobileController.dispose();
      passwordController.dispose();
      confirmationController.dispose();
    }
  }
}
