enum GameMode { single, multi }
enum PaymentMethod { cash, visa }

class Device {
  final String id;
  final String name;
  final String type;
  bool isOccupied;

  Device({
    required this.id,
    required this.name,
    required this.type,
    this.isOccupied = false,
  });
}
