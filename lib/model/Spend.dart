class Spend {
  static int _nextId = 0;

  final int id;
  DateTime dateTime;
  double amount;
  String info;

  Spend({
    required this.dateTime,
    required this.amount,
    this.info = '',
  }) : id = _nextId++;

  Spend.withId({
    required this.id,
    required this.dateTime,
    required this.amount,
    this.info = '',
  });

  factory Spend.fromMap(Map<String, dynamic> map) {
    final spend = Spend.withId(
      id: map['id'],
      dateTime: DateTime.parse(map['dateTime']),
      amount: map['amount'],
      info: map['info'] ?? '',
    );

    if (spend.id >= _nextId) {
      _nextId = spend.id + 1;
    }

    return spend;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dateTime': dateTime.toIso8601String(),
      'amount': amount,
      'info': info,
    };
  }
}
