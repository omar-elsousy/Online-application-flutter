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
  final _mobileController = TextEditingController(text: '01210007745');
  final _passwordController = TextEditingController(text: '12345678');

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
                  Container(
                    height: 96,
                    width: 96,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.25),
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
    await AppScope.of(context).login(
      mobile: _mobileController.text.trim(),
      password: _passwordController.text,
    );
  }

  Future<void> _openRegisterDialog() async {
    final mobileController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmationController = TextEditingController();
    var customers = <Map<String, dynamic>>[];
    String? selectedPosCode;
    String? checkedMobile;
    String? registerError;
    var isLookingUp = false;
    var isRegistering = false;
    ModalRoute<void>? registerDialogRoute;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            registerDialogRoute ??= ModalRoute.of(context);
            final canCreate =
                checkedMobile == mobileController.text.trim() &&
                selectedPosCode != null &&
                customers.any(
                  (customer) =>
                      customer['pos_code']?.toString() == selectedPosCode &&
                      customer['already_registered'] != true,
                ) &&
                !isLookingUp &&
                !isRegistering;

            Future<void> findCustomers() async {
              final mobile = mobileController.text.trim();
              if (mobile.isEmpty) {
                setDialogState(
                  () => registerError = 'Enter a mobile number first.',
                );
                return;
              }
              setDialogState(() {
                isLookingUp = true;
                registerError = null;
                checkedMobile = null;
                selectedPosCode = null;
                customers = [];
              });
              try {
                final result = await AppScope.of(
                  context,
                ).loadRegistrationCustomers(mobile);
                setDialogState(() {
                  customers = result;
                  checkedMobile = mobile;
                  final available = result
                      .where(
                        (customer) => customer['already_registered'] != true,
                      )
                      .toList();
                  if (available.length == 1) {
                    selectedPosCode = available.first['pos_code']?.toString();
                  }
                  if (result.isEmpty) {
                    registerError = 'No customers are linked to this number.';
                  }
                });
              } catch (error) {
                setDialogState(() => registerError = error.toString());
              } finally {
                setDialogState(() => isLookingUp = false);
              }
            }

            Future<void> createAccount() async {
              if (!canCreate || selectedPosCode == null) return;
              if (passwordController.text.length < 6) {
                setDialogState(
                  () =>
                      registerError = 'Password must be at least 6 characters.',
                );
                return;
              }
              if (passwordController.text != confirmationController.text) {
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
                mobile: mobileController.text.trim(),
                password: passwordController.text,
                passwordConfirmation: confirmationController.text,
                posCode: selectedPosCode!,
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: mobileController,
                        keyboardType: TextInputType.phone,
                        onChanged: (value) {
                          if (checkedMobile != null &&
                              checkedMobile != value.trim()) {
                            setDialogState(() {
                              checkedMobile = null;
                              selectedPosCode = null;
                              customers = [];
                              registerError = null;
                            });
                          }
                        },
                        decoration: const InputDecoration(labelText: 'Mobile'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: isLookingUp || isRegistering
                            ? null
                            : findCustomers,
                        icon: isLookingUp
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.search),
                        label: Text(
                          isLookingUp ? 'Searching...' : 'Find customers',
                        ),
                      ),
                      if (checkedMobile == mobileController.text.trim() &&
                          customers.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          customers.length > 1
                              ? 'Choose a customer. Customers already registered are disabled:'
                              : 'Customer linked to this number:',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        ...customers.map((customer) {
                          final code = customer['pos_code']?.toString() ?? '';
                          final alreadyRegistered =
                              customer['already_registered'] == true;
                          final isSelected = code == selectedPosCode;
                          return Opacity(
                            opacity: alreadyRegistered ? 0.48 : 1,
                            child: InkWell(
                              onTap: isRegistering || alreadyRegistered
                                  ? null
                                  : () => setDialogState(() {
                                      selectedPosCode = code;
                                      registerError = null;
                                    }),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      alreadyRegistered
                                          ? Icons.check_circle_outline
                                          : isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      color: alreadyRegistered
                                          ? Colors.grey
                                          : isSelected
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            customer['name']?.toString() ??
                                                'Customer',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            alreadyRegistered
                                                ? 'Already has an account · $code'
                                                : 'Customer code: $code',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                      if (checkedMobile == mobileController.text.trim() &&
                          selectedPosCode != null) ...[
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
                      ],
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
                  onPressed: canCreate ? createAccount : null,
                  child: isRegistering
                      ? const SizedBox(
                          width: 18,
                          height: 18,
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
