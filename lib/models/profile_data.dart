class ProfileData {
  const ProfileData({
    required this.firstName,
    required this.lastName,
    required this.studentId,
    required this.yearLevel,
    required this.program,
    required this.schoolEmail,
    required this.personalEmail,
    required this.role,
  });

  final String firstName;
  final String lastName;
  final String studentId;
  final String yearLevel;
  final String program;
  final String schoolEmail;
  final String personalEmail;
  final String role;

  bool get isAlumni => role.toLowerCase() == 'alumni';

  String get fullName {
    final combined = '${firstName.trim()} ${lastName.trim()}'.trim();
    return combined.isEmpty ? 'Unknown' : combined;
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    String readString(String key) {
      final value = json[key];
      if (value is String) return value.trim();
      return '';
    }

    final personalEmail = readString('personalEmail');
    final email = readString('email');
    final role = readString('role');

    return ProfileData(
      firstName: readString('firstName'),
      lastName: readString('lastName'),
      studentId: readString('studentId'),
      yearLevel: readString('yearLevel'),
      program: readString('program'),
      schoolEmail: readString('schoolEmail'),
      personalEmail: personalEmail.isNotEmpty ? personalEmail : email,
      role: role.isNotEmpty ? role : 'alumni',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'studentId': studentId.trim(),
      'yearLevel': yearLevel.trim(),
      'program': program.trim(),
      'schoolEmail': schoolEmail.trim(),
      'personalEmail': personalEmail.trim(),
    };
  }
}
