import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';

class GoalService {
  // Backend API configuration
  static const String baseUrl = 'https://srv797850.hstgr.cloud/api/goals';

  /// Get authentication token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch all goals for the current user
  Future<List<Goal>> fetchGoals() async {
    print('Debug: GoalService.fetchGoals() called');

    try {
      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Please login to view goals");

      print('Debug: Making request to: $baseUrl');

      final response = await http
          .get(
            Uri.parse(baseUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Debug: Response status: ${response.statusCode}');
      print('Debug: Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final dynamic rawData = json.decode(response.body);
          print('Debug: Raw response type: ${rawData.runtimeType}');

          List<dynamic> data;

          // Handle different response formats
          if (rawData is Map<String, dynamic>) {
            if (rawData.containsKey('data')) {
              data = rawData['data'] as List<dynamic>;
            } else if (rawData.containsKey('goals')) {
              data = rawData['goals'] as List<dynamic>;
            } else {
              print(
                'Debug: Unexpected object response format: ${rawData.keys}',
              );
              throw FormatException('Unexpected response format');
            }
          } else if (rawData is List<dynamic>) {
            data = rawData;
          } else {
            print('Debug: Unexpected response type: ${rawData.runtimeType}');
            throw FormatException('Unexpected response format');
          }

          final goals = <Goal>[];
          for (int i = 0; i < data.length; i++) {
            try {
              final goalJson = data[i];
              print('Debug: Parsing goal $i: ${goalJson.toString()}');
              final goal = Goal.fromJson(goalJson);
              goals.add(goal);
              print('Debug: Successfully parsed goal: ${goal.name}');
            } catch (e, stackTrace) {
              print('Debug: Failed to parse goal $i: $e');
              print('Debug: Goal JSON: ${data[i]}');
              print('Debug: Stack trace: $stackTrace');
              // Continue with other goals
            }
          }

          print('Debug: Successfully parsed ${goals.length} goals');
          return goals;
        } catch (e) {
          print('Debug: JSON parsing failed: $e');
          throw FormatException('Invalid server response');
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else if (response.statusCode == 302) {
        throw Exception("Session expired - Please login again");
      } else {
        throw Exception("Failed to fetch goals: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching goals: $e');
      rethrow;
    }
  }

  /// Create a new goal
  Future<Goal> createGoal(Goal goal) async {
    print('Debug: GoalService.createGoal() called with: ${goal.name}');

    try {
      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Unauthorized - Please login again");

      final goalJson = goal.toJson();
      final requestBody = json.encode(goalJson);
      print('Debug: Sending goal JSON: $goalJson');
      print('Debug: Request body: $requestBody');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: requestBody,
          )
          .timeout(const Duration(seconds: 10));

      print('Debug: Create goal response status: ${response.statusCode}');
      print('Debug: Create goal response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Handle different response formats
          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('data')) {
              return Goal.fromJson(responseData['data']);
            } else if (responseData.containsKey('goal')) {
              return Goal.fromJson(responseData['goal']);
            } else {
              // Assume the response itself is the goal data
              return Goal.fromJson(responseData);
            }
          } else {
            throw FormatException('Unexpected response format');
          }
        } catch (e) {
          print('Debug: Failed to parse goal creation response: $e');
          throw FormatException('Invalid server response');
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else if (response.statusCode == 422) {
        // Validation error
        try {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Validation failed';
          throw Exception("Validation error: $errorMessage");
        } catch (_) {
          throw Exception("Invalid goal data");
        }
      } else {
        throw Exception("Failed to create goal: ${response.statusCode}");
      }
    } catch (e) {
      print('Error creating goal: $e');
      rethrow;
    }
  }

  /// Update an existing goal
  Future<Goal> updateGoal(Goal goal) async {
    print('Debug: GoalService.updateGoal() called for ID: ${goal.id}');

    try {
      if (goal.id == null) {
        throw Exception('Goal ID is required for updates');
      }

      // Update the updatedAt timestamp
      final updatedGoal = goal.copyWith(updatedAt: DateTime.now());

      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Unauthorized - Please login again");

      final response = await http
          .put(
            Uri.parse("$baseUrl/${goal.id}"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
            body: json.encode(updatedGoal.toJson()),
          )
          .timeout(const Duration(seconds: 10));

      print('Debug: Update goal response status: ${response.statusCode}');
      print('Debug: Update goal response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Handle different response formats
          if (responseData is Map<String, dynamic>) {
            if (responseData.containsKey('data')) {
              return Goal.fromJson(responseData['data']);
            } else if (responseData.containsKey('goal')) {
              return Goal.fromJson(responseData['goal']);
            } else {
              // Assume the response itself is the goal data
              return Goal.fromJson(responseData);
            }
          } else {
            throw FormatException('Unexpected response format');
          }
        } catch (e) {
          print('Debug: Failed to parse goal update response: $e');
          throw FormatException('Invalid server response');
        }
      } else if (response.statusCode == 401) {
        throw Exception("Unauthorized - Please login again");
      } else if (response.statusCode == 404) {
        throw Exception("Goal not found");
      } else {
        throw Exception("Failed to update goal: ${response.statusCode}");
      }
    } catch (e) {
      print('Error updating goal: $e');
      rethrow;
    }
  }

  /// Update goal progress (add to current amount)
  Future<Goal> updateGoalProgress(String goalId, double amountToAdd) async {
    print(
      'Debug: GoalService.updateGoalProgress() called for ID: $goalId, amount: $amountToAdd',
    );

    try {
      // Fetch current goals
      final goals = await fetchGoals();
      print('Debug: Found ${goals.length} goals when updating progress');
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found'),
      );
      print(
        'Debug: Found goal "${goal.name}" with current amount: \$${goal.currentAmount}',
      );

      // Update the current amount
      final newCurrentAmount = goal.currentAmount + amountToAdd;
      final isCompleted = newCurrentAmount >= goal.targetAmount;
      print(
        'Debug: Calculated new amount: \$${newCurrentAmount} (was \$${goal.currentAmount}, adding \$${amountToAdd})',
      );

      final updatedGoal = goal.copyWith(
        currentAmount: newCurrentAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );
      print(
        'Debug: About to update goal with new amount: \$${newCurrentAmount}',
      );

      // Save the updated goal
      final result = await updateGoal(updatedGoal);
      print(
        'Debug: Successfully updated goal progress. New amount: \$${result.currentAmount}',
      );
      return result;
    } catch (e) {
      print('Error updating goal progress: $e');
      rethrow;
    }
  }

  /// Set goal progress (set current amount directly)
  Future<Goal> setGoalProgress(String goalId, double newAmount) async {
    print(
      'Debug: GoalService.setGoalProgress() called for ID: $goalId, amount: $newAmount',
    );

    try {
      // Fetch current goals
      final goals = await fetchGoals();
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found'),
      );

      // Set the new amount
      final isCompleted = newAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      // Save the updated goal
      return await updateGoal(updatedGoal);
    } catch (e) {
      print('Error setting goal progress: $e');
      rethrow;
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String goalId) async {
    print('Debug: GoalService.deleteGoal() called for ID: $goalId');

    try {
      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Unauthorized - Please login again");

      final response = await http
          .delete(
            Uri.parse("$baseUrl/$goalId"),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      print('Debug: Delete goal response status: ${response.statusCode}');
      print('Debug: Delete goal response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete goal: ${response.statusCode}");
      }

      print('Debug: Goal deleted successfully');
    } catch (e) {
      print('Error deleting goal: $e');
      rethrow;
    }
  }

  /// Get goal statistics
  Future<Map<String, dynamic>> getGoalStatistics() async {
    try {
      final goals = await fetchGoals();

      final totalGoals = goals.length;
      final completedGoals = goals.where((g) => g.isCompleted).length;
      final activeGoals = totalGoals - completedGoals;
      final overDueGoals = goals.where((g) => g.isOverdue).length;

      final totalTargetAmount = goals.fold<double>(
        0,
        (sum, goal) => sum + goal.targetAmount,
      );
      final totalSavedAmount = goals.fold<double>(
        0,
        (sum, goal) => sum + goal.currentAmount,
      );

      final overallProgress =
          totalTargetAmount > 0 ? (totalSavedAmount / totalTargetAmount) : 0.0;

      return {
        'totalGoals': totalGoals,
        'completedGoals': completedGoals,
        'activeGoals': activeGoals,
        'overdueGoals': overDueGoals,
        'totalTargetAmount': totalTargetAmount,
        'totalSavedAmount': totalSavedAmount,
        'overallProgress': overallProgress,
      };
    } catch (e) {
      print('Error getting goal statistics: $e');
      rethrow;
    }
  }

  /// Temporary diagnostic method to analyze API response
  Future<void> diagnoseApiResponse() async {
    print('🔍 Starting API response diagnosis...');

    try {
      final token = await _getAuthToken();
      if (token == null) {
        print('❌ No auth token found');
        return;
      }

      final response = await http
          .get(
            Uri.parse(baseUrl),
            headers: {
              "Authorization": "Bearer $token",
              "Content-Type": "application/json",
              "Accept": "application/json",
            },
          )
          .timeout(const Duration(seconds: 10));

      print('📊 Response Status: ${response.statusCode}');
      print('📊 Response Headers: ${response.headers}');
      print('📊 Raw Response Body:');
      print(response.body);

      if (response.statusCode == 200) {
        try {
          final dynamic rawData = json.decode(response.body);
          print('📊 Parsed JSON Type: ${rawData.runtimeType}');

          if (rawData is Map<String, dynamic>) {
            print('📊 JSON Keys: ${rawData.keys.toList()}');
            rawData.forEach((key, value) {
              print('📊 $key: ${value.runtimeType} = $value');
            });
          } else if (rawData is List<dynamic>) {
            print('📊 Array Length: ${rawData.length}');
            if (rawData.isNotEmpty) {
              print('📊 First Item Type: ${rawData[0].runtimeType}');
              if (rawData[0] is Map<String, dynamic>) {
                final firstItem = rawData[0] as Map<String, dynamic>;
                print('📊 First Item Keys: ${firstItem.keys.toList()}');
                firstItem.forEach((key, value) {
                  print('📊   $key: ${value.runtimeType} = $value');
                });
              }
            }
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
        }
      }
    } catch (e) {
      print('❌ Diagnosis failed: $e');
    }
  }
}
