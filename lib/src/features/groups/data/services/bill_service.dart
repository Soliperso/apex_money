import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_model.dart';
import '../models/debt_model.dart';
import 'bill_calculation_service.dart';
import '../../../../shared/config/api_config.dart';

/// Wrapper class to indicate when data comes from fallback/mock source
class BillServiceResult<T> {
  final T data;
  final bool isFromFallback;
  final String? message;

  const BillServiceResult({
    required this.data,
    this.isFromFallback = false,
    this.message,
  });
}

class BillService {
  String get baseUrl => ApiConfig.apiBaseUrl;

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Provide fallback mock data when API is down
  List<BillModel> _getMockBills(String groupId) {
    // Return empty list for new groups to avoid showing mock data in all groups
    // This prevents the same mock bills from appearing across different groups
    return [];
  }

  List<DebtModel> _getMockDebts(String groupId) {
    // Return empty list for new groups to avoid showing mock data in all groups
    // This prevents the same mock debts from appearing across different groups
    return [];
  }

  /// Create a new bill
  Future<BillModel> createBill(BillModel bill) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/groups/${bill.groupId}/bills'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bill.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return BillModel.fromJson(data['bill']);
      } else {
        throw Exception('Failed to create bill: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating bill: $e');
    }
  }

  /// Fetch bills for a group
  Future<BillServiceResult<List<BillModel>>> fetchGroupBillsWithFallback(
    String groupId,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/bills'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      print('Bills API Response Status: ${response.statusCode}');
      print('Bills API Response Headers: ${response.headers}');
      print('Bills API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print(
            'Warning: API returned HTML instead of JSON, using fallback data',
          );
          return BillServiceResult(
            data: _getMockBills(groupId),
            isFromFallback: true,
            message:
                'Server returned HTML instead of JSON - using offline data',
          );
        }

        // Handle empty response
        if (response.body.trim().isEmpty) {
          return BillServiceResult(data: []);
        }

        try {
          final data = jsonDecode(response.body);

          // Handle different response structures based on your API models
          List<BillModel> bills;
          if (data is List) {
            bills = data.map((bill) => BillModel.fromJson(bill)).toList();
          } else if (data is Map<String, dynamic>) {
            final billsList = data['bills'] ?? data['data'] ?? [];
            bills =
                (billsList as List)
                    .map((bill) => BillModel.fromJson(bill))
                    .toList();
          } else {
            throw Exception('Unexpected response format');
          }

          return BillServiceResult(data: bills);
        } catch (e) {
          print(
            'Warning: Failed to parse bills response, using fallback data: $e',
          );
          return BillServiceResult(
            data: _getMockBills(groupId),
            isFromFallback: true,
            message: 'Failed to parse server response - using offline data',
          );
        }
      } else if (response.statusCode == 404) {
        print('Warning: Bills endpoint not found, using fallback data');
        return BillServiceResult(
          data: _getMockBills(groupId),
          isFromFallback: true,
          message: 'Bills service not found - using offline data',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired - please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied - insufficient access rights');
      } else {
        print('Warning: API error ${response.statusCode}, using fallback data');
        return BillServiceResult(
          data: _getMockBills(groupId),
          isFromFallback: true,
          message: 'Server error ${response.statusCode} - using offline data',
        );
      }
    } catch (e) {
      if (e.toString().contains('Failed to host lookup') ||
          e.toString().contains('No address associated with hostname') ||
          e.toString().contains('TimeoutException')) {
        print('Warning: Network error, using fallback data: $e');
        return BillServiceResult(
          data: _getMockBills(groupId),
          isFromFallback: true,
          message: 'Network unavailable - using offline data',
        );
      }
      if (e.toString().contains('Authentication')) {
        throw e; // Re-throw authentication errors
      }
      print('Warning: Error fetching bills, using fallback data: $e');
      return BillServiceResult(
        data: _getMockBills(groupId),
        isFromFallback: true,
        message: 'Service unavailable - using offline data',
      );
    }
  }

  /// Fetch bills for a group (legacy method for backward compatibility)
  Future<List<BillModel>> fetchGroupBills(String groupId) async {
    final result = await fetchGroupBillsWithFallback(groupId);
    return result.data;
  }

  /// Update bill
  Future<BillModel> updateBill(BillModel bill) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bills/${bill.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(bill.toJson()),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return BillModel.fromJson(data['bill']);
      } else {
        throw Exception('Failed to update bill: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating bill: $e');
    }
  }

  /// Delete bill
  Future<void> deleteBill(String billId) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bills/$billId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete bill: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting bill: $e');
    }
  }

  /// Fetch debts for a group
  Future<BillServiceResult<List<DebtModel>>> fetchGroupDebtsWithFallback(
    String groupId,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/groups/$groupId/debts'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      print('Debts API Response Status: ${response.statusCode}');
      print('Debts API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        // Check if response is HTML instead of JSON
        if (response.body.trim().startsWith('<!DOCTYPE') ||
            response.body.trim().startsWith('<html')) {
          print(
            'Warning: API returned HTML instead of JSON, using fallback data',
          );
          return BillServiceResult(
            data: _getMockDebts(groupId),
            isFromFallback: true,
            message:
                'Server returned HTML instead of JSON - using offline data',
          );
        }

        // Handle empty response
        if (response.body.trim().isEmpty) {
          return BillServiceResult(data: []);
        }

        try {
          final data = jsonDecode(response.body);

          // Handle different response structures based on your API models
          List<DebtModel> debts;
          if (data is List) {
            debts = data.map((debt) => DebtModel.fromJson(debt)).toList();
          } else if (data is Map<String, dynamic>) {
            final debtsList = data['debts'] ?? data['data'] ?? [];
            debts =
                (debtsList as List)
                    .map((debt) => DebtModel.fromJson(debt))
                    .toList();
          } else {
            debts = [];
          }

          return BillServiceResult(data: debts);
        } catch (e) {
          print(
            'Warning: Failed to parse debts response, using fallback data: $e',
          );
          return BillServiceResult(
            data: _getMockDebts(groupId),
            isFromFallback: true,
            message: 'Failed to parse server response - using offline data',
          );
        }
      } else if (response.statusCode == 404) {
        print('Warning: Debts endpoint not found, using fallback data');
        return BillServiceResult(
          data: _getMockDebts(groupId),
          isFromFallback: true,
          message: 'Debts service not found - using offline data',
        );
      } else if (response.statusCode == 401) {
        throw Exception('Authentication expired - please login again');
      } else if (response.statusCode == 403) {
        throw Exception('Permission denied - insufficient access rights');
      } else {
        print('Warning: API error ${response.statusCode}, using fallback data');
        return BillServiceResult(
          data: _getMockDebts(groupId),
          isFromFallback: true,
          message: 'Server error ${response.statusCode} - using offline data',
        );
      }
    } catch (e) {
      if (e.toString().contains('Failed to host lookup') ||
          e.toString().contains('No address associated with hostname') ||
          e.toString().contains('TimeoutException')) {
        print('Warning: Network error, using fallback data: $e');
        return BillServiceResult(
          data: _getMockDebts(groupId),
          isFromFallback: true,
          message: 'Network unavailable - using offline data',
        );
      }
      if (e.toString().contains('Authentication')) {
        throw e; // Re-throw authentication errors
      }
      print('Warning: Error fetching debts, using fallback data: $e');
      return BillServiceResult(
        data: _getMockDebts(groupId),
        isFromFallback: true,
        message: 'Service unavailable - using offline data',
      );
    }
  }

  /// Fetch debts for a group (legacy method for backward compatibility)
  Future<List<DebtModel>> fetchGroupDebts(String groupId) async {
    final result = await fetchGroupDebtsWithFallback(groupId);
    return result.data;
  }

  /// Record payment
  Future<PaymentModel> recordPayment(PaymentModel payment) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/debts/${payment.debtId}/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payment.toJson()),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return PaymentModel.fromJson(data['payment']);
      } else {
        throw Exception('Failed to record payment: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error recording payment: $e');
    }
  }

  /// Mark bill split as paid
  Future<Map<String, dynamic>> markSplitAsPaid(
    String billId,
    String userId,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bills/$billId/splits/$userId/pay'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'payment_date': DateTime.now().toIso8601String()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'bill_status': data['bill_status'],
          'settlement_complete': data['settlement_complete'] ?? false,
          'message': data['message'] ?? 'Payment recorded successfully',
        };
      } else {
        throw Exception('Failed to mark split as paid: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking split as paid: $e');
    }
  }

  /// Send settlement notifications
  Future<void> sendSettlementNotification({
    required String groupId,
    required String billId,
    required String payerUserId,
    required String payeeUserId,
    required double amount,
    required String billTitle,
  }) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      await http.post(
        Uri.parse('$baseUrl/groups/$groupId/notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': 'settlement_notification',
          'recipient_user_id': payeeUserId,
          'data': {
            'bill_id': billId,
            'bill_title': billTitle,
            'payer_user_id': payerUserId,
            'amount': amount,
            'message': 'Payment received for "$billTitle"',
          },
        }),
      );
    } catch (e) {
      // Don't throw for notification failures - they're not critical
      print('Warning: Failed to send settlement notification: $e');
    }
  }

  /// Get pending settlement reminders for a user
  Future<List<Map<String, dynamic>>> getSettlementReminders(
    String groupId,
  ) async {
    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/settlement-reminders'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
      } else {
        return []; // Return empty list on error
      }
    } catch (e) {
      print('Warning: Failed to fetch settlement reminders: $e');
      return [];
    }
  }

  /// Get bill statistics for a group
  Future<Map<String, dynamic>> getBillStatistics(String groupId) async {
    try {
      final bills = await fetchGroupBills(groupId);
      final debts = await fetchGroupDebts(groupId);

      final totalBills = bills.length;
      final activeBills = bills.where((bill) => bill.status == 'active').length;
      final settledBills =
          bills.where((bill) => bill.status == 'settled').length;

      final totalBillAmount = bills.fold<double>(
        0.0,
        (sum, bill) => sum + bill.totalAmount,
      );
      final activeDebtAmount = debts
          .where((debt) => debt.status == 'active')
          .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);

      return {
        'totalBills': totalBills,
        'activeBills': activeBills,
        'settledBills': settledBills,
        'totalBillAmount': totalBillAmount,
        'activeDebtAmount': activeDebtAmount,
        'averageBillAmount':
            totalBills > 0 ? totalBillAmount / totalBills : 0.0,
      };
    } catch (e) {
      // Return empty statistics if API is down
      print('Warning: Failed to get bill statistics, returning empty data: $e');
      return {
        'totalBills': 0,
        'activeBills': 0,
        'settledBills': 0,
        'totalBillAmount': 0.0,
        'activeDebtAmount': 0.0,
        'averageBillAmount': 0.0,
      };
    }
  }

  /// Check if the API is healthy
  Future<bool> checkApiHealth() async {
    final token = await _getAuthToken();
    if (token == null) return false;

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
