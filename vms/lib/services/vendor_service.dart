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
      print('Fetching vendor profile with token: ${token.substring(0, 20)}...');
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorMe}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Vendor profile response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final profile = json.decode(response.body);
        print('Vendor profile received - ID: ${profile['id']}, Email: ${profile['email']}, Company: ${profile['company_name']}');
        return profile;
      } else {
        print('Vendor profile error: ${response.statusCode} - ${response.body}');
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
      print('Get documents response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final docs = json.decode(response.body);
        print('Get documents success: ${docs.length} documents found');
        for (var doc in docs) {
          print('Document: type=${doc['document_type']}, file_url=${doc['file_url']}');
        }
        return docs;
      } else {
        print('Get documents failed: ${response.statusCode} - ${response.body}');
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

  Future<Map<String, dynamic>?> getQrCode() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.vendorQrCode}'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          print('QR code request timeout after 20 seconds');
          throw Exception('QR code request timeout');
        },
      );
      
      print('QR code response status: ${response.statusCode}');
      print('QR code response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['qr_code_image_url'] != null && data['qr_code_image_url'].toString().isNotEmpty) {
          return data;
        } else {
          print('QR code URL is empty in response');
          return null;
        }
      } else {
        print('QR code request failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get QR code error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> scanQrCode(String qrData) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.scanQrCode}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'qr_data': qrData}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      print('Scan QR code error: $e');
      return null;
    }
  }
}
