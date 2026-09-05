class SalesReturn {
  final int? id;
  final String returnNumber;
  final int saleId;
  final int? customerId;
  final int? staffId;
  final double totalAmount;
  final String refundMethod;
  final String? reason;
  final String createdAt;

  SalesReturn({
    this.id,
    required this.returnNumber,
    required this.saleId,
    this.customerId,
    this.staffId,
    required this.totalAmount,
    required this.refundMethod,
    this.reason,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnNumber': returnNumber,
      'saleId': saleId,
      'customerId': customerId,
      'staffId': staffId,
      'totalAmount': totalAmount,
      'refundMethod': refundMethod,
      'reason': reason,
      'createdAt': createdAt,
    };
  }

  factory SalesReturn.fromMap(
      Map<String, dynamic> map,
      ) {
    return SalesReturn(
      id: map['id'],
      returnNumber:
      map['returnNumber']?.toString() ?? '',
      saleId:
      (map['saleId'] as num?)?.toInt() ?? 0,
      customerId:
      (map['customerId'] as num?)?.toInt(),
      staffId:
      (map['staffId'] as num?)?.toInt(),
      totalAmount:
      (map['totalAmount'] as num?)
          ?.toDouble() ??
          0,
      refundMethod:
      map['refundMethod']?.toString() ??
          'Cash',
      reason:
      map['reason']?.toString(),
      createdAt:
      map['createdAt']?.toString() ?? '',
    );
  }
}