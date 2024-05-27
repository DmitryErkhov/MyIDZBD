import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';
import 'table_bloc.dart'; // Убедитесь, что вы создали BLoC, события и состояния
import './loginpage.dart'; // Подключите файл с экрана авторизации

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'D9',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  PostgreSQLConnection? connection;
  bool _isAuthenticated = false;
  final tableNames = [
    'Customer',
    'staff',
    'interaction',
    'work',
    'service',
    'booking',
    'spare_part',
    'car',
    'brand_car'
  ];

  Map<String, String> primaryKeyMap = {
    'customer': 'id_customer',
    'booking': 'id_booking',
    'brand_car': 'id_model_brand_car',
    'car': 'vin_number_car',
    'interaction': 'id_interaction',
    'service': 'id_service',
    'spare_part': 'id_spare_part',
    'staff': 'id_staff',
    'work': 'name_work',
  };

  List<String> report = [
    'Отчет по ремонту',
    'Отчет по заказанным запчастям для ремонта',
    'Отчет по ремонтам за месяц '
  ];
  List<String> procedure = ['Создать для клиента заказ'];

  String currentTable = 'customer';

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

  void fetchDataFromTable(BuildContext context, String tableName) {
    BlocProvider.of<TableBloc>(context).add(LoadTableData(tableName));
  }

  void _onLoginSuccess() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (connection == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('D9'),
        ),
        body: Center(
          child: CircularProgressIndicator(), // Показываем индикатор загрузки, пока соединение устанавливается
        ),
      );
    }

    if (!_isAuthenticated) {
      return LoginPage(connection: connection!, onLoginSuccess: _onLoginSuccess);
    }

    return BlocProvider<TableBloc>(
      create: (context) => TableBloc(databaseConnection: connection!),
      child: Builder(
        builder: (newContext) {
          return Scaffold(
            appBar: AppBar(
              title: Text('D9'),
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Text('Таблицы'),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: tableNames.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              fetchDataFromTable(newContext, tableNames[index]);
                              currentTable = tableNames[index];
                            },
                            child: Text(tableNames[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  Text('Отчеты'),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: report.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              _showReportDialog(context, index);
                            },
                            child: Text(report[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  Text('Хранимые процедуры'),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: procedure.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ElevatedButton(
                            onPressed: () {
                              _showCreateBookingInteractionDialog(context);
                            },
                            child: Text(procedure[index]),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 2,
                      color: Colors.black26,
                    ),
                  ),
                  BlocBuilder<TableBloc, TableState>(
                    builder: (newContext, state) {
                      if (state is TableLoading) {
                        return CircularProgressIndicator();
                      } else if (state is TableLoaded) {
                        print(state.data);
                        var columns = state.data.isNotEmpty
                            ? state.data.first.keys.toList()
                            : [];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.data.isNotEmpty)
                              DataTable(
                                columns: columns
                                    .map((column) => DataColumn(
                                  label: Text(column),
                                ))
                                    .toList(),
                                rows: state.data.map((row) {
                                  return DataRow(
                                    cells: columns.map((column) {
                                      return DataCell(
                                        Text(row[column].toString()),
                                        onTap: () {
                                          _showEditDialog(newContext, row);
                                        },
                                      );
                                    }).toList(),
                                  );
                                }).toList(),
                              ),
                            ElevatedButton(
                              onPressed: () {
                                _showAddDialog(newContext, columns);
                              },
                              child: Text('Добавить значение в $currentTable'),
                            ),
                          ],
                        );
                      } else if (state is TableError) {
                        return Text('Error: ${state.message}');
                      }
                      return Container();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> rowData) {
    final textControllers = <String, TextEditingController>{};
    rowData.forEach((key, value) {
      textControllers[key] = TextEditingController(text: value.toString());
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Редактировать Значение"),
          content: SingleChildScrollView(
            child: ListBody(
              children: rowData.keys.map((key) {
                return TextField(
                  controller: textControllers[key],
                  decoration: InputDecoration(labelText: key),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Сохранить"),
              onPressed: () async {
                try {
                  Map<String, dynamic> updateValues = {};
                  textControllers.forEach((key, value) {
                    updateValues[key] = value.text;
                  });
                  String setString = updateValues.keys
                      .map((key) => "$key = @$key")
                      .join(", ");
                  String tableName = currentTable;
                  String primaryKeyName = primaryKeyMap[tableName.toLowerCase()]!;
                  String updateSQL =
                      "UPDATE $tableName SET $setString WHERE $primaryKeyName = @primaryKeyValue";
                  await connection!.execute(updateSQL,
                      substitutionValues: {
                        ...updateValues,
                        "primaryKeyValue": rowData[primaryKeyName]
                      });
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print("Error updating data: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context, List<dynamic> columnNames) {
    final textControllers = <String, TextEditingController>{};
    for (var column in columnNames) {
      textControllers[column] = TextEditingController();
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Добавить Значение"),
          content: SingleChildScrollView(
            child: ListBody(
              children: columnNames.map((column) {
                return TextField(
                  controller: textControllers[column],
                  decoration: InputDecoration(labelText: column),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Добавить"),
              onPressed: () async {
                try {
                  Map<String, dynamic> insertValues = {};
                  textControllers.forEach((key, value) {
                    insertValues[key] = value.text;
                  });
                  String columns = columnNames.join(", ");
                  String values = columnNames.map((col) => "@$col").join(", ");
                  String insertSQL =
                      "INSERT INTO $currentTable ($columns) VALUES ($values)";
                  await connection!.execute(insertSQL,
                      substitutionValues: insertValues);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print("Error inserting data: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Отчет ${index + 1}'),
          content: Text('Содержимое отчета ${index + 1}'),
          actions: <Widget>[
            TextButton(
              child: Text('Закрыть'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showCreateBookingInteractionDialog(BuildContext context) {
    final bookingController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Создать для клиента заказ'),
          content: TextField(
            controller: bookingController,
            decoration: InputDecoration(labelText: 'Номер заказа'),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Создать'),
              onPressed: () {
                // Логика создания заказа
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
