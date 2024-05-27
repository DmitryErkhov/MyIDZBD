import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:postgres/postgres.dart';

// События
abstract class TableEvent {}
class LoadTableData extends TableEvent {
  final String tableName;
  LoadTableData(this.tableName);
}

// Состояния
abstract class TableState {}
class TableInitial extends TableState {}
class TableLoading extends TableState {}
class TableLoaded extends TableState {
  final List<Map<String, dynamic>> data;
  TableLoaded(this.data);
}
class TableError extends TableState {
  final String message;
  TableError(this.message);
}
class ChangeTable extends TableState {
  final String message;
  ChangeTable(this.message);
}

// BLoC
class TableBloc extends Bloc<TableEvent, TableState> {
  final PostgreSQLConnection databaseConnection;

  TableBloc({required this.databaseConnection}) : super(TableInitial()) {
    on<LoadTableData>((event, emit) async {
      emit(TableLoading());
      try {
        List<Map<String, dynamic>> rows = await fetchData(event.tableName);
        emit(TableLoaded(rows));
      } catch (e) {
        emit(TableError(e.toString()));
      }
    });
  }

  Future<List<Map<String, dynamic>>> fetchData(String tableName) async {
    if (databaseConnection.isClosed) {
      await databaseConnection.open();
    }

    try {
      var result = await databaseConnection.query('SELECT * FROM $tableName');
      List<Map<String, dynamic>> rows = [];
      for (final row in result) {
        Map<String, dynamic> map = {};
        for (final field in row.toColumnMap().entries) {
          map[field.key] = field.value;
        }
        rows.add(map);
      }
      return rows;
    } catch (e) {
      print('Ошибка выполнения запроса к базе данных: $e');
      rethrow;
    }
  }

}
