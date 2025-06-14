import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart' as transaction_model;

class TransactionService {
  final String baseUrl = "https://srv797850.hstgr.cloud/api/transactions";

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<transaction_model.Transaction>> fetchTransactions() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized");

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .map((json) => transaction_model.Transaction.fromJson(json))
          .toList();
    } else {
      throw Exception("Failed to fetch transactions");
    }
  }

  Future<void> createTransaction(
    transaction_model.Transaction transaction,
  ) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized");

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create transaction");
    }
  }

  Future<void> updateTransaction(
    String id,
    transaction_model.Transaction transaction,
  ) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized");

    final response = await http.put(
      Uri.parse("$baseUrl/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update transaction");
    }
  }

  Future<void> deleteTransaction(String id) async {
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized");

    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to delete transaction");
    }
  }
}
