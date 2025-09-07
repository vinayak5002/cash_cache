import 'package:cash_cache/data/Data.dart';
import 'package:cash_cache/helpers/textHelper.dart';
import 'package:cash_cache/model/Cycle.dart';
import 'package:cash_cache/model/Spend.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:provider/provider.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

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
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      currentCycle.name,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${currentCycle.totalSpent.toStringAsFixed(2)} / ₹${currentCycle.budget.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: currentCycle.totalSpent > currentCycle.budget
                                ? Colors.red
                                : Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 16),
                    StepProgressIndicator(
                      totalSteps: currentCycle.budget.toInt(),
                      currentStep: currentCycle.totalSpent > currentCycle.budget
                          ? currentCycle.budget.toInt()
                          : currentCycle.totalSpent.toInt(),
                      size: 12,
                      padding: 0,
                      selectedColor:
                          currentCycle.totalSpent > currentCycle.budget
                              ? Colors.red
                              : Colors.yellow,
                      unselectedColor: Colors.grey.shade300,
                      roundedEdges: const Radius.circular(12),
                      selectedGradientColor: currentCycle.totalSpent >
                              currentCycle.budget
                          ? const LinearGradient(
                              colors: [Colors.red, Colors.redAccent],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.yellowAccent, Colors.deepOrange],
                            ),
                      unselectedGradientColor: LinearGradient(
                        colors: [Colors.grey.shade200, Colors.grey.shade400],
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
                                .deleteSpend(spend);
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
