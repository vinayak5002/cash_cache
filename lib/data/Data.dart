import 'dart:convert';

import 'package:cash_cache/constants/sharedPrefs.dart';
import 'package:cash_cache/model/Cycle.dart';
import 'package:cash_cache/model/Spend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Data extends ChangeNotifier {
  // SMS related fields
  List<SmsMessage> messages = [];
  late DateTime lastUpdated;
  late bool loadingSate;

  // Data
  List<Spend> pendingSpends = [];
  List<Cycle> cycles = [];

  Cycle get currentCycle {
    if (cycles.isNotEmpty) {
      return cycles.last;
    } else {
      // return a default cycle
      return Cycle(
        name: "No Cycle",
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 30)),
        budget: 0,
      );
    }
  }

  Data() {
    init();
  }

  void addPendingSpend(Spend spend) {
    pendingSpends.add(spend);
    savePendingSpendsData();
    notifyListeners();
  }

  void addSpendtoCategory(String category, Spend spend) {
    if (!currentCycle.categories.contains(category)) {
      currentCycle.categories.add(category);
    }
    if (currentCycle.spends.containsKey(category)) {
      currentCycle.spends[category]!.add(spend);
    } else {
      currentCycle.spends[category] = [spend];
    }
    pendingSpends.removeWhere((e) => e.id == spend.id);
    saveAllData();
    notifyListeners();
  }

  void deletePendingSpend(Spend spend) {
    pendingSpends.removeWhere((e) => e.id == spend.id);
    savePendingSpendsData();
    notifyListeners();
  }

  Future<void> init() async {
    loadingSate = true;
    notifyListeners();

    // clear old spends before loading
    pendingSpends = [];

    loadData();

    lastUpdated = await getLastUpdated();
    await initMessages();

    pendingSpends.addAll(extractSpendsFromMessages(messages));
    savePendingSpendsData();

    // clear all spends from shared preferences

    loadingSate = false;
    notifyListeners();
  }

  void loadSampleData() {
    Cycle cycle = Cycle(
      name: "Sample Cycle",
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
      budget: 5000,
    );

    cycle.categories = ["Food", "Transport", "Shopping"];
    // cycle.spends = {
    //   "Food": [
    //     Spend(
    //       dateTime: DateTime.now().subtract(const Duration(days: 5)),
    //       amount: 50,
    //       info: "Grocery shopping",
    //     ),
    //     Spend(
    //       dateTime: DateTime.now().subtract(const Duration(days: 3)),
    //       amount: 30,
    //       info: "Dinner out",
    //     ),
    //   ],
    //   "Transport": [
    //     Spend(
    //       dateTime: DateTime.now().subtract(const Duration(days: 10)),
    //       amount: 20,
    //       info: "Gas refill",
    //     ),
    //   ],
    //   "Shopping": [
    //     Spend(
    //       dateTime: DateTime.now().subtract(const Duration(days: 15)),
    //       amount: 100,
    //       info: "New shoes",
    //     ),
    //   ],
    // };

    cycles = [cycle];

    notifyListeners();
  }

  void loadData() async {
    // load data from shared preferences

    loadCycleData();
    loadPendingSpends();
  }

  void loadCycleData() async {
    // load data from shared preferences

    SharedPreferences pref = await SharedPreferences.getInstance();

    final storedCycleData = pref.getStringList(CYCLE_DATA_STORAGE_KEY);

    if (storedCycleData != null) {
      cycles = storedCycleData
          .map((cycleString) => Cycle.fromMap(jsonDecode(cycleString)))
          .toList();

      print("Data loaded: $storedCycleData");
    } else {
      print("No Cycle data found in shared preferences.");
    }
  }

  void loadPendingSpends() async {
    print("Called loadPendingSpends");
    SharedPreferences pref = await SharedPreferences.getInstance();

    final storedSpendsData = pref.getStringList(SPENDS_DATA_STORAGE_KEY);
    if (storedSpendsData != null) {
      // clear before adding
      pendingSpends.addAll(storedSpendsData
          .map((spendString) => Spend.fromMap(jsonDecode(spendString)))
          .toList());

      print("Pending spends loaded: $storedSpendsData");
    } else {
      print("No Pending spends data found in shared preferences.");
    }
  }

  void saveAllData() {
    print("Saving all data...");
    saveCycleData();
    savePendingSpendsData();
  }

  void saveCycleData() async {
    // save data to shared preferences

    SharedPreferences pref = await SharedPreferences.getInstance();

    final dataToStore =
        cycles.map((cycle) => jsonEncode(cycle.toMap())).toList();

    await pref.setStringList(CYCLE_DATA_STORAGE_KEY, dataToStore);

    print("Cycle Data saved: $dataToStore");
  }

  void savePendingSpendsData() async {
    // save data to shared preferences

    SharedPreferences pref = await SharedPreferences.getInstance();

    final dataToStore =
        pendingSpends.map((spend) => jsonEncode(spend.toMap())).toList();

    await pref.setStringList(SPENDS_DATA_STORAGE_KEY, dataToStore);

    print("Pending spends Data saved: $dataToStore");
  }

  Future<DateTime> getLastUpdated() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    final storedString = pref.getString('lastUpdated');
    // final storedString = null;

    print("Stored string: $storedString");

    if (storedString == null) {
      DateTime oneDayAgo = DateTime.now().subtract(const Duration(days: 5));
      // write the current time to the shared preferences
      pref.setString('lastUpdated', oneDayAgo.toString());

      // return a DataTime object with same time one day ago
      return oneDayAgo;
    } else {
      // print how long it has been last updated in mins single line
      print(
          "Last updated: ${DateTime.parse(storedString).difference(DateTime.now()).inMinutes} mins ago");

      return DateTime.parse(storedString);
    }
  }

  Future<void> initMessages() async {
    messages = await getMessagesTillLastUpdated();
    print('Fetched ${messages.length} new messages');

    if (messages.isNotEmpty) {
      lastUpdated = messages.first.date!;
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('lastUpdated', lastUpdated.toString());
    }
    notifyListeners();
  }

  Future<List<SmsMessage>> getMessagesTillLastUpdated() async {
    final SmsQuery query = SmsQuery();

    var permission = await Permission.sms.status;
    while (permission.isDenied) {
      permission = await Permission.sms.request();
    }

    // Fetch ALL messages at once
    final msgs = await query.querySms(
      kinds: [SmsQueryKind.inbox, SmsQueryKind.sent],
      count: 1000,
      sort: true,
    );

    print("Total messages fetched: ${msgs.length}");

    // Filter to only include those after lastUpdated
    final filtered = msgs.where((m) => m.date!.isAfter(lastUpdated)).toList();

    // Optionally limit to 100
    if (filtered.length > 100) {
      return filtered.take(100).toList();
    }

    return filtered;
  }

  List<Spend> extractSpendsFromMessages(List<SmsMessage> messages) {
    List<Spend> spends = [];

    final spendRegex = RegExp(
      r'\b(?:debited|withdrawn|spent)\b.*?(?:₹|INR|Rs\.?|USD|\$)\s*([\d,]+(?:\.\d{1,2})?)',
      caseSensitive: false,
    );

    for (var message in messages) {
      final match = spendRegex.firstMatch(message.body ?? '');

      if (match != null) {
        final amountString = match.group(1)?.replaceAll(',', '');
        if (amountString != null) {
          final amount = double.tryParse(amountString);
          if (amount != null) {
            print("Extracted spend: $amount from message: ${message.body}");
            spends.add(Spend(
                dateTime: message.date ?? DateTime.now(),
                amount: amount,
                info: message.body ?? ('No info')));
          }
        }
      }
    }

    print("Extracted spends: ${spends.length}");
    return spends;
  }
}
