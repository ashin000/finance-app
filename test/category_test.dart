import 'package:flutter_test/flutter_test.dart';
import 'package:finance/models/transaction_model.dart';

void main() {
  group('AI Local Expense Categorizer Tests', () {
    test('Should classify food-related merchants correctly', () {
      expect(TransactionModel.categorizeLocally('Expense', '', 'Swiggy', 'Swiggy'), 'Food');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Zomato', 'Zomato'), 'Food');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Pizza Hut', 'Pizza Hut'), 'Food');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Starbucks Cafe', 'Starbucks Cafe'), 'Food');
    });

    test('Should classify grocery merchants correctly', () {
      expect(TransactionModel.categorizeLocally('Expense', '', 'Blinkit', 'Blinkit'), 'Groceries');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Zepto', 'Zepto'), 'Groceries');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Reliance Mart', 'Reliance Mart'), 'Groceries');
    });

    test('Should classify fuel and transport merchants correctly', () {
      expect(TransactionModel.categorizeLocally('Expense', '', 'Shell Petrol Pump', 'Shell Petrol Pump'), 'Fuel');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Uber India', 'Uber India'), 'Travel');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Ola Cabs', 'Ola Cabs'), 'Travel');
    });

    test('Should classify shopping and subscription merchants correctly', () {
      expect(TransactionModel.categorizeLocally('Expense', '', 'Amazon Seller', 'Amazon Seller'), 'Shopping');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Netflix India', 'Netflix India'), 'Subscription');
      expect(TransactionModel.categorizeLocally('Expense', '', 'Spotify Premium', 'Spotify Premium'), 'Subscription');
    });

    test('Should classify income, cashback, and refunds correctly', () {
      expect(TransactionModel.categorizeLocally('Income', 'Salary Account', '', ''), 'Salary');
      expect(TransactionModel.categorizeLocally('Cashback', 'Google Pay Cashback', '', ''), 'Cashback');
      expect(TransactionModel.categorizeLocally('Refund', 'Refund from Amazon', '', ''), 'Refund');
    });

    test('Should fallback to Others for unrecognized merchants', () {
      expect(TransactionModel.categorizeLocally('Expense', '', 'Random Store XYZ', 'Random Store XYZ'), 'Others');
    });
  });
}
