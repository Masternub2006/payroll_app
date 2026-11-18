import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/employee.dart';
import '../models/monthly_record.dart';
import '../models/payment_type.dart';

class SalaryManager extends ChangeNotifier {
  static const _storageKey = 'payroll_employees_v1';
  final List<Employee> _employees = [];
  List<Employee> get employees => List.unmodifiable(_employees);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _employees
          ..clear()
          ..addAll(list.map((e) => Employee.fromJson(Map<String, dynamic>.from(e as Map))));
      } catch (_) {
        _employees.clear();
      }
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_employees.map((e) => e.toJson()).toList()));
  }

  Future<void> addEmployee({required String name, required PaymentType type, required double rate, required String initialMonth}) async {
    // Создаём запись за выбранный месяц сразу: для сотрудника на окладе
    // базовый оклад попадёт в ФОТ даже при нулевых премиях и отпускных.
    _employees.add(Employee(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name.trim(), paymentType: type, rate: rate,
      records: {initialMonth: const MonthlyRecord()},
    ));
    await _save();
    notifyListeners();
  }

  Future<void> updateEmployee(Employee updated) async {
    final index = _employees.indexWhere((e) => e.id == updated.id);
    if (index < 0) return;
    _employees[index] = updated;
    await _save();
    notifyListeners();
  }

  Future<void> deleteEmployee(String id) async {
    _employees.removeWhere((e) => e.id == id);
    await _save();
    notifyListeners();
  }

  Future<void> saveMonthlyRecord(String employeeId, String month, MonthlyRecord record) async {
    final index = _employees.indexWhere((e) => e.id == employeeId);
    if (index < 0) return;
    final employee = _employees[index];
    final records = Map<String, MonthlyRecord>.from(employee.records)..[month] = record;
    _employees[index] = employee.copyWith(records: records);
    await _save();
    notifyListeners();
  }

  double salaryFor(Employee employee, String month) {
    final record = employee.records[month];
    // Без записи за месяц начисление равно нулю.
    if (record == null) return 0;
    final rate = record.rateOverride ?? employee.rate;
    final base = employee.paymentType == PaymentType.fixed
        ? rate
        : (record.workedHours > 0 ? record.workedHours * rate : 0);
    return base + record.bonus + record.vacationPay;
  }

  double totalFor(String month) => _employees.fold(0, (sum, e) => sum + salaryFor(e, month));
}
