class AIInsight {
  final String title;
  final String description;
  final String type; // 'positive', 'negative', 'neutral'
  final String severity; // 'low', 'medium', 'high'

  AIInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.severity,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'neutral',
      severity: json['severity'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'severity': severity,
    };
  }
}

class AIRecommendation {
  final String title;
  final String description;
  final String action;
  final String potentialSavings;
  final String priority; // 'high', 'medium', 'low'

  AIRecommendation({
    required this.title,
    required this.description,
    required this.action,
    required this.potentialSavings,
    required this.priority,
  });

  factory AIRecommendation.fromJson(Map<String, dynamic> json) {
    return AIRecommendation(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      action: json['action'] ?? '',
      potentialSavings: json['potential_savings'] ?? '',
      priority: json['priority'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'action': action,
      'potential_savings': potentialSavings,
      'priority': priority,
    };
  }
}

class AIInsightResponse {
  final List<AIInsight> insights;

  AIInsightResponse({required this.insights});

  factory AIInsightResponse.fromJson(Map<String, dynamic> json) {
    return AIInsightResponse(
      insights:
          (json['insights'] as List? ?? [])
              .map((item) => AIInsight.fromJson(item))
              .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'insights': insights.map((insight) => insight.toJson()).toList()};
  }
}
