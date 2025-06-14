import 'package:flutter/material.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';

class TransactionCreatePage extends StatefulWidget {
  const TransactionCreatePage({Key? key}) : super(key: key);

  @override
  _TransactionCreatePageState createState() => _TransactionCreatePageState();
}

class _TransactionCreatePageState extends State<TransactionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _categoryController = TextEditingController();

  Future<void> _createTransaction() async {
    if (_formKey.currentState!.validate()) {
      final transaction = Transaction(
        description: _descriptionController.text,
        amount: double.parse(_amountController.text),
        date: DateTime.parse(_dateController.text),
        category: _categoryController.text,
        type: 'expense', // Default type for now
        status: 'pending', // Default status for now
        paymentMethodId: 'default', // Placeholder
        accountId: 'default', // Placeholder
        isRecurring: false, // Default value
      );

      try {
        await TransactionService().createTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction created successfully')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create transaction: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Transaction')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Date (YYYY-MM-DD)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a date';
                  }
                  try {
                    DateTime.parse(value);
                  } catch (_) {
                    return 'Please enter a valid date';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _createTransaction,
                child: const Text('Create Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
