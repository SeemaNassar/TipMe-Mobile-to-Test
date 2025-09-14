class FcmTokenDto {
  final String token;
  FcmTokenDto({
    required this.token
  });

  factory FcmTokenDto.fromJson(Map<String, dynamic> json) {
    return FcmTokenDto(
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
    };
  }
}