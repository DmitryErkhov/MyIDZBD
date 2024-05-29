import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';
import 'table_bloc.dart'; // Убедитесь, что вы создали BLoC, события и состояния
import './loginpage.dart'; // Подключите файл с экрана авторизации
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'dart:io';



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

  // Маппинг русских и английских названий таблиц
  final Map<String, String> tableNames = {
    'Клиенты': 'Customer',
    'Сотрудники': 'staff',
    'Взаимодействия': 'interaction',
    'Действия': 'work',
    'Услуги': 'service',
    'Заказы': 'booking',
    'Запчасти': 'spare_part',
    'Автомобили': 'car',
    'Марки автомобилей': 'brand_car'
  };

  // Маппинг русских и английских названий атрибутов
  final Map<String, Map<String, String>> attributeNames = {
    'Customer': {
      'lfp_customer': 'ФИО клиента',
      'address': 'Адрес',
      'phone_customer': 'Телефон',
    },
    'booking': {
      'id_booking': 'Номер заказа',
      'lfp_customer': 'ФИО клиента',
      'vin_number_car': 'ВИН номер ТС',
      'date_application_booking': 'Дата обращения',
      'date_finish_booking': 'Дата завершения ремонта',
      'date_car_accept_booking': 'Дата приема ТС',
      'date_start_repair_booking': 'Дата приема ТС',
      'status_booking': 'Статус заказа',
      'service': 'Услуга',
      'name_service': 'Услуга',
      'price_service': 'Цена услуги',
      'staff': 'Исполнитель',
      'name_spare_part': 'Название запчасти',
      'price_spare_part': 'Цена запчасти',
    },
    'work': {
      'name_work': 'Название действия',
    },
    'interaction': {
      'id_booking': 'Номер заказа',
      'name_work': 'Название действия',
      'date_time_interaction': 'Дата',
      'service': 'Услуга',
      'staff': 'Исполнитель',
    },
    'service': {
      'id_service': 'Католожный номер услуги',
      'name_service': 'Название услуги',
      'price_service': 'Цена услуги',
      'coutn_hour_service': 'Норма часы',
    },
    'staff': {
      'lfp_staff': 'Имя',
      'post_staff': 'Должность',
    },
    'spare_part': {
      'id_booking': 'Номер заказа',
      'name_spare_part': 'Название запчасти',
      'number_spare_part': 'Артикул запчасти',
      'price_spare_part': 'Цена запчасти',
    },
    'brand_car': {
      'name_brand_car': 'Марка',
      'name_model_brand_car': 'Модель',
    },
    'car': {
      'vin_number_car': 'ВИН номер',
      'color_car': 'Цвет',
      'state_number_car': 'Рег. номер',
      'price_spare_part': 'Цена запчасти',
      'name_brand_car': 'Марка',
      'name_model_brand_car': 'Модель',
    },
    // Добавьте маппинг для других таблиц
  };

  // Маппинг исключаемых атрибутов
  final Map<String, List<String>> excludedAttributes = {
    'Customer': ['id_customer'], // Пример: исключить ID клиента
    'staff': ['id_staff', 'login', 'password'],       // Пример: исключить ID сотрудника
    'booking': ['id_customer'],       // Пример: исключить ID сотрудника
    'spare_part': ['id_spare_part'],       // исключить ID запчасти
    'brand_car': ['id_model_brand_car'],       // исключить ID запчасти
    'car': ['id_model_brand_car'],       // исключить ID запчасти
    'interaction': ['id_interaction','id_service','id_staff'],       // исключить ID запчасти
  };

  Map<String, String> primaryKeyMap = {
    'Customer': 'id_customer',
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

  String currentTable = 'Customer';

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
    String englishTableName = tableNames[tableName] ?? tableName;
    BlocProvider.of<TableBloc>(context).add(LoadTableData(englishTableName));
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
      child: Builder( // Создание нового контекста под BlocProvider
        builder: (newContext) { // Используйте newContext для доступа к BlocProvider
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
                        itemCount: tableNames.keys.length,
                        padding: const EdgeInsets.all(8),
                        itemBuilder: (BuildContext context, int index) {
                          String tableName = tableNames.keys.elementAt(index);
                          return Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () {
                                fetchDataFromTable(newContext, tableName);
                                currentTable = tableNames[tableName]!;
                              },
                              child: Text(tableName),
                            ),
                          );
                        }
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
                                }, child: Text(report[index])),
                          );
                        }
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
                            child: ElevatedButton(onPressed: () {
                              _showCreateBookingInteractionDialog(context);
                            },
                                child: Text(procedure[index])),
                          );
                        }
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

                  // BlocBuilder для отображения данных
                  BlocBuilder<TableBloc, TableState>(
                    builder: (newContext, state) {
                      if (state is TableLoading) {
                        return CircularProgressIndicator();
                      } else if (state is TableLoaded) {
                        print(state.data);
                        // Получаем первую строку данных для определения столбцов
                        var columns = state.data.isNotEmpty ? state.data.first.keys.toList() : [];

                        // Исключение ненужных атрибутов
                        var filteredColumns = columns.where((column) {
                          return !(excludedAttributes[currentTable]?.contains(column) ?? false);
                        }).toList();

                        // Получение русских названий атрибутов
                        var russianColumnNames = filteredColumns.map((column) {
                          return attributeNames[currentTable]?[column] ?? column;
                        }).toList();

                        return Column(
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                columns: russianColumnNames.map((column) => DataColumn(label: Text(column))).toList(),
                                rows: state.data.map((row) {
                                  return DataRow(
                                      cells: filteredColumns.map((column) => DataCell(Text('${row[column] ?? ''}'))).toList(),
                                      selected: true,
                                      onLongPress: () {
                                        _showEditDialog(context, row, currentTable);
                                      }
                                  );
                                }).toList(),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _showAddDialog(context, filteredColumns.map((column) => column.toString()).toList());
                              },
                              child: Icon(Icons.add),
                            ),
                          ],
                        );
                      } else if (state is TableError) {
                        return Text('Ошибка: ${state.message}');
                      } else {
                        return Container(); // Пустое состояние или инструкции
                      }
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }




  void _showEditDialog(BuildContext context, Map<String, dynamic> rowData, String tableName) {
    final textControllers = <String, TextEditingController>{};
    rowData.forEach((key, value) {
      textControllers[key] = TextEditingController(text: value.toString());
    });

    // Получение имени первичного ключа для текущей таблицы
    String? primaryKeyName = primaryKeyMap[tableName];

    if (primaryKeyName == null) {
      print("Primary key for table $tableName is not defined.");
      return;
    }

    // Получение русских названий столбцов
    var russianColumnNames = rowData.keys.map((column) {
      return attributeNames[tableName]?[column] ?? column;
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Редактировать Значение в ${tableNames.keys.firstWhere((k) => tableNames[k] == tableName, orElse: () => tableName)}"),
          content: SingleChildScrollView(
            child: ListBody(
              children: List.generate(rowData.length, (index) {
                String columnName = rowData.keys.elementAt(index);
                return TextField(
                  controller: textControllers[columnName],
                  decoration: InputDecoration(
                    labelText: russianColumnNames[index], // Используем русское название столбца как метку
                  ),
                );
              }),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Удалить"),
              onPressed: () async {
                // Выполнение SQL запроса для удаления
                try {
                  String deleteSQL = "DELETE FROM $tableName WHERE $primaryKeyName = @value";
                  await connection!.execute(deleteSQL, substitutionValues: {
                    "value": rowData[primaryKeyName]
                  });
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  print("Error deleting data: $e");
                }
              },
            ),
            ElevatedButton(
              child: Text("Сохранить"),
              onPressed: () async {
                // Выполнение SQL запроса для обновления
                try {
                  Map<String, String> updateValues = {};
                  textControllers.forEach((key, value) {
                    updateValues[key] = value.text;
                  });

                  String setString = updateValues.entries.map((entry) => "${entry.key} = @${entry.key}").join(", ");
                  String updateSQL = "UPDATE $tableName SET $setString WHERE $primaryKeyName = @primaryKeyValue";
                  updateValues['primaryKeyValue'] = rowData[primaryKeyName].toString();

                  await connection!.execute(updateSQL, substitutionValues: updateValues);
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


  void _showAddDialog(BuildContext context, List<String> columnNames) {
    // Удаление системных полей которые мы НЕ будем вводить
    currentTable == 'interaction' ? columnNames.remove('date_time_interaction') :
    currentTable == 'booking' ? {columnNames.remove('id_booking'), columnNames.remove('date_application_booking'), columnNames.remove('date_finish_booking'), columnNames.remove('status_booking'), columnNames.remove('date_car_accept_booking'), columnNames.remove('date_start_repair_booking')} : null;

    // Создаем контроллеры для текстовых полей каждого столбца
    final textControllers = Map.fromIterable(
      columnNames,
      // предполагается, что columnNames это List<String> названий столбцов
      key: (columnName) => columnName,
      value: (columnName) => TextEditingController(),
    );

    // Получение русских названий столбцов
    var russianColumnNames = columnNames.map((column) {
      return attributeNames[currentTable]?[column] ?? column;
    }).toList();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Добавить запись в ${tableNames.keys.firstWhere((k) => tableNames[k] == currentTable, orElse: () => currentTable)}"),
          content: SingleChildScrollView(
            child: ListBody(
              children: List.generate(columnNames.length, (index) {
                String columnName = columnNames[index];
                return TextField(
                  controller: textControllers[columnName],
                  decoration: InputDecoration(
                    labelText: russianColumnNames[index], // Используем русское название столбца как метку
                  ),
                );
              }),
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Отмена"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text("Сохранить"),
              onPressed: () async {
                // Создайте Map для данных новой записи
                Map<String, dynamic> newData = {};
                textControllers.forEach((columnName, controller) {
                  newData[columnName] = controller.text; // Получение данных из текстовых полей
                });

                // Выполните запрос на добавление данных
                try {
                  Map<String, String> substitutionValues = {};
                  textControllers.forEach((key, value) {
                    substitutionValues[key] = value.text;
                  });

                  // Создание строки с названиями столбцов и строкой с плейсхолдерами для значений
                  String columns = substitutionValues.keys.join(', ');
                  String values = substitutionValues.keys.map((k) => '@$k').join(', ');

                  // SQL запрос на вставку
                  String insertSQL = "INSERT INTO $currentTable ($columns) VALUES ($values)";
                  currentTable == 'car' ? insertSQL = "SELECT insert_car($values)" :
                  currentTable == 'interaction' ? insertSQL = "SELECT insert_interactions($values)" :
                  currentTable == 'booking' ? insertSQL = "SELECT insert_booking($values)" : null;
                  print(values);

                  // Выполнение запроса с подстановкой значений
                  await connection!.execute(insertSQL, substitutionValues: substitutionValues);

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // Обработка возможных ошибок при добавлении данных
                  print("Error adding data: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }


  void _showCreateBookingInteractionDialog(BuildContext context) {
    // Контроллеры для текстовых полей
    final inLfpCustomerController = TextEditingController();
    final inStateNumberCarController = TextEditingController();
    final inStaffIdController = TextEditingController();
    // Показать диалоговое окно
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Создать booking и interaction"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: inLfpCustomerController,
                  decoration: InputDecoration(labelText: 'lfp_customer'),
                ),
                TextField(
                  controller: inStateNumberCarController,
                  decoration: InputDecoration(labelText: 'state_number_car'),
                ),
                TextField(
                  controller: inStaffIdController,
                  decoration: InputDecoration(labelText: 'staff_id'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text("Отмена"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text("Далее"),
              onPressed: () async {
                try {
                  // Вызов хранимой процедуры с параметрами
                  await connection!.execute(
                    "SELECT create_booking_and_interaction(@inLfpCustomer, @inStateNumberCar, @inStaffId)",
                    substitutionValues: {
                      "inLfpCustomer": inLfpCustomerController.text,
                      "inStateNumberCar": inStateNumberCarController.text,
                      "inStaffId": inStaffIdController.text,
                    },
                  );
                  // Закрыть диалоговое окно при успехе
                  Navigator.of(context).pop();
                } catch (e) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Ошибка"),
                        content: Text("Произошла ошибка: $e"),
                        actions: <Widget>[
                          ElevatedButton(
                            child: Text("OK"),
                            onPressed: () => Navigator.of(context).pop(), // Закрыть окно сообщения об ошибке
                          ),
                        ],
                      );
                    },
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context, int reportIndex) async {
    // Создание контроллеров для текстовых полей
    final idBookingController = TextEditingController();
    final yearController = TextEditingController();
    final monthController = TextEditingController();

    // Создание списка виджетов для текстовых полей
    List<Widget> inputFields = [];

    // Определите поля ввода на основе индекса отчета
    if (reportIndex == 0 || reportIndex == 1) {
      inputFields.add(TextField(
        controller: idBookingController,
        decoration: InputDecoration(labelText: 'ID Заказа'),
        keyboardType: TextInputType.number,
      ));
    } else if (reportIndex == 2) {
      inputFields.add(TextField(
        controller: yearController,
        decoration: InputDecoration(labelText: 'Год'),
        keyboardType: TextInputType.number,
      ));
      inputFields.add(TextField(
        controller: monthController,
        decoration: InputDecoration(labelText: 'Месяц'),
        keyboardType: TextInputType.number,
      ));
    }

    // Показать диалоговое окно
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Введите данные для ${report[reportIndex]}"),
          content: SingleChildScrollView(
            child: ListBody(children: inputFields),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Показать'),
              onPressed: () async {
                // Здесь нужно подготовить и выполнить SQL запрос
                String sqlQuery = '';
                switch (reportIndex) {
                  case 0:
                  // Запрос для первого отчета
                    sqlQuery = "SELECT DISTINCT b.id_booking, b.date_application_booking, b.date_car_accept_booking, b.date_start_repair_booking, s.name_service, s.price_service, p.name_spare_part, p.price_spare_part FROM booking b "
                        "INNER JOIN render r ON b.id_booking = r.id_booking "
                        "INNER JOIN service s ON s.id_service = r.id_service "
                        "INNER JOIN spare_part p ON p.id_booking = b.id_booking "
                        "INNER JOIN customer c ON c.id_customer = b.id_customer "
                        "WHERE b.id_booking = ${idBookingController.text};";
                    break;
                  case 1:
                  // Запрос для второго отчета
                    sqlQuery = "SELECT DISTINCT p.name_spare_part, p.price_spare_part "
                        "FROM spare_part p "
                        "WHERE p.id_booking = ${idBookingController.text};";
                    break;
                  case 2:
                  // Запрос для третьего отчета
                    sqlQuery = "SELECT b.id_booking, b.vin_number_car, b.date_application_booking, b.date_finish_booking, b.status_booking, b.date_car_accept_booking, b.date_start_repair_booking, c.lfp_customer FROM booking b JOIN customer c ON b.id_customer = c.id_customer "
                        "WHERE EXTRACT(YEAR FROM b.date_application_booking) = ${yearController.text} "
                        "AND EXTRACT(MONTH FROM b.date_application_booking) = ${monthController.text};";
                    break;
                }

                try {
                  // Выполнение запроса
                  var results = await connection!.query(sqlQuery);
                  var columnNames = results.columnDescriptions
                      .map((col) => col.columnName)
                      .toList();

                  // Перевод названий столбцов
                  String englishTableName = 'booking'; // Определите английское название таблицы
                  var translatedColumnNames = columnNames.map((column) {
                    return attributeNames[englishTableName]?[column] ?? column;
                  }).toList();

                  // Замена значений null на "-"
                  var dataRows = results.map((row) {
                    return row.map((cell) => cell?.toString() ?? "-").toList();
                  }).toList();

                  // Закрытие текущего диалогового окна
                  Navigator.of(context).pop();

                  // Загрузка шрифта
                  final fontData = await rootBundle.load("assets/fonts/OpenSans-Regular.ttf");
                  final ttf = pw.Font.ttf(fontData);

                  // Создание PDF-документа
                  final pdf = pw.Document();

                  // Добавление страницы с заголовком, таблицей данных и подвалом
                  pdf.addPage(
                    pw.Page(
                      build: (pw.Context context) {
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'ООО Надеж сервис\nОГРН: 1234800005274\n398902, Липецкая область, г Липецк, ул Ударников, д. 90/1, офис 27',
                              style: pw.TextStyle(font: ttf, fontSize: 18, fontWeight: pw.FontWeight.bold),
                            ),
                            pw.SizedBox(height: 20),
                            pw.Table.fromTextArray(
                              headers: translatedColumnNames,
                              data: dataRows,
                              headerStyle: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold),
                              cellStyle: pw.TextStyle(font: ttf),
                            ),
                            pw.SizedBox(height: 20),
                            pw.Text(
                              'Дата создания отчета: ${DateTime.now()}\nОтветственный _____________________  Давыдов А.Р',
                              style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold),
                            ),
                          ],
                        );
                      },
                    ),
                  );

                  // Открытие диалога для выбора директории
                  String? outputDir = await FilePicker.platform.getDirectoryPath();

                  if (outputDir != null) {
                    final filePath = "$outputDir/report_${report[reportIndex]}.pdf";

                    // Сохранение PDF-файла
                    final file = File(filePath);
                    await file.writeAsBytes(await pdf.save());

                    // Отображение сообщения о успешном сохранении
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Отчет сохранен в $filePath")),
                    );
                  } else {
                    // Отображение сообщения о отмене сохранения
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Сохранение отчета отменено")),
                    );
                  }
                } catch (e) {
                  print("Ошибка выполнения запроса: $e");
                }
              },
            ),
          ],
        );
      },
    );
  }



// void _showReportDialog(BuildContext context, int reportIndex) async {
  //   // Создание контроллеров для текстовых полей
  //   final idBookingController = TextEditingController();
  //   final yearController = TextEditingController();
  //   final monthController = TextEditingController();
  //
  //   // Создание списка виджетов для текстовых полей
  //   List<Widget> inputFields = [];
  //
  //   // Определите поля ввода на основе индекса отчета
  //   if (reportIndex == 0 || reportIndex == 1) {
  //     inputFields.add(TextField(
  //       controller: idBookingController,
  //       decoration: InputDecoration(labelText: 'ID Booking'),
  //       keyboardType: TextInputType.number,
  //     ));
  //   } else if (reportIndex == 2) {
  //     inputFields.add(TextField(
  //       controller: yearController,
  //       decoration: InputDecoration(labelText: 'Year'),
  //       keyboardType: TextInputType.number,
  //     ));
  //     inputFields.add(TextField(
  //       controller: monthController,
  //       decoration: InputDecoration(labelText: 'Month'),
  //       keyboardType: TextInputType.number,
  //     ));
  //   }
  //
  //   // Показать диалоговое окно
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text("Введите данные для ${report[reportIndex]}"),
  //         content: SingleChildScrollView(
  //           child: ListBody(children: inputFields),
  //         ),
  //         actions: <Widget>[
  //           ElevatedButton(
  //             child: Text('Отмена'),
  //             onPressed: () => Navigator.of(context).pop(),
  //           ),
  //           ElevatedButton(
  //             child: Text('Показать'),
  //             onPressed: () async {
  //               // Здесь нужно подготовить и выполнить SQL запрос
  //               String sqlQuery = '';
  //               switch (reportIndex) {
  //                 case 0:
  //                 // Запрос для первого отчета
  //                   sqlQuery = "SELECT DISTINCT b.id_booking, b.date_application_booking, b.date_car_accept_booking, b.date_start_repair_booking, s.name_service, s.price_service, p.name_spare_part, p.price_spare_part FROM booking b "
  //                       "INNER JOIN render r ON b.id_booking = r.id_booking "
  //                       "INNER JOIN service s ON s.id_service = r.id_service "
  //                       "INNER JOIN spare_part p ON p.id_booking = b.id_booking "
  //                       "INNER JOIN customer c ON c.id_customer = b.id_customer "
  //                       "WHERE b.id_booking = ${idBookingController.text};";
  //                   break;
  //                 case 1:
  //                 // Запрос для второго отчета
  //                   sqlQuery = "SELECT DISTINCT p.name_spare_part, p.price_spare_part "
  //                       "FROM spare_part p "
  //                       "WHERE p.id_booking = ${idBookingController.text};";
  //                   break;
  //                 case 2:
  //                 // Запрос для третьего отчета
  //                   sqlQuery = "SELECT * FROM booking b "
  //                       "WHERE EXTRACT(YEAR FROM b.date_application_booking) = ${yearController.text} "
  //                       "AND EXTRACT(MONTH FROM b.date_application_booking) = ${monthController.text};";
  //                   break;
  //               }
  //
  //               try {
  //                 // Выполнение запроса
  //                 var results = await connection!.query(sqlQuery);
  //                 var columnNames = results.columnDescriptions
  //                     .map((col) => col.columnName)
  //                     .toList();
  //
  //                 // Закрытие текущего диалогового окна
  //                 Navigator.of(context).pop();
  //
  //                 // Отображение результатов в новом диалоговом окне с DataTable
  //                 showDialog(
  //                   context: context,
  //                   builder: (BuildContext context) {
  //                     // Подготовка данных для DataTable
  //                     List<DataColumn> columns = columnNames
  //                         .map((name) => DataColumn(label: Text(name)))
  //                         .toList();
  //                     List<DataRow> rows = results.map((row) {
  //                       return DataRow(
  //                         cells: row.map((cell) => DataCell(Text(cell.toString()))).toList(),
  //                       );
  //                     }).toList();
  //
  //                     return AlertDialog(
  //                       title: Text('Результаты для ${report[reportIndex]}'),
  //                       content: SingleChildScrollView(
  //                         scrollDirection: Axis.horizontal,
  //                         child: DataTable(columns: columns, rows: rows),
  //                       ),
  //                       actions: <Widget>[
  //                         ElevatedButton(
  //                           child: Text('Закрыть'),
  //                           onPressed: () => Navigator.of(context).pop(),
  //                         ),
  //                       ],
  //                     );
  //                   },
  //                 );
  //               } catch (e) {
  //                 print("Ошибка выполнения запроса: $e");
  //               }
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }


}

