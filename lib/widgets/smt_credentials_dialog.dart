import 'package:flutter/material.dart';

class SMTCredentials {
  final String username;
  final String password;

  SMTCredentials({required this.username, required this.password});
}

class SmtCredentialsDialog extends StatefulWidget {
  const SmtCredentialsDialog({super.key});

  @override
  State<SmtCredentialsDialog> createState() => _SmtCredentialsDialogState();
}

class _SmtCredentialsDialogState extends State<SmtCredentialsDialog> {
  final _formKey = GlobalKey<FormState>();
  String _username = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Credentials for Smart Meter Texas'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Username'),
              onChanged: (value) => _username = value,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter username' : null,
            ),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onChanged: (value) => _password = value,
              validator: (value) =>
                  value == null || value.isEmpty ? 'Enter password' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(
                  SMTCredentials(username: _username, password: _password));
            }
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
