import 'package:cash_cache/data/Data.dart';
import 'package:cash_cache/helpers/textHelper.dart';
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
                trailing: const Icon(Icons.arrow_forward_ios, size: 18),
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
    );
  }
}
