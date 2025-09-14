// lib/viewModels/privacyPolicyData.dart
class PrivacyPolicyData {
  final String title;
  final String description;
  final int number;
  final bool isNumbered;

  PrivacyPolicyData({
    required this.title,
    required this.description,
    required this.number,
    this.isNumbered = true,
  });

  factory PrivacyPolicyData.fromJson(Map<String, dynamic> json) {
    return PrivacyPolicyData(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      number: json['number'] ?? 1,
      isNumbered: json['isNumbered'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'number': number,
    'isNumbered': isNumbered,
  };
}