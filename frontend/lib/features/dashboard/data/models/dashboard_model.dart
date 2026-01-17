class TenantDue {
  final String tenantName;
  final String tenantId;
  final String flatNo;
  final double dueAmount;
  final String? month;

  TenantDue({
    required this.tenantName,
    required this.tenantId,
    required this.flatNo,
    required this.dueAmount,
    this.month,
  });

  factory TenantDue.fromMap(Map<String, dynamic> map) {
    return TenantDue(
      tenantName: map['tenant_name'] ?? '',
      tenantId: map['tenant_id'] ?? '',
      flatNo: map['flat_no'] ?? '',
      dueAmount: (map['due_amount'] ?? 0).toDouble(),
      month: map['month'],
    );
  }
}

class DashboardStats {
  final double totalRevenue;
  final double totalDue;
  final int collectedCount;
  final int totalFlats;
  final int occupiedFlats;
  final List<TenantDue> topDues;

  DashboardStats({
    required this.totalRevenue,
    required this.totalDue,
    required this.collectedCount,
    required this.totalFlats,
    required this.occupiedFlats,
    required this.topDues,
  });

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalRevenue: (map['total_revenue'] ?? 0).toDouble(),
      totalDue: (map['total_due'] ?? 0).toDouble(),
      collectedCount: map['collected_count'] ?? 0,
      totalFlats: map['total_flats'] ?? 0,
      occupiedFlats: map['occupied_flats'] ?? 0,
      topDues: List<TenantDue>.from(
        (map['top_dues'] ?? []).map((x) => TenantDue.fromMap(x)),
      ),
    );
  }
}
