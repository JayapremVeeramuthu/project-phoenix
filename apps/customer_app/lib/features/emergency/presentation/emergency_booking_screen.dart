import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class EmergencyBookingScreen extends ConsumerStatefulWidget {
  const EmergencyBookingScreen({super.key});

  @override
  ConsumerState<EmergencyBookingScreen> createState() =>
      _EmergencyBookingScreenState();
}

class _EmergencyBookingScreenState
    extends ConsumerState<EmergencyBookingScreen> {
  String? _selectedEmergencyType;
  bool _submitted = false;

  final List<String> _emergencyTypes = [
    'Electrical Sparking / Blackout',
    'Water Pipe Burst / Flooding',
    'Sewage Backflow',
    'Gas Leak Suspected',
    'Lockout / Security Breach',
  ];

  void _triggerEmergency() async {
    if (_selectedEmergencyType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select the nature of your emergency.')),
      );
      return;
    }
    setState(() {
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;

    return Scaffold(
      backgroundColor: const Color(0xFF7F1D1D), // Dark Red Premium Theme
      appBar: AppBar(
        backgroundColor: const Color(0xFF7F1D1D),
        foregroundColor: Colors.white,
        title: const Text(
          'EMERGENCY DISPATCH',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _submitted
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.yellowAccent, width: 3),
                      ),
                      child: const Icon(
                        Icons
                            .gif_box_outlined, // Replacing with generic animated alert simulation
                        color: Colors.yellowAccent,
                        size: 72,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'DISPATCH TRIGGERED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Priority ticket generated. Allocating nearest available technician from Branch #04 (Anna Nagar).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              'Estimated Arrival Time',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 14),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '12 MINS',
                              style: TextStyle(
                                color: Colors.yellowAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    ElevatedButton(
                      onPressed: () {
                        context.go('${AppRouter.tracking}/em-booking-01');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7F1D1D),
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: const Text(
                        'Track Dispatch Live',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade400),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.yellowAccent, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'WARNING: Emergency bookings bypass standard scheduling. Priority Dispatch fee applies.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Select Emergency Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSeniorMode ? 22 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: _emergencyTypes.map((type) {
                          final isSelected = _selectedEmergencyType == type;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.yellowAccent.withValues(alpha: 0.2)
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.yellowAccent
                                    : Colors.white24,
                                width: 2,
                              ),
                            ),
                            child: ListTile(
                              title: Text(
                                type,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.yellowAccent
                                      : Colors.white,
                                  fontSize: isSeniorMode ? 18 : 16,
                                  fontWeight:
                                      isSelected ? FontWeight.bold : null,
                                ),
                              ),
                              trailing: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? Colors.yellowAccent
                                    : Colors.white60,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedEmergencyType = type;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _triggerEmergency,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellowAccent,
                        foregroundColor: Colors.black,
                        minimumSize:
                            Size(double.infinity, isSeniorMode ? 64 : 52),
                      ),
                      child: Text(
                        'REQUEST EMERGENCY DISPATCH',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 18 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
