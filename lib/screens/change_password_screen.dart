import 'package:flutter/material.dart';

class ChangePasswordScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const ChangePasswordScreen({super.key, required this.onNavigate});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _changePassword() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate back to profile
          widget.onNavigate('profile');
        }
      });
    }
  }

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your current password';
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a new password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (value == _currentPasswordController.text) {
      return 'New password must be different from current password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your new password';
    }
    if (value != _newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('profile'),
        ),
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info card
              Card(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Choose a strong password with at least 8 characters',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Current Password
              Text(
                'Current Password',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                validator: _validateCurrentPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your current password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // New Password
              Text(
                'New Password',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                validator: _validateNewPassword,
                decoration: InputDecoration(
                  hintText: 'Enter your new password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureNewPassword = !_obscureNewPassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              // Confirm New Password
              Text(
                'Confirm New Password',
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                validator: _validateConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm your new password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),

              // Password Requirements
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password Requirements',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      _RequirementItem(
                        text: 'At least 8 characters',
                        met: _newPasswordController.text.length >= 8,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _RequirementItem(
                        text: 'Different from current password',
                        met: _newPasswordController.text.isNotEmpty &&
                            _newPasswordController.text != _currentPasswordController.text,
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 8),
                      _RequirementItem(
                        text: 'Passwords match',
                        met: _confirmPasswordController.text.isNotEmpty &&
                            _confirmPasswordController.text == _newPasswordController.text,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Change Password Button
              FilledButton(
                onPressed: _isLoading ? null : _changePassword,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Change Password'),
              ),
              const SizedBox(height: 16),

              // Cancel Button
              OutlinedButton(
                onPressed: _isLoading ? null : () => widget.onNavigate('profile'),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final String text;
  final bool met;
  final ColorScheme colorScheme;

  const _RequirementItem({
    required this.text,
    required this.met,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 20,
          color: met ? colorScheme.secondary : colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: met ? colorScheme.secondary : colorScheme.onSurfaceVariant,
            fontWeight: met ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
