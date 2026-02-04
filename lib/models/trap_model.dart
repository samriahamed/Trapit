class TrapModel {
  final String trapId;
  final String trapName;
  bool isActive;

  TrapModel({
    required this.trapId,
    required this.trapName,
    required this.isActive,
  });

  factory TrapModel.fromJson(Map<String, dynamic> json) {
    return TrapModel(
      trapId: json['trap_id'],
      trapName: json['trap_name'],
      isActive: json['status'] == 'active',
    );
  }
}
