/// Odoo Salesperson / Staff model returned by POST /api/get_salesperson_data
class OdooSalesperson {
  final int id;
  final String name;
  final int companyId;
  final String companyName;

  const OdooSalesperson({
    required this.id,
    required this.name,
    this.companyId = 0,
    this.companyName = '',
  });

  factory OdooSalesperson.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final idInt = rawId is int
        ? rawId
        : (rawId is num ? rawId.toInt() : int.tryParse(rawId?.toString() ?? '0') ?? 0);

    final rawCompanyId = json['company_id'];
    final companyIdInt = rawCompanyId is int
        ? rawCompanyId
        : (rawCompanyId is num
            ? rawCompanyId.toInt()
            : int.tryParse(rawCompanyId?.toString() ?? '0') ?? 0);

    final compName = (json['company_name'] as String? ?? '').trim();

    return OdooSalesperson(
      id: idInt,
      name: (json['name'] as String? ?? 'Staff').trim(),
      companyId: companyIdInt,
      companyName: compName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'company_id': companyId,
        'company_name': companyName,
      };

  @override
  String toString() => 'OdooSalesperson(id: $id, name: $name, company: $companyName)';
}
