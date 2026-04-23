class AppUser {
  const AppUser({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    this.phoneNumber,
    this.studentId,
    this.profileImageUrl,
  });

  final int id;
  final String firebaseUid;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final String? phoneNumber;
  final String? studentId;
  final String? profileImageUrl;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      firebaseUid: json['firebase_uid'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      phoneNumber: json['phone_number'] as String?,
      studentId: json['student_id'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}