import 'sales_model.dart';

/// Odoo Company / Branch model returned by POST /api/get_company_data
class OdooCompany {
  final int id;
  final String name;

  const OdooCompany({
    required this.id,
    required this.name,
  });

  factory OdooCompany.fromJson(Map<String, dynamic> json) {
    return OdooCompany(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: (json['name'] as String? ?? '').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  /// Converts this company into an [OutletInfo] for branch selection across the app
  OutletInfo toOutletInfo() {
    final formattedName = name;
    String short = formattedName;
    if (short.length > 20) {
      short = '${short.substring(0, 17)}...';
    }

    return OutletInfo(
      id: id.toString(),
      name: formattedName,
      shortName: short,
      location: '',
      posTerminalId: '',
      isOnline: true,
    );
  }

  @override
  String toString() => 'OdooCompany(id: $id, name: $name)';
}
