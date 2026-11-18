class MonthlyRecord {
  const MonthlyRecord({
    this.workedHours = 0,
    this.bonus = 0,
    this.vacationPay = 0,
    this.note = '',
    this.rateOverride,
  });

  final double workedHours;
  final double bonus;
  final double vacationPay;
  final String note;
  // Ставка/оклад, действующие только в этом месяце.
  final double? rateOverride;

  Map<String, dynamic> toJson() => {
        'workedHours': workedHours,
        'bonus': bonus,
        'vacationPay': vacationPay,
        'note': note,
        'rateOverride': rateOverride,
      };

  factory MonthlyRecord.fromJson(Map<String, dynamic> json) => MonthlyRecord(
        workedHours: (json['workedHours'] as num?)?.toDouble() ?? 0,
        bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
        vacationPay: (json['vacationPay'] as num?)?.toDouble() ?? 0,
        note: json['note'] as String? ?? '',
        rateOverride: (json['rateOverride'] as num?)?.toDouble(),
      );
}
