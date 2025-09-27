import 'package:cash_cache/constants/styling.dart';
import 'package:cash_cache/data/Data.dart';
import 'package:cash_cache/helpers/textHelper.dart';
import 'package:cash_cache/model/Cycle.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart' as pc;
import 'package:fl_chart/fl_chart.dart' as fl;
import 'package:provider/provider.dart';

class Cyclepage extends StatefulWidget {
  final Cycle cycle;

  const Cyclepage({super.key, required this.cycle});

  @override
  State<Cyclepage> createState() => _CyclepageState();
}

class _CyclepageState extends State<Cyclepage> {
  List<String> _days = [];
  Map<String, Map<String, double>> _dailySpends = {};

  @override
  void initState() {
    super.initState();
    _prepareDailySpends();
  }

  void _prepareDailySpends() {
    _dailySpends = {};

    widget.cycle.spends.forEach((category, spends) {
      for (var spend in spends) {
        final day = spend.dateTime.toString().split(" ")[0];
        _dailySpends.putIfAbsent(day, () => {});
        _dailySpends[day]![category] =
            (_dailySpends[day]![category] ?? 0) + spend.amount;
      }
    });

    _days = _dailySpends.keys.toList()..sort();
  }

  List<fl.BarChartGroupData> _buildBarGroups() {
    _dailySpends = {};

    widget.cycle.spends.forEach((category, spends) {
      for (var spend in spends) {
        final day = spend.dateTime.toString().split(" ")[0];
        _dailySpends.putIfAbsent(day, () => {});
        _dailySpends[day]![category] =
            (_dailySpends[day]![category] ?? 0) + spend.amount;
      }
    });

    _days = _dailySpends.keys.toList()..sort();

    List<fl.BarChartGroupData> groups = [];
    for (int i = 0; i < _days.length; i++) {
      final day = _days[i];
      final categoryMap = _dailySpends[day]!;

      double runningTotal = 0;
      final rodStackItems = <fl.BarChartRodStackItem>[];

      for (int j = 0; j < widget.cycle.categories.length; j++) {
        final category = widget.cycle.categories[j];
        final amount = categoryMap[category] ?? 0;

        if (amount > 0) {
          final start = runningTotal;
          runningTotal += amount;
          rodStackItems.add(fl.BarChartRodStackItem(
            start,
            runningTotal,
            colorList[j % colorList.length],
          ));
        }
      }

      groups.add(
        fl.BarChartGroupData(
          x: i,
          barRods: [
            fl.BarChartRodData(
              toY: runningTotal,
              rodStackItems: rodStackItems,
              width: 20,
              borderRadius: BorderRadius.zero,
            ),
          ],
        ),
      );
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, double> dataMap = {
      for (var category in widget.cycle.categories) category: 0.0,
    };

    for (var key in widget.cycle.spends.keys) {
      dataMap[key] = widget.cycle.spends[key]!
          .fold(0.0, (sum, spend) => sum + spend.amount);
    }

    final hasSpends = dataMap.values.any((v) => v > 0);
    print("Has spends: $hasSpends");
    print(widget.cycle.spends);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cycle Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              widget.cycle.id ==
                      Provider.of<Data>(context, listen: false)
                          .getCurrentCycleId()
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            onPressed: () {
              Provider.of<Data>(context, listen: false)
                  .setAsCurrentCycle(widget.cycle.id);
              setState(() {});
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            hasSpends
                ? pc.PieChart(
                    dataMap: dataMap,
                    animationDuration: const Duration(milliseconds: 800),
                    chartLegendSpacing: 32,
                    chartRadius: MediaQuery.of(context).size.width / 2.0,
                    colorList: colorList,
                    initialAngleInDegree: 0,
                    chartType: pc.ChartType.disc,
                    ringStrokeWidth: 32,
                    legendOptions: const pc.LegendOptions(
                      showLegendsInRow: false,
                      legendPosition: pc.LegendPosition.right,
                      showLegends: true,
                      legendShape: BoxShape.circle,
                      legendTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    chartValuesOptions: const pc.ChartValuesOptions(
                      showChartValueBackground: true,
                      showChartValues: true,
                      showChartValuesInPercentage: false,
                      showChartValuesOutside: false,
                      decimalPlaces: 1,
                    ),
                  )
                : const Center(
                    child: Text(
                      "No spends recorded yet",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            Expanded(
              child: DefaultTabController(
                length: 2, // 👈 two tabs
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TabBar(
                      labelColor: Colors.blue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue,
                      tabs: [
                        Tab(text: "Categories"),
                        Tab(text: "Graphs"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: TabBarView(
                        children: [
                          // ---------------- Tab 1: Category List ----------------
                          ListView.builder(
                            itemCount: widget.cycle.categories.length,
                            itemBuilder: (context, index) {
                              final category = widget.cycle.categories[index];
                              final spends =
                                  widget.cycle.spends[category] ?? [];
                              final totalSpent = spends.fold(
                                  0.0, (sum, spend) => sum + spend.amount);

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blueAccent,
                                    child: Text(
                                      category[0].toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Total Spent: Rs.${totalSpent.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${spends.length} items',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    final spends =
                                        widget.cycle.spends[category] ?? [];

                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20)),
                                      ),
                                      builder: (_) {
                                        return StatefulBuilder(
                                          builder: (context, setModalState) {
                                            return DraggableScrollableSheet(
                                              expand: false,
                                              initialChildSize: 0.6,
                                              minChildSize: 0.4,
                                              maxChildSize: 0.9,
                                              builder:
                                                  (context, scrollController) {
                                                return Padding(
                                                  padding: const EdgeInsets.all(
                                                      16.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Spends in $category",
                                                        style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 10),
                                                      Expanded(
                                                        child: ListView.builder(
                                                          controller:
                                                              scrollController,
                                                          itemCount:
                                                              spends.length,
                                                          itemBuilder:
                                                              (context, index) {
                                                            final spend =
                                                                spends[index];
                                                            return ListTile(
                                                              leading: const Icon(
                                                                  Icons
                                                                      .payments,
                                                                  color: Colors
                                                                      .blue),
                                                              title: Text(
                                                                  "₹${spend.amount.toStringAsFixed(2)}"),
                                                              subtitle: Text(
                                                                  dateToString(spend
                                                                      .dateTime)),
                                                              trailing:
                                                                  IconButton(
                                                                icon: const Icon(
                                                                    Icons
                                                                        .delete,
                                                                    color: Colors
                                                                        .red),
                                                                onPressed: () {
                                                                  // Remove spend from the category
                                                                  setModalState(
                                                                      () {
                                                                    spends.removeAt(
                                                                        index);
                                                                    widget.cycle
                                                                            .spends[category] =
                                                                        spends;
                                                                  });

                                                                  // Update parent state so graphs/categories reflect deletion
                                                                  setState(
                                                                      () {});
                                                                },
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
                                ),
                              );
                            },
                          ),

                          // ---------------- Tab 2: Graphs ----------------
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: AspectRatio(
                                    aspectRatio: 1.6,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: _days.length *
                                            40.0, // 👈 40 px per bar group
                                        child: fl.BarChart(
                                          fl.BarChartData(
                                            alignment: fl
                                                .BarChartAlignment.spaceAround,
                                            titlesData: fl.FlTitlesData(
                                              show: true,
                                              bottomTitles: fl.AxisTitles(
                                                sideTitles: fl.SideTitles(
                                                  showTitles: true,
                                                  getTitlesWidget:
                                                      (double value,
                                                          fl.TitleMeta meta) {
                                                    if (value.toInt() <
                                                        _days.length) {
                                                      return fl.SideTitleWidget(
                                                        meta: meta,
                                                        child: Text(
                                                          _days[value.toInt()]
                                                              .substring(
                                                                  5), // e.g. "09-26" if yyyy-mm-dd
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 10),
                                                        ),
                                                      );
                                                    }
                                                    return const SizedBox
                                                        .shrink();
                                                  },
                                                  reservedSize: 32,
                                                ),
                                              ),
                                              leftTitles: fl.AxisTitles(
                                                sideTitles: fl.SideTitles(
                                                  showTitles: true,
                                                  reservedSize: 40,
                                                  getTitlesWidget:
                                                      (value, meta) {
                                                    if (value == meta.max)
                                                      return Container();
                                                    return Text(
                                                      value.toInt().toString(),
                                                      style: const TextStyle(
                                                          fontSize: 10),
                                                    );
                                                  },
                                                ),
                                              ),
                                              topTitles: const fl.AxisTitles(
                                                sideTitles: fl.SideTitles(
                                                    showTitles: false),
                                              ),
                                              rightTitles: const fl.AxisTitles(
                                                sideTitles: fl.SideTitles(
                                                    showTitles: false),
                                              ),
                                            ),
                                            gridData: fl.FlGridData(
                                              show: true,
                                              checkToShowHorizontalLine:
                                                  (value) => value % 100 == 0,
                                              getDrawingHorizontalLine:
                                                  (value) => fl.FlLine(
                                                color: Colors.grey
                                                    .withOpacity(0.2),
                                                strokeWidth: 1,
                                              ),
                                              drawVerticalLine: false,
                                            ),
                                            borderData:
                                                fl.FlBorderData(show: false),
                                            barGroups: _buildBarGroups(),
                                            barTouchData: fl.BarTouchData(
                                              touchCallback:
                                                  (fl.FlTouchEvent event,
                                                      fl.BarTouchResponse?
                                                          response) {
                                                if (event is! fl.FlTapUpEvent ||
                                                    response == null ||
                                                    response.spot == null) {
                                                  return;
                                                }

                                                final index = response
                                                    .spot!.touchedBarGroupIndex;
                                                if (index >= 0 &&
                                                    index < _days.length) {
                                                  final day = _days[index];
                                                  final spendsOnDay =
                                                      _dailySpends[day] ?? {};

                                                  showModalBottomSheet(
                                                    context: context,
                                                    shape:
                                                        const RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.vertical(
                                                              top: Radius
                                                                  .circular(
                                                                      20)),
                                                    ),
                                                    builder: (_) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16.0),
                                                        child: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              "Spends on ${formatDate(day)}",
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 18,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 10),
                                                            ...spendsOnDay
                                                                .entries
                                                                .map((entry) =>
                                                                    ListTile(
                                                                      leading:
                                                                          CircleAvatar(
                                                                        backgroundColor:
                                                                            colorList[widget.cycle.categories.indexOf(entry.key) %
                                                                                colorList.length],
                                                                        child: Text(
                                                                            entry.key[0]
                                                                                .toUpperCase(),
                                                                            style:
                                                                                const TextStyle(color: Colors.white)),
                                                                      ),
                                                                      title: Text(
                                                                          entry
                                                                              .key),
                                                                      trailing:
                                                                          Text(
                                                                        "₹${entry.value.toStringAsFixed(2)}",
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.green),
                                                                      ),
                                                                    )),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // showmodal to add category
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              String newCategory = '';

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[400],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      "Add Category",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      autofocus: true, // 👈 opens keyboard automatically
                      decoration: InputDecoration(
                        labelText: 'New Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      onChanged: (value) {
                        newCategory = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (newCategory.isNotEmpty &&
                              !widget.cycle.categories.contains(newCategory)) {
                            setState(() {
                              widget.cycle.categories.add(newCategory);
                              widget.cycle.spends[newCategory] = [];
                            });
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Add Category',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
