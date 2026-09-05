class Sale {
  final int? id;
  final String billNumber;
  final int? customerId;
  final int? staffId;

  final double subtotal;
  final double discount;
  final double gst;
  final double grandTotal;

  final String paymentMethod;
  final String paymentStatus;
  final String createdAt;

  Sale({
    this.id,
    required this.billNumber,
    this.customerId,
    this.staffId,
    required this.subtotal,
    required this.discount,
    required this.gst,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'billNumber': billNumber,
      'customerId': customerId,
      'staffId': staffId,
      'subtotal': subtotal,
      'discount': discount,
      'gst': gst,
      'grandTotal': grandTotal,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'createdAt': createdAt,
    };
  }

  factory Sale.fromMap(
      Map<String, dynamic> map,
      ) {
    return Sale(
      id: map['id'],
      billNumber:
      map['billNumber']?.toString() ?? '',
      customerId: map['customerId'],
      staffId: map['staffId'],

      subtotal:
      (map['subtotal'] as num?)
          ?.toDouble() ??
          0,

      discount:
      (map['discount'] as num?)
          ?.toDouble() ??
          0,

      gst:
      (map['gst'] as num?)
          ?.toDouble() ??
          0,

      grandTotal:
      (map['grandTotal'] as num?)
          ?.toDouble() ??
          0,

      paymentMethod:
      map['paymentMethod']?.toString() ??
          'Cash',

      paymentStatus:
      map['paymentStatus']?.toString() ??
          'Paid',

      createdAt:
      map['createdAt']?.toString() ?? '',
    );
  }
}