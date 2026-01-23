import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/api_constants.dart';

class VendorService {
  final String token;

  VendorService(this.token);

  Future<List<dynamic>?> getAllVendors() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/vendors/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get all vendors error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getVendorProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorMe}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get vendor error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getDocuments() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/documents/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Get docs error: $e');
      return null;
    }
  }

  Future<List<String>?> getVerifiedCompanies() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/vendors/companies'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return List<String>.from(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Get companies error: $e');
      return null;
    }
  }

  Future<bool> updateVendor(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorMe}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
      if (response.statusCode != 200) {
        print('Update failing: ${response.statusCode} - ${response.body}');
      }
      return response.statusCode == 200;
    } catch (e) {
      print('Update vendor error: $e');
      return false;
    }
  }

  Future<bool> verifyProfile() async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorMe}/verify'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Verify profile error: $e');
      return false;
    }
  }

  Future<bool> uploadDocument(String type, String filePath) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/documents/upload'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['document_type'] = type;
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      print('DEBUG: Uploading $filePath as $type');
      var response = await request.send();
      final respStr = await response.stream.bytesToString();

      print('DEBUG: Upload Response Status: ${response.statusCode}');
      print('DEBUG: Upload Response Body: $respStr');

      return response.statusCode == 200;
    } catch (e) {
      print('Upload doc error: $e');
      return false;
    }
  }
}
