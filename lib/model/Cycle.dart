import 'package:cash_cache/model/Spend.dart';

class Cycle {
  static int _nextId = 0;

  final int id;
  String name;
  DateTime startDate;
  DateTime endDate;

  double budget;
  List<String> categories = [];
  Map<String, List<Spend>> spends = {};

  Cycle({
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.budget,
  }) : id = _nextId++;

  Cycle.withId({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.budget,
  });

  double get totalSpent {
    double total = 0;
    for (var spendList in spends.values) {
      for (var spend in spendList) {
        total += spend.amount;
      }
    }
    return total;
  }

  factory Cycle.fromMap(Map<String, dynamic> map) {
    final cycle = Cycle.withId(
      id: map['id'],
      name: map['name'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      budget: map['budget'],
    );

    if (map['categories'] != null) {
      cycle.categories = List<String>.from(map['categories']);
    }

    if (map['spends'] != null) {
      final rawSpends = Map<String, dynamic>.from(map['spends']);
      cycle.spends = rawSpends.map(
        (key, value) {
          // value should be a List<dynamic>
          final spendList = List<Map<String, dynamic>>.from(value);
          return MapEntry(
            key,
            spendList.map((spend) => Spend.fromMap(spend)).toList(),
          );
        },
      );
    }

    if (cycle.id >= _nextId) {
      _nextId = cycle.id + 1;
    }

    return cycle;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'budget': budget,
      'categories': categories,
      'spends': spends.map(
        (k, v) => MapEntry(
          k,
          v.map((spend) => spend.toMap()).toList(),
        ),
      ),
    };
  }
}
