import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart' as transaction_model;
import '../../../goals/data/services/goal_transaction_sync_service.dart';

class TransactionService {
  final String baseUrl = "https://srv797850.hstgr.cloud/api/transactions";
  final bool useMockData = false; // Disabled mock data - using real backend
  final bool fallbackToMockOnError =
      false; // Disabled fallback - force real authentication

  // Goal sync service for automatic goal updates
  final GoalTransactionSyncService _goalSyncService =
      GoalTransactionSyncService();

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<List<transaction_model.Transaction>> fetchTransactions() async {
    final token = await _getAuthToken();
    print('Debug: Token available: ${token != null}');

    if (token == null) {
      throw Exception("Please login to view transactions");
    }

    // First, let's validate the token format
    print('Debug: Token length: ${token.length}');
    print(
      'Debug: Token starts with: ${token.substring(0, math.min(10, token.length))}',
    );

    try {
      print('Debug: Making request to: $baseUrl');

      // Try different query parameters to avoid problematic relationships
      // Laravel-specific parameters to control relationship loading
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'without_relations': '1', // Custom parameter to disable relations
          'simple': '1', // Request simple format
          'no_eager': '1', // Disable eager loading
          'fields':
              'id,description,amount,date,category,type,status', // Only specific fields
        },
      );

      print('Debug: Request URI with parameters: $uri');

      final response = await http
          .get(
            uri,
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
              "X-Requested-With": "XMLHttpRequest", // Laravel AJAX header
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Debug: Response status: ${response.statusCode}');
      print('Debug: Response headers: ${response.headers}');
      print('Debug: Response body length: ${response.body.length}');
      print(
        'Debug: Response body preview: ${response.body.substring(0, math.min(200, response.body.length))}',
      );

      if (response.statusCode == 200) {
        try {
          final dynamic rawData = json.decode(response.body);
          print('Debug: Raw response type: ${rawData.runtimeType}');

          List<dynamic> data;

          // Handle different response formats
          if (rawData is Map<String, dynamic>) {
            // If response is wrapped in an object, look for common array keys
            if (rawData.containsKey('data')) {
              data = rawData['data'] as List<dynamic>;
            } else if (rawData.containsKey('transactions')) {
              data = rawData['transactions'] as List<dynamic>;
            } else {
              print(
                'Debug: Unexpected object response format: ${rawData.keys}',
              );
              throw FormatException(
                'Expected array or object with data/transactions key',
              );
            }
          } else if (rawData is List<dynamic>) {
            data = rawData;
          } else {
            throw FormatException(
              'Unexpected response format: ${rawData.runtimeType}',
            );
          }

          print('Debug: Successfully parsed ${data.length} transactions');

          final transactions = <transaction_model.Transaction>[];
          for (int i = 0; i < data.length; i++) {
            try {
              final transaction = transaction_model.Transaction.fromJson(
                data[i],
              );
              transactions.add(transaction);
            } catch (e) {
              print('Debug: Failed to parse transaction at index $i: $e');
              // Continue with other transactions instead of failing completely
            }
          }

          print(
            'Debug: Successfully created ${transactions.length} transaction objects',
          );
          return transactions;
        } catch (e) {
          print('Debug: JSON parsing error: $e');
          print('Debug: Response body: ${response.body}');
          throw Exception("Invalid response format from server: $e");
        }
      } else if (response.statusCode == 302) {
        // Handle redirect to login page (backend session expired)
        print('Debug: Got 302 redirect, likely session expired');
        throw Exception("Session expired (302 redirect) - Please login again");
      } else if (response.statusCode == 401) {
        print('Debug: Got 401 unauthorized, token likely invalid');
        throw Exception("Unauthorized (401) - Please login again");
      } else if (response.statusCode == 500) {
        print('Debug: Got 500 server error');
        throw Exception("Server error (500) - Backend issue");
      } else {
        print('Debug: Got HTTP ${response.statusCode}');
        throw Exception(
          "HTTP ${response.statusCode} - Response: ${response.body}",
        );
      }
    } catch (e) {
      print('Network error: $e');

      if (e.toString().contains('SocketException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception(
          "Network connection failed - Check your internet connection",
        );
      }
      rethrow;
    }
  }

  // Alternative API call that tries different endpoints to avoid relationship issues
  Future<List<transaction_model.Transaction>>
  fetchTransactionsAlternative() async {
    final token = await _getAuthToken();
    if (token == null) throw Exception("Please login to view transactions");

    // Try different API endpoints and parameters that might not have the relationship issue
    final alternativeAttempts = [
      {
        'url': '$baseUrl/simple',
        'params': <String, String>{},
        'description': 'Simple endpoint',
      },
      {
        'url': baseUrl,
        'params': {'format': 'basic', 'relations': 'none'},
        'description': 'Basic format with no relations',
      },
      {
        'url': baseUrl,
        'params': {
          'select':
              'id,description,amount,date,category,type,status,created_at',
        },
        'description': 'Specific field selection',
      },
      {
        'url': baseUrl.replaceAll(
          '/api/transactions',
          '/api/user/transactions',
        ),
        'params': <String, String>{},
        'description': 'User-specific endpoint',
      },
      {
        'url': '$baseUrl/list',
        'params': <String, String>{},
        'description': 'List endpoint',
      },
    ];

    Exception? lastException;

    for (var attempt in alternativeAttempts) {
      try {
        print('Debug: Trying ${attempt['description']}: ${attempt['url']}');

        final uri = Uri.parse(
          attempt['url'] as String,
        ).replace(queryParameters: attempt['params'] as Map<String, String>?);

        final response = await http
            .get(
              uri,
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
                "Accept": "application/json",
                "X-Requested-With": "XMLHttpRequest",
              },
            )
            .timeout(const Duration(seconds: 8));

        print(
          'Debug: ${attempt['description']} response: ${response.statusCode}',
        );

        if (response.statusCode == 200) {
          try {
            final dynamic rawData = json.decode(response.body);
            print('Debug: ${attempt['description']} - parsing response');

            List<dynamic> data;

            if (rawData is Map<String, dynamic>) {
              if (rawData.containsKey('data')) {
                data = rawData['data'] as List<dynamic>;
              } else if (rawData.containsKey('transactions')) {
                data = rawData['transactions'] as List<dynamic>;
              } else {
                print(
                  'Debug: ${attempt['description']} - unexpected object format',
                );
                continue;
              }
            } else if (rawData is List<dynamic>) {
              data = rawData;
            } else {
              print(
                'Debug: ${attempt['description']} - unexpected response type',
              );
              continue;
            }

            final transactions = <transaction_model.Transaction>[];
            for (var transactionJson in data) {
              try {
                final transaction = transaction_model.Transaction.fromJson(
                  transactionJson,
                );
                transactions.add(transaction);
              } catch (e) {
                print('Debug: Failed to parse individual transaction: $e');
                // Continue with other transactions
              }
            }

            if (transactions.isNotEmpty) {
              print(
                'Debug: ${attempt['description']} SUCCESS - ${transactions.length} transactions',
              );
              return transactions;
            }
          } catch (e) {
            print('Debug: ${attempt['description']} - JSON parsing failed: $e');
            continue;
          }
        } else if (response.statusCode == 404) {
          print('Debug: ${attempt['description']} - endpoint not found');
          continue;
        } else {
          print(
            'Debug: ${attempt['description']} - HTTP ${response.statusCode}',
          );
          continue;
        }
      } catch (e) {
        print('Debug: ${attempt['description']} - request failed: $e');
        lastException = e is Exception ? e : Exception(e.toString());
        continue;
      }
    }

    throw lastException ?? Exception("All alternative endpoints failed");
  }

  // Mock data has been removed as we're now using real backend data only

  Future<void> createTransaction(
    transaction_model.Transaction transaction,
  ) async {
    // Always use real backend for creating transactions
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized - Please login again");

    try {
      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: json.encode(transaction.toJson()),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Transaction created successfully

        // Sync with goals after successful creation
        try {
          await _goalSyncService.syncTransactionWithGoals(transaction);
        } catch (e) {
          print('Warning: Failed to sync transaction with goals: $e');
          // Don't throw error here - transaction was created successfully
        }

        return;
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Validation failed';
          throw Exception("Validation error: $errorMessage");
        } catch (_) {
          throw Exception("Invalid transaction data");
        }
      } else if (response.statusCode >= 500) {
        throw Exception("Server error - Please try again later");
      } else {
        throw Exception(
          "Failed to create transaction (${response.statusCode})",
        );
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception("Request timed out - Please check your connection");
      } else if (e.toString().contains('SocketException')) {
        throw Exception("Network error - Please check your connection");
      } else if (e.toString().contains('FormatException')) {
        throw Exception("Invalid server response");
      } else {
        rethrow; // Re-throw custom exceptions
      }
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
    // This function now uses the real backend API exclusively for persistence
    // Mock data has been removed to ensure proper deletion persistence
    final token = await _getAuthToken();
    if (token == null) throw Exception("Unauthorized");

    print('Debug: Attempting to delete transaction from backend with ID: $id');

    // First, try to get the transaction details for goal sync reversal
    transaction_model.Transaction? transactionToDelete;
    try {
      // Fetch all transactions and find the one being deleted
      final allTransactions = await fetchTransactions();
      transactionToDelete = allTransactions.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Transaction not found'),
      );
    } catch (e) {
      print('Warning: Could not fetch transaction for goal sync reversal: $e');
    }

    final response = await http.delete(
      Uri.parse("$baseUrl/$id"),
      headers: {"Authorization": "Bearer $token", "Accept": "application/json"},
    );

    print('Debug: Delete response status: ${response.statusCode}');
    print('Debug: Delete response body: ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        "Failed to delete transaction: HTTP ${response.statusCode} - ${response.body}",
      );
    }

    // If deletion was successful and we have transaction details, reverse goal updates
    if (transactionToDelete != null) {
      try {
        await _goalSyncService.reverseTransactionFromGoals(transactionToDelete);
      } catch (e) {
        print(
          'Warning: Failed to reverse goal updates after transaction deletion: $e',
        );
        // Don't throw error here - transaction was deleted successfully
      }
    }
  }

  // Method to test authentication with the backend
  Future<Map<String, dynamic>> testAuthentication() async {
    final token = await _getAuthToken();

    final result = {
      'hasToken': token != null,
      'tokenLength': token?.length ?? 0,
      'tokenPreview':
          token != null
              ? token.substring(0, math.min(20, token.length))
              : 'N/A',
    };

    if (token == null) {
      result['error'] = 'No authentication token found';
      result['solution'] = 'Please login through the profile page';
      return result;
    }

    try {
      // Test with a simple GET request to see what response we get
      final response = await http
          .get(
            Uri.parse(baseUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 5));

      result['responseStatus'] = response.statusCode;
      result['responseHeaders'] = response.headers;
      result['responseBodyPreview'] = response.body.substring(
        0,
        math.min(200, response.body.length),
      );

      if (response.statusCode == 200) {
        result['authenticationStatus'] = 'SUCCESS';
        try {
          final data = json.decode(response.body);
          result['dataType'] = data.runtimeType.toString();
          if (data is List) {
            result['transactionCount'] = data.length;
          }
        } catch (e) {
          result['jsonParsingError'] = e.toString();
        }
      } else if (response.statusCode == 302) {
        result['authenticationStatus'] = 'REDIRECT_TO_LOGIN';
        result['error'] = 'Session expired or token invalid';
        result['solution'] = 'Login again through the profile page';
      } else if (response.statusCode == 401) {
        result['authenticationStatus'] = 'UNAUTHORIZED';
        result['error'] = 'Token is invalid or expired';
        result['solution'] = 'Login again through the profile page';
      } else {
        result['authenticationStatus'] = 'FAILED';
        result['error'] = 'Unexpected response: ${response.statusCode}';
      }
    } catch (e) {
      result['authenticationStatus'] = 'ERROR';
      result['error'] = e.toString();
      result['solution'] = 'Check network connection or backend availability';
    }

    return result;
  }

  // Method to clear stored token (for logout or token refresh)
  Future<void> clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    print('Debug: Cleared stored access token');
  }

  // Method to check if we should attempt token refresh
  Future<bool> shouldRefreshToken(int statusCode) async {
    return statusCode == 401 || statusCode == 302;
  }

  // Minimal API request to test if we can get any response without triggering relationships
  Future<Map<String, dynamic>> testMinimalAPI() async {
    final token = await _getAuthToken();
    if (token == null) return {'error': 'No token'};

    try {
      // Try a HEAD request first to see if the endpoint is accessible
      final headResponse = await http
          .head(Uri.parse(baseUrl), headers: {"Authorization": "Bearer $token"})
          .timeout(const Duration(seconds: 5));

      if (headResponse.statusCode == 200) {
        // If HEAD works, try a GET with minimal parameters
        final getResponse = await http
            .get(
              Uri.parse('$baseUrl?limit=1&page=1&minimal=1'),
              headers: {
                "Authorization": "Bearer $token",
                "Accept": "application/json",
              },
            )
            .timeout(const Duration(seconds: 5));

        return {
          'head_status': headResponse.statusCode,
          'get_status': getResponse.statusCode,
          'get_body_preview': getResponse.body.substring(
            0,
            math.min(100, getResponse.body.length),
          ),
          'success': getResponse.statusCode == 200,
        };
      } else {
        return {
          'head_status': headResponse.statusCode,
          'error': 'HEAD request failed',
        };
      }
    } catch (e) {
      return {'error': e.toString(), 'success': false};
    }
  }

  // Comprehensive debugging method to try various API approaches
  Future<Map<String, dynamic>> debugApiEndpoints() async {
    final token = await _getAuthToken();
    final results = <String, dynamic>{};

    if (token == null) {
      results['error'] = 'No authentication token available';
      return results;
    }

    final headers = {
      "Authorization": "Bearer $token",
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-Requested-With": "XMLHttpRequest",
    };

    // Test various endpoints and parameters
    final testCases = [
      {
        'name': 'Basic transactions endpoint',
        'url': 'https://srv797850.hstgr.cloud/api/transactions',
        'params': <String, String>{},
      },
      {
        'name': 'Transactions with select fields only',
        'url': 'https://srv797850.hstgr.cloud/api/transactions',
        'params': {'select': 'id,description,amount,date'},
      },
      {
        'name': 'Transactions with explicit no relationships',
        'url': 'https://srv797850.hstgr.cloud/api/transactions',
        'params': {'without': 'bill,bills,relationships'},
      },
      {
        'name': 'Transactions with limit=1',
        'url': 'https://srv797850.hstgr.cloud/api/transactions',
        'params': {'limit': '1'},
      },
      {
        'name': 'Transactions with paginate=false',
        'url': 'https://srv797850.hstgr.cloud/api/transactions',
        'params': {'paginate': 'false', 'per_page': '1'},
      },
      {
        'name': 'Raw transactions endpoint',
        'url': 'https://srv797850.hstgr.cloud/api/transactions/raw',
        'params': <String, String>{},
      },
      {
        'name': 'Single transaction by ID',
        'url': 'https://srv797850.hstgr.cloud/api/transactions/1',
        'params': <String, String>{},
      },
    ];

    for (final testCase in testCases) {
      try {
        final uri = Uri.parse(
          testCase['url'] as String,
        ).replace(queryParameters: testCase['params'] as Map<String, String>);

        print('Debug: Testing ${testCase['name']}: $uri');

        final response = await http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 5));

        results[testCase['name'] as String] = {
          'status': response.statusCode,
          'success': response.statusCode == 200,
          'bodyLength': response.body.length,
          'bodyPreview': response.body.substring(
            0,
            math.min(100, response.body.length),
          ),
        };

        // If we get a 200, try to parse it
        if (response.statusCode == 200) {
          try {
            final parsed = json.decode(response.body);
            results[testCase['name'] as String]['parsed'] = true;
            results[testCase['name'] as String]['dataType'] =
                parsed.runtimeType.toString();
          } catch (e) {
            results[testCase['name'] as String]['parseError'] = e.toString();
          }
        }

        // Short delay between requests
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        results[testCase['name'] as String] = {'error': e.toString()};
      }
    }

    return results;
  }

  // Test if we can use POST to request specific transaction data
  Future<Map<String, dynamic>> testPostTransactionRequest() async {
    final token = await _getAuthToken();

    if (token == null) {
      return {'error': 'No authentication token available'};
    }

    try {
      // Some APIs allow POST requests to specify exactly what fields to return
      // and avoid problematic relationships
      final postData = {
        'action': 'list',
        'fields': ['id', 'description', 'amount', 'date', 'category', 'type'],
        'exclude_relations': true,
        'format': 'simple',
        'limit': 5,
      };

      final response = await http
          .post(
            Uri.parse('https://srv797850.hstgr.cloud/api/transactions'),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
              "X-Requested-With": "XMLHttpRequest",
            },
            body: json.encode(postData),
          )
          .timeout(const Duration(seconds: 10));

      return {
        'status': response.statusCode,
        'success': response.statusCode == 200,
        'bodyLength': response.body.length,
        'bodyPreview': response.body.substring(
          0,
          math.min(200, response.body.length),
        ),
        'method': 'POST',
      };
    } catch (e) {
      return {'error': e.toString(), 'success': false};
    }
  }

  // Test accessing user profile to verify authentication works
  Future<Map<String, dynamic>> testUserProfile() async {
    final token = await _getAuthToken();

    if (token == null) {
      return {'error': 'No authentication token available'};
    }

    try {
      final response = await http
          .get(
            Uri.parse('https://srv797850.hstgr.cloud/api/user'),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      return {
        'status': response.statusCode,
        'success': response.statusCode == 200,
        'bodyLength': response.body.length,
        'bodyPreview': response.body.substring(
          0,
          math.min(200, response.body.length),
        ),
        'endpoint': '/api/user',
      };
    } catch (e) {
      return {'error': e.toString(), 'success': false};
    }
  }
}
