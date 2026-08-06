import 'package:hive/hive.dart';

class TransactionModel {
  final String id;
  final double amount;
  final String type; // Income, Expense, Refund, Cashback, Failed Payment, Pending Transaction
  final String category; // Food, Groceries, Shopping, Travel, Salary, etc.
  final String sender;
  final String receiver;
  final String merchant;
  final String bank;
  final String upiApp;
  final DateTime timestamp;
  final String notificationText;
  final bool isSynced;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.type,
    required this.category,
    required this.sender,
    required this.receiver,
    required this.merchant,
    required this.bank,
    required this.upiApp,
    required this.timestamp,
    required this.notificationText,
    this.isSynced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  TransactionModel copyWith({
    String? id,
    double? amount,
    String? type,
    String? category,
    String? sender,
    String? receiver,
    String? merchant,
    String? bank,
    String? upiApp,
    DateTime? timestamp,
    String? notificationText,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      merchant: merchant ?? this.merchant,
      bank: bank ?? this.bank,
      upiApp: upiApp ?? this.upiApp,
      timestamp: timestamp ?? this.timestamp,
      notificationText: notificationText ?? this.notificationText,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Firestore JSON serialization
  Map<String, dynamic> toFirestore() {
    return {
      'amount': amount,
      'type': type,
      'category': category,
      'sender': sender,
      'receiver': receiver,
      'merchant': merchant,
      'bank': bank,
      'upiApp': upiApp,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'notificationText': notificationText,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory TransactionModel.fromFirestore(String id, Map<String, dynamic> json) {
    return TransactionModel(
      id: id,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String? ?? 'Expense',
      category: json['category'] as String? ?? 'Others',
      sender: json['sender'] as String? ?? '',
      receiver: json['receiver'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      bank: json['bank'] as String? ?? '',
      upiApp: json['upiApp'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      notificationText: json['notificationText'] as String? ?? '',
      isSynced: true,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  // Kotlin shared preferences JSON mapping
  factory TransactionModel.fromNativeJson(Map<String, dynamic> json) {
    final double parsedAmount = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final String parsedType = json['type'] as String? ?? 'Expense';
    final String senderStr = json['sender'] as String? ?? '';
    final String receiverStr = json['receiver'] as String? ?? '';
    final String merchantStr = json['merchant'] as String? ?? '';

    // Automatic AI local categorizer
    final category = categorizeLocally(parsedType, senderStr, receiverStr, merchantStr);

    return TransactionModel(
      id: json['id'] as String? ?? '${DateTime.now().millisecondsSinceEpoch}_$parsedAmount',
      amount: parsedAmount,
      type: parsedType,
      category: category,
      sender: senderStr,
      receiver: receiverStr,
      merchant: merchantStr,
      bank: json['bank'] as String? ?? '',
      upiApp: json['upiApp'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      notificationText: json['notificationText'] as String? ?? '',
      isSynced: false,
      updatedAt: DateTime.now(),
    );
  }

  static String categorizeLocally(String type, String sender, String receiver, String merchant) {
    if (type == 'Income' || type == 'Cashback' || type == 'Refund') {
      final name = sender.toLowerCase();
      if (name.contains('salary') || name.contains('payroll') || name.contains('employer')) return 'Salary';
      if (name.contains('dividend') || name.contains('mutual') || name.contains('investment')) return 'Investment Return';
      if (name.contains('cashback')) return 'Cashback';
      if (name.contains('refund')) return 'Refund';
      return 'Income';
    } else {
      final dest = (merchant.isNotEmpty ? merchant : receiver).toLowerCase();
      if (dest.contains('swiggy') || dest.contains('zomato') || dest.contains('rest') || dest.contains('cafe') || dest.contains('food') || dest.contains('starbucks') || dest.contains('dominos') || dest.contains('pizza')) {
        return 'Food';
      }
      if (dest.contains('grocery') || dest.contains('supermarket') || dest.contains('blinkit') || dest.contains('instamart') || dest.contains('zepto') || dest.contains('mart') || dest.contains('spencer')) {
        return 'Groceries';
      }
      if (dest.contains('petrol') || dest.contains('shell') || dest.contains('fuel') || dest.contains('hpcl') || dest.contains('iocl') || dest.contains('bpcl')) {
        return 'Fuel';
      }
      if (dest.contains('amazon') || dest.contains('flipkart') || dest.contains('myntra') || dest.contains('shopping') || dest.contains('mall') || dest.contains('decathlon') || dest.contains('trends')) {
        return 'Shopping';
      }
      if (dest.contains('netflix') || dest.contains('spotify') || dest.contains('youtube') || dest.contains('disney') || dest.contains('hotstar') || dest.contains('prime')) {
        return 'Subscription';
      }
      if (dest.contains('uber') || dest.contains('ola') || dest.contains('rapido') || dest.contains('irctc') || dest.contains('metro') || dest.contains('flight') || dest.contains('travel') || dest.contains('bus')) {
        return 'Travel';
      }
      if (dest.contains('recharge') || dest.contains('jio') || dest.contains('airtel') || dest.contains('vi ') || dest.contains('bsnl')) {
        return 'Internet';
      }
      if (dest.contains('electricity') || dest.contains('power') || dest.contains('water') || dest.contains('bescom')) {
        return 'Electricity';
      }
      if (dest.contains('rent') || dest.contains('pg ') || dest.contains('owner')) {
        return 'Rent';
      }
      if (dest.contains('hospital') || dest.contains('pharmacy') || dest.contains('medical') || dest.contains('clinic') || dest.contains('apollo') || dest.contains('doctor')) {
        return 'Healthcare';
      }
      if (dest.contains('school') || dest.contains('college') || dest.contains('udemy') || dest.contains('coursera') || dest.contains('education') || dest.contains('fees')) {
        return 'Education';
      }
      if (dest.contains('emi') || dest.contains('loan') || dest.contains('finance')) {
        return 'EMI';
      }
      if (dest.contains('pvr') || dest.contains('inox') || dest.contains('movie') || dest.contains('ticket') || dest.contains('bookmyshow') || dest.contains('game')) {
        return 'Entertainment';
      }
      return 'Others';
    }
  }
}

// Hive custom adapter for TransactionModel
class TransactionModelAdapter extends TypeAdapter<TransactionModel> {
  @override
  final int typeId = 0;

  @override
  TransactionModel read(BinaryReader reader) {
    return TransactionModel(
      id: reader.readString(),
      amount: reader.readDouble(),
      type: reader.readString(),
      category: reader.readString(),
      sender: reader.readString(),
      receiver: reader.readString(),
      merchant: reader.readString(),
      bank: reader.readString(),
      upiApp: reader.readString(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      notificationText: reader.readString(),
      isSynced: reader.readBool(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, TransactionModel obj) {
    writer.writeString(obj.id);
    writer.writeDouble(obj.amount);
    writer.writeString(obj.type);
    writer.writeString(obj.category);
    writer.writeString(obj.sender);
    writer.writeString(obj.receiver);
    writer.writeString(obj.merchant);
    writer.writeString(obj.bank);
    writer.writeString(obj.upiApp);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
    writer.writeString(obj.notificationText);
    writer.writeBool(obj.isSynced);
    writer.writeInt(obj.updatedAt.millisecondsSinceEpoch);
  }
}
