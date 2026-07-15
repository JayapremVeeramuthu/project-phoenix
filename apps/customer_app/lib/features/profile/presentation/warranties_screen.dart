import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class WarrantyCard {
  final String id;
  final String itemName;
  final String installDate;
  final String expiryDate;
  final String duration;
  final String status; // ACTIVE, EXPIRED

  WarrantyCard({
    required this.id,
    required this.itemName,
    required this.installDate,
    required this.expiryDate,
    required this.duration,
    required this.status,
  });
}

class AmcContract {
  final String id;
  final String applianceName;
  final String scheduleType; // e.g. Quarterly, Bi-Annual
  final String nextServiceDate;
  final int checksRemaining;
  final String status; // ACTIVE, RENEWAL_DUE

  AmcContract({
    required this.id,
    required this.applianceName,
    required this.scheduleType,
    required this.nextServiceDate,
    required this.checksRemaining,
    required this.status,
  });
}

class WarrantiesScreen extends ConsumerWidget {
  const WarrantiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    final List<WarrantyCard> warranties = [
      WarrantyCard(
        id: 'WR-MCB-9988',
        itemName: 'Havells Miniature Circuit Breaker (MCB)',
        installDate: '14 May 2026',
        expiryDate: '14 May 2028',
        duration: '2 Years Manufacturer Warranty',
        status: 'ACTIVE',
      ),
      WarrantyCard(
        id: 'WR-MTR-4422',
        itemName: 'Crompton Water Pump Motor 1HP',
        installDate: '02 Apr 2024',
        expiryDate: '02 Apr 2025',
        duration: '1 Year Brand Warranty',
        status: 'EXPIRED',
      ),
    ];

    final List<AmcContract> amcContracts = [
      AmcContract(
        id: 'AMC-AC-4019',
        applianceName: 'Daikin AC Multi-split System',
        scheduleType: 'Quarterly Routine Maintenance',
        nextServiceDate: '25 Aug 2026',
        checksRemaining: 3,
        status: 'ACTIVE',
      ),
      AmcContract(
        id: 'AMC-RO-9201',
        applianceName: 'Kent Grand Plus RO Purifier',
        scheduleType: 'Bi-Annual Servicing',
        nextServiceDate: '01 Jul 2026',
        checksRemaining: 0,
        status: 'RENEWAL_DUE',
      ),
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Warranty & AMC Contracts'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Product Warranties'),
              Tab(text: 'AMC Contracts'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Warranties Tab
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: warranties.length,
              itemBuilder: (context, index) {
                final card = warranties[index];
                final isExpired = card.status == 'EXPIRED';
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card.id,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isExpired
                                    ? Colors.grey.shade200
                                    : Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color:
                                        isExpired ? Colors.grey : Colors.teal),
                              ),
                              child: Text(
                                card.status,
                                style: TextStyle(
                                  color: isExpired
                                      ? Colors.grey.shade800
                                      : Colors.teal.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          card.itemName,
                          style: TextStyle(
                            fontSize: isSeniorMode ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Installed On: ${card.installDate}'),
                        Text('Expires On: ${card.expiryDate}'),
                        const SizedBox(height: 4),
                        Text(
                          card.duration,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isExpired
                                ? Colors.black54
                                : Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton.icon(
                              onPressed: isExpired
                                  ? null
                                  : () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Raising simulated warranty claim request...')),
                                      );
                                    },
                              icon: const Icon(Icons.support_agent_outlined),
                              label: const Text('Claim Support'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // AMC Tab
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: amcContracts.length,
              itemBuilder: (context, index) {
                final amc = amcContracts[index];
                final isDue = amc.status == 'RENEWAL_DUE';
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              amc.id,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueGrey),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDue
                                    ? Colors.red.shade50
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: isDue ? Colors.red : Colors.green),
                              ),
                              child: Text(
                                isDue ? 'RENEWAL DUE' : 'ACTIVE',
                                style: TextStyle(
                                  color: isDue
                                      ? Colors.red.shade800
                                      : Colors.green.shade800,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          amc.applianceName,
                          style: TextStyle(
                            fontSize: isSeniorMode ? 18 : 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Plan Schedule: ${amc.scheduleType}'),
                        Text('Next Routine Check: ${amc.nextServiceDate}'),
                        const SizedBox(height: 4),
                        Text(
                          '${amc.checksRemaining} Free Maintenance Visits Left',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isDue)
                              ElevatedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Opening checkout to renew AMC contract...')),
                                  );
                                },
                                icon: const Icon(Icons.autorenew_outlined),
                                label: const Text('Renew Plan'),
                              )
                            else
                              OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Requesting routine maintenance visit booking...')),
                                  );
                                },
                                icon: const Icon(Icons.calendar_month),
                                label: const Text('Schedule Service'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
