class TrapModel {
  final String trapId;
  final String trapName;
  bool isActive;

  // optional — for live feed phase
  final String? localIp;
  final String? rtspUrl;

  TrapModel({
    required this.trapId,
    this.trapName = 'Trap',
    this.isActive = false,
    this.localIp,
    this.rtspUrl,
  });

  factory TrapModel.fromJson(Map<String, dynamic> json) {
    return TrapModel(
      trapId: (json['trap_id'] ?? json['trapId'] ?? '').toString(),
      trapName:
      (json['trap_name'] ?? json['trapName'] ?? 'Trap').toString(),
      isActive:
      (json['status'] ?? 'inactive')
          .toString()
          .toLowerCase() ==
          'active',

      // SAFE optional reads
      localIp: json['local_ip']?.toString(),
      rtspUrl: json['rtsp_url']?.toString(),
    );
  }
}