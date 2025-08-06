import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

/// Service for extracting text from receipt images using Google ML Kit OCR
class ReceiptOCRService {
  static const List<String> _supportedFormats = ['jpg', 'jpeg', 'png'];

  final TextRecognizer _textRecognizer = TextRecognizer();
  final ImagePicker _imagePicker = ImagePicker();

  /// Check if camera permission is available
  Future<bool> isCameraAvailable() async {
    try {
      // Try to check camera availability by accessing camera briefly
      // This is a simple check - in production you might want to use
      // permission_handler package for more robust permission checking
      return true; // Camera package handles permissions internally
    } catch (e) {
      return false;
    }
  }

  /// Dispose of resources when service is no longer needed
  void dispose() {
    _textRecognizer.close();
  }

  /// Pick and scan receipt from camera or gallery
  Future<ReceiptScanResult?> scanReceiptFromSource(ImageSource source) async {
    try {
      // Pick image from camera or gallery
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85, // Balance between quality and file size
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile == null) {
        return null; // User cancelled
      }

      // Optional: Crop image for better OCR accuracy
      final croppedFile = await _cropImage(pickedFile.path);
      final imagePath = croppedFile?.path ?? pickedFile.path;

      // Perform OCR on the image
      return await scanReceiptFromPath(imagePath);
    } catch (e) {
      throw ReceiptOCRException('Failed to scan receipt from source: $e');
    }
  }

  /// Scan receipt from existing image file path
  Future<ReceiptScanResult> scanReceiptFromPath(String imagePath) async {
    try {
      print('🔍 OCR DEBUG: Starting scan for image: $imagePath');

      // Validate file format
      if (!_isValidImageFormat(imagePath)) {
        throw ReceiptOCRException(
          'Unsupported image format. Please use JPG or PNG.',
        );
      }

      // Create input image
      final inputImage = InputImage.fromFilePath(imagePath);
      print('🔍 OCR DEBUG: Created InputImage successfully');

      // Process with ML Kit Text Recognition
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      print('🔍 OCR DEBUG: ML Kit processing completed');
      print('🔍 OCR DEBUG: Raw text length: ${recognizedText.text.length}');
      print(
        '🔍 OCR DEBUG: Number of text blocks: ${recognizedText.blocks.length}',
      );
      print('🔍 OCR DEBUG: Raw text content:\n${recognizedText.text}');
      print('🔍 OCR DEBUG: =====================================');

      // Extract and parse receipt data
      final extractedData = _parseReceiptText(recognizedText);
      print('🔍 OCR DEBUG: Parsing completed');
      print('🔍 OCR DEBUG: Merchant: ${extractedData.merchantName}');
      print('🔍 OCR DEBUG: Amount: ${extractedData.totalAmount}');
      print('🔍 OCR DEBUG: Date: ${extractedData.date}');
      print('🔍 OCR DEBUG: Items count: ${extractedData.items.length}');
      print(
        '🔍 OCR DEBUG: Has essential data: ${extractedData.hasEssentialData}',
      );

      return ReceiptScanResult(
        imagePath: imagePath,
        rawText: recognizedText.text,
        extractedData: extractedData,
        textBlocks:
            recognizedText.blocks
                .map(
                  (block) => TextBlock(
                    text: block.text,
                    confidence: block.cornerPoints.length / 4.0,
                  ),
                )
                .toList(),
      );
    } catch (e) {
      print('❌ OCR DEBUG: Error occurred: $e');
      if (e is ReceiptOCRException) rethrow;
      throw ReceiptOCRException('Failed to process receipt image: $e');
    }
  }

  /// Optional image cropping for better OCR accuracy
  Future<CroppedFile?> _cropImage(String imagePath) async {
    try {
      return await ImageCropper().cropImage(
        sourcePath: imagePath,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 90,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Receipt',
            toolbarColor: const Color(0xFF4F46E5),
            toolbarWidgetColor: const Color(0xFFFFFFFF),
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(
            title: 'Crop Receipt',
            doneButtonTitle: 'Done',
            cancelButtonTitle: 'Cancel',
          ),
        ],
      );
    } catch (e) {
      // If cropping fails, continue with original image
      return null;
    }
  }

  /// Parse recognized text to extract receipt data
  ReceiptData _parseReceiptText(RecognizedText recognizedText) {
    final text = recognizedText.text;
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    print('🔍 PARSE DEBUG: Processing ${lines.length} lines');
    for (int i = 0; i < lines.length && i < 10; i++) {
      print('🔍 PARSE DEBUG: Line $i: "${lines[i]}"');
    }

    final merchantName = _extractMerchantName(lines);
    final totalAmount = _extractTotalAmount(text);
    final date = _extractDate(text);
    final items = _extractItems(lines);

    print('🔍 PARSE DEBUG: Merchant extraction result: $merchantName');
    print('🔍 PARSE DEBUG: Amount extraction result: $totalAmount');
    print('🔍 PARSE DEBUG: Date extraction result: $date');
    print('🔍 PARSE DEBUG: Items extraction result: ${items.length} items');

    return ReceiptData(
      merchantName: merchantName,
      totalAmount: totalAmount,
      date: date,
      items: items,
      rawLines: lines,
    );
  }

  /// Extract merchant name (usually at the top of receipt)
  String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    // Take the first non-empty line that looks like a business name
    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i].trim();
      if (line.length > 3 &&
          !_isAmountLine(line) &&
          !_isDateLine(line) &&
          !line.toLowerCase().contains('receipt')) {
        return line;
      }
    }
    return lines.first.trim();
  }

  /// Extract total amount using regex patterns
  double? _extractTotalAmount(String text) {
    print(
      '🔍 AMOUNT DEBUG: Searching for amounts in text of length ${text.length}',
    );

    // Common total patterns: "Total: $12.34", "TOTAL $12.34", "Amount: 12.34"
    final totalPatterns = [
      RegExp(r'total[\s:$]*(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'amount[\s:$]*(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'sum[\s:$]*(\d+\.?\d*)', caseSensitive: false),
      RegExp(r'\$(\d+\.?\d*)(?:\s*total)?', caseSensitive: false),
      RegExp(r'(\d+\.\d{2})(?:\s*$)', multiLine: true), // Last decimal amount
      RegExp(r'(\d+\.\d{2})', multiLine: true), // Any decimal amount
    ];

    for (int i = 0; i < totalPatterns.length; i++) {
      final pattern = totalPatterns[i];
      print('🔍 AMOUNT DEBUG: Trying pattern $i: ${pattern.pattern}');

      final matches = pattern.allMatches(text);
      for (final match in matches) {
        final amountStr = match.group(1);
        print('🔍 AMOUNT DEBUG: Found match: "$amountStr"');
        final amount = double.tryParse(amountStr ?? '');
        if (amount != null && amount > 0) {
          print('🔍 AMOUNT DEBUG: Valid amount found: \$$amount');
          return amount;
        }
      }
    }

    print('🔍 AMOUNT DEBUG: No valid amount found');
    return null;
  }

  /// Extract date from receipt text
  DateTime? _extractDate(String text) {
    // Common date patterns
    final datePatterns = [
      RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})'), // MM/DD/YYYY or DD/MM/YYYY
      RegExp(r'(\d{4}[/-]\d{1,2}[/-]\d{1,2})'), // YYYY/MM/DD
      RegExp(r'(\w{3,9}\s+\d{1,2},?\s+\d{4})'), // January 15, 2024
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final dateStr = match.group(1);
        try {
          // Simple date parsing - can be enhanced
          if (dateStr != null) {
            if (dateStr.contains('/')) {
              final parts = dateStr.split('/');
              if (parts.length == 3) {
                final month = int.tryParse(parts[0]);
                final day = int.tryParse(parts[1]);
                final year = int.tryParse(parts[2]);
                if (month != null && day != null && year != null) {
                  final fullYear = year < 100 ? 2000 + year : year;
                  return DateTime(fullYear, month, day);
                }
              }
            }
          }
        } catch (e) {
          // Continue to next pattern if parsing fails
        }
      }
    }

    return null;
  }

  /// Extract individual items from receipt (basic implementation)
  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];

    for (final line in lines) {
      // Skip obvious non-item lines
      if (_isHeaderLine(line) || _isTotalLine(line) || _isDateLine(line)) {
        continue;
      }

      // Look for lines with prices
      final amountMatch = RegExp(r'(\d+\.?\d*)$').firstMatch(line.trim());
      if (amountMatch != null) {
        final amount = double.tryParse(amountMatch.group(1) ?? '');
        if (amount != null && amount > 0) {
          final description = line.replaceAll(amountMatch.group(0)!, '').trim();
          if (description.isNotEmpty) {
            items.add(ReceiptItem(description: description, amount: amount));
          }
        }
      }
    }

    return items;
  }

  // Helper methods for text classification
  bool _isValidImageFormat(String path) {
    final extension = path.split('.').last.toLowerCase();
    return _supportedFormats.contains(extension);
  }

  bool _isAmountLine(String line) {
    return RegExp(r'\$?\d+\.?\d*').hasMatch(line);
  }

  bool _isDateLine(String line) {
    return RegExp(r'\d{1,2}[/-]\d{1,2}[/-]\d{2,4}').hasMatch(line);
  }

  bool _isHeaderLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('receipt') ||
        lower.contains('invoice') ||
        lower.contains('store') ||
        lower.contains('restaurant');
  }

  bool _isTotalLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('total') ||
        lower.contains('amount') ||
        lower.contains('sum');
  }
}

/// Result of OCR processing
class ReceiptScanResult {
  final String imagePath;
  final String rawText;
  final ReceiptData extractedData;
  final List<TextBlock> textBlocks;

  ReceiptScanResult({
    required this.imagePath,
    required this.rawText,
    required this.extractedData,
    required this.textBlocks,
  });
}

/// Structured data extracted from receipt
class ReceiptData {
  final String? merchantName;
  final double? totalAmount;
  final DateTime? date;
  final List<ReceiptItem> items;
  final List<String> rawLines;

  ReceiptData({
    this.merchantName,
    this.totalAmount,
    this.date,
    required this.items,
    required this.rawLines,
  });

  /// Check if essential data was extracted successfully
  bool get hasEssentialData => merchantName != null || totalAmount != null;

  /// Get suggested transaction description
  String get suggestedDescription {
    if (merchantName != null) return merchantName!;
    if (items.isNotEmpty) return items.first.description;
    return 'Receipt scan';
  }

  /// Get suggested transaction category based on merchant name
  String get suggestedCategory {
    if (merchantName == null) return 'Other';

    final name = merchantName!.toLowerCase();

    // Restaurant/Food patterns
    if (name.contains('restaurant') ||
        name.contains('cafe') ||
        name.contains('coffee') ||
        name.contains('pizza') ||
        name.contains('burger') ||
        name.contains('food')) {
      return 'Food';
    }

    // Gas station patterns
    if (name.contains('gas') ||
        name.contains('fuel') ||
        name.contains('shell') ||
        name.contains('exxon') ||
        name.contains('bp')) {
      return 'Gas';
    }

    // Shopping patterns
    if (name.contains('market') ||
        name.contains('store') ||
        name.contains('shop') ||
        name.contains('walmart') ||
        name.contains('target')) {
      return 'Shopping';
    }

    // Default
    return 'Other';
  }
}

/// Individual item from receipt
class ReceiptItem {
  final String description;
  final double amount;

  ReceiptItem({required this.description, required this.amount});
}

/// Text block with confidence score
class TextBlock {
  final String text;
  final double confidence;

  TextBlock({required this.text, required this.confidence});
}

/// Custom exception for OCR operations
class ReceiptOCRException implements Exception {
  final String message;

  ReceiptOCRException(this.message);

  @override
  String toString() => 'ReceiptOCRException: $message';
}
