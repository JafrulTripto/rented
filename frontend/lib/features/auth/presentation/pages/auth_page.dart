import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;

  void _submit(BuildContext context, WidgetRef ref) {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        ref
            .read(authProvider.notifier)
            .login(
              _emailController.text.trim(),
              _passwordController.text.trim(),
            );
      } else {
        ref
            .read(authProvider.notifier)
            .register(
              _emailController.text.trim(),
              _passwordController.text.trim(),
              _nameController.text.trim(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Signup')),
      body: Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authProvider);

          // Show error if any
          if (authState.error != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(authState.error!)));
              }
            });
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLogin ? 'Welcome Back!' : 'Create Account',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? 'Password too short'
                          : null,
                    ),
                    const SizedBox(height: 32),
                    if (authState.isLoading)
                      const CircularProgressIndicator()
                    else ...[
                      ElevatedButton(
                        onPressed: () => _submit(context, ref),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        child: Text(_isLogin ? 'LOGIN' : 'SIGNUP'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin
                              ? 'New here? Signup'
                              : 'Already have an account? Login',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'or Login with google',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.read(authProvider.notifier).signInWithGoogle(),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                        ),
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png',
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.login),
                        ),
                        label: const Text('Sign in with Google'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
