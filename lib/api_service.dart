import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class ApiService {
  // CONFIGURATION: Ganti '10.0.2.2' (emulator) dengan IP komputer Anda jika menggunakan HP fisik
  static const String serverIp = '172.16.70.27'; // IP komputer lokal
  static const int port = 3000;

  static String get baseUrl {
    if (kIsWeb) {
      if (Uri.base.host == 'localhost' || Uri.base.host == '127.0.0.1') {
        return 'http://localhost:$port/api';
      }
      return 'https://tenungeza-backend.vercel.app/api';
    }
    if (Platform.isAndroid) return 'http://$serverIp:$port/api';
    return 'http://localhost:$port/api';
  }

  static const Duration requestTimeout = Duration(seconds: 15);

  static String getFormattedImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      final base = baseUrl.replaceAll('/api', '');
      return '$base$url';
    }
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final base = baseUrl.replaceAll('/api', '');
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || 
          host == '127.0.0.1' || 
          host == '10.0.2.2' || 
          host.startsWith('172.') || 
          host.startsWith('192.') || 
          host.startsWith('10.')) {
        return '$base$path';
      }
    } catch (_) {}
    return url;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  static Future<void> setToken(String token, String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    await prefs.setString('user_role', role);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
  }

  static Future<String?> uploadImage(XFile imageFile) async {
    try {
      final token = await getToken();
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'));
      request.headers['Authorization'] = 'Bearer $token';
      
      final bytes = await imageFile.readAsBytes();
      final lower = imageFile.name.toLowerCase();
      final mimeSubtype = lower.endsWith('.png')
          ? 'png'
          : lower.endsWith('.webp')
              ? 'webp'
              : lower.endsWith('.gif')
                  ? 'gif'
                  : 'jpeg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: imageFile.name,
          contentType: MediaType('image', mimeSubtype),
        ),
      );

      var response = await request.send().timeout(requestTimeout);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        return jsonDecode(responseData)['url'];
      }
      return null;
    } catch (e) {
      print("Stability Error (Upload): $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['requires2FA'] == true) {
          return data;
        }
        await setToken(data['token'], data['user']?['role'] ?? 'USER');
        return data;
      } else {
        String msg = 'Gagal login (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Gagal login. ($e)');
    }
  }

  static Future<void> requestOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String msg = 'Gagal request OTP (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {
          msg = '$msg: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}';
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> requestPasswordResetOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String msg = 'Gagal request OTP (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {
          msg = '$msg: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}';
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<void> resetPasswordWithOtp(String email, String otp, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp, 'newPassword': newPassword}),
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String msg = 'Gagal reset password (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {
          msg = '$msg: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}';
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static Future<Map<String, dynamic>> register(String name, String email, String password, String phone, String otp, {String role = 'USER'}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'phone': phone, 'otp': otp, 'role': role}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) return jsonDecode(response.body);
      
      String msg = 'Gagal daftar (Status: ${response.statusCode})';
      try {
        final errorData = jsonDecode(response.body);
        msg = errorData['error'] ?? msg;
      } catch (_) {}
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal mendaftar. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat profil: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProfile(String name, String phone, String email, String birthDate) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'name': name, 'phone': phone, 'email': email, 'birthDate': birthDate}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        String msg = 'Gagal memperbarui profil (Status: ${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          msg = body['error'] ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Ralat sistem: $e');
    }
  }

  static Future<Map<String, dynamic>> toggle2fa() async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/users/2fa/toggle'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Gagal mengubah 2FA');
      }
    } catch (e) {
      throw Exception('Ralat sistem: $e');
    }
  }

  static Future<Map<String, dynamic>> verify2faLogin(String email, String otp) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/verify-2fa'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await setToken(data['token'], data['user']?['role'] ?? 'USER');
        }
        return data;
      } else {
        String msg = 'Gagal verifikasi (Status: ${response.statusCode})';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Gagal verifikasi. ($e)');
    }
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/users/change-password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String msg = 'Gagal menukar password';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>?;
          msg = body?['error']?.toString() ?? msg;
        } catch (_) {
          msg = '$msg (${response.statusCode})';
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Ralat: $e');
    }
  }

  static Future<List<dynamic>> getProducts() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products')).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat produk. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getProductDetail(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/products/$id')).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal memuat detail produk. ($e)');
    }
  }

  static Future<void> addProduct(String name, String description, int price, String imageUrl, int stock) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/products'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name, 'description': description, 'price': price, 'imageUrl': imageUrl, 'stock': stock
        })
      ).timeout(requestTimeout);
      if (response.statusCode != 200) throw Exception('Gagal simpan');
    } catch (e) {
      throw Exception('Gagal menambah produk. ($e)');
    }
  }

  static Future<void> updateProduct(int id, String name, String description, int price, String imageUrl, int stock, {String status = 'ACTIVE'}) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/products/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name, 'description': description, 'price': price, 'imageUrl': imageUrl, 'stock': stock, 'status': status
        }),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Update gagal. ($e)');
    }
  }

  static Future<void> deleteProduct(int id) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode != 200) throw Exception('Gagal hapus');
    } catch (e) {
      throw Exception('Penghapusan gagal. ($e)');
    }
  }

  static Future<void> toggleProductStatus(int id) async {
    try {
      final token = await getToken();
      await http.post(
        Uri.parse('$baseUrl/products/$id/toggle'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
    } catch (e) {
      throw Exception('Toggle status gagal. ($e)');
    }
  }

  static Future<Map<String, dynamic>> createOrder(List<Map<String, dynamic>> items, int totalPrice, {int dpAmount = 0}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'items': items, 'totalPrice': totalPrice, 'dpAmount': dpAmount}),
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal membuat pesanan. ($e)');
    }
  }

  static Future<List<dynamic>> getOrders() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal mendapatkan rekod pesanan. ($e)');
    }
  }

  static Future<void> cancelOrder(int id) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/orders/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      
      if (response.statusCode != 200) {
        String msg = 'Gagal membatalkan pesanan';
        try {
          final errorData = jsonDecode(response.body);
          msg = errorData['error'] ?? msg;
        } catch (_) {
          msg = '$msg (Status: ${response.statusCode})';
        }
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Ralat: $e');
    }
  }

  static Future<Map<String, dynamic>> getOrderById(int id) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/orders/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat detail pesanan: $e');
    }
  }

  static Future<void> updateTracking(int orderId, {String? courierName, String? awbNumber, String? trackingStatus}) async {
    try {
      final token = await getToken();
      final body = <String, dynamic>{};
      if (courierName != null) body['courierName'] = courierName;
      if (awbNumber != null) body['awbNumber'] = awbNumber;
      if (trackingStatus != null) body['trackingStatus'] = trackingStatus;
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$orderId/tracking'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(requestTimeout);
      
      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate tracking: ${response.body}');
      }
    } catch (e) {
      throw Exception('Ralat tracking: $e');
    }
  }

  static Future<void> updateOrderStatus(int id, String status, {String? paymentProofUrl, String? courierName, String? awbNumber}) async {
    try {
      final token = await getToken();
      final body = {'status': status};
      if (paymentProofUrl != null) {
        body['paymentProofUrl'] = paymentProofUrl;
      }
      if (courierName != null) {
        body['courierName'] = courierName;
      }
      if (awbNumber != null) {
        body['awbNumber'] = awbNumber;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/update-status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) throw Exception('Gagal mengemaskini status');
    } catch (e) {
      throw Exception('Ralat: $e');
    }
  }

  static Future<Map<String, dynamic>> getSellerStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/seller/stats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat data seller. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat data admin. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getCustomerStats() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/customer/stats'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Status ${response.statusCode}: ${response.body.length > 50 ? response.body.substring(0, 50) : response.body}');
      }
    } catch (e) {
      throw Exception('Gagal memuat data pelanggan. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getFinanceReport(DateTimeRange range) async {
    try {
      final token = await getToken();
      final from = Uri.encodeQueryComponent(range.start.toIso8601String());
      final to = Uri.encodeQueryComponent(range.end.toIso8601String());
      final response = await http.get(
        Uri.parse('$baseUrl/finance/report?from=$from&to=$to'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      String msg = 'Gagal memuat laporan keuangan';
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>?;
        msg = body?['error']?.toString() ?? msg;
      } catch (_) {
        msg = '$msg (Status: ${response.statusCode})';
      }
      throw Exception(msg);
    } catch (e) {
      throw Exception('Gagal memuat laporan keuangan. ($e)');
    }
  }

  static Future<List<dynamic>> getUsers() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal memuat pengguna. ($e)');
    }
  }

  static Future<void> addUser(String name, String email, String password, String phone, String role) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email, 'password': password, 'phone': phone, 'role': role}),
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String msg = 'Gagal tambah user';
        try {
          final body = jsonDecode(response.body);
          msg = body['error'] ?? msg;
        } catch (_) {}
        throw Exception(msg);
      }
    } catch (e) {
      throw Exception('Gagal tambah user: $e');
    }
  }

  static Future<void> updateUser(int id, String name, String email, String phone, String role) async {
    try {
      final token = await getToken();
      await http.put(
        Uri.parse('$baseUrl/admin/users/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': name, 'email': email, 'phone': phone, 'role': role}),
      ).timeout(requestTimeout);
    } catch (e) {
      throw Exception('Update user gagal. ($e)');
    }
  }

  static Future<void> deleteUser(int id) async {
    try {
      final token = await getToken();
      await http.delete(
        Uri.parse('$baseUrl/admin/users/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
    } catch (e) {
      throw Exception('Hapus user gagal. ($e)');
    }
  }

  static Future<void> resetPassword(int id, String newPassword) async {
    try {
      final token = await getToken();
      await http.post(
        Uri.parse('$baseUrl/admin/users/$id/reset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': newPassword}),
      ).timeout(requestTimeout);
    } catch (e) {
      throw Exception('Reset password gagal. ($e)');
    }
  }

  static Future<void> toggleUserStatus(int id) async {
    try {
      final token = await getToken();
      await http.post(
        Uri.parse('$baseUrl/admin/users/$id/toggle'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
    } catch (e) {
      throw Exception('Toggle status user gagal. ($e)');
    }
  }

  static Future<Map<String, dynamic>> getPaymentSettings() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/settings/payment'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal mendapatkan pengaturan pembayaran: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePaymentSettings(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/settings/payment'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal menyimpan pengaturan: $e');
    }
  }

  // Seller: Get orders (optionally filtered by status)
  static Future<List<dynamic>> getSellerOrders({String? status}) async {
    try {
      final token = await getToken();
      final uri = status != null 
          ? '$baseUrl/seller/orders?status=$status'
          : '$baseUrl/seller/orders';
      final response = await http.get(
        Uri.parse(uri),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Gagal memuat pesanan seller. ($e)');
    }
  }

  // Seller: Verify DP payment
  static Future<void> verifyOrder(int id) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/verify'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal verifikasi');
      }
    } catch (e) {
      throw Exception('Gagal memverifikasi pesanan. ($e)');
    }
  }

  // Seller: Reject DP payment
  static Future<void> rejectOrder(int id, {String? reason}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/reject'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'reason': reason ?? ''}),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal menolak');
      }
    } catch (e) {
      throw Exception('Gagal menolak pesanan. ($e)');
    }
  }

  // Seller: Mark as Processed (Production Finished)
  static Future<void> markProcessed(int id) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/mark-processed'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      
      if (response.statusCode != 200) {
        String errMsg = 'Gagal memproses (Status: ${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errMsg = body['error'] ?? errMsg;
        } catch (_) {
          // Response is not JSON (likely HTML 404/500)
        }
        throw Exception(errMsg);
      }
    } catch (e) {
      throw Exception('Gagal menandai pesanan selesai diproses. ($e)');
    }
  }

  // Seller: Verify Final Payment
  static Future<void> verifyFinalPayment(int id) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/verify-final'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);

      if (response.statusCode != 200) {
        String errMsg = 'Gagal verifikasi final (Status: ${response.statusCode})';
        try {
          final body = jsonDecode(response.body);
          errMsg = body['error'] ?? errMsg;
        } catch (_) { }
        throw Exception(errMsg);
      }
    } catch (e) {
      throw Exception('Gagal memverifikasi pembayaran lunas. ($e)');
    }
  }

  // Payment Gateway: Cek gateway aktif (tripay / midtrans)
  static Future<Map<String, dynamic>> getPaymentConfig() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/payment/config'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'gateway': 'midtrans'}; // fallback
    } catch (e) {
      return {'gateway': 'midtrans'}; // fallback jika server tidak merespons
    }
  }

  // Payment Gateway: Ambil daftar channel pembayaran TriPay
  static Future<List<dynamic>> getPaymentChannels() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/payment/channels'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['channels'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Payment Gateway: Get token for order
  static Future<Map<String, dynamic>> getPaymentToken(int id, {required String amountType, String? method}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/orders/$id/payment-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'amountType': amountType,
          if (method != null) 'method': method,
        }),
      ).timeout(requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal mengambil token pembayaran');
      }
    } catch (e) {
      throw Exception('Ralat sistem pembayaran: $e');
    }
  }

  // Reviews
  static Future<List<dynamic>> getMyReviews() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/reviews/me'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception('Gagal memuat ulasan');
    } catch (e) {
      throw Exception('Ralat: $e');
    }
  }

  static Future<void> submitReview(int productId, int rating, String comment, {List<String>? imageUrls}) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'productId': productId,
          'rating': rating,
          'comment': comment,
          if (imageUrls != null && imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        }),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal mengirim ulasan');
      }
    } catch (e) {
      throw Exception('Ralat: $e');
    }
  }


  // Get addresses for a specific user (seller/admin only)
  static Future<List<dynamic>> getUserAddresses(int userId) async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mengambil alamat pengguna');
      }
    } catch (e) {
      throw Exception('Ralat alamat pengguna: $e');
    }
  }

  static Future<List<dynamic>> getAddresses() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/addresses'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Gagal mengambil alamat');
      }
    } catch (e) {
      throw Exception('Ralat alamat: $e');
    }
  }

  static Future<void> addAddress(Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/addresses'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Gagal menambah alamat');
      }
    } catch (e) {
      throw Exception('Ralat alamat: $e');
    }
  }

  static Future<void> updateAddress(int id, Map<String, dynamic> data) async {
    try {
      final token = await getToken();
      final response = await http.put(
        Uri.parse('$baseUrl/addresses/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Gagal mengupdate alamat');
      }
    } catch (e) {
      throw Exception('Ralat alamat: $e');
    }
  }

  static Future<void> deleteAddress(int id) async {
    try {
      final token = await getToken();
      final response = await http.delete(
        Uri.parse('$baseUrl/addresses/$id'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(requestTimeout);
      if (response.statusCode != 200) {
        throw Exception('Gagal menghapus alamat');
      }
    } catch (e) {
      throw Exception('Ralat alamat: $e');
    }
  }
}
