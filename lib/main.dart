import 'package:flutter/material.dart';
import 'models/employee.dart';
import 'models/monthly_record.dart';
import 'models/payment_type.dart';
import 'services/salary_manager.dart';

void main() => runApp(const PayrollApp());

class PayrollApp extends StatefulWidget {
  const PayrollApp({super.key});
  @override
  State<PayrollApp> createState() => _PayrollAppState();
}

class _PayrollAppState extends State<PayrollApp> {
  final manager = SalaryManager();
  @override
  void initState() { super.initState(); manager.load(); }
  @override
  void dispose() { manager.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Учёт зарплаты',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3157C8)),
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      cardTheme: const CardThemeData(elevation: 0, color: Colors.white),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    ),
    home: HomeScreen(manager: manager),
  );
}

const monthNames = ['Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'];
String monthKey(DateTime d) => '${d.month.toString().padLeft(2, '0')}-${d.year}';
String monthTitle(DateTime d) => '${monthNames[d.month - 1]} ${d.year}';
String money(double value) => value.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ' ');

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.manager});
  final SalaryManager manager;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime selected = DateTime(DateTime.now().year, DateTime.now().month);
  String get period => monthKey(selected);

  Future<void> chooseMonth() async {
    final picked = await showDatePicker(context: context, initialDate: selected,
      firstDate: DateTime(2000), lastDate: DateTime(2100), helpText: 'Выберите дату нужного месяца');
    if (picked != null) setState(() => selected = DateTime(picked.year, picked.month));
  }

  Future<void> employeeDialog([Employee? employee]) async {
    final name = TextEditingController(text: employee?.name ?? '');
    final rate = TextEditingController(text: employee == null ? '' : employee.rate.toString());
    var type = employee?.paymentType ?? PaymentType.fixed;
    final result = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(
      title: Text(employee == null ? 'Новый сотрудник' : 'Изменить сотрудника'),
      content: SizedBox(width: 420, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'ФИО')),
        const SizedBox(height: 12),
        DropdownButtonFormField<PaymentType>(value: type, decoration: const InputDecoration(labelText: 'Тип оплаты'),
          items: PaymentType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(),
          onChanged: (v) { if (v != null) setLocal(() => type = v); }),
        const SizedBox(height: 12),
        TextField(controller: rate, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: type == PaymentType.fixed ? 'Месячный оклад' : 'Ставка за час')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () { final parsed = double.tryParse(rate.text.replaceAll(',', '.')); if (name.text.trim().isEmpty || parsed == null || parsed < 0) return; Navigator.pop(ctx, true); }, child: const Text('Сохранить'))],
    )));
    if (result == true) {
      final parsed = double.parse(rate.text.replaceAll(',', '.'));
      if (employee == null) { await widget.manager.addEmployee(name: name.text, type: type, rate: parsed, initialMonth: period); }
      else { await widget.manager.updateEmployee(employee.copyWith(name: name.text.trim(), paymentType: type, rate: parsed)); }
    }
    name.dispose(); rate.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Учёт зарплаты', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: false),
    floatingActionButton: FloatingActionButton.extended(onPressed: () => employeeDialog(), icon: const Icon(Icons.person_add_alt_1), label: const Text('Сотрудник')),
    body: AnimatedBuilder(animation: widget.manager, builder: (context, _) {
      final employees = widget.manager.employees;
      final total = widget.manager.totalFor(period);
      return ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 100), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Период расчёта', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Row(children: [
            IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month - 1)), icon: const Icon(Icons.chevron_left)),
            Expanded(child: InkWell(onTap: chooseMonth, borderRadius: BorderRadius.circular(12), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(monthTitle(selected), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)), const SizedBox(width: 8), const Icon(Icons.calendar_month, size: 19)])))),
            IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month + 1)), icon: const Icon(Icons.chevron_right)),
          ]),
          const Divider(height: 22),
          const Text('Общий фонд оплаты труда', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(money(total), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: -1)),
          const SizedBox(height: 3),
          Text('Сотрудников: ${employees.length}', style: const TextStyle(color: Colors.black54)),
        ]))),
        const SizedBox(height: 18),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Сотрудники', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), Text('${employees.length}', style: const TextStyle(color: Colors.black54))]),
        const SizedBox(height: 10),
        if (employees.isEmpty) Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [Icon(Icons.groups_outlined, size: 42, color: Colors.blueGrey.shade300), const SizedBox(height: 10), const Text('Пока нет сотрудников', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 4), const Text('Добавьте первого сотрудника, чтобы начать учёт', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54))]))),
        ...employees.map((e) => Card(margin: const EdgeInsets.only(bottom: 8), child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          leading: CircleAvatar(backgroundColor: const Color(0xFFE9EDFC), foregroundColor: const Color(0xFF3157C8), child: Text(e.name.trim().isEmpty ? '?' : e.name.trim()[0].toUpperCase())),
          title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('${e.paymentType.label} · ${money(e.rate)} ${e.paymentType == PaymentType.hourly ? '/ час' : '/ мес.'}'),
          trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text(money(widget.manager.salaryFor(e, period)), style: const TextStyle(fontWeight: FontWeight.bold)), const Text('начислено', style: TextStyle(fontSize: 11, color: Colors.black54))]),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeScreen(manager: widget.manager, employeeId: e.id, selectedMonth: selected))),
        ))),
      ]);
    }),
  );
}

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key, required this.manager, required this.employeeId, required this.selectedMonth});
  final SalaryManager manager; final String employeeId; final DateTime selectedMonth;
  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  late DateTime selected;
  String get period => monthKey(selected);
  @override
  void initState() { super.initState(); selected = widget.selectedMonth; }

  Future<void> recordDialog(Employee employee) async {
    final old = employee.records[period] ?? const MonthlyRecord();
    final hours = TextEditingController(text: old.workedHours == 0 ? '' : old.workedHours.toString());
    final bonus = TextEditingController(text: old.bonus == 0 ? '' : old.bonus.toString());
    final vacation = TextEditingController(text: old.vacationPay == 0 ? '' : old.vacationPay.toString());
    final rate = TextEditingController(text: (old.rateOverride ?? employee.rate).toString());
    final note = TextEditingController(text: old.note);
    final saved = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Начисления · ${monthTitle(selected)}'),
      content: SizedBox(width: 420, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        _numberField(rate, employee.paymentType == PaymentType.fixed ? 'Оклад за месяц' : 'Ставка за час'),
        if (employee.paymentType == PaymentType.hourly) ...[const SizedBox(height: 10), _numberField(hours, 'Отработанные часы')],
        const SizedBox(height: 10), _numberField(bonus, 'Премии'),
        const SizedBox(height: 10), _numberField(vacation, 'Отпускные'),
        const SizedBox(height: 10), TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Комментарий')),
      ]))),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(onPressed: () { final nums = [rate, hours, bonus, vacation].map((c) => c.text.trim().isEmpty ? 0.0 : double.tryParse(c.text.replaceAll(',', '.'))).toList(); if (nums.any((n) => n == null || n < 0)) return; Navigator.pop(ctx, true); }, child: const Text('Сохранить'))],
    ));
    if (saved == true) {
      double val(TextEditingController c) => c.text.trim().isEmpty ? 0 : double.parse(c.text.replaceAll(',', '.'));
      await widget.manager.saveMonthlyRecord(employee.id, period, MonthlyRecord(
        workedHours: val(hours), bonus: val(bonus), vacationPay: val(vacation), note: note.text.trim(), rateOverride: val(rate),
      ));
    }
    for (final c in [hours, bonus, vacation, rate, note]) { c.dispose(); }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: widget.manager, builder: (context, _) {
    final matches = widget.manager.employees.where((e) => e.id == widget.employeeId);
    if (matches.isEmpty) return const Scaffold(body: Center(child: Text('Сотрудник удалён')));
    final e = matches.first; final r = e.records[period]; final amount = widget.manager.salaryFor(e, period);
    return Scaffold(appBar: AppBar(title: const Text('Карточка сотрудника'), actions: [PopupMenuButton<String>(onSelected: (v) async { if (v == 'delete') { await widget.manager.deleteEmployee(e.id); if (mounted) Navigator.pop(context); } else if (v == 'edit') { await _editEmployee(e); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Редактировать')), PopupMenuItem(value: 'delete', child: Text('Удалить сотрудника'))])]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => recordDialog(e), icon: const Icon(Icons.edit_calendar), label: const Text('Внести данные')),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 100), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.bold)), const SizedBox(height: 5),
          Text('${e.paymentType.label} · ${money(e.rate)} ${e.paymentType == PaymentType.hourly ? 'за час' : 'в месяц'}', style: const TextStyle(color: Colors.black54)),
          const Divider(height: 26), const Text('Начислено за период', style: TextStyle(color: Colors.black54)),
          Text(money(amount), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        ]))),
        Card(child: Column(children: [ListTile(leading: const Icon(Icons.calendar_month), title: Text(monthTitle(selected), style: const TextStyle(fontWeight: FontWeight.w600)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month - 1)), icon: const Icon(Icons.chevron_left)), IconButton(onPressed: () => setState(() => selected = DateTime(selected.year, selected.month + 1)), icon: const Icon(Icons.chevron_right))])),
          const Divider(height: 1),
          if (e.paymentType == PaymentType.hourly) _infoRow('Отработанные часы', '${money(r?.workedHours ?? 0)} ч'),
          _infoRow(e.paymentType == PaymentType.fixed ? 'Оклад за месяц' : 'Ставка за час', money(r?.rateOverride ?? (r == null ? 0 : e.rate))),
          _infoRow('Премии', money(r?.bonus ?? 0)), _infoRow('Отпускные', money(r?.vacationPay ?? 0)),
          if ((r?.note ?? '').isNotEmpty) _infoRow('Комментарий', r!.note),
          if (r == null) const Padding(padding: EdgeInsets.all(16), child: Text('За этот месяц данные ещё не внесены. Начисление — 0.', style: TextStyle(color: Colors.black54))),
        ])),
        const Padding(padding: EdgeInsets.only(top: 12), child: Text('История начислений', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
        ..._historyTiles(e),
      ]),
    );
  });

  List<Widget> _historyTiles(Employee e) {
    final keys = e.records.keys.toList()..sort((a,b) => _periodSort(b).compareTo(_periodSort(a)));
    return keys.map((key) => Card(child: ListTile(dense: true, leading: const Icon(Icons.receipt_long_outlined), title: Text(key), trailing: Text(money(widget.manager.salaryFor(e, key)), style: const TextStyle(fontWeight: FontWeight.w600)), onTap: () { final p = key.split('-'); setState(() { selected = DateTime(int.parse(p[1]), int.parse(p[0])); }); }))).toList();
  }

  Future<void> _editEmployee(Employee e) async {
    final name = TextEditingController(text: e.name); final rate = TextEditingController(text: e.rate.toString()); var type = e.paymentType;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) => AlertDialog(title: const Text('Редактировать сотрудника'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: name, decoration: const InputDecoration(labelText: 'ФИО')), const SizedBox(height: 10), DropdownButtonFormField<PaymentType>(value: type, items: PaymentType.values.map((v) => DropdownMenuItem(value: v, child: Text(v.label))).toList(), onChanged: (v) { if (v != null) setLocal(() => type = v); }), const SizedBox(height: 10), _numberField(rate, 'Ставка / оклад')]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')), FilledButton(onPressed: () { if (name.text.trim().isNotEmpty && double.tryParse(rate.text.replaceAll(',', '.')) != null) Navigator.pop(ctx, true); }, child: const Text('Сохранить'))])));
    if (ok == true) await widget.manager.updateEmployee(e.copyWith(name: name.text.trim(), rate: double.parse(rate.text.replaceAll(',', '.')), paymentType: type));
    name.dispose(); rate.dispose();
  }
}

Widget _numberField(TextEditingController c, String label) => TextField(controller: c, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: label));
Widget _infoRow(String label, String value) => Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: [Expanded(child: Text(label, style: const TextStyle(color: Colors.black54))), Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)))]));
int _periodSort(String key) { final p = key.split('-'); if (p.length != 2) return 0; return int.tryParse(p[1] + p[0]) ?? 0; }
