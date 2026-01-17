import 'dart:convert';
import 'package:frontend/features/house/data/models/house_model.dart';

class Tenant {
  final String? id;
  final String? userId;
  final String houseId;
  final String flatId;
  final String name;
  final String phone;
  final String? nidNumber;
  final String? nidFrontUrl;
  final String? nidBackUrl;
  final bool isActive;
  final DateTime? joinDate;
  final double advanceAmount;
  final double dueAmount; // From calculated response
  final String? houseName;
  final String? flatNumber;
  final DateTime? createdAt;
  final Flat? flat;

  Tenant({
    this.id,
    this.userId,
    required this.houseId,
    required this.flatId,
    required this.name,
    required this.phone,
    this.nidNumber,
    this.nidFrontUrl,
    this.nidBackUrl,
    this.isActive = true,
    this.joinDate,
    this.advanceAmount = 0.0,
    this.dueAmount = 0.0,
    this.houseName,
    this.flatNumber,
    this.createdAt,
    this.flat,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'house_id': houseId,
      'flat_id': flatId,
      'name': name,
      'phone': phone,
      'nid_number': nidNumber,
      'nid_front_url': nidFrontUrl,
      'nid_back_url': nidBackUrl,
      'is_active': isActive,
      'join_date': joinDate?.toIso8601String(),
      'advance_amount': advanceAmount,
      if (flat != null) 'flat': flat!.toMap(),
    };
  }

  factory Tenant.fromMap(Map<String, dynamic> map) {
    return Tenant(
      id: map['id'],
      userId: map['user_id'],
      houseId: map['house_id'] ?? '',
      flatId: map['flat_id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      nidNumber: map['nid_number'],
      nidFrontUrl: map['nid_front_url'],
      nidBackUrl: map['nid_back_url'],
      isActive: map['is_active'] ?? true,
      joinDate: map['join_date'] != null
          ? DateTime.parse(map['join_date'])
          : null,
      advanceAmount: (map['advance_amount'] ?? 0.0).toDouble(),
      dueAmount: (map['due_amount'] ?? 0.0).toDouble(),
      houseName: map['house_name'],
      flatNumber: map['flat_number'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      flat: map['flat'] != null ? Flat.fromMap(map['flat']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Tenant.fromJson(String source) => Tenant.fromMap(json.decode(source));
}
