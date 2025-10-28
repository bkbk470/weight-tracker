import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const LoginScreen({super.key, required this.onNavigate});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool showPassword = false;
  bool isLoading = false;
  final emailController = TextEditingController(text: 'user@example.com');
  final passwordController = TextEditingController(text: 'password');
  final nameController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> handleSubmit() async {
    // Validate inputs
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    if (!isLogin && nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (!isLogin && passwordController.text != confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() => isLoading = true);

    try {
      if (isLogin) {
        // Sign in
        final response = await SupabaseService.instance.signIn(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (response.user == null) {
          _showError('Login failed. Please check your credentials.');
          setState(() => isLoading = false);
          return;
        }

        // Success - navigate to dashboard
        if (mounted) {
          widget.onNavigate('dashboard');
        }
      } else {
        // Sign up
        final response = await SupabaseService.instance.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
          fullName: nameController.text.trim(),
        );

        if (response.user == null) {
          _showError('Sign up failed. Please try again.');
          setState(() => isLoading = false);
          return;
        }

        // Success - navigate to dashboard
        if (mounted) {
          _showSuccess('Account created successfully!');
          await Future.delayed(const Duration(seconds: 1));
          widget.onNavigate('dashboard');
        }
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> handleSocialLogin(String provider) async {
    setState(() => isLoading = true);

    try {
      bool success = false;

      if (provider == 'google') {
        success = await SupabaseService.instance.signInWithGoogle();
      } else if (provider == 'apple') {
        success = await SupabaseService.instance.signInWithApple();
      }

      // If OAuth was initiated successfully, wait for auth state change
      // The auth state listener in main.dart will handle navigation
      if (success) {
        print('✅ OAuth flow initiated for $provider');
        // Don't navigate yet - wait for auth callback
      } else {
        _showError('Failed to initiate $provider sign in');
      }
    } catch (e) {
      _showError('Error signing in with $provider: ${e.toString().replaceAll('Exception: ', '')}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradients
          Positioned(
            top: MediaQuery.of(context).size.height / 3,
            right: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 3,
            left: -100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Logo and title
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fitness_center,
                      size: 40,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  Text(
                    'FitTrack',
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin
                        ? 'Welcome back! Sign in to continue'
                        : 'Create your account to get started',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Tab switcher
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => isLogin = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isLogin ? colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sign In',
                                style: textTheme.labelLarge?.copyWith(
                                  color: isLogin
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              FocusScope.of(context).unfocus();
                              setState(() => isLogin = false);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !isLogin ? colorScheme.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Sign Up',
                                style: textTheme.labelLarge?.copyWith(
                                  color: !isLogin
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Form fields
                  if (!isLogin) ...[
                    TextField(
                      controller: nameController,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          showPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => showPassword = !showPassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!isLogin) ...[
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: !showPassword,
                      onTapOutside: (_) => FocusScope.of(context).unfocus(),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Submit button
                  FilledButton(
                    onPressed: isLoading ? null : handleSubmit,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isLogin ? 'Sign In' : 'Create Account'),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'or continue with',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colorScheme.outlineVariant)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Social login buttons
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => handleSocialLogin('google'),
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    label: const Text('Continue with Google'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : () => handleSocialLogin('apple'),
                    icon: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    label: const Text('Continue with Apple'),
                  ),
                  const SizedBox(height: 24),

                  // Terms
                  Text.rich(
                    TextSpan(
                      text: 'By ${isLogin ? 'signing in' : 'creating an account'}, you agree to our ',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      children: [
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
