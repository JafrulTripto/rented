import 'dart:convert';

class RentPayment {
  final String? id;
  final String tenantId;
  final String month;
  final int year;
  final double basicRent;
  final double gasBill;
  final double electricityBill;
  final double utilityBill;
  final double waterCharges;
  final double? totalPaid;
  final DateTime? paymentDate;
  final DateTime? createdAt;

  RentPayment({
    this.id,
    required this.tenantId,
    required this.month,
    required this.year,
    required this.basicRent,
    required this.gasBill,
    required this.electricityBill,
    required this.utilityBill,
    required this.waterCharges,
    this.totalPaid,
    this.paymentDate,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tenant_id': tenantId,
      'month': month,
      'year': year,
      'basic_rent': basicRent,
      'gas_bill': gasBill,
      'electricity_bill': electricityBill,
      'utility_bill': utilityBill,
      'water_charges': waterCharges,
    };
  }

  factory RentPayment.fromMap(Map<String, dynamic> map) {
    return RentPayment(
      id: map['id'],
      tenantId: map['tenant_id'] ?? '',
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      basicRent: (map['basic_rent'] ?? 0.0).toDouble(),
      gasBill: (map['gas_bill'] ?? 0.0).toDouble(),
      electricityBill: (map['electricity_bill'] ?? 0.0).toDouble(),
      utilityBill: (map['utility_bill'] ?? 0.0).toDouble(),
      waterCharges: (map['water_charges'] ?? 0.0).toDouble(),
      totalPaid: (map['total_paid'] ?? 0.0).toDouble(),
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'])
          : (map['created_at'] != null
                ? DateTime.parse(map['created_at'])
                : null),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory RentPayment.fromJson(String source) =>
      RentPayment.fromMap(json.decode(source));
}
