import '../models/bill_model.dart';
import '../models/debt_model.dart';
import '../models/group_member_model.dart';

class BillCalculationService {
  
  /// Calculate bill splits based on the split method
  static List<BillSplitModel> calculateSplits({
    required String billId,
    required double totalAmount,
    required String splitMethod,
    required List<GroupMemberModel> selectedMembers,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
  }) {
    switch (splitMethod) {
      case 'equal':
        return _calculateEqualSplit(billId, totalAmount, selectedMembers);
      case 'percentage':
        return _calculatePercentageSplit(billId, totalAmount, selectedMembers, percentages ?? {});
      case 'custom':
        return _calculateCustomSplit(billId, totalAmount, selectedMembers, customAmounts ?? {});
      default:
        throw ArgumentError('Unknown split method: $splitMethod');
    }
  }

  /// Calculate equal split among all selected members
  static List<BillSplitModel> _calculateEqualSplit(
    String billId,
    double totalAmount,
    List<GroupMemberModel> members,
  ) {
    if (members.isEmpty) return [];
    
    final amountPerPerson = totalAmount / members.length;
    final percentage = 100.0 / members.length;
    
    return members.map((member) => BillSplitModel(
      billId: billId,
      userId: member.userId,
      amount: amountPerPerson,
      percentage: percentage,
    )).toList();
  }

  /// Calculate percentage-based split
  static List<BillSplitModel> _calculatePercentageSplit(
    String billId,
    double totalAmount,
    List<GroupMemberModel> members,
    Map<String, double> percentages,
  ) {
    // Validate percentages sum to 100%
    final totalPercentage = percentages.values.fold<double>(0.0, (sum, percentage) => sum + percentage);
    if ((totalPercentage - 100.0).abs() > 0.01) {
      throw ArgumentError('Percentages must sum to 100%. Current sum: $totalPercentage%');
    }

    return members.map((member) {
      final percentage = percentages[member.userId] ?? 0.0;
      final amount = (totalAmount * percentage) / 100.0;
      
      return BillSplitModel(
        billId: billId,
        userId: member.userId,
        amount: amount,
        percentage: percentage,
      );
    }).toList();
  }

  /// Calculate custom amount split
  static List<BillSplitModel> _calculateCustomSplit(
    String billId,
    double totalAmount,
    List<GroupMemberModel> members,
    Map<String, double> customAmounts,
  ) {
    // Validate custom amounts sum to total
    final totalCustom = customAmounts.values.fold<double>(0.0, (sum, amount) => sum + amount);
    if ((totalCustom - totalAmount).abs() > 0.01) {
      throw ArgumentError('Custom amounts must sum to total amount. Current sum: \$${totalCustom.toStringAsFixed(2)}, Expected: \$${totalAmount.toStringAsFixed(2)}');
    }

    return members.map((member) {
      final amount = customAmounts[member.userId] ?? 0.0;
      final percentage = totalAmount > 0 ? (amount / totalAmount) * 100.0 : 0.0;
      
      return BillSplitModel(
        billId: billId,
        userId: member.userId,
        amount: amount,
        percentage: percentage,
      );
    }).toList();
  }

  /// Calculate debts from a bill
  static List<DebtModel> calculateDebtsFromBill(BillModel bill) {
    final debts = <DebtModel>[];
    final payerId = bill.paidByUserId;
    
    for (final split in bill.splits) {
      // Skip if this person paid the bill (they don't owe themselves)
      if (split.userId == payerId) continue;
      
      // Create debt from each split to the payer
      final debt = DebtModel(
        groupId: bill.groupId,
        debtorUserId: split.userId,
        creditorUserId: payerId,
        amount: split.amount,
        currency: bill.currency,
        status: 'active',
        billIds: [bill.id!],
        createdDate: bill.dateCreated,
        payments: [],
      );
      
      debts.add(debt);
    }
    
    return debts;
  }

  /// Optimize debts by combining and offsetting debts between same people
  static List<DebtModel> optimizeDebts(List<DebtModel> debts) {
    final optimizedDebts = <String, DebtModel>{};
    
    for (final debt in debts) {
      if (debt.status != 'active') continue;
      
      final key = _createDebtKey(debt.debtorUserId, debt.creditorUserId);
      final reverseKey = _createDebtKey(debt.creditorUserId, debt.debtorUserId);
      
      if (optimizedDebts.containsKey(reverseKey)) {
        // There's a reverse debt - offset them
        final reverseDebt = optimizedDebts[reverseKey]!;
        final netAmount = debt.amount - reverseDebt.amount;
        
        if (netAmount > 0.01) {
          // Original debt is larger
          optimizedDebts[key] = debt.copyWith(
            amount: netAmount,
            billIds: [...debt.billIds, ...reverseDebt.billIds],
          );
          optimizedDebts.remove(reverseKey);
        } else if (netAmount < -0.01) {
          // Reverse debt is larger
          optimizedDebts[reverseKey] = reverseDebt.copyWith(
            amount: -netAmount,
            billIds: [...reverseDebt.billIds, ...debt.billIds],
          );
        } else {
          // They cancel out
          optimizedDebts.remove(reverseKey);
        }
      } else if (optimizedDebts.containsKey(key)) {
        // Add to existing debt
        final existingDebt = optimizedDebts[key]!;
        optimizedDebts[key] = existingDebt.copyWith(
          amount: existingDebt.amount + debt.amount,
          billIds: [...existingDebt.billIds, ...debt.billIds],
        );
      } else {
        // New debt
        optimizedDebts[key] = debt;
      }
    }
    
    return optimizedDebts.values.toList();
  }

  /// Create a consistent key for debt pairs
  static String _createDebtKey(String debtorId, String creditorId) {
    return '${debtorId}_owes_$creditorId';
  }

  /// Calculate group balance summary
  static Map<String, double> calculateGroupBalances(List<DebtModel> debts) {
    final balances = <String, double>{};
    
    for (final debt in debts) {
      if (debt.status != 'active') continue;
      
      final remainingAmount = debt.remainingAmount;
      if (remainingAmount <= 0.01) continue;
      
      // Debtor owes money (negative balance)
      balances[debt.debtorUserId] = (balances[debt.debtorUserId] ?? 0.0) - remainingAmount;
      
      // Creditor is owed money (positive balance)
      balances[debt.creditorUserId] = (balances[debt.creditorUserId] ?? 0.0) + remainingAmount;
    }
    
    return balances;
  }

  /// Get settlement suggestions to minimize number of transactions
  static List<Map<String, dynamic>> getSettlementSuggestions(Map<String, double> balances) {
    final suggestions = <Map<String, dynamic>>[];
    final debtors = <String, double>{};
    final creditors = <String, double>{};
    
    // Separate debtors and creditors
    balances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors[userId] = -balance; // Make positive
      } else if (balance > 0.01) {
        creditors[userId] = balance;
      }
    });
    
    // Create settlement suggestions
    final debtorsList = debtors.entries.toList();
    final creditorsList = creditors.entries.toList();
    
    int debtorIndex = 0;
    int creditorIndex = 0;
    
    while (debtorIndex < debtorsList.length && creditorIndex < creditorsList.length) {
      final debtorEntry = debtorsList[debtorIndex];
      final creditorEntry = creditorsList[creditorIndex];
      
      final debtorId = debtorEntry.key;
      final debtorAmount = debtorEntry.value;
      final creditorId = creditorEntry.key;
      final creditorAmount = creditorEntry.value;
      
      final settlementAmount = debtorAmount < creditorAmount ? debtorAmount : creditorAmount;
      
      suggestions.add({
        'from': debtorId,
        'to': creditorId,
        'amount': settlementAmount,
      });
      
      // Update remaining amounts
      debtorsList[debtorIndex] = MapEntry(debtorId, debtorAmount - settlementAmount);
      creditorsList[creditorIndex] = MapEntry(creditorId, creditorAmount - settlementAmount);
      
      // Move to next if current is settled
      if (debtorsList[debtorIndex].value <= 0.01) debtorIndex++;
      if (creditorsList[creditorIndex].value <= 0.01) creditorIndex++;
    }
    
    return suggestions;
  }

  /// Validate bill split configuration
  static bool validateSplitConfiguration({
    required String splitMethod,
    required double totalAmount,
    required List<GroupMemberModel> selectedMembers,
    Map<String, double>? customAmounts,
    Map<String, double>? percentages,
  }) {
    if (selectedMembers.isEmpty) return false;
    if (totalAmount <= 0) return false;
    
    switch (splitMethod) {
      case 'equal':
        return true; // Always valid if we have members and amount
      case 'percentage':
        if (percentages == null) return false;
        final totalPercentage = percentages.values.fold<double>(0.0, (sum, p) => sum + p);
        return (totalPercentage - 100.0).abs() <= 0.01;
      case 'custom':
        if (customAmounts == null) return false;
        final totalCustom = customAmounts.values.fold<double>(0.0, (sum, a) => sum + a);
        return (totalCustom - totalAmount).abs() <= 0.01;
      default:
        return false;
    }
  }
}