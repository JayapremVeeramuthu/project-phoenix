import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';
import 'package:project_phoenix_customer/features/profile/presentation/image_crop_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:project_phoenix_customer/features/profile/presentation/widgets/address_selection_sheet.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    _initProfileScreen();
  }

  Future<void> _initProfileScreen() async {
    // Print verification logs requested by the user
    final fbUser = fb.FirebaseAuth.instance.currentUser;
    debugPrint("=== PROFILE OPENED VERIFICATION LOGS ===");
    debugPrint("FirebaseAuth.instance.currentUser: $fbUser");
    if (fbUser != null) {
      debugPrint("  uid: ${fbUser.uid}");
      debugPrint("  email: ${fbUser.email}");
    }
    
    const storage = FlutterSecureStorage();
    final accessToken = await storage.read(key: 'access_token');
    final refreshToken = await storage.read(key: 'refresh_token');
    debugPrint("SecureStorage values:");
    debugPrint("  accessToken: $accessToken");
    debugPrint("  refreshToken: $refreshToken");
    
    final authState = ref.read(authNotifierProvider);
    debugPrint("Riverpod state:");
    debugPrint("  isAuthenticated: ${authState.isAuthenticated}");
    debugPrint("  isGuest: ${authState.isGuest}");
    debugPrint("  userId: ${authState.userId}");
    debugPrint("  userName: ${authState.userName}");
    debugPrint("=========================================");

    final authNotifier = ref.read(authNotifierProvider.notifier);
    
    // Log state, current user, secure storage (via helper)
    await authNotifier.logProfileScreenOpening();

    // Call GET /auth/profile and print the API response
    final userId = ref.read(authNotifierProvider).userId;
    if (userId != null) {
      try {
        final apiClient = ref.read(apiClientProvider);
        final response = await apiClient.get('/auth/profile?userId=$userId');
        debugPrint("=== GET /auth/profile API response ===");
        debugPrint(response.data.toString());
        debugPrint("======================================");
      } catch (e) {
        debugPrint("Failed to fetch profile API response directly for log: $e");
      }
      
      // Perform state refresh
      await authNotifier.fetchLatestProfile();
    }
  }

  Future<void> _showAddPhoneDialog(BuildContext context) async {
    final phoneController = TextEditingController();
    final otpController = TextEditingController();
    String selectedCountryCode = '+91';
    bool codeSent = false;
    bool isVerifying = false;

    await showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(codeSent ? 'Enter OTP' : 'Add Mobile Number'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!codeSent) ...[
                      const Text(
                        'Please enter your mobile number to link it to your account.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          DropdownButton<String>(
                            value: selectedCountryCode,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedCountryCode = value;
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                              DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                              DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                              DropdownMenuItem(value: '+971', child: Text('🇦🇪 +971')),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Phone Number',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      const Text(
                        'A 6-digit verification code has been sent to your mobile number.',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Verification Code',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (!codeSent) {
                            if (phoneController.text.trim().isEmpty) return;
                            setState(() {
                              isVerifying = true;
                            });
                            final fullPhone = '$selectedCountryCode${phoneController.text.trim()}';
                            try {
                              await ref.read(authNotifierProvider.notifier).sendOtpForLinking(fullPhone);
                              setState(() {
                                codeSent = true;
                                isVerifying = false;
                              });
                              // Simulate auto-filling test OTP for easy dev verification
                              Future.delayed(const Duration(seconds: 2), () {
                                if (context.mounted) {
                                  otpController.text = '123456';
                                }
                              });
                            } catch (e) {
                              setState(() {
                                isVerifying = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to send OTP: $e'), backgroundColor: Colors.red),
                              );
                            }
                          } else {
                            if (otpController.text.trim().isEmpty) return;
                            setState(() {
                              isVerifying = true;
                            });
                            final fullPhone = '$selectedCountryCode${phoneController.text.trim()}';
                            final success = await ref
                                .read(authNotifierProvider.notifier)
                                .verifyOtpForLinking(fullPhone, otpController.text.trim());
                            if (success) {
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Mobile number linked successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              setState(() {
                                isVerifying = false;
                              });
                              final errorMsg = ref.read(authNotifierProvider).error ?? 'OTP verification failed';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(codeSent ? 'Verify' : 'Send Code'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    if (!context.mounted) return;

    final croppedBytes = await showDialog<Uint8List>(
      context: context,
      builder: (context) => ImageCropDialog(imageBytes: bytes),
    );

    if (croppedBytes == null) return;

    // Show upload progress indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final dio = ref.read(apiClientProvider).dio;
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          croppedBytes,
          filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      });

      final response = await dio.post(
        '/media/upload',
        data: formData,
      );

      if (response.statusCode == 201) {
        final url = response.data['url'] as String;
        await ref.read(authNotifierProvider.notifier).updateAvatar(url);
      }
    } catch (e) {
      debugPrint('Upload failed: $e');
    } finally {
      if (context.mounted) {
        Navigator.pop(context); // Close loading indicator
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;
    final theme = Theme.of(context);

    final String displayName = authState.isAuthenticated
        ? (authState.userName ?? authState.userEmail ?? authState.userPhone ?? 'Customer')
        : 'Guest Account';

    final String firstLetter = (authState.isAuthenticated
        ? (authState.userName ?? authState.userEmail ?? authState.userPhone ?? 'C')
        : 'Guest')[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Profile',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: isSeniorMode ? 24 : 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Detail Header Card with premium gradient accent
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: authState.isAuthenticated ? () => _pickAndUploadImage(context) : null,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: isSeniorMode ? 44 : 36,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          backgroundImage: authState.userAvatar != null && authState.userAvatar!.isNotEmpty
                              ? NetworkImage(authState.userAvatar!)
                              : null,
                          child: authState.userAvatar == null || authState.userAvatar!.isEmpty
                              ? Text(
                                  firstLetter,
                                  style: TextStyle(
                                    fontSize: isSeniorMode ? 36 : 28,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: isSeniorMode ? 24 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (authState.userRole != null && authState.userRole!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            authState.userRole!,
                            style: TextStyle(
                              color: theme.colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: isSeniorMode ? 14 : 12,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (authState.userEmail != null && authState.userEmail!.isNotEmpty)
                      Text(
                        authState.userEmail!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: isSeniorMode ? 16 : 14,
                        ),
                      ),
                    if (authState.userPhone == null ||
                        authState.userPhone!.isEmpty ||
                        authState.userPhone!.startsWith('fb_'))
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton.icon(
                          onPressed: () => _showAddPhoneDialog(context),
                          icon: const Icon(Icons.add_call, size: 16),
                          label: const Text('Add Mobile Number'),
                          style: TextButton.styleFrom(
                            backgroundColor: theme.colorScheme.primaryContainer,
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            authState.userPhone!,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: isSeniorMode ? 15 : 13,
                            ),
                          ),
                        ),
                      ),
                    if (authState.isAuthenticated) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push(AppRouter.profileEdit),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.green.shade700, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Verified Customer',
                              style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Saved Address Section
            if (authState.isAuthenticated) ...[
              _buildAddressSection(context, authState, isSeniorMode, theme),
              const SizedBox(height: 12),
            ],

            // Quick Stats Row
            if (authState.isAuthenticated) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.handyman_rounded,
                      label: 'Bookings',
                      value: '2',
                      isSeniorMode: isSeniorMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.verified_user_rounded,
                      label: 'Warranties',
                      value: '2',
                      isSeniorMode: isSeniorMode,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      icon: Icons.receipt_long_rounded,
                      label: 'Invoices',
                      value: '2',
                      isSeniorMode: isSeniorMode,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Profile Actions List
            if (authState.isAuthenticated) ...[
              _buildSectionHeader('Account'),
              _buildListTile(
                context,
                icon: Icons.home_work_rounded,
                title: 'Saved Properties',
                subtitle: 'Manage your home & office addresses',
                onTap: () => context.push(AppRouter.profileProperties),
                isSeniorMode: isSeniorMode,
              ),
              _buildListTile(
                context,
                icon: Icons.history_rounded,
                title: 'Booking History',
                subtitle: 'View past bookings and invoices',
                onTap: () => context.push(AppRouter.profileBookings),
                isSeniorMode: isSeniorMode,
              ),
              _buildListTile(
                context,
                icon: Icons.receipt_long_rounded,
                title: 'Digital Invoices',
                subtitle: 'Download and share tax invoices',
                onTap: () => context.push(AppRouter.profileInvoices),
                isSeniorMode: isSeniorMode,
              ),
              _buildListTile(
                context,
                icon: Icons.verified_user_rounded,
                title: 'Warranty Cards',
                subtitle: 'Active warranties & AMC contracts',
                onTap: () => context.push(AppRouter.profileWarranties),
                isSeniorMode: isSeniorMode,
              ),
              const SizedBox(height: 8),
            ],
            _buildSectionHeader('Preferences'),
            _buildListTile(
              context,
              icon: Icons.settings_rounded,
              title: 'App Settings',
              subtitle: 'Theme, language & accessibility',
              onTap: () => context.push(AppRouter.profileSettings),
              isSeniorMode: isSeniorMode,
            ),
            const SizedBox(height: 24),

            // Version info
            Center(
              child: Text(
                'Project Phoenix v2.0.0',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Log Out / Authenticate button
            ElevatedButton.icon(
              onPressed: () async {
                if (authState.isAuthenticated) {
                  await ref.read(authNotifierProvider.notifier).logout();
                }
                if (context.mounted) {
                  context.go(AppRouter.authSelection);
                }
              },
              icon: Icon(authState.isAuthenticated
                  ? Icons.logout_rounded
                  : Icons.login_rounded),
              label: Text(
                authState.isAuthenticated ? 'Sign Out' : 'Sign In',
                style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    authState.isAuthenticated ? Colors.red.shade700 : null,
                foregroundColor:
                    authState.isAuthenticated ? Colors.white : null,
                minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required bool isSeniorMode,
  }) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: isSeniorMode ? 16 : 12,
          horizontal: 12,
        ),
        child: Column(
          children: [
            Icon(icon,
                color: theme.colorScheme.primary,
                size: isSeniorMode ? 28 : 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isSeniorMode ? 20 : 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: isSeniorMode ? 13 : 11,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isSeniorMode,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary,
              size: isSeniorMode ? 24 : 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isSeniorMode ? 18 : 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: isSeniorMode ? 14 : 12),
        ),
        trailing: Icon(Icons.arrow_forward_ios,
            size: isSeniorMode ? 18 : 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4)),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: isSeniorMode ? 8.0 : 4.0,
        ),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmDeleteAddress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Saved Address?'),
        content: const Text(
          'Are you sure you want to remove your saved address? This will delete it from your account and database.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await ref.read(authNotifierProvider.notifier).deleteAddress();
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address removed successfully.'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final err = ref.read(authNotifierProvider).error ?? 'Failed to delete address';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildAddressSection(
    BuildContext context,
    AuthState authState,
    bool isSeniorMode,
    ThemeData theme,
  ) {
    final bool hasAddress = authState.address != null && authState.address!.trim().isNotEmpty;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasAddress ? AppTheme.primaryTeal.withValues(alpha: 0.12) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasAddress ? Icons.location_on_rounded : Icons.location_off_rounded,
                    color: hasAddress ? AppTheme.primaryTeal : Colors.grey.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved Address',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 18 : 16,
                        ),
                      ),
                      Text(
                        hasAddress ? 'Primary Service Location' : 'No default address set',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 13 : 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasAddress)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      'ACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasAddress) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authState.address!,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSeniorMode ? 16 : 14,
                        color: Colors.black87,
                      ),
                    ),
                    if ((authState.city != null && authState.city!.isNotEmpty) ||
                        (authState.state != null && authState.state!.isNotEmpty) ||
                        (authState.pincode != null && authState.pincode!.isNotEmpty)) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (authState.city != null && authState.city!.isNotEmpty) authState.city!,
                          if (authState.state != null && authState.state!.isNotEmpty) authState.state!,
                          if (authState.pincode != null && authState.pincode!.isNotEmpty) 'PIN: ${authState.pincode!}',
                        ].join(', '),
                        style: TextStyle(
                          fontSize: isSeniorMode ? 14 : 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => AddressSelectionSheet.show(context),
                      icon: const Icon(Icons.edit_location_alt_outlined, size: 16),
                      label: Text(
                        'Change Address',
                        style: TextStyle(fontSize: isSeniorMode ? 14 : 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryTeal,
                        side: BorderSide(color: AppTheme.primaryTeal),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteAddress(context),
                    icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                    label: Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: isSeniorMode ? 14 : 13,
                        color: Colors.red,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'No saved address on file. Add your address or use GPS detection so technicians can reach you quickly.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSeniorMode ? 14 : 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => AddressSelectionSheet.show(context),
                      icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                      label: Text(
                        'Add Address via GPS',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 15 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryTeal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
