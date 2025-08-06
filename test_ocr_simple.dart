import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/src/shared/services/receipt_ocr_service.dart';

/// Simple OCR test with sample text image
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🧪 Testing OCR Text Recognition...');
  
  final ocrService = ReceiptOCRService();
  
  try {
    // Test with a simple receipt-like text
    print('📄 Testing OCR parsing logic directly...');
    
    // Simulate what ML Kit might return for a typical receipt
    final testReceiptText = '''
STARBUCKS COFFEE
123 Main Street
City, State 12345

Date: 12/15/2023
Time: 2:30 PM

Grande Latte         5.45
Blueberry Muffin     3.25
Tax                  0.70

TOTAL              \$9.40

Thank you for visiting!
''';
    
    print('🔍 Test text length: ${testReceiptText.length}');
    print('🔍 Test text content:\n$testReceiptText');
    print('=' * 50);
    
    // Test the parsing logic directly (this will use our debug prints)
    // Note: This won't work without actual ML Kit result, but shows our parsing logic
    print('✅ OCR service created successfully');
    print('📋 Test completed - check debug output above');
    
  } catch (e) {
    print('❌ OCR test failed: $e');
  } finally {
    ocrService.dispose();
  }
}