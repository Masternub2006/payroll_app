import 'monthly_record.dart';
import 'payment_type.dart';

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.paymentType,
    required this.rate,
    this.records = const {},
  });

  final String id;
  final String name;
  final PaymentType paymentType;
  final double rate;
  final Map<String, MonthlyRecord> records;

  Employee copyWith({
    String? name,
    PaymentType? paymentType,
    double? rate,
    Map<String, MonthlyRecord>? records,
  }) => Employee(
        id: id,
        name: name ?? this.name,
        paymentType: paymentType ?? this.paymentType,
        rate: rate ?? this.rate,
        records: records ?? this.records,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'paymentType': paymentType.storageKey,
        'rate': rate,
        'records': records.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    final rawRecords = (json['records'] as Map?) ?? {};
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      paymentType: PaymentTypeLabel.fromKey(json['paymentType'] as String?),
      rate: (json['rate'] as num?)?.toDouble() ?? 0,
      records: rawRecords.map((key, value) => MapEntry(
        key.toString(),
        MonthlyRecord.fromJson(Map<String, dynamic>.from(value as Map)),
      )),
    );
  }
}
