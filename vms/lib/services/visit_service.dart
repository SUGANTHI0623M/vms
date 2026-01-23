import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../core/models/visit.dart';

import 'dart:io';

class VisitService extends ChangeNotifier {
  List<Visit> _pendingVisits = [];
  List<Visit> get pendingVisits => _pendingVisits;

  Future<List<dynamic>?> getMyVisits(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/visits/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint('Get visits error: $e');
      return null;
    }
  }

  Future<bool> checkOut(
    int visitId,
    double lat,
    double long,
    File selfie,
    String token,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/visits/$visitId/check-out'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['check_out_latitude'] = lat.toString();
      request.fields['check_out_longitude'] = long.toString();
      request.files.add(
        await http.MultipartFile.fromPath('selfie', selfie.path),
      );

      var response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Check-out error: $e');
      return false;
    }
  }

  Future<Visit?> requestVisit({
    required String socId,
    required int organizationId,
    required String department,
    required String purpose,
    String? token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.visitRequest}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'soc_id': socId,
          'organization_id': organizationId,
          'department': department,
          'purpose': purpose,
        }),
      );

      if (response.statusCode == 200) {
        return Visit.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('Visit request error: $e');
      return null;
    }
  }

  Future<bool> updateStatus(
    int visitId,
    VisitStatus status,
    String token,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.visitStatusUpdate}/$visitId/status',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': status.toString().split('.').last}),
      );

      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update status error: $e');
      return false;
    }
  }

  Future<bool> checkIn(int visitId, String? selfieUrl, String token) async {
    try {
      final response = await http.post(
        Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.visitCheckIn}/$visitId/check-in',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'selfie_url': selfieUrl}),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Check-in error: $e');
      return false;
    }
  }

  Future<bool> loadPendingVisits(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.pendingVisits}'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        _pendingVisits = data.map((v) => Visit.fromJson(v)).toList();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Load pending visits error: $e');
      return false;
    }
  }
}
