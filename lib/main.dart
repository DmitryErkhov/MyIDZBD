import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_color_style.dart';
import 'app_text_style.dart';
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
      home: LoginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? _postStaff;
  PostgreSQLConnection? connection;

  bool showReports = true;

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
    'Марки автомобилей': 'brand_car',
    'Оказанные услуги' : 'render'
  };

  // Маппинг русских и английских названий атрибутов
  final Map<String, Map<String, String>> attributeNames = {
    'Customer': {
      'lfp_customer': 'ФИО клиента',
      'address': 'Адрес',
      'phone_customer': 'Телефон',
    },
    'render':{
      'id_booking': 'Номер заказа',
      'name_service': 'Название услуги',
    },
    'booking': {
      'id_booking': 'Номер заказа',
      'lfp_customer': 'ФИО клиента',
      'vin_number_car': 'ВИН номер ТС',
      'date_application_booking': 'Дата обращения',
      'date_finish_booking': 'Дата завершения ремонта',
      'date_car_accept_booking': 'Дата приема ТС',
      'date_start_repair_booking': 'Дата начала ремонта',
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
      'login': 'Логин для входа',
      'password': 'Пароль для входа',
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
    'staff': ['id_staff', 'login', 'password'], // Пример: исключить ID сотрудника
    'booking': ['id_customer'], // Пример: исключить ID сотрудника
    'spare_part': ['id_spare_part'], // исключить ID запчасти
    'brand_car': ['id_model_brand_car'], // исключить ID запчасти
    'render': ['id_render','id_service'], // исключить ID запчасти
    'car': ['id_model_brand_car'], // исключить ID запчасти
    'interaction': ['id_interaction', 'id_service', 'id_staff'], // исключить ID запчасти
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
    'render': 'id_service'
  };

  List<String> report = [
    'Отчет по ремонту',
    'Отчет по заказанным запчастям для ремонта',
    'Отчет по ремонтам за месяц '
  ];
  List<String> procedure = ['Изменить статус заказа'];

  String currentTable = 'Customer';

  // Маппинг должностей к доступным таблицам
  final Map<String, List<String>> accessControl = {
    'Механик': ['interaction', 'work', 'service', 'booking', 'spare_part', 'render'],
    'Менеджер': [
      'Customer',
      'staff',
      'interaction',
      'work',
      'service',
      'booking',
      'spare_part',
      'car',
      'brand_car',
      'render'
    ],
    'Директор': [
      'Customer',
      'staff',
      'interaction',
      'work',
      'service',
      'booking',
      'spare_part',
      'car',
      'brand_car',
      'render'
    ],
    // для других должностей
  };

  @override
  void initState() {
    super.initState();
    loadConfigAndConnect();
    _loadPostStaff();
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

  Future<void> _loadPostStaff() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _postStaff = prefs.getString('post_staff');

      // Удаляем доступа к таблицам и отчетам
      _postStaff == 'Механик' ?
      {tableNames.remove('Клиенты'), tableNames.remove('Автомобили'), tableNames.remove('Марки автомобилей'), report.remove('Отчет по ремонтам за месяц ')} : null;
    });
  }

  void fetchDataFromTable(BuildContext context, String tableName) {
    String englishTableName = tableNames[tableName] ?? tableName;
    BlocProvider.of<TableBloc>(context).add(LoadTableData(englishTableName));
  }

  @override
  Widget build(BuildContext context) {
    if (connection == null) {
      return Scaffold(
        appBar: AppBar(
          title: SizedBox(width: 100, height: 100, child: Image.asset('assets/images/d9.png')),
        ),
        body: Center(
          child: CircularProgressIndicator(), // Показываем индикатор загрузки, пока соединение устанавливается
        ),
      );
    }

    return BlocProvider<TableBloc>(
      create: (context) => TableBloc(databaseConnection: connection!),
      child: Builder(
        builder: (newContext) {
          return Scaffold(
            appBar: AppBar(
              title: SizedBox(width: 100, height: 100, child: Image.asset('assets/images/d9.png')),
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 20,),
                      SizedBox(
                        height: 50,
                        child: ToggleButtons(
                          isSelected: [showReports, !showReports],
                          onPressed: (index) {
                            setState(() {
                              showReports = index == 0;
                            });
                          },
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('Отчеты'),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text('Быстрые действия'),
                            ),
                          ],
                        ),
                      ),
                      if (showReports) ...[
                        SizedBox(
                          height: 80,
                          width: MediaQuery.of(context).size.width-300,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: report.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
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
                                  onPressed: () {
                                    _showReportDialog(context, index);
                                  },
                                  child: Text(report[index], style: CustomTextStyle.outlinedButtonAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),),
                                ),
                              );
                            },
                          ),
                        ),
                      ] else ...[
                        SizedBox(
                          height: 80,
                          width: 900,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: procedure.length,
                            padding: const EdgeInsets.all(8),
                            itemBuilder: (BuildContext context, int index) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
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
                                  onPressed: () {
                                    procedure[index] == 'Изменить статус заказа' ? _showChangeStatusBooking(context) : null;
                                    // _showCreatePurchaseDialog(context);
                                  },
                                  child: Text(procedure[index], style: CustomTextStyle.outlinedButtonAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 2,
                      color: CustomColorStyle.accentColor,
                    ),
                  ),
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: Row(
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width/5,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width/5,
                            height: MediaQuery.of(context).size.height,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              itemCount: tableNames.keys.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (BuildContext context, int index) {
                                String tableName = tableNames.keys.elementAt(index);
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
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
                                    onPressed: () {
                                      fetchDataFromTable(newContext, tableName);
                                      currentTable = tableNames[tableName]!;
                                    },
                                    child: Text(tableName, style: CustomTextStyle.outlinedButtonAuthPage(MediaQuery.of(context).size * MediaQuery.of(context).devicePixelRatio),),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: MediaQuery.of(context).size.height,
                          color: CustomColorStyle.accentColor,
                        ),
                        SizedBox(
                          child: BlocBuilder<TableBloc, TableState>(
                            builder: (newContext, state) {
                              if (state is TableLoading) {
                                return CircularProgressIndicator();
                              } else if (state is TableLoaded) {
                                print(state.data);
                                var columns = state.data.isNotEmpty
                                    ? state.data.first.keys.toList()
                                    : [];
                                var filteredColumns = columns.where((column) {
                                  return !(excludedAttributes[currentTable]
                                      ?.contains(column) ??
                                      false);
                                }).toList();
                                var russianColumnNames = filteredColumns.map((column) {
                                  return attributeNames[currentTable]?[column] ??
                                      column;
                                }).toList();

                                return Padding(
                                  padding: const EdgeInsets.only(left: 20),
                                  child: Column(
                                    children: [
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: russianColumnNames
                                              .map((column) =>
                                              DataColumn(label: Text(column)))
                                              .toList(),
                                          rows: state.data.map((row) {
                                            return DataRow(
                                              cells: filteredColumns
                                                  .map((column) => DataCell(
                                                  Text('${row[column] ?? ''}')))
                                                  .toList(),
                                              selected: true,
                                              onLongPress: () {
                                                if (accessControl[_postStaff]
                                                    ?.contains(currentTable) ??
                                                    false) {
                                                  _showEditDialog(
                                                      context, row, currentTable);
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      if (accessControl[_postStaff]
                                          ?.contains(currentTable) ??
                                          false)
                                        ElevatedButton(
                                          onPressed: () {
                                            _showAddDialog(
                                                context,
                                                filteredColumns
                                                    .map((column) => column.toString())
                                                    .toList());
                                          },
                                          child: Icon(Icons.add),
                                        ),
                                    ],
                                  ),
                                );
                              } else if (state is TableError) {
                                return Text('Ошибка: ${state.message}');
                              } else {
                                return Container(); // Пустое состояние или инструкции
                              }
                            },
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }




  void _showEditDialog(BuildContext context, Map<String, dynamic> rowData, String tableName) {
    // Инициализация контроллеров для текстовых полей
    final textControllers = <String, TextEditingController>{};
    final updateValues = <String, String>{};

    // Список полей, которые необходимо исключить из интерфейса редактирования
    final List<String> excludedColumns = excludedAttributes[tableName] ?? [];

    // Формирование контроллеров и подготовка данных для обновления
    rowData.forEach((key, value) {
      if (!excludedColumns.contains(key)) {
        textControllers[key] = TextEditingController(text: value.toString());
      }

      // Все значения сохраняем для обновления, включая исключённые
      updateValues[key] = value.toString();
    });

    print(rowData);

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
          title: Text("Редактировать значение в ${tableNames.keys.firstWhere((k) => tableNames[k] == tableName, orElse: () => tableName)}"),
          content: SingleChildScrollView(
            child: ListBody(
              children: rowData.keys.where((key) => !excludedColumns.contains(key)).map((columnName) {
                int index = rowData.keys.toList().indexOf(columnName);
                return TextField(
                  controller: textControllers[columnName],
                  cursorColor: CustomColorStyle.accentColor,
                  style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                  decoration: InputDecoration(
                    focusColor: CustomColorStyle.accentColor,
                    labelText: russianColumnNames[index],
                    hintText: russianColumnNames[index],
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
                );
              }).toList(),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ошибка при удалении данных: $e"),
                        duration: Duration(seconds: 13),
                      )
                  );
                }
              },
            ),
            if(currentTable != 'booking' && currentTable != 'render') ...[
            ElevatedButton(
              child: Text("Сохранить"),
              onPressed: () async {
                try {
                  // Обновление значений из контроллеров
                  textControllers.forEach((key, value) {
                    updateValues[key] = value.text;
                  });
                  print('object');
                  print(updateValues);

                  String setString = updateValues.entries.where((entry) => !excludedColumns.contains(entry.key)).map((entry) => "${entry.key} = @${entry.key}").join(", ");
                  String updateSQL;
                  tableName == 'car' ? updateSQL = "Select update_car('${updateValues['vin_number_car']}','${updateValues['name_brand_car']}','${updateValues['name_model_brand_car']}','${updateValues['state_number_car']}','${updateValues['color_car']}')":
                  tableName == 'interaction' ? updateSQL = "Select update_interaction('${updateValues['id_interaction']}','${updateValues['name_work']}','${updateValues['staff']}','${updateValues['date_time_interaction']}','${updateValues['service']}')": updateSQL = "UPDATE $tableName SET $setString WHERE $primaryKeyName = @primaryKeyValue" ;
                  updateValues['primaryKeyValue'] = rowData[primaryKeyName].toString();
                  print(updateSQL);

                  tableName == 'car' ? await connection!.execute(updateSQL)  : await connection!.execute(updateSQL, substitutionValues: updateValues) ;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ошибка при обновление данных: $e"),
                        duration: Duration(seconds: 13),
                      )
                  );
                }
              },
            ) ]
          ],
        );
      },
    );
  }


  String hashPassword(String password) {
    final bytes = utf8.encode(password); // Переводим пароль в байты
    final digest = sha256.convert(bytes); // Хэшируем байты
    return digest.toString(); // Возвращаем хэш в виде строки
  }

  void _showAddDialog(BuildContext context, List<String> columnNames) {
    // Удаление системных полей которые мы НЕ будем вводить
    currentTable == 'interaction' ? columnNames.remove('date_time_interaction') :
    currentTable == 'booking' ? {columnNames.remove('id_booking'), columnNames.remove('date_application_booking'), columnNames.remove('date_finish_booking'), columnNames.remove('status_booking'), columnNames.remove('date_car_accept_booking'), columnNames.remove('date_start_repair_booking')} :
    currentTable == 'staff' ? {columnNames.add('login'), columnNames.add('password')} :
    currentTable == 'service' ? columnNames.remove('id_service') : null;

    // Создаем контроллеры для текстовых полей каждого столбца
    final textControllers = Map.fromIterable(
      columnNames,
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
                  cursorColor: CustomColorStyle.accentColor,
                  style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                  decoration: InputDecoration(
                    focusColor: CustomColorStyle.accentColor,
                    labelText: russianColumnNames[index],
                    hintText: russianColumnNames[index],
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
                try {
                  Map<String, String> substitutionValues = {};
                  textControllers.forEach((key, value) {
                    currentTable == 'staff' && key == 'password' ? substitutionValues[key] = hashPassword(value.text) :
                    substitutionValues[key] = value.text;
                  });

                  String columns = substitutionValues.keys.join(', ');
                  String values = substitutionValues.keys.map((k) => '@$k').join(', ');

                  String insertSQL = "INSERT INTO $currentTable ($columns) VALUES ($values)";
                  currentTable == 'car' ? insertSQL = "SELECT insert_car($values)" :
                  currentTable == 'render' ? insertSQL = "SELECT add_render($values)" :
                  currentTable == 'interaction' ? insertSQL = "SELECT insert_interactions($values)" :
                  currentTable == 'booking' ? insertSQL = "SELECT insert_booking($values)" : null;

                  await connection!.execute(insertSQL, substitutionValues: substitutionValues);

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                        (Route<dynamic> route) => false,
                  );
                } catch (e) {
                  // Выводим ошибку в SnackBar
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Ошибка при добавлении данных: $e"),
                        duration: Duration(seconds: 23),
                      )
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

// Моя хранимая процедура
  void _showChangeStatusBooking(BuildContext context) {
    // Контроллеры для текстовых полей
    final idBooking = TextEditingController();
    final statusBooking = TextEditingController();
    // Показать диалоговое окно
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Изменить статус заказ"),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                TextField(
                  controller: idBooking,
                  cursorColor: CustomColorStyle.accentColor,
                  style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                  decoration: InputDecoration(
                    focusColor: CustomColorStyle.accentColor,
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0), // Увеличение отступов по горизонтали
                      child: Icon(Icons.numbers_outlined, color: CustomColorStyle.greyColor,),
                    ),
                    hintText: 'Номер заказа',
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
                TextField(
                  controller: statusBooking,
                  cursorColor: CustomColorStyle.accentColor,
                  style: CustomTextStyle.textInTextFieldAuthPage(MediaQuery.of(context).size),
                  decoration: InputDecoration(
                    focusColor: CustomColorStyle.accentColor,
                    prefixIcon: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0), // Увеличение отступов по горизонтали
                      child: Icon(Icons.stacked_line_chart, color: CustomColorStyle.greyColor,),
                    ),
                    hintText: 'Статус заказа',
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
                    "UPDATE booking SET status_booking = @newStatusBooking WHERE id_booking = @idBooking",
                    substitutionValues: {
                      "newStatusBooking": statusBooking.text,
                      "idBooking": idBooking.text,
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
        decoration: InputDecoration(labelText: 'Номер заказа'),
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




}

