import 'dart:convert';

class House {
  final String id;
  final String userId;
  final String name;
  final List<Flat> flats;

  House({
    required this.id,
    required this.userId,
    required this.name,
    this.flats = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'flats': flats.map((x) => x.toMap()).toList(),
    };
  }

  factory House.fromMap(Map<String, dynamic> map) {
    return House(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      name: map['name'] ?? '',
      flats: map['flats'] != null
          ? List<Flat>.from(map['flats']?.map((x) => Flat.fromMap(x)))
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory House.fromJson(String source) => House.fromMap(json.decode(source));
}

class Flat {
  final String id;
  final String houseId;
  final String number;
  final double basicRent;
  final double gasBill;
  final double utilityBill;
  final double waterCharges;

  Flat({
    required this.id,
    required this.houseId,
    required this.number,
    this.basicRent = 0.0,
    this.gasBill = 0.0,
    this.utilityBill = 0.0,
    this.waterCharges = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'house_id': houseId,
      'number': number,
      'basic_rent': basicRent,
      'gas_bill': gasBill,
      'utility_bill': utilityBill,
      'water_charges': waterCharges,
    };
  }

  factory Flat.fromMap(Map<String, dynamic> map) {
    return Flat(
      id: map['id'] ?? '',
      houseId: map['house_id'] ?? '',
      number: map['number'] ?? '',
      basicRent: (map['basic_rent'] ?? 0.0).toDouble(),
      gasBill: (map['gas_bill'] ?? 0.0).toDouble(),
      utilityBill: (map['utility_bill'] ?? 0.0).toDouble(),
      waterCharges: (map['water_charges'] ?? 0.0).toDouble(),
    );
  }

  String toJson() => json.encode(toMap());

  factory Flat.fromJson(String source) => Flat.fromMap(json.decode(source));
}
