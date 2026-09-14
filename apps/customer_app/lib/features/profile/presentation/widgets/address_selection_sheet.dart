import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/services/location_service.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';
import 'package:shared_theme/shared_theme.dart';

class AddressSelectionSheet extends ConsumerStatefulWidget {
  final String? initialAddress;
  final String? initialCity;
  final String? initialState;
  final String? initialPincode;

  const AddressSelectionSheet({
    super.key,
    this.initialAddress,
    this.initialCity,
    this.initialState,
    this.initialPincode,
  });

  static Future<bool?> show(BuildContext context) {
    final auth = ProviderScope.containerOf(context, listen: false).read(authNotifierProvider);
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddressSelectionSheet(
        initialAddress: auth.address,
        initialCity: auth.city,
        initialState: auth.state,
        initialPincode: auth.pincode,
      ),
    );
  }

  @override
  ConsumerState<AddressSelectionSheet> createState() => _AddressSelectionSheetState();
}

class _AddressSelectionSheetState extends ConsumerState<AddressSelectionSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _buildingController;
  late TextEditingController _streetController;
  late TextEditingController _areaController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;

  bool _isFetchingLocation = false;
  bool _isSaving = false;
  String? _gpsStatusMessage;
  double? _resolvedLat;
  double? _resolvedLng;
  double? _resolvedAccuracy;

  @override
  void initState() {
    super.initState();
    _buildingController = TextEditingController();
    _streetController = TextEditingController(text: widget.initialAddress ?? '');
    _areaController = TextEditingController();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _stateController = TextEditingController(text: widget.initialState ?? '');
    _pincodeController = TextEditingController(text: widget.initialPincode ?? '');
  }

  @override
  void dispose() {
    _buildingController.dispose();
    _streetController.dispose();
    _areaController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isFetchingLocation = true;
      _gpsStatusMessage = 'Requesting GPS satellite & device coordinates...';
    });

    try {
      final locationService = ref.read(locationServiceProvider);
      final loc = await locationService.getCurrentLocation();
      final lat = (loc['latitude'] as num).toDouble();
      final lng = (loc['longitude'] as num).toDouble();
      final accuracy = (loc['accuracy'] as num).toDouble();

      setState(() {
        _resolvedLat = lat;
        _resolvedLng = lng;
        _resolvedAccuracy = accuracy;
        _gpsStatusMessage = 'Coordinates resolved (±${accuracy.toStringAsFixed(1)}m). Reverse geocoding address...';
      });

      // Real Reverse Geocode via backend / OpenStreetMap Nominatim
      final addressData = await locationService.reverseGeocode(lat, lng);

      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _buildingController.text = addressData['houseNumber'] ?? '';
          _streetController.text = addressData['street'] ?? '';
          _areaController.text = addressData['area'] ?? '';
          _cityController.text = addressData['city'] ?? '';
          _stateController.text = addressData['state'] ?? '';
          _pincodeController.text = addressData['pincode'] ?? '';
          _gpsStatusMessage = 'Real GPS location applied successfully!';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Real address resolved from GPS (Accuracy: ${accuracy.toStringAsFixed(1)}m)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFetchingLocation = false;
          _gpsStatusMessage = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not obtain GPS location: ${e.toString().replaceAll("Exception: ", "")}'),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    // Format address line from building, street, and area
    final parts = [
      _buildingController.text.trim(),
      _streetController.text.trim(),
      _areaController.text.trim(),
    ].where((s) => s.isNotEmpty).toList();

    final fullAddress = parts.isNotEmpty ? parts.join(', ') : _streetController.text.trim();
    final city = _cityController.text.trim();
    final stateName = _stateController.text.trim();
    final pincode = _pincodeController.text.trim();

    debugPrint('[ADDRESS_SHEET] _saveAddress triggered');
    debugPrint('[ADDRESS_SHEET] fullAddress="$fullAddress", city="$city", state="$stateName", pincode="$pincode"');

    final success = await ref.read(authNotifierProvider.notifier).updateAddress(
      address: fullAddress,
      city: city,
      stateName: stateName,
      pincode: pincode,
    );

    debugPrint('[ADDRESS_SHEET] updateAddress returned: success=$success');

    if (mounted) {
      setState(() {
        _isSaving = false;
      });

      if (success) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = ref.read(authNotifierProvider).error ?? 'Failed to save address';
        debugPrint('[ADDRESS_SHEET] Address save failed: $error');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorMode = ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialAddress == null || widget.initialAddress!.isEmpty
                        ? 'Set Your Address'
                        : 'Change Saved Address',
                    style: TextStyle(
                      fontSize: isSeniorMode ? 22 : 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // GPS Quick Action Banner Button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal.withValues(alpha: 0.12),
                      Colors.teal.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.primaryTeal.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Use Current GPS Location',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSeniorMode ? 16 : 14,
                                  color: Colors.teal.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Auto-detect coordinates & reverse-geocode address',
                                style: TextStyle(
                                  fontSize: isSeniorMode ? 13 : 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: 80,
                            maxWidth: 120,
                          ),
                          child: ElevatedButton(
                            onPressed: _isFetchingLocation ? null : _fetchCurrentLocation,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTeal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              elevation: 0,
                            ),
                            child: _isFetchingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Locate Me', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                    if (_gpsStatusMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.teal.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isFetchingLocation ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                              size: 14,
                              color: _isFetchingLocation ? Colors.orange : Colors.green,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _gpsStatusMessage!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.teal.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_resolvedLat != null && _resolvedLng != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade100.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.satellite_alt_rounded, size: 12, color: Colors.teal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'GPS: ${_resolvedLat!.toStringAsFixed(5)}° N, ${_resolvedLng!.toStringAsFixed(5)}° E (${_resolvedAccuracy != null ? '±${_resolvedAccuracy!.toStringAsFixed(1)}m accuracy' : 'high precision'})',
                                style: TextStyle(fontSize: 10, color: Colors.teal.shade900, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Form fields
              TextFormField(
                controller: _buildingController,
                decoration: InputDecoration(
                  labelText: 'Flat / House / Building No.',
                  hintText: 'e.g. Flat 405, Tower B',
                  prefixIcon: const Icon(Icons.apartment_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _streetController,
                decoration: InputDecoration(
                  labelText: 'Street / Road *',
                  hintText: 'e.g. OMR Road, Anna Salai',
                  prefixIcon: const Icon(Icons.signpost_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter street name or road';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _areaController,
                decoration: InputDecoration(
                  labelText: 'Area / Suburb / Locality',
                  hintText: 'e.g. Thoraipakkam, T-Nagar',
                  prefixIcon: const Icon(Icons.location_city_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'City *',
                        hintText: 'e.g. Chennai',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter city';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'PIN Code',
                        hintText: '600096',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  hintText: 'e.g. Tamil Nadu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveAddress,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Address',
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
