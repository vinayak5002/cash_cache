import 'package:cash_cache/data/Data.dart';
import 'package:cash_cache/helpers/textHelper.dart';
import 'package:cash_cache/model/Cycle.dart';
import 'package:cash_cache/pages/CyclePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CyclesListPage extends StatefulWidget {
  const CyclesListPage({super.key});

  @override
  State<CyclesListPage> createState() => _CyclesListPageState();
}

class _CyclesListPageState extends State<CyclesListPage> {
  @override
  Widget build(BuildContext context) {
    final cycles = Provider.of<Data>(context).cycles;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cycles Page',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView.builder(
          itemCount: cycles.length,
          itemBuilder: (context, index) {
            final cycle = cycles[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Text(
                    cycle.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  cycle.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 6),
                          Text(
                            'Start: ${dateToString(cycle.startDate.toLocal())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.event,
                              size: 16, color: Colors.redAccent),
                          const SizedBox(width: 6),
                          Text(
                            'End:   ${dateToString(cycle.endDate.toLocal())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Budget: Rs.${cycle.budget}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: GestureDetector(
                  child: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Delete Cycle"),
                        content: const Text(
                            "Are you sure you want to delete this cycle?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Provider.of<Data>(context, listen: false)
                                  .deleteCycle(
                                      cycle); // 👈 implement this in Data
                              Navigator.of(ctx).pop();
                            },
                            child: const Text("Delete"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Cyclepage(cycle: cycle),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateCycleDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateCycleDialog(BuildContext context) {
    final nameController = TextEditingController();
    final budgetController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create New Cycle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: "Cycle Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: budgetController,
                      decoration:
                          const InputDecoration(labelText: "Budget (Rs.)"),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(startDate == null
                          ? "Select Start Date"
                          : "Start: ${dateToString(startDate!)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            startDate = picked;
                          });
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(endDate == null
                          ? "Select End Date"
                          : "End: ${dateToString(endDate!)}"),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate:
                              startDate ?? DateTime.now(), // after start
                          firstDate: startDate ?? DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            endDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final budget =
                        double.tryParse(budgetController.text) ?? 0.0;

                    if (name.isNotEmpty &&
                        startDate != null &&
                        endDate != null) {
                      final newCycle = Cycle(
                        name: name,
                        startDate: startDate!,
                        endDate: endDate!,
                        budget: budget,
                      );

                      Provider.of<Data>(context, listen: false)
                          .addCycle(newCycle);
                      Navigator.pop(ctx);
                    } else {
                      // optional: show warning if date not selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Please select start and end dates")),
                      );
                    }
                  },
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
