import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/receipt_ocr_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';

/// Widget for scanning receipts with camera or gallery selection
class ReceiptScannerWidget extends StatefulWidget {
  final Function(ReceiptScanResult) onReceiptScanned;
  final String buttonText;
  final IconData buttonIcon;
  final bool showFullDialog;

  const ReceiptScannerWidget({
    super.key,
    required this.onReceiptScanned,
    this.buttonText = 'Scan Receipt',
    this.buttonIcon = Icons.camera_alt,
    this.showFullDialog = true,
  });

  @override
  State<ReceiptScannerWidget> createState() => _ReceiptScannerWidgetState();
}

class _ReceiptScannerWidgetState extends State<ReceiptScannerWidget> {
  final ReceiptOCRService _ocrService = ReceiptOCRService();
  bool _isProcessing = false;

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: ElevatedButton.icon(
        onPressed: _isProcessing ? null : _showScanOptions,
        icon:
            _isProcessing
                ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                )
                : Icon(widget.buttonIcon),
        label: Text(
          _isProcessing ? 'Processing...' : widget.buttonText,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          elevation: _isProcessing ? 0 : 2,
          shadowColor: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  /// Show options to scan from camera or gallery
  void _showScanOptions() {
    if (widget.showFullDialog) {
      _showFullScanDialog();
    } else {
      _showQuickScanOptions();
    }
  }

  /// Show full dialog with instructions and options
  void _showFullScanDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.camera_alt, color: Color(0xFF4F46E5)),
                SizedBox(width: 8),
                Text('Scan Receipt'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Automatically extract transaction details from your receipt.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tips for better results:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('• Make sure the receipt is well-lit'),
                const Text('• Keep the receipt flat and straight'),
                const Text('• Include the total amount and date'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _scanReceipt(ImageSource.camera);
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _scanReceipt(ImageSource.gallery);
                        },
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  /// Show quick bottom sheet with scan options
  void _showQuickScanOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Scan Receipt',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _ScanOptionCard(
                        icon: Icons.camera_alt,
                        title: 'Camera',
                        subtitle: 'Take a photo',
                        onTap: () {
                          Navigator.of(context).pop();
                          _scanReceipt(ImageSource.camera);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ScanOptionCard(
                        icon: Icons.photo_library,
                        title: 'Gallery',
                        subtitle: 'Choose photo',
                        onTap: () {
                          Navigator.of(context).pop();
                          _scanReceipt(ImageSource.gallery);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  /// Scan receipt from selected source
  Future<void> _scanReceipt(ImageSource source) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _ocrService.scanReceiptFromSource(source);

      if (result != null) {
        // Show scan results before auto-filling
        if (mounted) {
          await _showScanResults(result);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Show scan results for user review
  Future<void> _showScanResults(ReceiptScanResult result) async {
    print('🔍 WIDGET DEBUG: Showing scan results dialog');
    print(
      '🔍 WIDGET DEBUG: Has essential data: ${result.extractedData.hasEssentialData}',
    );
    print('🔍 WIDGET DEBUG: Raw text length: ${result.rawText.length}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _ScanResultsDialog(result: result),
    );

    print('🔍 WIDGET DEBUG: Dialog result: $confirmed');
    if (confirmed == true) {
      print('🔍 WIDGET DEBUG: Calling onReceiptScanned callback');
      widget.onReceiptScanned(result);
    }
  }

  /// Show error dialog with permission-specific help
  void _showErrorDialog(String error) {
    String title = 'Scan Error';
    String message = 'Failed to scan receipt. Please try again.';
    List<Widget> actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('OK'),
      ),
    ];

    // Handle specific error types
    if (error.toLowerCase().contains('permission') ||
        error.toLowerCase().contains('camera_access_denied')) {
      title = 'Camera Permission Required';
      message =
          'To scan receipts, please allow camera access in your device settings.\n\niOS: Settings > Apex Money > Camera\nAndroid: Settings > Apps > Apex Money > Permissions';

      actions = [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // You could add deep linking to settings here if needed
          },
          child: const Text('Open Settings'),
        ),
      ];
    } else if (error.toLowerCase().contains('photo') ||
        error.toLowerCase().contains('gallery')) {
      title = 'Photo Access Required';
      message =
          'To select receipt images, please allow photo library access in your device settings.';
    } else if (error.contains('ReceiptOCRException:')) {
      message = error.replaceAll('ReceiptOCRException: ', '');
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  error.toLowerCase().contains('permission')
                      ? Icons.security
                      : Icons.error_outline,
                  color: AppTheme.errorColor,
                ),
                const SizedBox(width: 8),
                Text(title),
              ],
            ),
            content: Text(message),
            actions: actions,
          ),
    );
  }
}

/// Card widget for scan options
class _ScanOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog to show scan results and allow user to confirm
class _ScanResultsDialog extends StatelessWidget {
  final ReceiptScanResult result;

  const _ScanResultsDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = result.extractedData;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.receipt_long, color: Color(0xFF4F46E5)),
          SizedBox(width: 8),
          Text('Receipt Scanned'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (data.hasEssentialData) ...[
              const Text(
                'Extracted Information:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              if (data.merchantName != null) ...[
                _InfoRow(
                  icon: Icons.store,
                  label: 'Merchant',
                  value: data.merchantName!,
                ),
                const SizedBox(height: 8),
              ],

              if (data.totalAmount != null) ...[
                _InfoRow(
                  icon: Icons.attach_money,
                  label: 'Amount',
                  value: '\$${data.totalAmount!.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
              ],

              if (data.date != null) ...[
                _InfoRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value:
                      '${data.date!.month}/${data.date!.day}/${data.date!.year}',
                ),
                const SizedBox(height: 8),
              ],

              _InfoRow(
                icon: Icons.category,
                label: 'Category',
                value: data.suggestedCategory,
              ),

              if (data.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Items (${data.items.length}):',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.items.length,
                    itemBuilder: (context, index) {
                      final item = data.items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.description,
                                style: const TextStyle(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '\$${item.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Limited information extracted. You can still use this scan and fill in the details manually.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Use This Scan'),
        ),
      ],
    );
  }
}

/// Widget to display info row with icon, label and value
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
