class CreateCustomerInput {
  final String customerId;
  final String customerName;
  final String street;
  final String street2;
  final String city;
  final String zip;
  final String mobile;
  final String vat;
  final double openBalance;

  const CreateCustomerInput({
    required this.customerId,
    required this.customerName,
    this.street = '',
    this.street2 = '',
    this.city = '',
    this.zip = '',
    required this.mobile,
    this.vat = '',
    this.openBalance = 0.0,
  });

  Map<String, dynamic> toOdooParams() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'street': street,
      'street2': street2,
      'city': city,
      'zip': zip,
      'mobile': mobile,
      'vat': vat,
      'open_balance': openBalance == openBalance.roundToDouble()
          ? openBalance.toInt()
          : openBalance,
    };
  }
}

class CreateCustomerResult {
  final bool success;
  final String? msg;
  final String? error;

  const CreateCustomerResult({
    required this.success,
    this.msg,
    this.error,
  });

  factory CreateCustomerResult.fromOdooResult(Map<String, dynamic> result) {
    return CreateCustomerResult(
      success: result['success'] == true,
      msg: result['msg']?.toString() ?? result['message']?.toString(),
      error: result['error']?.toString(),
    );
  }
}

class OdooCustomer {
  final String customerId;
  final String name;
  final String mobile;
  final String street;
  final String street2;
  final String city;
  final String zip;
  final String vat;
  final double openBalance;
  final double outstandingBalance;
  final double availableBalance;
  final double creditPeriod;
  final int? companyId;
  final String? companyName;
  final String? email;
  final DateTime createdAt;

  const OdooCustomer({
    required this.customerId,
    required this.name,
    required this.mobile,
    this.street = '',
    this.street2 = '',
    this.city = '',
    this.zip = '',
    this.vat = '',
    this.openBalance = 0.0,
    this.outstandingBalance = 0.0,
    this.availableBalance = 0.0,
    this.creditPeriod = 0.0,
    this.companyId,
    this.companyName,
    this.email,
    required this.createdAt,
  });

  factory OdooCustomer.fromInput(CreateCustomerInput input) {
    return OdooCustomer(
      customerId: input.customerId,
      name: input.customerName,
      mobile: input.mobile,
      street: input.street,
      street2: input.street2,
      city: input.city,
      zip: input.zip,
      vat: input.vat,
      openBalance: input.openBalance,
      outstandingBalance: 0.0,
      availableBalance: input.openBalance,
      createdAt: DateTime.now(),
    );
  }

  factory OdooCustomer.fromJson(Map<String, dynamic> json) {
    final rawId = json['customer_id'] ?? json['id'] ?? '';
    final customerId = rawId.toString();
    final name = (json['name'] as String? ?? 'Unnamed Customer').trim();

    final phoneVal = json['phone'] ?? json['mobile'];
    final mobile = phoneVal is String ? phoneVal.trim() : '';

    final vatVal = json['vat_number'] ?? json['vat'];
    final vat = vatVal is String ? vatVal.trim() : '';

    final emailVal = json['email'];
    final email = emailVal is String ? emailVal.trim() : null;

    final companyIdVal = json['company_id'];
    final companyId = companyIdVal is int
        ? companyIdVal
        : (companyIdVal is num ? companyIdVal.toInt() : null);

    final companyVal = json['company'];
    final companyName = companyVal is String ? companyVal.trim() : null;

    final creditPeriod = (json['credit_period'] as num?)?.toDouble() ?? 0.0;
    final outstanding = (json['outstanding_balance'] as num?)?.toDouble() ?? 0.0;
    final available = (json['available_balance'] as num?)?.toDouble() ?? 0.0;
    final openBal = (json['open_balance'] as num?)?.toDouble() ?? available;

    String street = '';
    String city = '';
    String country = '';

    if (json['address'] is List) {
      final addr = json['address'] as List;
      if (addr.isNotEmpty && addr[0] is String) street = (addr[0] as String).trim();
      if (addr.length > 1 && addr[1] is String) city = (addr[1] as String).trim();
      if (addr.length > 2 && addr[2] is String) country = (addr[2] as String).trim();
    } else {
      street = json['street'] is String ? (json['street'] as String).trim() : '';
      city = json['city'] is String ? (json['city'] as String).trim() : '';
      country = json['street2'] is String ? (json['street2'] as String).trim() : '';
    }

    final zip = json['zip'] is String ? (json['zip'] as String).trim() : '';

    return OdooCustomer(
      customerId: customerId,
      name: name,
      mobile: mobile,
      street: street,
      street2: country,
      city: city,
      zip: zip,
      vat: vat,
      openBalance: openBal,
      outstandingBalance: outstanding,
      availableBalance: available,
      creditPeriod: creditPeriod,
      companyId: companyId,
      companyName: companyName,
      email: email,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'name': name,
        'phone': mobile,
        'vat_number': vat,
        'credit_period': creditPeriod,
        'outstanding_balance': outstandingBalance,
        'available_balance': availableBalance,
        'company_id': companyId,
        'company': companyName,
        'email': email,
        'address': [street, city, street2],
      };
}
