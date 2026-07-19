import 'dart:async';
import 'dart:math';
import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:project_phoenix_customer/core/services/location_service.dart';
import 'package:project_phoenix_customer/core/services/media_service.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_notifier.dart';
import 'package:project_phoenix_customer/features/services/data/repositories/services_repository.dart';
import 'package:project_phoenix_customer/features/services/domain/entities/service_item.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';
import 'package:shared_models/shared_models.dart';

class ImageUploadTracker {
  final String id;
  final String localPath;
  final XFile xFile;
  double progress;
  String status; // 'uploading', 'success', 'failed'
  String? remoteUrl;
  String? errorMessage;

  ImageUploadTracker({
    required this.id,
    required this.localPath,
    required this.xFile,
    this.progress = 0.0,
    this.status = 'uploading',
    this.remoteUrl,
    this.errorMessage,
  });
}

class BookingFlowScreen extends ConsumerStatefulWidget {
  final String serviceId;

  const BookingFlowScreen({
    super.key,
    required this.serviceId,
  });

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  final _formKeyAddress = GlobalKey<FormState>();
  final _formKeyDescription = GlobalKey<FormState>();

  // Form controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _buildingController = TextEditingController();
  final _streetController = TextEditingController();
  final _areaController = TextEditingController();
  final _cityController = TextEditingController(text: 'Chennai');
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _descController = TextEditingController();
  final _couponController = TextEditingController();

  List<ServiceItem> _selectedServices = [];
  String? _initialCategoryId;
  String _selectedPropertyType = 'Home';

  // Voice Note states
  bool _isRecording = false;
  bool _hasRecorded = false;
  int _secondsRecorded = 0;
  bool _isPlaying = false;
  int _secondsPlayed = 0;
  Timer? _recordingTimer;
  Timer? _playbackTimer;

  // Attached images tracked by state tracker
  final List<ImageUploadTracker> _imageTrackers = [];

  bool _termsAccepted = false;

  List<BookingDto> _realPastBookings = [];
  bool _loadingHistory = true;

  Future<void> _fetchPastBookings() async {
    try {
      final customerId = ref.read(authNotifierProvider).userId;
      if (customerId != null) {
        final repo = ref.read(bookingRepositoryProvider);
        final bookings = await repo.getBookings(page: 1, limit: 50, customerId: customerId);
        final completed = bookings.where((b) => b.status == 'COMPLETED').toList();
        if (mounted) {
          setState(() {
            _realPastBookings = completed;
            _loadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _loadingHistory = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loadingHistory = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = ref.read(authNotifierProvider).userName ?? '';
    final String currentPhone = ref.read(authNotifierProvider).userPhone ?? '';
    _phoneController.text = currentPhone.startsWith('fb_') ? '' : currentPhone;
    _emailController.text = ref.read(authNotifierProvider).userEmail ?? '';
    _buildingController.text = 'Phoenix Tower B, Flat 405';
    _streetController.text = 'OMR Road';
    _areaController.text = 'Thoraipakkam';
    _pincodeController.text = '600096';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPastBookings();
      final service =
          ref.read(servicesRepositoryProvider).getServiceById(widget.serviceId);
      if (service != null) {
        setState(() {
          _selectedServices = [service];
          _initialCategoryId = service.categoryId;
        });
        ref.read(bookingNotifierProvider.notifier).initBookingWithService(service);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _descController.dispose();
    _couponController.dispose();
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  // --- Voice Recording Controls ---
  void _startRecording() {
    setState(() {
      _isRecording = true;
      _hasRecorded = false;
      _secondsRecorded = 0;
      _isPlaying = false;
      _secondsPlayed = 0;
    });
    _playbackTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRecorded >= 30) {
        _stopRecording();
      } else {
        setState(() {
          _secondsRecorded++;
        });
      }
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecorded = true;
    });
    ref.read(bookingNotifierProvider.notifier).addVoiceNote(
          '/local/simulated_voice_note.m4a',
          transcript:
              'AC compressor makes a heavy rattling sound when heating mode starts.',
        );
  }

  void _playVoiceNote() {
    if (_secondsRecorded == 0) return;
    setState(() {
      _isPlaying = true;
      _secondsPlayed = 0;
    });
    _playbackTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsPlayed >= _secondsRecorded) {
        _stopVoiceNotePlayback();
      } else {
        setState(() {
          _secondsPlayed++;
        });
      }
    });
  }

  void _pauseVoiceNote() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
    });
  }

  void _stopVoiceNotePlayback() {
    _playbackTimer?.cancel();
    setState(() {
      _isPlaying = false;
      _secondsPlayed = 0;
    });
  }

  void _deleteVoiceNote() {
    _stopVoiceNotePlayback();
    setState(() {
      _hasRecorded = false;
      _secondsRecorded = 0;
    });
    ref.read(bookingNotifierProvider.notifier).addVoiceNote('', transcript: '');
  }

  double? _gpsLatitude;
  double? _gpsLongitude;
  double? _gpsAccuracy;

  void _fetchCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requesting GPS permission and fetching high-accuracy coordinates...')),
    );
    final locationService = LocationService();
    
    // Request permission correctly
    final permission = await locationService.requestPermission();
    if (!permission.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(permission.message ?? 'Location permission denied.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final loc = await locationService.getCurrentLocation();
      final lat = loc['latitude'] as double;
      final lng = loc['longitude'] as double;
      final accuracy = loc['accuracy'] as double;

      setState(() {
        _gpsLatitude = lat;
        _gpsLongitude = lng;
        _gpsAccuracy = accuracy;
      });

      // Update coordinates in notifier
      ref.read(bookingNotifierProvider.notifier).updateCoordinates(lat, lng);

      // Reverse geocode details
      final addressData = await locationService.reverseGeocode(lat, lng);
      
      setState(() {
        _buildingController.text = addressData['houseNumber'] ?? '';
        _streetController.text = addressData['street'] ?? '';
        _areaController.text = addressData['area'] ?? '';
        _cityController.text = addressData['city'] ?? '';
        _pincodeController.text = addressData['pincode'] ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location resolved with accuracy: ${accuracy.toStringAsFixed(1)}m. Address auto-filled.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to resolve GPS coordinates: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- Real Image Picking & Upload Pipeline ---
  void _pickRealImage(String source, {int? replaceIndex}) async {
    if (_imageTrackers.length >= 10 && replaceIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 10 images allowed'), backgroundColor: Colors.red),
      );
      return;
    }

    final mediaService = MediaService();
    final pickedFile = await mediaService.pickAndCompressImage(source);
    if (pickedFile == null) return;

    // Log selected image path & bytes
    final bytes = await pickedFile.readAsBytes();
    print('[DEBUG] Selected image path: ${pickedFile.path}');
    print('[DEBUG] Image bytes: ${bytes.length} bytes');

    final trackerId = pickedFile.path + DateTime.now().millisecondsSinceEpoch.toString();
    final newTracker = ImageUploadTracker(
      id: trackerId,
      localPath: pickedFile.path,
      xFile: pickedFile,
      progress: 0.0,
      status: 'uploading',
    );

    setState(() {
      if (replaceIndex != null) {
        // Delete old notifier registration first
        final oldTracker = _imageTrackers[replaceIndex];
        if (oldTracker.remoteUrl != null) {
          final notifyIdx = ref.read(bookingNotifierProvider).imagePaths.indexOf(oldTracker.remoteUrl!);
          if (notifyIdx >= 0) {
            ref.read(bookingNotifierProvider.notifier).removeImage(notifyIdx);
          }
        }
        _imageTrackers[replaceIndex] = newTracker;
      } else {
        _imageTrackers.add(newTracker);
      }
    });

    _uploadImageTracker(newTracker);
  }

  void _uploadImageTracker(ImageUploadTracker tracker) async {
    print('[DEBUG] Upload start for: ${tracker.xFile.name}');
    final mediaService = MediaService();

    try {
      final uploadUrl = await mediaService.uploadImageDirectly(
        tracker.xFile,
        onProgress: (progress) {
          setState(() {
            tracker.progress = progress.fraction;
          });
        },
      );

      print('[DEBUG] Upload success for: ${tracker.xFile.name}');
      print('[DEBUG] Returned MinIO URL: $uploadUrl');

      setState(() {
        tracker.status = 'success';
        tracker.remoteUrl = uploadUrl;
      });

      // Synchronize to BookingNotifier state
      ref.read(bookingNotifierProvider.notifier).addImage(uploadUrl);

      // Perform cache eviction/refresh and log it
      print('[DEBUG] Image cache refresh for: $uploadUrl');
      final imageProvider = kIsWeb
          ? NetworkImage(uploadUrl)
          : NetworkImage(uploadUrl) as ImageProvider;
      PaintingBinding.instance.imageCache.evict(imageProvider);

    } catch (e) {
      print('[DEBUG] Upload failed for: ${tracker.xFile.name} with error: $e');
      setState(() {
        tracker.status = 'failed';
        tracker.errorMessage = e.toString();
      });
    }
  }

  void _retryUpload(ImageUploadTracker tracker) {
    setState(() {
      tracker.status = 'uploading';
      tracker.progress = 0.0;
      tracker.errorMessage = null;
    });
    _uploadImageTracker(tracker);
  }

  void _deleteImageTracker(ImageUploadTracker tracker) {
    setState(() {
      final index = _imageTrackers.indexOf(tracker);
      if (index >= 0) {
        _imageTrackers.removeAt(index);
        
        // Remove from notifier if it was uploaded successfully
        if (tracker.remoteUrl != null) {
          final notifyIdx = ref.read(bookingNotifierProvider).imagePaths.indexOf(tracker.remoteUrl!);
          if (notifyIdx >= 0) {
            ref.read(bookingNotifierProvider.notifier).removeImage(notifyIdx);
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingNotifierProvider);
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale;
    final isSeniorMode = settings.isSeniorMode;

    if (state.services.isEmpty || _selectedServices.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final themeAccentColor = state.isEmergency
        ? Colors.red.shade800
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          state.isEmergency ? 'EMERGENCY DISPATCH' : 'Book Service',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: state.isEmergency ? Colors.red.shade800 : null,
          ),
        ),
      ),
      body: Column(
        children: [
          // Steps Indicator Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: themeAccentColor.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final isActive = index <= state.currentStep;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isActive ? themeAccentColor : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: _buildStepContent(
                  state, isSeniorMode, locale, themeAccentColor),
            ),
          ),
          // Stepper Buttons Row
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                if (state.currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref
                            .read(bookingNotifierProvider.notifier)
                            .setStep(state.currentStep - 1);
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize:
                            Size(double.infinity, isSeniorMode ? 60 : 48),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                if (state.currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (state.currentStep == 0 && _selectedServices.isEmpty)
                        ? null
                        : () => _handleNextStep(state),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeAccentColor,
                      foregroundColor: Colors.white,
                      minimumSize:
                          Size(double.infinity, isSeniorMode ? 60 : 48),
                    ),
                    child: Text(
                        state.currentStep == 5 ? 'Confirm & Book' : 'Continue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(BookingFormState state, bool isSeniorMode,
      Locale locale, Color themeColor) {
    switch (state.currentStep) {
      case 0:
        return _buildSubServiceStep(isSeniorMode, locale);
      case 1:
        return _buildComplaintHistoryStep(isSeniorMode, themeColor);
      case 2:
        return _buildAddressStep(isSeniorMode);
      case 3:
        return _buildScheduleStep(state, isSeniorMode, themeColor);
      case 4:
        return _buildDescriptionStep(state, isSeniorMode);
      case 5:
        return _buildReviewStep(state, isSeniorMode, themeColor);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Select Services (Multi-Select) ---
  Widget _buildSubServiceStep(bool isSeniorMode, Locale locale) {
    final servicesRepo = ref.watch(servicesRepositoryProvider);
    final category = _initialCategoryId != null
        ? servicesRepo.getCategoryById(_initialCategoryId!)
        : null;
    final items = category?.items ?? [];
    final selectedCount = _selectedServices.length;
    final runningTotal =
        _selectedServices.fold(0.0, (sum, s) => sum + s.basePrice);
    final totalDuration =
        _selectedServices.fold(0, (sum, s) => sum + s.durationMinutes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Services Required',
          style: TextStyle(
              fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // Selected count badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selectedCount > 0
                ? Colors.green.shade50
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedCount > 0
                  ? Colors.green.shade300
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selectedCount > 0
                    ? Icons.check_circle_rounded
                    : Icons.info_outline,
                size: 18,
                color: selectedCount > 0 ? Colors.green.shade700 : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                selectedCount > 0
                    ? 'Selected Services ($selectedCount)'
                    : 'Tap cards to select services',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: isSeniorMode ? 16 : 13,
                  color:
                      selectedCount > 0 ? Colors.green.shade800 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected =
                _selectedServices.any((s) => s.id == item.id);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedServices.removeWhere((s) => s.id == item.id);
                  } else {
                    _selectedServices = [..._selectedServices, item];
                  }
                });
                ref
                    .read(bookingNotifierProvider.notifier)
                    .toggleService(item);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green.shade50
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? Colors.green.shade600
                        : Colors.grey.shade300,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  title: Text(
                    item.getName(locale),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSeniorMode ? 18 : 15,
                      color: isSelected ? Colors.green.shade900 : null,
                    ),
                  ),
                  subtitle: Text(
                    '₹${item.basePrice.toStringAsFixed(0)}  •  ${item.durationMinutes} min',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.green.shade700
                          : Colors.grey.shade600,
                    ),
                  ),
                  trailing: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      key: ValueKey(isSelected),
                      color: isSelected
                          ? Colors.green.shade700
                          : Colors.grey.shade400,
                      size: 28,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // Running total panel
        if (selectedCount > 0) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSeniorMode ? 16 : 14,
                    color: Colors.green.shade900,
                  ),
                ),
                const SizedBox(height: 10),
                ..._selectedServices.map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              s.getName(locale),
                              style: TextStyle(
                                fontSize: isSeniorMode ? 14 : 13,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                          Text(
                            '₹${s.basePrice.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: isSeniorMode ? 14 : 13,
                              color: Colors.green.shade900,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 16 : 14,
                        color: Colors.green.shade900,
                      ),
                    ),
                    Text(
                      '₹${runningTotal.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 18 : 16,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Est. duration: $totalDuration min',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // --- Step 2: Auto-Complaint History ---
  Widget _buildComplaintHistoryStep(bool isSeniorMode, Color themeColor) {
    if (_loadingHistory) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAutoHistoryHeader(),
          const SizedBox(height: 32),
          const Center(
            child: CircularProgressIndicator(),
          ),
        ],
      );
    }

    if (_realPastBookings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAutoHistoryHeader(),
          const SizedBox(height: 24),
          Text(
            'Previous Service Records',
            style: TextStyle(
                fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'No previous service records found.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAutoHistoryHeader(),
        const SizedBox(height: 24),
        Text(
          'Previous Service Records',
          style: TextStyle(
              fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._realPastBookings.map((log) {
          final serviceName = log.serviceIds.isNotEmpty
              ? log.serviceIds.map((s) => s.split('-').map((w) {
                  if (w.isEmpty) return '';
                  return w[0].toUpperCase() + w.substring(1);
                }).join(' ')).join(', ')
              : 'General Service';
          final formattedDate = log.scheduledAt.isNotEmpty
              ? log.scheduledAt.split('T')[0]
              : 'N/A';
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(serviceName,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Text(formattedDate,
                          style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                  const Divider(),
                  Text('Technician: ${log.technicianName ?? "Awaiting Assignment"}'),
                  const SizedBox(height: 6),
                  Text('Diagnosis: "${log.description}"',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  const SizedBox(height: 6),
                  Text('Materials used: Standard maintenance parts'),
                  const SizedBox(height: 6),
                  Text('Recommendations: System check complete',
                      style: TextStyle(
                          color: themeColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildAutoHistoryHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Auto-History Check: We checked your property files so you do not have to repeat past diagnostics.',
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Detailed Address Form ---
  Widget _buildAddressStep(bool isSeniorMode) {
    return Form(
      key: _formKeyAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address & Property Info',
            style: TextStyle(
                fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Saved Property Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Home', 'Office', 'Rental'].map((type) {
              final isSelected = _selectedPropertyType == type;
              return ChoiceChip(
                label: Text(type),
                selected: isSelected,
                onSelected: (val) {
                  if (val) {
                    setState(() {
                      _selectedPropertyType = type;
                      if (type == 'Home') {
                        _buildingController.text = 'Phoenix Tower B, Flat 405';
                        _streetController.text = 'OMR Road';
                        _areaController.text = 'Thoraipakkam';
                        _pincodeController.text = '600096';
                      } else {
                        _buildingController.clear();
                        _streetController.clear();
                        _areaController.clear();
                        _pincodeController.clear();
                      }
                    });
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _fetchCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Get Current Location via GPS'),
          ),
          const SizedBox(height: 16),
          // Google Map Interactive Simulation
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blueGrey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.shade300, width: 1.5),
            ),
            child: Stack(
              children: [
                // Simulated map grid background lines
                Positioned.fill(
                  child: GridPaper(
                    color: Colors.blue.withValues(alpha: 0.1),
                    interval: 50.0,
                    divisions: 2,
                    subdivisions: 2,
                    child: Container(),
                  ),
                ),
                // Stylized map landmarks
                Positioned(
                  left: 60,
                  top: 40,
                  child: Chip(
                    avatar: const Icon(Icons.apartment, size: 16, color: Colors.blue),
                    label: const Text('Phoenix Tower B', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                Positioned(
                  right: 40,
                  bottom: 50,
                  child: Chip(
                    avatar: const Icon(Icons.restaurant, size: 16, color: Colors.orange),
                    label: const Text('Food Court', style: TextStyle(fontSize: 10)),
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                // Center pin
                Center(
                  child: GestureDetector(
                    onPanUpdate: (details) async {
                      // Simulated Drag action: Randomly offsets latitude and longitude values and auto-fills
                      final random = Random();
                      final currentLat = _gpsLatitude ?? 12.9716;
                      final currentLng = _gpsLongitude ?? 80.2462;
                      final newLat = currentLat + (random.nextDouble() - 0.5) * 0.0005;
                      final newLng = currentLng + (random.nextDouble() - 0.5) * 0.0005;
                      
                      setState(() {
                        _gpsLatitude = newLat;
                        _gpsLongitude = newLng;
                        _gpsAccuracy = 5.0 + random.nextDouble() * 3.0; // Dynamic high accuracy on adjust
                      });

                      ref.read(bookingNotifierProvider.notifier).updateCoordinates(newLat, newLng);
                      
                      final locationService = LocationService();
                      final addressData = await locationService.reverseGeocode(newLat, newLng);
                      setState(() {
                        _buildingController.text = addressData['houseNumber'] ?? '';
                        _streetController.text = addressData['street'] ?? '';
                        _areaController.text = addressData['area'] ?? '';
                        _cityController.text = addressData['city'] ?? '';
                        _pincodeController.text = addressData['pincode'] ?? '';
                      });
                    },
                    child: const Icon(
                      Icons.location_pin,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ),
                // Coordinates display overlay
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _gpsLatitude != null
                                ? 'Lat: ${_gpsLatitude!.toStringAsFixed(4)}, Lng: ${_gpsLongitude!.toStringAsFixed(4)}'
                                : 'Google Maps Preview Active. Drag marker or tap GPS.',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_gpsAccuracy != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _gpsAccuracy! <= 20.0 ? Colors.green : Colors.amber,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Acc: ${_gpsAccuracy!.toStringAsFixed(1)}m',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Customer Name'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Mobile Number'),
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.length != 10
                ? 'Enter a 10-digit number'
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _buildingController,
            decoration: const InputDecoration(
                labelText: 'House / Building / Apartment'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _streetController,
            decoration: const InputDecoration(labelText: 'Street Name'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _areaController,
            decoration: const InputDecoration(labelText: 'Area / Locality'),
            validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _landmarkController,
            decoration: const InputDecoration(labelText: 'Landmark (Optional)'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _pincodeController,
            decoration: const InputDecoration(labelText: 'PIN Code'),
            keyboardType: TextInputType.number,
            validator: (val) =>
                val == null || val.length != 6 ? 'Enter a 6-digit PIN' : null,
          ),
        ],
      ),
    );
  }

  // --- Step 4: Schedule ---
  Widget _buildScheduleStep(
      BookingFormState state, bool isSeniorMode, Color themeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Schedule Date',
          style: TextStyle(
              fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('Today'),
                selected: state.date != null &&
                    DateFormat('yyyy-MM-dd').format(state.date!) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now()),
                onSelected: (selected) {
                  if (selected) {
                    ref
                        .read(bookingNotifierProvider.notifier)
                        .updateDateTime(DateTime.now(), state.timeSlot);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Tomorrow'),
                selected: state.date != null &&
                    DateFormat('yyyy-MM-dd').format(state.date!) ==
                        DateFormat('yyyy-MM-dd').format(
                            DateTime.now().add(const Duration(days: 1))),
                onSelected: (selected) {
                  if (selected) {
                    ref.read(bookingNotifierProvider.notifier).updateDateTime(
                          DateTime.now().add(const Duration(days: 1)),
                          state.timeSlot,
                        );
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              ref
                  .read(bookingNotifierProvider.notifier)
                  .updateDateTime(picked, state.timeSlot);
            }
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            state.date == null
                ? 'Choose Custom Date'
                : 'Selected: ${DateFormat('dd MMM yyyy').format(state.date!)}',
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Preferred Time Slot',
          style: TextStyle(
              fontSize: isSeniorMode ? 18 : 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: ['MORNING', 'AFTERNOON', 'EVENING', 'ANYTIME'].map((slot) {
            return ChoiceChip(
              label: Text(slot),
              selected: state.timeSlot == slot,
              onSelected: (selected) {
                if (selected) {
                  ref
                      .read(bookingNotifierProvider.notifier)
                      .updateDateTime(state.date, slot);
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text(
            'Is this an EMERGENCY?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('Priority queue. Fast technician assignment.'),
          value: state.isEmergency,
          activeColor: Colors.red.shade800,
          onChanged: (val) {
            ref.read(bookingNotifierProvider.notifier).toggleEmergency(val);
          },
        ),
      ],
    );
  }

  Widget _buildTrackerImage(ImageUploadTracker tracker, {required bool fullScreen}) {
    // Print debug log for preview widget rebuild
    print('[DEBUG] Preview widget rebuild with image path: ${tracker.localPath}');

    if (tracker.status == 'failed') {
      return Container(
        color: Colors.red.shade50,
        child: const Center(
          child: Icon(Icons.error_outline, color: Colors.red, size: 36),
        ),
      );
    }

    final path = tracker.remoteUrl ?? tracker.localPath;

    if (tracker.remoteUrl != null) {
      return Image.network(
        tracker.remoteUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('[DEBUG] Error loading remote image: $error');
          return Container(
            color: Colors.red.shade50,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.red)),
          );
        },
      );
    }

    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('[DEBUG] Error loading local Web blob image: $error');
          return Container(
            color: Colors.red.shade50,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.red)),
          );
        },
      );
    } else {
      return Image.file(
        io.File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('[DEBUG] Error loading local Mobile file image: $error');
          return Container(
            color: Colors.red.shade50,
            child: const Center(child: Icon(Icons.broken_image, color: Colors.red)),
          );
        },
      );
    }
  }

  // --- Step 5: Problem Description, Photos, and Voice notes ---
  Widget _buildDescriptionStep(BookingFormState state, bool isSeniorMode) {
    final uploadedCount = _imageTrackers.where((t) => t.status == 'success').length;

    return Form(
      key: _formKeyDescription,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Describe the Issue',
            style: TextStyle(
                fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descController,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Enter details here...',
            ),
          ),
          const Divider(height: 32),
          Text(
            'Photos',
            style: TextStyle(
                fontSize: isSeniorMode ? 18 : 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickRealImage('camera'),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _pickRealImage('gallery'),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
          if (_imageTrackers.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imageTrackers.length,
                itemBuilder: (context, index) {
                  final tracker = _imageTrackers[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Stack(
                      children: [
                        // Thumbnail Preview
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => Dialog(
                                backgroundColor: Colors.black,
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    InteractiveViewer(
                                      child: Center(
                                        child: _buildTrackerImage(tracker, fullScreen: true),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: tracker.status == 'failed'
                                    ? Colors.red
                                    : (tracker.status == 'success' ? Colors.green : Colors.grey.shade400),
                                width: 1.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: _buildTrackerImage(tracker, fullScreen: false),
                            ),
                          ),
                        ),

                        // Upload progress overlay
                        if (tracker.status == 'uploading')
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Uploading...\n${(tracker.progress * 100).toStringAsFixed(0)}%',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Retry overlay on Failure
                        if (tracker.status == 'failed')
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    InkWell(
                                      onTap: () => _retryUpload(tracker),
                                      child: const Icon(Icons.refresh, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Retry',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Replace loop button
                        if (tracker.status != 'uploading')
                          Positioned(
                            left: 2,
                            bottom: 2,
                            child: InkWell(
                              onTap: () {
                                _pickRealImage('gallery', replaceIndex: index);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(4),
                                child: const Icon(Icons.loop, color: Colors.white, size: 14),
                              ),
                            ),
                          ),

                        // Delete Action Button
                        Positioned(
                          top: 2,
                          right: 2,
                          child: InkWell(
                            onTap: () => _deleteImageTracker(tracker),
                            child: Container(
                              decoration: const BoxDecoration(
                                  color: Colors.red, shape: BoxShape.circle),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.delete,
                                  color: Colors.white, size: 12),
                            ),
                          ),
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Uploaded N / 10 Photos Label below image list/section
            Text(
              'Uploaded\n$uploadedCount / 10 Photos',
              style: TextStyle(
                fontSize: isSeniorMode ? 16 : 13,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          const Divider(height: 32),
          Text(
            'Add Voice Note (Max 30s)',
            style: TextStyle(
                fontSize: isSeniorMode ? 18 : 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (!_hasRecorded) ...[
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording
                  ? 'Stop Recording (${_secondsRecorded}s)'
                  : 'Start Recording'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : null),
            ),
            if (_isRecording) ...[
              const SizedBox(height: 12),
              // Animated simulated recording waveform
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(10, (idx) {
                  final ht = 10.0 +
                      (idx % 3 == 0 ? 30.0 : 15.0) *
                          (_secondsRecorded % 2 == 0 ? 0.5 : 1.0);
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: ht,
                    color: Colors.red,
                  );
                }),
              ),
            ],
          ] else ...[
            // Custom Voice Note Player simulation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                            _isPlaying ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.teal),
                        iconSize: 36,
                        onPressed:
                            _isPlaying ? _pauseVoiceNote : _playVoiceNote,
                      ),
                      Expanded(
                        child: Text(
                          _isPlaying
                              ? 'Playing: ${_secondsPlayed}s / ${_secondsRecorded}s'
                              : 'Voice Note: ${_secondsRecorded}s',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.teal),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _deleteVoiceNote,
                      ),
                    ],
                  ),
                  if (_isPlaying)
                    LinearProgressIndicator(
                      value: _secondsPlayed / _secondsRecorded,
                      color: Colors.teal,
                      backgroundColor: Colors.teal.shade100,
                    ),
                ],
              ),
            ),
          ],
          if (state.voiceTranscript != null &&
              state.voiceTranscript!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              width: double.infinity,
              child: Text('AI Transcript preview: "${state.voiceTranscript}"',
                  style: const TextStyle(fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  // --- Step 6: Summary & Confirmation ---
  Widget _buildReviewStep(
      BookingFormState state, bool isSeniorMode, Color themeColor) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale;
    final totalDuration = state.totalDurationMinutes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirm Booking Summary',
          style: TextStyle(
              fontSize: isSeniorMode ? 22 : 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // --- Selected Services List ---
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.build_circle_rounded,
                      color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Booked Services (${state.services.length})',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSeniorMode ? 16 : 14,
                      color: Colors.green.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...state.services.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              s.getName(locale),
                              style: TextStyle(
                                fontSize: isSeniorMode ? 15 : 14,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${s.basePrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: isSeniorMode ? 15 : 14,
                            color: Colors.green.shade900,
                          ),
                        ),
                      ],
                    ),
                  )),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Est. Duration',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.green.shade700,
                    ),
                  ),
                  Text(
                    '$totalDuration min',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Property Type'),
          subtitle: Text(
              '${state.propertyName} - ${_buildingController.text}, ${_streetController.text}'),
          leading: const Icon(Icons.home_work),
        ),
        ListTile(
          title: const Text('Target Location'),
          subtitle: Text(
              '${_areaController.text}, ${_cityController.text} - ${_pincodeController.text}'),
          leading: const Icon(Icons.location_on),
        ),
        ListTile(
          title: const Text('Preferred Slot'),
          subtitle: Text(
              '${state.date != null ? DateFormat('dd MMM yyyy').format(state.date!) : ''} - ${state.timeSlot}'),
          leading: const Icon(Icons.access_time),
        ),
        const Divider(),
        const SizedBox(height: 12),
        // Coupon input field
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _couponController,
                decoration: const InputDecoration(
                    hintText: 'Enter Promo Code (PHOENIX15)'),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final success = ref
                    .read(bookingNotifierProvider.notifier)
                    .applyCoupon(_couponController.text);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          success ? 'Coupon Applied!' : 'Invalid Coupon Code')),
                );
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(100, 48),
              ),
              child: const Text('Apply'),
            ),
          ],
        ),
        if (state.couponCode != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Active Coupon:',
                  style: TextStyle(
                      color: Colors.green, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {
                  ref.read(bookingNotifierProvider.notifier).removeCoupon();
                  _couponController.clear();
                },
                child:
                    const Text('Remove', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Base Price', style: TextStyle(fontSize: 14)),
            Text('₹${state.estimatedPrice.toStringAsFixed(0)}'),
          ],
        ),
        if (state.discountAmount > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Discount Applied',
                  style: TextStyle(color: Colors.green)),
              Text('-₹${state.discountAmount.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.green)),
            ],
          ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grand Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(
              '₹${state.totalAmount.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: themeColor),
            ),
          ],
        ),
        const SizedBox(height: 20),
        CheckboxListTile(
          title: const Text('I agree to terms of services.'),
          value: _termsAccepted,
          onChanged: (val) {
            setState(() {
              _termsAccepted = val ?? false;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Calling Support Hotline...')));
                },
                icon: const Icon(Icons.phone),
                label: const Text('Call Support'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Opening WhatsApp booking helper...')));
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('WhatsApp Book'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleNextStep(BookingFormState state) {
    if (state.currentStep == 0) {
      if (_selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one service'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      ref.read(bookingNotifierProvider.notifier).setStep(1);
    } else if (state.currentStep == 1) {
      ref.read(bookingNotifierProvider.notifier).setStep(2);
    } else if (state.currentStep == 2) {
      if (_formKeyAddress.currentState!.validate()) {
        ref.read(bookingNotifierProvider.notifier).updateProperty(
              _selectedPropertyType,
              '${_buildingController.text}, ${_streetController.text}, ${_areaController.text}, ${_pincodeController.text}',
            );
        ref.read(bookingNotifierProvider.notifier).setStep(3);
      }
    } else if (state.currentStep == 3) {
      if (state.date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select schedule date')));
        return;
      }
      ref.read(bookingNotifierProvider.notifier).setStep(4);
    } else if (state.currentStep == 4) {
      final hasImages = _imageTrackers.isNotEmpty;
      final hasDescription = _descController.text.trim().isNotEmpty;
      final hasVoiceNote = state.voiceNotePath != null && state.voiceNotePath!.isNotEmpty;

      if (!hasImages && !hasDescription && !hasVoiceNote) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add photos, voice note or description.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_imageTrackers.length > 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 10 images allowed.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      ref
          .read(bookingNotifierProvider.notifier)
          .updateDescription(_descController.text.trim());
      ref.read(bookingNotifierProvider.notifier).setStep(5);
    } else if (state.currentStep == 5) {
      if (!_termsAccepted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please accept terms of services.')));
        return;
      }
      _confirmBookingFlow();
    }
  }

  Future<void> _confirmBookingFlow() async {
    final customerId = ref.read(authNotifierProvider).userId ?? 'guest-id';
    final success = await ref
        .read(bookingNotifierProvider.notifier)
        .confirmBooking(customerId);

    if (success && mounted) {
      final state = ref.read(bookingNotifierProvider);
      context.go(
        '${AppRouter.booking}/success?id=${state.generatedBookingId}&offline=${state.isOfflineSaved}',
      );
    }
  }
}
