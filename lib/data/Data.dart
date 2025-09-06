import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Data extends ChangeNotifier {
  List<SmsMessage> messages = [];
  late DateTime lastUpdated;
  late bool loadingSate;

  Data() {
    init();
  }

  Future<void> init() async {
    loadingSate = true;
    notifyListeners();

    lastUpdated = await getLastUpdated();
    await initMessages();

    loadingSate = false;
    notifyListeners();
  }

  Future<DateTime> getLastUpdated() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    // final storedString = pref.getString('lastUpdated');
    final storedString = null;

    print("Stored string: $storedString");

    if (storedString == null) {
      DateTime oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      // write the current time to the shared preferences
      pref.setString('lastUpdated', oneDayAgo.toString());

      // return a DataTime object with same time one day ago
      return oneDayAgo;

    } else {
      // print how long it has been last updated in mins single line
      print("Last updated: ${DateTime.parse(storedString).difference(DateTime.now()).inMinutes} mins ago");

      return DateTime.parse(storedString);
    }
  }

  Future<void> initMessages() async {
    messages = await getMessagesTillLastUpdated();
    if (messages.isNotEmpty) {
      lastUpdated = messages.first.date!; // Set to the first message's date
      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('lastUpdated', lastUpdated.toString());
    }
    notifyListeners();
  }

  Future<List<SmsMessage>> getMessagesTillLastUpdated() async {
    final SmsQuery query = SmsQuery();
    var permission = await Permission.sms.status;
    if (permission.isGranted) {
      List<SmsMessage> allMessages = [];
      bool continueFetching = true;

      do {
        print("Messages read till now: ${allMessages.length}");
        final msgs = await query.querySms(
          kinds: [
            SmsQueryKind.inbox,
            SmsQueryKind.sent,
          ],
          count: 50, // Increase count for a bigger batch of messages
          sort: true,
        );

        print("Messages fetched: ${msgs.length}");

        // Break out of loop if no new messages
        if (msgs.isEmpty) {
          break;
        }

        // Filter messages to only include those that are after 'lastUpdated'
        allMessages.addAll(
          msgs.where((m) => m.date!.isAfter(lastUpdated)),
        );

        if (allMessages.length >= 100) {
          break;
        }

      } while(allMessages.isNotEmpty && allMessages.last.date!.isAfter(lastUpdated) && continueFetching);

      return allMessages;
    } else {
      await Permission.sms.request();
    }
    return [];
  }
}
