class BudgetItem {
  final int? id;
  final String description;
  final double amount;
  final String type;
  final int month;
  final int year;
  final String createdAt;

  BudgetItem({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.month,
    required this.year,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'month': month,
      'year': year,
      'createdAt': createdAt,
    };
  }

  factory BudgetItem.fromMap(Map<String, dynamic> map) {
    return BudgetItem(
      id: map['id'] as int?,
      description: map['description'] as String,
      amount: map['amount'] as double,
      type: map['type'] as String,
      month: map['month'] as int,
      year: map['year'] as int,
      createdAt: map['createdAt'] as String,
    );
  }
}
