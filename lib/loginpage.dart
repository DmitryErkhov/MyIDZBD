import 'dart:convert';
import './main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

import 'app_color_style.dart';
import 'app_text_style.dart';

class LoginPage extends StatefulWidget {
  LoginPage();

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  PostgreSQLConnection? connection;
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    loadConfigAndConnect();
  }

  Future<void> loadConfigAndConnect() async {
    try {
      final config = await loadDatabaseConfig();
      connection = PostgreSQLConnection(
        config['hostname'],
        config['port'],
        config['databaseName'],
        username: config['username'],
        password: config['password'],
      );
      await connection!.open();
      print('Connected to PostgreSQL database.');
      setState(() {}); // Обновление состояния после успешного соединения
    } catch (e) {
      print('Error connecting to PostgreSQL database: $e');
    }
  }

  Future<Map<String, dynamic>> loadDatabaseConfig() async {
    final configString = await rootBundle.loadString('assets/db_config.json');
    return json.decode(configString) as Map<String, dynamic>;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Переводим пароль в байты
    final digest = sha256.convert(bytes); // Хэшируем байты
    return digest.toString(); // Возвращаем хэш в виде строки
  }

  Future<void> _authenticate() async {
    final login = _loginController.text;
    final password = _passwordController.text;

    // Хэшируем пароль перед отправкой его в базу данных
    final hashedPassword = hashPassword(password);
    print(hashedPassword);

    try {
      final results = await connection!.query(
        'SELECT * FROM staff WHERE login = @login AND password = @password',
        substitutionValues: {
          'login': login,
          'password': hashedPassword,
        },
      );

      if (results.isNotEmpty) {
        final postStaff = results.first[2].toString();
        print('post_staff: $postStaff');

        // Сохраняем post_staff в shared preferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('post_staff', postStaff);

        // Переходим на следующую страницу
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => MyHomePage()),
              (Route<dynamic> route) => false,
        );
      } else {
        setState(() {
          _errorMessage = 'Неверный логин или пароль';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка авторизации: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(width: 100, height: 100, child: Image.asset('assets/images/d9.png')),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.of(context).size.width/18),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width/5,
                  height: MediaQuery.of(context).size.width/5,
                  child:  Image.asset('assets/images/login.png'),
                ),
                SizedBox(
                  width: MediaQuery.of(context).size.width/3.15,
                  child: Text(
                    'Авторизация',
                    textAlign: TextAlign.center,
                    style: CustomTextStyle.titleAuthPage(MediaQuery.of(context).size),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: MediaQuery.of(context).size.width/48),
                  child: Container(
                    width: MediaQuery.of(context).size.width/3.15,
                    child: TextFormField(
                      controller: _loginController,
                      cursorColor: CustomColorStyle.accentColor,
                      style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                      decoration: InputDecoration(
                        focusColor: CustomColorStyle.accentColor,
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0), // Увеличение отступов по горизонтали
                          child: Icon(Icons.people_alt_outlined, color: CustomColorStyle.greyColor,),
                        ),
                        hintText: 'Логин для входа',
                        hintStyle: CustomTextStyle.hintTextFieldAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),
                        fillColor: CustomColorStyle.backGroundWhite,
                        filled: true,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: CustomColorStyle.greyColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: CustomColorStyle.accentColor,),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: MediaQuery.of(context).size.width/3.15,
                  margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.width/200),
                  child: TextFormField(
                    controller: _passwordController,
                    cursorColor: CustomColorStyle.accentColor,
                    style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                    obscureText: _obscureText,
                    decoration: InputDecoration(
                      focusColor: CustomColorStyle.accentColor,
                      prefixIcon: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0), // Увеличение отступов по горизонтали
                        child: Icon(Icons.password, color: CustomColorStyle.greyColor,),
                      ),
                      hintText: 'Пароль',
                      hintStyle: CustomTextStyle.hintTextFieldAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),
                      fillColor: CustomColorStyle.backGroundWhite,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: CustomColorStyle.greyColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: CustomColorStyle.accentColor,),
                      ),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                          icon: Icon(
                            _obscureText ? Icons.visibility : Icons.visibility_off,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
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
                Container(
                  width: MediaQuery.of(context).size.width/3.15,
                  margin: EdgeInsets.only(top: MediaQuery.of(context).size.width/48),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      textStyle: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),
                      side: BorderSide(
                        color: CustomColorStyle.accentColor, //Set border color
                        width: 1, //Set border width
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                    onPressed: _authenticate,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Text('Войти', style: CustomTextStyle.outlinedButtonAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),), // add your button text here
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.touch_app_outlined, color: CustomColorStyle.accentColor, size: 24,), // add your suffix icon here
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
