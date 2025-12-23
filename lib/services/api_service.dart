import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  static String getBaseUrl() {
    if (kIsWeb) {
      return "http://192.168.100.8:3000"; // ip lokal
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:3000"; // Emulator Android
    } else {
      return "http://192.168.100.8:3000"; // desktop & iOS & device Android fisik
    }
  }

  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final Uri url = Uri.parse("${getBaseUrl()}/register");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(
            {"username": username, "email": email, "password": password}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Registrasi gagal", "message": response.body};
      }
    } catch (e) {
      return {"error": "Network error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> login(
      String usernameOrEmail, String password) async {
    final Uri url = Uri.parse("${getBaseUrl()}/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "usernameOrEmail": usernameOrEmail,
        "password": password,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> uploadPhoto(
      Uint8List fileBytes, String fileName) async {
    final Uri url = Uri.parse("${getBaseUrl()}/upload");
    final token = await _getToken(); // ambil token dari shared_preferences

    var request = http.MultipartRequest('POST', url);
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    // Tidak perlu kirim userId karena backend pakai token untuk ambil userId
    request.files.add(
        http.MultipartFile.fromBytes('img', fileBytes, filename: fileName));
// Tambahkan print debug di sini:
    print("=== Debug uploadPhoto ===");
    print("URL: $url");
    print("Headers: ${request.headers}");
    print("Filename: $fileName");
    print("File bytes length: ${fileBytes.length}");
    var response = await request.send();
    var responseBody = await http.Response.fromStream(response);

    if (response.statusCode == 201) {
      return jsonDecode(responseBody.body);
    } else {
      return {"error": "Gagal upload", "message": responseBody.body};
    }
  }

  static Future<List<dynamic>> fetchPhotos() async {
    final Uri url = Uri.parse("${getBaseUrl()}/photos");
    final token = await _getToken(); // tambahkan ambil token

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // kirim token
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("fetchPhotos gagal: ${response.body}");
        return [];
      }
    } catch (e) {
      print("fetchPhotos error: $e");
      return [];
    }
  }

  static Future<List<dynamic>> fetchUserPhotos(int userId) async {
    final Uri url = Uri.parse("${getBaseUrl()}/users/$userId/photos");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> likePhoto(int photoId) async {
    final Uri url = Uri.parse("${getBaseUrl()}/like"); // Ubah ke /like

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _getToken()}"
        },
        body: jsonEncode({"photoId": photoId}), // Kirim photoId di body
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {"error": "Gagal menyukai foto", "message": response.body};
      }
    } catch (e) {
      return {"error": "Network error", "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> commentPhoto(
      int photoId, int userId, String comment) async {
    final Uri url = Uri.parse("${getBaseUrl()}/comments");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${await _getToken()}"
        },
        body: jsonEncode({"photoId": photoId, "comment": comment}),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        print("Komentar gagal: ${response.body}"); // debug
        return {
          "error": "Gagal menambahkan komentar",
          "message": response.body
        };
      }
    } catch (e) {
      return {"error": "Network error", "message": e.toString()};
    }
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<List<Map<String, dynamic>>> getComments(int photoId) async {
    final Uri url = Uri.parse("${getBaseUrl()}/comments/$photoId");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Pastikan user_id bertipe int
        return List<Map<String, dynamic>>.from(data.map((item) {
          return {
            "id": item["id"],
            "user_id": int.tryParse(item["user_id"].toString()), // aman
            "username": item["username"],
            "comment": item["comment"],
          };
        }));
      } else {
        return [];
      }
    } catch (e) {
      print("Error getComments: $e");
      return [];
    }
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  static Future<bool> deleteComment(int commentId) async {
    final baseUrl = getBaseUrl();
    final token = await _getToken(); // Ambil token dari SharedPreferences
    final url = Uri.parse('$baseUrl/comments/$commentId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
