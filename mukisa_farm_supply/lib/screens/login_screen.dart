import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedRole = 'sales';
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final err = await auth.login(_selectedRole, _passwordController.text);
    if (err != null) {
      setState(() { _error = err; _loading = false; });
      return;
    }
    // After successful login, AuthProvider notifies listeners and the
    // app's top-level `Consumer<AuthProvider>` will switch the home
    // to the correct role-based screen. No explicit navigation needed.
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Sign in as'),
                  const SizedBox(height: 8),
                  ToggleButtons(
                    isSelected: [_selectedRole == 'sales', _selectedRole == 'admin'],
                    onPressed: (i) {
                      setState(() { _selectedRole = i == 0 ? 'sales' : 'admin'; });
                    },
                    children: const [Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text('sales')), Padding(padding: EdgeInsets.symmetric(horizontal:12), child: Text('admin'))],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (v) => v == null || v.isEmpty ? 'Enter password' : null,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Sign in'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                    },
                    child: const Text('Register user (sales/admin)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
