/// Represents an incoming notification event captured from the SMS platform listener.
class RawNotification {
  final String key;
  final String packageName;
  final String title;
  final String text;
  final int postTime; // Epoch milliseconds
  final bool isSmsApp;

  const RawNotification({
    required this.key,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postTime,
    this.isSmsApp = false,
  });

  factory RawNotification.fromMap(Map<String, dynamic> map) {
    return RawNotification(
      key: map['key'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      text: map['text'] as String? ?? '',
      postTime:
          map['postTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      isSmsApp: map['isSmsApp'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
    'key': key,
    'packageName': packageName,
    'title': title,
    'text': text,
    'postTime': postTime,
    'isSmsApp': isSmsApp,
  };
}
