enum PaymentType { fixed, hourly }

extension PaymentTypeLabel on PaymentType {
  String get label => this == PaymentType.fixed ? 'Оклад' : 'Почасовая';

  String get storageKey => name;

  static PaymentType fromKey(String? key) =>
      key == 'hourly' ? PaymentType.hourly : PaymentType.fixed;
}
