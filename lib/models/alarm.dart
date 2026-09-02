/// アラームの繰り返し曜日は [DateTime.monday]〜[DateTime.sunday] (1〜7) で表す。
/// [repeatDays] が空の場合は次に来る指定時刻に1回だけ鳴る単発アラームとなる。
class Alarm {
  final String id;
  final int notificationBaseId;
  final int hour;
  final int minute;
  final String label;
  final bool isEnabled;
  final Set<int> repeatDays;

  const Alarm({
    required this.id,
    required this.notificationBaseId,
    required this.hour,
    required this.minute,
    this.label = '',
    this.isEnabled = true,
    this.repeatDays = const {},
  });

  Alarm copyWith({
    int? hour,
    int? minute,
    String? label,
    bool? isEnabled,
    Set<int>? repeatDays,
  }) {
    return Alarm(
      id: id,
      notificationBaseId: notificationBaseId,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'notificationBaseId': notificationBaseId,
      'hour': hour,
      'minute': minute,
      'label': label,
      'isEnabled': isEnabled,
      'repeatDays': repeatDays.toList(),
    };
  }

  factory Alarm.fromJson(Map<String, dynamic> json) {
    return Alarm(
      id: json['id'] as String,
      notificationBaseId: json['notificationBaseId'] as int,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      label: json['label'] as String? ?? '',
      isEnabled: json['isEnabled'] as bool? ?? true,
      repeatDays: ((json['repeatDays'] as List<dynamic>?) ?? const [])
          .map((e) => e as int)
          .toSet(),
    );
  }
}
