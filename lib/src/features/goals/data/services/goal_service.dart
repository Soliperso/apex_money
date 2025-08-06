import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/goal_model.dart';
import '../../../../shared/config/api_config.dart';

class GoalService {
  // Backend API configuration
  static String get baseUrl => '${ApiConfig.apiBaseUrl}/goals';

  /// Get authentication token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Fetch all goals for the current user
  Future<List<Goal>> fetchGoals() async {
    try {
      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Please login to view goals");

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

      if (response.statusCode == 200) {
        try {
          final dynamic rawData = json.decode(response.body);

          List<dynamic> data;

          // Handle different response formats
          if (rawData is Map<String, dynamic>) {
            if (rawData.containsKey('data')) {
              data = rawData['data'] as List<dynamic>;
            } else if (rawData.containsKey('goals')) {
              data = rawData['goals'] as List<dynamic>;
            } else {
              throw FormatException('Unexpected response format');
            }
          } else if (rawData is List<dynamic>) {
            data = rawData;
          } else {
            throw FormatException('Unexpected response format');
          }

          final goals = <Goal>[];
          for (int i = 0; i < data.length; i++) {
            try {
              final goalJson = data[i];
              final goal = Goal.fromJson(goalJson);
              goals.add(goal);
            } catch (e, stackTrace) {
              // Continue with other goals
            }
          }

          return goals;
        } catch (e) {
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
      rethrow;
    }
  }

  /// Create a new goal
  Future<Goal> createGoal(Goal goal) async {
    try {
      // Use real backend API
      final token = await _getAuthToken();
      if (token == null) throw Exception("Unauthorized - Please login again");

      final goalJson = goal.toJson();
      final requestBody = json.encode(goalJson);

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
      rethrow;
    }
  }

  /// Update an existing goal
  Future<Goal> updateGoal(Goal goal) async {
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
      rethrow;
    }
  }

  /// Update goal progress (add to current amount)
  Future<Goal> updateGoalProgress(String goalId, double amountToAdd) async {
    try {
      // Fetch current goals
      final goals = await fetchGoals();
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found'),
      );

      // Update the current amount
      final newCurrentAmount = goal.currentAmount + amountToAdd;
      final isCompleted = newCurrentAmount >= goal.targetAmount;

      final updatedGoal = goal.copyWith(
        currentAmount: newCurrentAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      // Save the updated goal
      final result = await updateGoal(updatedGoal);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Set goal progress (set current amount directly)
  Future<Goal> setGoalProgress(String goalId, double newAmount) async {
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
      rethrow;
    }
  }

  /// Delete a goal
  Future<void> deleteGoal(String goalId) async {
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

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception("Failed to delete goal: ${response.statusCode}");
      }
    } catch (e) {
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
      rethrow;
    }
  }

  /// Temporary diagnostic method to analyze API response
  Future<void> diagnoseApiResponse() async {
    try {
      final token = await _getAuthToken();
      if (token == null) {
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

      if (response.statusCode == 200) {
        try {
          final dynamic rawData = json.decode(response.body);

          if (rawData is Map<String, dynamic>) {
            rawData.forEach((key, value) {
              // Analyze response structure
            });
          } else if (rawData is List<dynamic>) {
            if (rawData.isNotEmpty) {
              if (rawData[0] is Map<String, dynamic>) {
                final firstItem = rawData[0] as Map<String, dynamic>;
                firstItem.forEach((key, value) {
                  // Analyze first item structure
                });
              }
            }
          }
        } catch (e) {
          // Handle parsing errors
        }
      }
    } catch (e) {
      // Handle request errors
    }
  }
}
