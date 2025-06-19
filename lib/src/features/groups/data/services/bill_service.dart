import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bill_model.dart';
import '../models/debt_model.dart';
import 'bill_calculation_service.dart';

class BillService {
  final String baseUrl = "https://srv797850.hstgr.cloud/api";
  final bool useMockData = true; // Enable mock data for development
  
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Create a new bill
  Future<BillModel> createBill(BillModel bill) async {
    if (useMockData) {
      return _createMockBill(bill);
    }

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
  Future<List<BillModel>> fetchGroupBills(String groupId) async {
    if (useMockData) {
      return _getMockGroupBills(groupId);
    }

    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/bills'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['bills'] as List)
            .map((bill) => BillModel.fromJson(bill))
            .toList();
      } else {
        throw Exception('Failed to fetch bills: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching bills: $e');
    }
  }

  /// Update bill
  Future<BillModel> updateBill(BillModel bill) async {
    if (useMockData) {
      return _updateMockBill(bill);
    }

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
    if (useMockData) {
      return _deleteMockBill(billId);
    }

    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bills/$billId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete bill: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting bill: $e');
    }
  }

  /// Fetch debts for a group
  Future<List<DebtModel>> fetchGroupDebts(String groupId) async {
    if (useMockData) {
      return _getMockGroupDebts(groupId);
    }

    final token = await _getAuthToken();
    if (token == null) {
      throw Exception("Authentication required");
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/groups/$groupId/debts'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['debts'] as List)
            .map((debt) => DebtModel.fromJson(debt))
            .toList();
      } else {
        throw Exception('Failed to fetch debts: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching debts: $e');
    }
  }

  /// Record payment
  Future<PaymentModel> recordPayment(PaymentModel payment) async {
    if (useMockData) {
      return _recordMockPayment(payment);
    }

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
  Future<void> markSplitAsPaid(String billId, String userId) async {
    if (useMockData) {
      return _markMockSplitAsPaid(billId, userId);
    }

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
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark split as paid: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error marking split as paid: $e');
    }
  }

  // Mock Data Methods for Development
  static List<BillModel> _mockBills = [];
  static List<DebtModel> _mockDebts = [];
  static List<PaymentModel> _mockPayments = [];

  BillModel _createMockBill(BillModel bill) {
    final mockBill = bill.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _mockBills.add(mockBill);
    
    // Generate debts from this bill
    final debts = BillCalculationService.calculateDebtsFromBill(mockBill);
    for (final debt in debts) {
      _mockDebts.add(debt.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      ));
    }
    
    return mockBill;
  }

  List<BillModel> _getMockGroupBills(String groupId) {
    return _mockBills.where((bill) => bill.groupId == groupId).toList()
      ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));
  }

  BillModel _updateMockBill(BillModel bill) {
    final index = _mockBills.indexWhere((b) => b.id == bill.id);
    if (index != -1) {
      _mockBills[index] = bill;
      return bill;
    }
    throw Exception('Bill not found');
  }

  void _deleteMockBill(String billId) {
    _mockBills.removeWhere((bill) => bill.id == billId);
    _mockDebts.removeWhere((debt) => debt.billIds.contains(billId));
  }

  List<DebtModel> _getMockGroupDebts(String groupId) {
    final groupDebts = _mockDebts.where((debt) => debt.groupId == groupId).toList();
    return BillCalculationService.optimizeDebts(groupDebts);
  }

  PaymentModel _recordMockPayment(PaymentModel payment) {
    final mockPayment = payment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    _mockPayments.add(mockPayment);
    
    // Update the debt with this payment
    final debtIndex = _mockDebts.indexWhere((debt) => debt.id == payment.debtId);
    if (debtIndex != -1) {
      final debt = _mockDebts[debtIndex];
      final updatedPayments = [...debt.payments, mockPayment];
      _mockDebts[debtIndex] = debt.copyWith(
        payments: updatedPayments,
        status: debt.isFullySettled ? 'settled' : 'active',
        settledDate: debt.isFullySettled ? DateTime.now() : null,
      );
    }
    
    return mockPayment;
  }

  void _markMockSplitAsPaid(String billId, String userId) {
    final billIndex = _mockBills.indexWhere((bill) => bill.id == billId);
    if (billIndex != -1) {
      final bill = _mockBills[billIndex];
      final updatedSplits = bill.splits.map((split) {
        if (split.userId == userId) {
          return split.copyWith(
            isPaid: true,
            paidDate: DateTime.now(),
          );
        }
        return split;
      }).toList();
      
      _mockBills[billIndex] = bill.copyWith(splits: updatedSplits);
    }
  }

  /// Get bill statistics for a group
  Future<Map<String, dynamic>> getBillStatistics(String groupId) async {
    final bills = await fetchGroupBills(groupId);
    final debts = await fetchGroupDebts(groupId);
    
    final totalBills = bills.length;
    final activeBills = bills.where((bill) => bill.status == 'active').length;
    final settledBills = bills.where((bill) => bill.status == 'settled').length;
    
    final totalBillAmount = bills.fold<double>(0.0, (sum, bill) => sum + bill.totalAmount);
    final activeDebtAmount = debts
        .where((debt) => debt.status == 'active')
        .fold<double>(0.0, (sum, debt) => sum + debt.remainingAmount);
    
    return {
      'totalBills': totalBills,
      'activeBills': activeBills,
      'settledBills': settledBills,
      'totalBillAmount': totalBillAmount,
      'activeDebtAmount': activeDebtAmount,
      'averageBillAmount': totalBills > 0 ? totalBillAmount / totalBills : 0.0,
    };
  }
}