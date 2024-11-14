class SentinelsQsrInfo {

  SentinelsQsrInfo({
    required this.cost,
    required this.deposit,
  });

  factory SentinelsQsrInfo.fromJson(Map<String, dynamic> json) {
      return SentinelsQsrInfo(
        cost: BigInt.parse(json['cost'] as String),
        deposit: BigInt.parse(json['deposit'] as String),
      );
  }

  final BigInt cost;
  final BigInt deposit;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'cost': cost.toString(),
      'deposit': deposit.toString(),
    };
  }
}
