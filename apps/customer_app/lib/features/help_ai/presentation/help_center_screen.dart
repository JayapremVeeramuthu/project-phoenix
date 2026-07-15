import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class FaqItem {
  final String category;
  final String question;
  final String answer;

  FaqItem(
      {required this.category, required this.question, required this.answer});
}

class HelpCenterScreen extends ConsumerWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    final List<FaqItem> faqs = [
      FaqItem(
        category: 'Emergency Dispatch',
        question: 'How do I request an Emergency dispatch?',
        answer:
            'Toggle the "EMERGENCY BOOKING" option on the home dashboard or schedule booking step. This queues your request in our top priority queue.',
      ),
      FaqItem(
        category: 'Offline Capability',
        question: 'How does offline booking work?',
        answer:
            'If you have no internet access, the app caches details in SQLite and stores your booking in an offline queue. It automatically uploads once connectivity is restored.',
      ),
      FaqItem(
        category: 'Payments & Billings',
        question: 'What payment methods do you support?',
        answer:
            'We support UPI (GPay, PhonePe), Debit/Credit Cards, Net Banking, and Cash After Service.',
      ),
    ];

    final List<Map<String, String>> guideVideos = [
      {
        'title': 'Checking Your Tripped MCB',
        'duration': '1:24 min',
        'desc':
            'Simple step-by-step diagnostic to check if your main breaker tripped.'
      },
      {
        'title': 'Shutting Off Main Water Line',
        'duration': '0:45 min',
        'desc': 'Learn where to locate the shutoff gate valve in emergencies.'
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI Assistant Banner
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.psychology_outlined,
                        size: 48, color: Colors.teal),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI Diagnostic Assistant',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          const Text(
                              'Troubleshoot issues instantly or ask system recommendations.',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              context.go(AppRouter.aiAssistant);
                            },
                            child: const Text('Chat with AI'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Help Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Opening WhatsApp Support (+91 90000 12345)...')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.chat_outlined,
                                color: Colors.green, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'WhatsApp',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSeniorMode ? 18 : 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Calling Support Hotline 1800-PHOENIX...')),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          children: [
                            const Icon(Icons.phone_in_talk,
                                color: Colors.teal, size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'Call Center',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: isSeniorMode ? 18 : 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Troubleshooting Videos
            Text(
              'Troubleshooting Guides',
              style: TextStyle(
                  fontSize: isSeniorMode ? 22 : 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: guideVideos.length,
                itemBuilder: (context, index) {
                  final video = guideVideos[index];
                  return Container(
                    width: 250,
                    margin: const EdgeInsets.only(right: 12),
                    child: Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade100,
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8)),
                                ),
                                child: const Center(
                                    child: Icon(Icons.play_circle_outline,
                                        size: 40, color: Colors.white)),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: Container(
                                  color: Colors.black87,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 2),
                                  child: Text(
                                    video['duration']!,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(video['title']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                Text(video['desc']!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 11)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // FAQs list
            Text(
              'Frequently Asked Questions',
              style: TextStyle(
                fontSize: isSeniorMode ? 22 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...faqs.map((faq) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text(
                    faq.question,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSeniorMode ? 18 : 15,
                    ),
                  ),
                  subtitle:
                      Text(faq.category, style: const TextStyle(fontSize: 11)),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        faq.answer,
                        style: TextStyle(
                            fontSize: isSeniorMode ? 16 : 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
