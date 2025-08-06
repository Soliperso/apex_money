import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'lib/src/shared/services/ai_service.dart';
import 'lib/src/features/transactions/data/models/transaction_model.dart';

void main() async {
  print('🧪 Testing AI Service...');
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    print('✅ Environment loaded');
    
    // Create test transactions
    final testTransactions = [
      Transaction(
        id: '1',
        amount: 50.0,
        category: 'Food',
        description: 'Lunch at restaurant',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        paymentMethodId: 'card',
      ),
      Transaction(
        id: '2',
        amount: 1200.0,
        category: 'Salary',
        description: 'Monthly salary',
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.income,
        paymentMethodId: 'bank',
      ),
      Transaction(
        id: '3',
        amount: 150.0,
        category: 'Shopping',
        description: 'Groceries',
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.expense,
        paymentMethodId: 'card',
      ),
    ];
    
    print('✅ Test transactions created: ${testTransactions.length}');
    
    // Test AI Service
    final aiService = AIService();
    print('✅ AI Service initialized');
    
    print('🤖 Generating AI insights...');
    final insights = await aiService.generateInsights(testTransactions);
    
    print('🎉 AI Insights generated successfully!');
    print('📊 Insights received: ${insights.insights.length}');
    
    for (int i = 0; i < insights.insights.length; i++) {
      final insight = insights.insights[i];
      print('  ${i + 1}. ${insight['title']}: ${insight['description']}');
    }
    
    print('✅ AI Service test completed successfully!');
    
  } catch (e, stackTrace) {
    print('❌ AI Service test failed: $e');
    print('📍 Stack trace: $stackTrace');
    exit(1);
  }
}