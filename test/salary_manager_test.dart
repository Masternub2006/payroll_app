import 'package:flutter_test/flutter_test.dart';
import 'package:payroll_app/models/employee.dart';
import 'package:payroll_app/models/monthly_record.dart';
import 'package:payroll_app/models/payment_type.dart';
import 'package:payroll_app/services/salary_manager.dart';

void main() {
  group('SalaryManager calculations', () {
    final manager = SalaryManager();
    test('fixed salary plus bonus and vacation pay', () {
      const employee = Employee(id: '1', name: 'Иванов Иван', paymentType: PaymentType.fixed, rate: 50000,
        records: {'11-2026': MonthlyRecord(bonus: 5000, vacationPay: 2000)});
      expect(manager.salaryFor(employee, '11-2026'), 57000);
    });
    test('fixed salary is included even without bonus or vacation pay', () {
      const employee = Employee(id: '4', name: 'Орлов Олег', paymentType: PaymentType.fixed, rate: 60000,
        records: {'11-2026': MonthlyRecord()});
      expect(manager.salaryFor(employee, '11-2026'), 60000);
    });
    test('hourly salary is hours multiplied by rate plus additions', () {
      const employee = Employee(id: '2', name: 'Петров Пётр', paymentType: PaymentType.hourly, rate: 500,
        records: {'11-2026': MonthlyRecord(workedHours: 80, bonus: 1000)});
      expect(manager.salaryFor(employee, '11-2026'), 41000);
    });
    test('missing month record means zero', () {
      const employee = Employee(id: '3', name: 'Сидоров', paymentType: PaymentType.fixed, rate: 60000);
      expect(manager.salaryFor(employee, '11-2026'), 0);
    });
  });
}
