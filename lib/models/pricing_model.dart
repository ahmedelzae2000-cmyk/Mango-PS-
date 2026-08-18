class PricingModel {
  double ps4SingleRate;
  double ps4MultiRate;
  double ps5SingleRate;
  double ps5MultiRate;

  PricingModel({
    this.ps4SingleRate = 30.0,
    this.ps4MultiRate = 40.0,
    this.ps5SingleRate = 50.0,
    this.ps5MultiRate = 70.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'ps4SingleRate': ps4SingleRate,
      'ps4MultiRate': ps4MultiRate,
      'ps5SingleRate': ps5SingleRate,
      'ps5MultiRate': ps5MultiRate,
    };
  }

  factory PricingModel.fromMap(Map<String, dynamic> map) {
    return PricingModel(
      ps4SingleRate: (map['ps4SingleRate'] ?? 30.0).toDouble(),
      ps4MultiRate: (map['ps4MultiRate'] ?? 40.0).toDouble(),
      ps5SingleRate: (map['ps5SingleRate'] ?? 50.0).toDouble(),
      ps5MultiRate: (map['ps5MultiRate'] ?? 70.0).toDouble(),
    );
  }
}
