import 'package:cash_cache/data/Data.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:provider/provider.dart';

onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage called");
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final pendingSpends = Provider.of<Data>(context).pendingSpends;

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          )
        ],
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          children: [
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            Provider.of<Data>(context).loadingSate == true
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: pendingSpends.length,
                      itemBuilder: (context, index) {
                        final spend = pendingSpends[index];
                        return ListTile(
                          title: Text(spend.amount.toString()),
                          subtitle: Text(spend.dateTime.toString()),
                          trailing: IconButton(
                              onPressed: () => {
                                    // diplay modal sheet
                                    showModalBottomSheet(
                                      context: context,
                                      builder: (context) {
                                        return Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Spend Details',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .headlineSmall,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                  'Amount: ₹${spend.amount.toString()}'),
                                              Text(
                                                  'Date: ${spend.dateTime.toString()}'),
                                              Text('Info: ${spend.info}'),
                                              const SizedBox(height: 16),
                                              ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text('Close'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    )
                                  },
                              icon: const Icon(Icons.info)),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
