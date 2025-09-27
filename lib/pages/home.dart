import 'package:cash_cache/data/Data.dart';
import 'package:cash_cache/helpers/textHelper.dart';
import 'package:cash_cache/model/Cycle.dart';
import 'package:cash_cache/model/Spend.dart';
import 'package:cash_cache/pages/CyclePage.dart';
import 'package:cash_cache/pages/CyclesListPage.dart';
import 'package:cash_cache/widgets/CycleCard.dart';
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
    final currentCycle = Provider.of<Data>(context).currentCycle;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dashboard"),
        centerTitle: true,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CyclesListPage(),
              ),
            );
          },
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Cyclepage(
                        cycle: currentCycle,
                      ),
                    ),
                  );
                },
                child: CycleCard(currentCycle: currentCycle)),
            const SizedBox(height: 24),
            Text(
              'Pending Spends (${pendingSpends.length})',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Provider.of<Data>(context).loadingSate == true
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: pendingSpends.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final spend = pendingSpends[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.currency_rupee),
                            title: Text(
                              "₹${spend.amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            onTap: () {
                              spendCategoryModalSheet(
                                  context, currentCycle, spend);
                            },
                            subtitle: Text(
                              timeStampToString(spend.dateTime),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.info_outline,
                                  color: Colors.blueAccent),
                              onPressed: () {
                                spendInfoModalSheet(context, spend);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          addCustomSpendModalSheet(context);
        },
      ),
    );
  }

  // create a modal bottom sheet to add a custom spend
  Future<dynamic> addCustomSpendModalSheet(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController infoController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Custom Spend',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: infoController,
                    decoration: const InputDecoration(
                      labelText: 'Info (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${dateToString(selectedDate)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null && picked != selectedDate) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Select Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final double? amount =
                            double.tryParse(amountController.text);
                        final String info = infoController.text;

                        if (amount != null && amount > 0) {
                          final newSpend = Spend(
                            dateTime: selectedDate,
                            amount: amount,
                            info: info,
                          );
                          Provider.of<Data>(context, listen: false)
                              .addPendingSpend(newSpend);
                          Navigator.pop(context);
                        } else {
                          // Show error if amount is invalid
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid amount.'),
                            ),
                          );
                        }
                      },
                      child: const Text(
                        'Add Spend',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<dynamic> spendCategoryModalSheet(
      BuildContext context, Cycle cycle, Spend spend) {
    double sliderValue = spend.amount;

    return showModalBottomSheet(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: MediaQuery.of(context).viewInsets,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Category',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Adding: ₹${sliderValue.toStringAsFixed(2)}",
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value: sliderValue,
                        min: 0,
                        max: spend.amount,
                        label: sliderValue.toStringAsFixed(2),
                        onChanged: (double newValue) {
                          setState(() {
                            sliderValue = newValue;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                sliderValue = spend.amount / 2;
                              });
                            },
                            child: const Text("1/2"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                sliderValue = spend.amount / 3;
                              });
                            },
                            child: const Text("1/3"),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              setState(() {
                                sliderValue = spend.amount / 4;
                              });
                            },
                            child: const Text("1/4"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...cycle.categories.map((category) {
                        return ListTile(
                          leading: const Icon(Icons.label_outline),
                          title: Text(category),
                          onTap: () {
                            Provider.of<Data>(context, listen: false)
                                .addSpendtoCategory(
                              category,
                              Spend.withId(
                                id: spend.id,
                                dateTime: spend.dateTime,
                                amount: sliderValue,
                                info: spend.info,
                              ),
                            );
                            Navigator.pop(context, category);
                          },
                        );
                      }).toList(),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Provider.of<Data>(context, listen: false)
                                .deletePendingSpend(spend);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.delete, color: Colors.white),
                          label: const Text(
                            "Delete Spend",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<dynamic> spendInfoModalSheet(BuildContext context, Spend spend) {
    return showModalBottomSheet(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spend Details',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Amount: ₹${spend.amount.toString()}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'Date: ${dateToString(spend.dateTime)}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Text(
                'Info: ${spend.info}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Close',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
