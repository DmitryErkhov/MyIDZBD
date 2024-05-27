import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';

class LoginPage extends StatefulWidget {
  final PostgreSQLConnection connection;
  final VoidCallback onLoginSuccess;

  LoginPage({required this.connection, required this.onLoginSuccess});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;

  Future<void> _authenticate() async {
    final login = _loginController.text;
    final password = _passwordController.text;

    try {
      final results = await widget.connection.query(
        'SELECT * FROM staff WHERE login = @login AND password = @password',
        substitutionValues: {
          'login': login,
          'password': password,
        },
      );

      if (results.isNotEmpty) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _errorMessage = 'Invalid login or password';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error during authentication: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _loginController,
              decoration: InputDecoration(labelText: 'Login'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _authenticate,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
