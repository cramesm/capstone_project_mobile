import 'dart:convert';
import 'dart:typed_data';

import 'package:capstone_project/constants.dart';
import 'package:capstone_project/models/profile_data.dart';
import 'package:http/http.dart' as http;

class MongoDataApiService {
  MongoDataApiService._();

  static final MongoDataApiService instance = MongoDataApiService._();
  static const Duration _timeout = Duration(seconds: 12);

  String? _accessToken;
  String? _refreshToken;
  String? _currentEmail;
  DateTime? _accessTokenExpiresAt;

  Uri _uri(String path) => Uri.parse('$AUTH_API_BASE_URL$path');

  bool get hasSession => _accessToken != null && _refreshToken != null;
  String? get accessToken => _accessToken;
  DateTime? get accessTokenExpiresAt => _accessTokenExpiresAt;

  Map<String, String> authHeaders() {
    if (_accessToken == null) return const {};
    return {'Authorization': 'Bearer $_accessToken'};
  }

  Future<_ApiResponse> _postJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      headers.addAll(authHeaders());
    }

    final response = await http
        .post(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    return _decodeResponse(response);
  }

  Future<_ApiResponse> _getJson(String path, {bool withAuth = false}) async {
    final headers = <String, String>{};
    if (withAuth) {
      headers.addAll(authHeaders());
    }

    final response =
        await http.get(_uri(path), headers: headers).timeout(_timeout);
    return _decodeResponse(response);
  }

  Future<_ApiResponse> _putJson(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withAuth) {
      headers.addAll(authHeaders());
    }

    final response = await http
        .put(
          _uri(path),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    return _decodeResponse(response);
  }

  _ApiResponse _decodeResponse(http.Response response) {
    if (response.body.isEmpty) {
      return _ApiResponse(response.statusCode, const {});
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return _ApiResponse(response.statusCode, decoded);
      }
    } catch (_) {}

    return _ApiResponse(response.statusCode, const {});
  }

  String _messageFor(Map<String, dynamic> data, String fallback) {
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  void _clearSession() {
    _accessToken = null;
    _refreshToken = null;
    _currentEmail = null;
    _accessTokenExpiresAt = null;
  }

  void _applySession(Map<String, dynamic> data, {String? emailFallback}) {
    final accessToken = data['accessToken']?.toString().trim() ?? '';
    final refreshToken = data['refreshToken']?.toString().trim() ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw Exception('Missing session tokens.');
    }

    _accessToken = accessToken;
    _refreshToken = refreshToken;

    final user = data['user'];
    if (user is Map) {
      final email = user['email'];
      if (email is String && email.trim().isNotEmpty) {
        _currentEmail = email.trim();
      }
    }

    if ((_currentEmail == null || _currentEmail!.isEmpty) &&
        emailFallback != null) {
      _currentEmail = emailFallback.trim();
    }

    final expiresIn = data['expiresInSeconds'];
    if (expiresIn is num) {
      _accessTokenExpiresAt =
          DateTime.now().add(Duration(seconds: expiresIn.toInt()));
    }
  }

  Future<void> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? schoolEmail,
    String? studentId,
    String? yearLevel,
    String? program,
  }) async {
    final response = await _postJson('/auth/register', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'password': password.trim(),
      'schoolEmail': (schoolEmail ?? '').trim(),
      'studentId': (studentId ?? '').trim(),
      'yearLevel': (yearLevel ?? '').trim(),
      'program': (program ?? '').trim(),
    });

    if (response.statusCode == 201 && response.data['success'] == true) {
      return;
    }

    throw Exception(_messageFor(response.data, 'Registration failed.'));
  }

  Future<String?> requestRegisterOtp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String yearLevel,
    required String program,
  }) async {
    final response = await _postJson('/auth/register/request-otp', {
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'email': email.trim(),
      'password': password.trim(),
      'schoolEmail': '',
      'studentId': '',
      'yearLevel': yearLevel.trim(),
      'program': program.trim(),
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final otp = response.data['otp'];
      return otp == null ? null : otp.toString();
    }

    throw Exception(_messageFor(response.data, 'Failed to request OTP.'));
  }

  Future<void> verifyRegisterOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _postJson('/auth/register/verify-otp', {
      'email': email.trim(),
      'otp': otp.trim(),
    });

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        response.data['success'] == true) {
      return;
    }

    throw Exception(_messageFor(response.data, 'OTP verification failed.'));
  }

  Future<ProfileData> fetchProfile() async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final response = await _getJson('/profile', withAuth: true);
    if (response.statusCode == 200 && response.data['success'] == true) {
      final user = response.data['user'];
      if (user is Map<String, dynamic>) {
        final email = user['email'];
        if (email is String && email.trim().isNotEmpty) {
          _currentEmail = email.trim();
        }
        return ProfileData.fromJson(user);
      }
      throw Exception('Invalid profile response.');
    }

    throw Exception(_messageFor(response.data, 'Failed to load profile.'));
  }

  Future<ProfileData> updateProfile({
    required ProfileData profile,
    String? newPassword,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final body = profile.toJson();
    if (newPassword != null && newPassword.trim().isNotEmpty) {
      body['newPassword'] = newPassword.trim();
    }

    final response = await _putJson('/profile', body, withAuth: true);
    if (response.statusCode == 200 && response.data['success'] == true) {
      final user = response.data['user'];
      if (user is Map<String, dynamic>) {
        final email = user['email'];
        if (email is String && email.trim().isNotEmpty) {
          _currentEmail = email.trim();
        }
        return ProfileData.fromJson(user);
      }
      throw Exception('Invalid profile response.');
    }

    throw Exception(_messageFor(response.data, 'Failed to update profile.'));
  }

  Future<bool> login({
    required String email,
    required String password,
    String? role,
  }) async {
    _clearSession();
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password.trim(),
    };
    if (role != null && role.trim().isNotEmpty) {
      body['role'] = role.trim();
    }
    final response = await _postJson('/auth/login', body);

    if (response.statusCode == 200 && response.data['success'] == true) {
      _applySession(response.data, emailFallback: email);
      return true;
    }

    if (response.statusCode == 400 || response.statusCode == 401) {
      return false;
    }

    throw Exception(_messageFor(response.data, 'Login failed.'));
  }

  Future<void> refreshSession() async {
    final email = _currentEmail;
    final refreshToken = _refreshToken;

    if (email == null || email.isEmpty || refreshToken == null) {
      throw Exception('No refresh session available.');
    }

    final response = await _postJson('/auth/refresh', {
      'email': email,
      'refreshToken': refreshToken,
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      _applySession(response.data, emailFallback: email);
      return;
    }

    throw Exception(_messageFor(response.data, 'Session refresh failed.'));
  }

  Future<void> logout() async {
    final email = _currentEmail;
    final refreshToken = _refreshToken;
    _clearSession();

    if (email == null || refreshToken == null) {
      return;
    }

    try {
      await _postJson('/auth/logout', {
        'email': email,
        'refreshToken': refreshToken,
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>> uploadReceipt({
    required Uint8List bytes,
    required String fileName,
    required String paymentType,
    required String docName,
    required String purpose,
    double? amount,
    String? status,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final request = http.MultipartRequest('POST', _uri('/payments/receipt'));
    request.headers.addAll(authHeaders());
    request.fields['paymentType'] = paymentType;
    request.fields['docName'] = docName;
    request.fields['purpose'] = purpose;
    if (amount != null) {
      request.fields['amount'] = amount.toStringAsFixed(2);
    }
    if (status != null && status.trim().isNotEmpty) {
      request.fields['status'] = status.trim();
    }

    final safeName = fileName.trim().isEmpty ? 'receipt.jpg' : fileName.trim();
    request.files.add(
      http.MultipartFile.fromBytes(
        'receipt',
        bytes,
        filename: safeName,
      ),
    );

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeResponse(response);

    if (response.statusCode == 201 && decoded.data['success'] == true) {
      return decoded.data;
    }

    throw Exception(_messageFor(decoded.data, 'Failed to upload receipt.'));
  }

  Future<ProfileData> uploadProfilePhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final request = http.MultipartRequest('POST', _uri('/profile/photo'));
    request.headers.addAll(authHeaders());

    final safeName = fileName.trim().isEmpty ? 'profile.jpg' : fileName.trim();
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: safeName,
      ),
    );

    final streamed = await request.send().timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeResponse(response);

    if (response.statusCode == 201 && decoded.data['success'] == true) {
      final user = decoded.data['profile'];
      if (user is Map<String, dynamic>) {
        final email = user['email'];
        if (email is String && email.trim().isNotEmpty) {
          _currentEmail = email.trim();
        }
        return ProfileData.fromJson(user);
      }
      throw Exception('Invalid profile response.');
    }

    throw Exception(_messageFor(decoded.data, 'Failed to upload photo.'));
  }

  Future<Map<String, dynamic>> createDocumentRequest({
    required String docName,
    required String purpose,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final response = await _postJson(
      '/requests',
      {
        'docName': docName.trim(),
        'purpose': purpose.trim(),
      },
      withAuth: true,
    );

    if (response.statusCode == 201 && response.data['success'] == true) {
      return response.data;
    }

    throw Exception(_messageFor(response.data, 'Failed to submit request.'));
  }

  Future<List<Map<String, dynamic>>> fetchRequests({
    List<String>? statuses,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final filtered = (statuses ?? [])
        .map((status) => status.trim())
        .where((status) => status.isNotEmpty)
        .toList();

    final path = filtered.isEmpty
        ? '/requests'
        : '/requests?status=${Uri.encodeQueryComponent(filtered.join(','))}';

    final response = await _getJson(path, withAuth: true);
    if (response.statusCode == 200 && response.data['success'] == true) {
      final raw = response.data['requests'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    }

    throw Exception(_messageFor(response.data, 'Failed to load requests.'));
  }

  Future<Map<String, dynamic>?> fetchReceiptForRequest({
    required String docName,
    required String purpose,
  }) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final params = <String, String>{
      'docName': docName.trim(),
      'purpose': purpose.trim(),
    };
    final uri = _uri('/receipts').replace(queryParameters: params);
    final response = await http.get(uri, headers: authHeaders()).timeout(_timeout);
    final decoded = _decodeResponse(response);
    if (response.statusCode == 200 && decoded.data['success'] == true) {
      final receipt = decoded.data['receipt'];
      if (receipt is Map) {
        return Map<String, dynamic>.from(receipt);
      }
      return null;
    }

    throw Exception(_messageFor(decoded.data, 'Failed to load receipt.'));
  }

  Future<List<Map<String, dynamic>>> fetchNotifications({int limit = 50}) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final safeLimit = limit <= 0 ? 50 : limit;
    final response = await _getJson(
      '/notifications?limit=$safeLimit',
      withAuth: true,
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      final raw = response.data['notifications'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    }

    throw Exception(_messageFor(response.data, 'Failed to load notifications.'));
  }

  Future<List<Map<String, dynamic>>> fetchTransactions({int limit = 50}) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated.');
    }

    final safeLimit = limit <= 0 ? 50 : limit;
    final response = await _getJson(
      '/transactions?limit=$safeLimit',
      withAuth: true,
    );
    if (response.statusCode == 200 && response.data['success'] == true) {
      final raw = response.data['transactions'];
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      return [];
    }

    throw Exception(_messageFor(response.data, 'Failed to load transactions.'));
  }

  Future<String?> requestPasswordResetOtp({required String email}) async {
    final response = await _postJson('/auth/forgot-password/request-otp', {
      'email': email.trim(),
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final otp = response.data['otp'];
      return otp == null ? null : otp.toString();
    }

    throw Exception(
      _messageFor(response.data, 'Failed to request password reset OTP.'),
    );
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final response = await _postJson('/auth/forgot-password/verify-otp', {
      'email': email.trim(),
      'otp': otp.trim(),
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      final resetToken = response.data['resetToken'];
      if (resetToken is String && resetToken.trim().isNotEmpty) {
        return resetToken;
      }
      throw Exception('Missing reset token.');
    }

    throw Exception(_messageFor(response.data, 'OTP verification failed.'));
  }

  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _postJson('/auth/forgot-password/reset', {
      'resetToken': resetToken.trim(),
      'newPassword': newPassword.trim(),
    });

    if (response.statusCode == 200 && response.data['success'] == true) {
      return;
    }

    throw Exception(_messageFor(response.data, 'Password reset failed.'));
  }
}

class _ApiResponse {
  _ApiResponse(this.statusCode, this.data);

  final int statusCode;
  final Map<String, dynamic> data;
}
