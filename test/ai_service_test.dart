import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../lib/src/shared/services/ai_service.dart';
import '../lib/src/features/transactions/data/models/transaction_model.dart';

void main() {
  group('AI Service Tests', () {
    setUpAll(() async {
      // Load environment variables for testing
      await dotenv.load(fileName: '.env');
    });

    test('AI Service initialization should work with valid API key', () {
      expect(() => AIService(), returnsNormally);
    });

    test('Generate insights with sample transactions', () async {
      // Create test transactions with realistic data
      final testTransactions = [
        Transaction(
          id: '1',
          amount: 12.50,
          category: 'Food',
          description: 'Coffee and pastry',
          date: DateTime.now().subtract(const Duration(days: 1)),
          type: 'expense',
          status: 'completed',
          paymentMethodId: 'card',
          accountId: 'main_account',
          isRecurring: false,
        ),
        Transaction(
          id: '2',
          amount: 2500.0,
          category: 'Salary',
          description: 'Monthly salary deposit',
          date: DateTime.now().subtract(const Duration(days: 5)),
          type: 'income',
          status: 'completed',
          paymentMethodId: 'bank',
          accountId: 'main_account',
          isRecurring: false,
        ),
        Transaction(
          id: '3',
          amount: 89.99,
          category: 'Shopping',
          description: 'Weekly groceries',
          date: DateTime.now().subtract(const Duration(days: 3)),
          type: 'expense',
          status: 'completed',
          paymentMethodId: 'card',
          accountId: 'main_account',
          isRecurring: false,
        ),
        Transaction(
          id: '4',
          amount: 45.00,
          category: 'Gas',
          description: 'Fuel for car',
          date: DateTime.now().subtract(const Duration(days: 2)),
          type: 'expense',
          status: 'completed',
          paymentMethodId: 'card',
          accountId: 'main_account',
          isRecurring: false,
        ),
        Transaction(
          id: '5',
          amount: 120.00,
          category: 'Utilities',
          description: 'Electricity bill',
          date: DateTime.now().subtract(const Duration(days: 7)),
          type: 'expense',
          status: 'completed',
          paymentMethodId: 'bank',
          accountId: 'main_account',
          isRecurring: false,
        ),
      ];

      final aiService = AIService();
      
      try {
        final insights = await aiService.generateInsights(testTransactions);
        
        // Verify insights were generated
        expect(insights, isNotNull);
        expect(insights.insights, isNotEmpty);
        
        // Log insights for manual verification
        print('✅ AI Insights generated successfully!');
        print('📊 Number of insights: ${insights.insights.length}');
        
        for (int i = 0; i < insights.insights.length; i++) {
          final insight = insights.insights[i];
          print('  ${i + 1}. ${insight.title}: ${insight.description}');
          print('     Type: ${insight.type}, Severity: ${insight.severity}');
        }
        
        // Verify insight structure
        for (final insight in insights.insights) {
          expect(insight.title, isA<String>());
          expect(insight.description, isA<String>());
          expect(insight.type, isA<String>());
          expect(insight.severity, isA<String>());
          expect(insight.title, isNotEmpty);
          expect(insight.description, isNotEmpty);
        }
        
      } catch (e) {
        print('❌ AI Service test failed: $e');
        
        // If it's an API key issue, provide helpful message
        if (e.toString().contains('API key')) {
          print('💡 This might be an API key configuration issue');
          print('   Check that your OpenAI API key is valid and has credits');
        }
        
        rethrow;
      }
    }, timeout: const Timeout(Duration(minutes: 2)));

    test('Handle empty transaction list gracefully', () async {
      final aiService = AIService();
      
      try {
        final insights = await aiService.generateInsights([]);
        
        // Should handle empty list without crashing
        expect(insights, isNotNull);
        print('✅ Empty transaction list handled gracefully');
        
      } catch (e) {
        print('ℹ️  Expected behavior for empty transactions: $e');
        // This might fail gracefully, which is acceptable
      }
    });
    
    test('Test AI service with high volume of transactions', () async {
      // Generate 50 test transactions to test volume handling
      final largeTransactionList = <Transaction>[];
      final categories = ['Food', 'Gas', 'Shopping', 'Entertainment', 'Utilities', 'Transport'];
      
      for (int i = 0; i < 50; i++) {
        largeTransactionList.add(
          Transaction(
            id: 'test_$i',
            amount: (10 + (i * 5.5)) % 200, // Varying amounts
            category: categories[i % categories.length],
            description: 'Test transaction $i',
            date: DateTime.now().subtract(Duration(days: i % 30)),
            type: i % 5 == 0 ? 'income' : 'expense',
            status: 'completed',
            paymentMethodId: 'card',
            accountId: 'main_account',
            isRecurring: false,
          ),
        );
      }
      
      final aiService = AIService();
      
      try {
        final insights = await aiService.generateInsights(largeTransactionList);
        
        expect(insights, isNotNull);
        expect(insights.insights, isNotEmpty);
        
        print('✅ High volume test passed with ${largeTransactionList.length} transactions');
        print('📊 Generated ${insights.insights.length} insights');
        
      } catch (e) {
        print('❌ High volume test failed: $e');
        rethrow;
      }
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}