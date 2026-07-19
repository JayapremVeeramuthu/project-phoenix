import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/core/database/sqlite_helper.dart';
import 'package:project_phoenix_customer/features/services/domain/entities/service_item.dart';

class ServicesRepository {
  final ApiClient? _apiClient;
  List<ServiceCategory> _categoriesList = [];

  ServicesRepository([this._apiClient]) {
    _categoriesList = List.from(_bootstrapCategories);
    // Asynchronously pull fresh data and populate cache
    loadCategoriesData();
  }

  Future<void> loadCategoriesData() async {
    try {
      final remoteList = await getCategoriesRemote();
      if (remoteList.isNotEmpty) {
        _categoriesList = remoteList;
        // Save to SQLite cache
        final dbList = <Map<String, dynamic>>[];
        for (var cat in remoteList) {
          for (var item in cat.items) {
            dbList.add({
              'id': item.id,
              'category': cat.id,
              'name': item.nameEn,
              'description': item.descriptionEn,
              'price': item.basePrice,
              'duration_minutes': item.durationMinutes,
            });
          }
        }
        await SqliteHelper().cacheServices(dbList);
      }
    } catch (_) {
      // Offline fallback: load from SQLite cache
      try {
        final cached = await SqliteHelper().getCachedServices();
        if (cached.isNotEmpty) {
          final Map<String, List<ServiceItem>> itemsByCat = {};
          for (var row in cached) {
            final catId = row['category'] as String;
            final item = ServiceItem(
              id: row['id'] as String,
              categoryId: catId,
              nameEn: row['name'] as String,
              nameTa: row['name'] as String,
              descriptionEn: row['description'] as String? ?? '',
              descriptionTa: row['description'] as String? ?? '',
              basePrice: (row['price'] as num).toDouble(),
              durationMinutes: row['duration_minutes'] as int,
            );
            itemsByCat.putIfAbsent(catId, () => []).add(item);
          }

          final List<ServiceCategory> loadedCategories = [];
          for (var cat in _bootstrapCategories) {
            if (itemsByCat.containsKey(cat.id)) {
              loadedCategories.add(ServiceCategory(
                id: cat.id,
                nameEn: cat.nameEn,
                nameTa: cat.nameTa,
                icon: cat.icon,
                items: itemsByCat[cat.id]!,
              ));
            }
          }
          if (loadedCategories.isNotEmpty) {
            _categoriesList = loadedCategories;
          }
        }
      } catch (_) {}
    }
  }

  final List<ServiceCategory> _bootstrapCategories = [
    ServiceCategory(
      id: 'home-services',
      nameEn: 'Home Services',
      nameTa: 'வீட்டு சேவைகள்',
      icon: Icons.home_repair_service_rounded,
      items: [
        ServiceItem(id: 'painting', categoryId: 'home-services', nameEn: 'Painting Services', nameTa: 'வண்ணம் பூசுதல்', descriptionEn: 'Premium interior and exterior wall painting.', descriptionTa: 'வீட்டின் உள்புற பெயிண்டிங்.', basePrice: 12, durationMinutes: 180),
        ServiceItem(id: 'carpenter-service', categoryId: 'home-services', nameEn: 'Carpenter Services', nameTa: 'தச்சர் வேலைகள்', descriptionEn: 'Furniture installation and wood repairs.', descriptionTa: 'மரச்சாமான்கள் தச்சர் வேலை.', basePrice: 399, durationMinutes: 120),
        ServiceItem(id: 'furniture-assembly', categoryId: 'home-services', nameEn: 'Furniture Assembly', nameTa: 'மரச்சாமான்கள் பொருத்துதல்', descriptionEn: 'Assembly of modular cupboards and beds.', descriptionTa: 'மரச்சாமான்கள் அசெம்பிள் செய்தல்.', basePrice: 499, durationMinutes: 90),
        ServiceItem(id: 'modular-kitchen', categoryId: 'home-services', nameEn: 'Modular Kitchen Service', nameTa: 'மாடுலர் சமையலறை சேவை', descriptionEn: 'Modular kitchen assembly and fixes.', descriptionTa: 'சமையலறை மாடுலர் அமைப்புகள்.', basePrice: 799, durationMinutes: 150),
        ServiceItem(id: 'aluminium-glass-work', categoryId: 'home-services', nameEn: 'Aluminium & Glass Work', nameTa: 'அலுமினியம் & கண்ணாடி வேலை', descriptionEn: 'Custom framing and windows replacement.', descriptionTa: 'அலுமினியம் மற்றும் கண்ணாடி கதவுகள்.', basePrice: 0, durationMinutes: 60),
        ServiceItem(id: 'door-lock-repair', categoryId: 'home-services', nameEn: 'Door & Lock Repair', nameTa: 'கதவு & பூட்டு பழுதுபார்ப்பு', descriptionEn: 'Fixing handle alignment and locks.', descriptionTa: 'பூட்டு மற்றும் கைப்பிடிகள் சீரமைப்பு.', basePrice: 399, durationMinutes: 60),
        ServiceItem(id: 'waterproofing', categoryId: 'home-services', nameEn: 'Waterproofing', nameTa: 'நீர் கசிவு தடுப்பு', descriptionEn: 'Terrace and bathroom leakage protection.', descriptionTa: 'சுவர்களில் நீர் கசிவு தடுப்பு.', basePrice: 30, durationMinutes: 180),
        ServiceItem(id: 'laundry-ironing', categoryId: 'home-services', nameEn: 'Laundry & Ironing', nameTa: 'சலவை & இஸ்திரி', descriptionEn: 'Premium laundry wash, fold, and iron.', descriptionTa: 'துணிகள் சலவை மற்றும் இஸ்திரி.', basePrice: 15, durationMinutes: 60),
        ServiceItem(id: 'home-cook', categoryId: 'home-services', nameEn: 'Home Cook Services', nameTa: 'சமையல்காரர் சேவை', descriptionEn: 'Healthy custom home cooking service.', descriptionTa: 'வீட்டில் சமைத்து தரும் சமையல்காரர்.', basePrice: 800, durationMinutes: 180),
      ],
    ),
    ServiceCategory(
      id: 'repairs-maintenance',
      nameEn: 'Repairs & Maintenance',
      nameTa: 'பழுதுபார்ப்பு மற்றும் பராமரிப்பு',
      icon: Icons.handyman_rounded,
      items: [
        ServiceItem(id: 'electrical-repair', categoryId: 'repairs-maintenance', nameEn: 'Electrical Services', nameTa: 'மின்சார பழுதுபார்ப்பு', descriptionEn: 'Switchboard installation and wiring (Materials extra).', descriptionTa: 'மின்சார சுவிட்சுகள் பழுதுபார்ப்பு.', basePrice: 299, durationMinutes: 60),
        ServiceItem(id: 'plumbing-repair', categoryId: 'repairs-maintenance', nameEn: 'Plumbing Services', nameTa: 'குழாய் வேலைகள் (பிளம்பிங்)', descriptionEn: 'Tap fixes and leak troubleshooting (Materials extra).', descriptionTa: 'தண்ணீர் குழாய் பழுதுபார்ப்பு.', basePrice: 299, durationMinutes: 60),
        ServiceItem(id: 'ac-service', categoryId: 'repairs-maintenance', nameEn: 'AC Service', nameTa: 'ஏசி சர்வீஸ்', descriptionEn: 'Filter cleaning and cooling checkup.', descriptionTa: 'ஏசி பில்டர் சர்வீஸ் மற்றும் பராமரிப்பு.', basePrice: 599, durationMinutes: 90),
        ServiceItem(id: 'ac-install', categoryId: 'repairs-maintenance', nameEn: 'AC Installation', nameTa: 'ஏசி நிறுவுதல்', descriptionEn: 'Mounting split or window AC units.', descriptionTa: 'ஏசி சாதனம் சுவரில் பொருத்துதல்.', basePrice: 1499, durationMinutes: 120),
        ServiceItem(id: 'refrigerator-repair', categoryId: 'repairs-maintenance', nameEn: 'Refrigerator Repair', nameTa: 'குளிர்சாதனப் பெட்டி பழுதுபார்ப்பு', descriptionEn: 'Thermostat and gas recharge fixes.', descriptionTa: 'பிரிட்ஜ் கம்ப்ரஸர் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90),
        ServiceItem(id: 'washing-machine-repair', categoryId: 'repairs-maintenance', nameEn: 'Washing Machine Repair', nameTa: 'சலவை இயந்திரம் பழுதுபார்ப்பு', descriptionEn: 'Drum spin and inlet water diagnostics.', descriptionTa: 'வாஷிங் மெஷின் டிரம் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90),
        ServiceItem(id: 'tv-repair', categoryId: 'repairs-maintenance', nameEn: 'TV Repair', nameTa: 'தொலைக்காட்சி பழுதுபார்ப்பு', descriptionEn: 'Panel repairs and sound adjustments.', descriptionTa: 'டிவி டிஸ்ப்ளே பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90),
        ServiceItem(id: 'microwave-repair', categoryId: 'repairs-maintenance', nameEn: 'Microwave Repair', nameTa: 'மைக்ரோவேவ் ஓவன் பழுதுபார்ப்பு', descriptionEn: 'Magnetron and tray repairs.', descriptionTa: 'மைக்ரோவேவ் ஓவன் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 60),
        ServiceItem(id: 'geyser-repair', categoryId: 'repairs-maintenance', nameEn: 'Geyser Repair', nameTa: 'கீசர் பழுதுபார்ப்பு', descriptionEn: 'Heating element and thermostat swap.', descriptionTa: 'கீசர் தெர்மோஸ்டாட் மாற்றுதல்.', basePrice: 399, durationMinutes: 60),
        ServiceItem(id: 'inverter-service', categoryId: 'repairs-maintenance', nameEn: 'Inverter & Battery Service', nameTa: 'இன்வெர்ட்டர் & பேட்டரி பராமரிப்பு', descriptionEn: 'Distilled water top-up and test check.', descriptionTa: 'இன்வெர்ட்டர் பேட்டரி பராமரிப்பு.', basePrice: 499, durationMinutes: 60),
      ],
    ),
    ServiceCategory(
      id: 'cleaning-services',
      nameEn: 'Cleaning Services',
      nameTa: 'சுத்தம் செய்யும் சேவைகள்',
      icon: Icons.cleaning_services_rounded,
      items: [
        ServiceItem(id: 'home-cleaning', categoryId: 'cleaning-services', nameEn: 'Home Cleaning', nameTa: 'வீடு சுத்தம் செய்தல்', descriptionEn: 'Standard apartment broom and mop.', descriptionTa: 'வீட்டை கூட்டி பெருக்கி சுத்தம் செய்தல்.', basePrice: 999, durationMinutes: 120),
        ServiceItem(id: 'deep-cleaning', categoryId: 'cleaning-services', nameEn: 'Deep Cleaning', nameTa: 'ஆழமான சுத்தம் செய்தல்', descriptionEn: 'Thorough apartment sanitization and scale removal.', descriptionTa: 'வீட்டின் ஒட்டுமொத்த ஆழமான சுத்தம்.', basePrice: 2999, durationMinutes: 240),
        ServiceItem(id: 'sofa-cleaning', categoryId: 'cleaning-services', nameEn: 'Sofa Cleaning', nameTa: 'சோபா சுத்தம் செய்தல்', descriptionEn: 'Fabric shampooing and stain extraction.', descriptionTa: 'சோபா துணிகளை சுத்தம் செய்தல்.', basePrice: 499, durationMinutes: 90),
        ServiceItem(id: 'mattress-cleaning', categoryId: 'cleaning-services', nameEn: 'Mattress Cleaning', nameTa: 'மெத்தை சுத்தம் செய்தல்', descriptionEn: 'Dust mite extraction and UV clean.', descriptionTa: 'மெத்தை கிருமி நீக்க தூசி வெளிகொணரல்.', basePrice: 599, durationMinutes: 90),
        ServiceItem(id: 'glass-cleaning', categoryId: 'cleaning-services', nameEn: 'Glass Cleaning', nameTa: 'கண்ணாடி சுத்தம் செய்தல்', descriptionEn: 'Window panels scrub and squeegee.', descriptionTa: 'ஜன்னல் கண்ணாடிகள் சுத்தம் செய்தல்.', basePrice: 499, durationMinutes: 60),
        ServiceItem(id: 'bathroom-cleaning', categoryId: 'cleaning-services', nameEn: 'Bathroom Cleaning', nameTa: 'குளியலறை சுத்தம் செய்தல்', descriptionEn: 'Tile grout clean and sanitization.', descriptionTa: 'குளியலறை தரை மற்றும் டைல்ஸ் சுத்தம்.', basePrice: 599, durationMinutes: 60),
        ServiceItem(id: 'kitchen-cleaning', categoryId: 'cleaning-services', nameEn: 'Kitchen Cleaning', nameTa: 'சமையலறை சுத்தம் செய்தல்', descriptionEn: 'Stove, chimney, and cabinets deep scrub.', descriptionTa: 'சமையலறை மேடைகள் மற்றும் அடுப்பு சுத்தம்.', basePrice: 999, durationMinutes: 120),
        ServiceItem(id: 'sanitization', categoryId: 'cleaning-services', nameEn: 'Sanitization Services', nameTa: 'கிருமிநாசினி தெளிப்பு', descriptionEn: 'Sanitizing rooms and high-touch areas.', descriptionTa: 'வீடு முழுவதும் கிருமிநாசினி தெளித்தல்.', basePrice: 799, durationMinutes: 45),
        ServiceItem(id: 'pest-control', categoryId: 'cleaning-services', nameEn: 'Pest Control', nameTa: 'பூச்சி கட்டுப்பாடு', descriptionEn: 'Cockroach, bedbug and termite treatment.', descriptionTa: 'கரையான் மற்றும் பூச்சி கட்டுப்பாடு.', basePrice: 899, durationMinutes: 90),
        ServiceItem(id: 'water-tank-cleaning', categoryId: 'cleaning-services', nameEn: 'Borewell & Water Tank Cleaning', nameTa: 'தண்ணீர் தொட்டி சுத்தம் செய்தல்', descriptionEn: 'Overhead and underground water tank scrub.', descriptionTa: 'தண்ணீர் தொட்டி சுத்தம் செய்யும் சேவை.', basePrice: 999, durationMinutes: 120),
      ],
    ),
    ServiceCategory(
      id: 'healthcare-home',
      nameEn: 'Healthcare at Home',
      nameTa: 'வீட்டு மருத்துவம்',
      icon: Icons.medical_services_rounded,
      items: [
        ServiceItem(id: 'home-nursing', categoryId: 'healthcare-home', nameEn: 'Home Nursing', nameTa: 'வீட்டு செவிலியர்', descriptionEn: 'Professional nursing care at home.', descriptionTa: 'வீட்டில் செவிலியர் பராமரிப்பு சேவை.', basePrice: 1200, durationMinutes: 480),
        ServiceItem(id: 'elder-care', categoryId: 'healthcare-home', nameEn: 'Elder Care', nameTa: 'முதியோர் பராமரிப்பு', descriptionEn: 'Compassionate assistance for senior citizens.', descriptionTa: 'முதியோர்களுக்கு உதவி மற்றும் பராமரிப்பு.', basePrice: 1000, durationMinutes: 480),
        ServiceItem(id: 'baby-care', categoryId: 'healthcare-home', nameEn: 'Baby Care', nameTa: 'குழந்தை பராமரிப்பு', descriptionEn: 'Trusted newborn and infant babysitting.', descriptionTa: 'குழந்தைகள் மற்றும் பச்சிளம் காப்பகம்.', basePrice: 900, durationMinutes: 480),
        ServiceItem(id: 'physiotherapy', categoryId: 'healthcare-home', nameEn: 'Physiotherapy at Home', nameTa: 'வீட்டு உடற்பயிற்சி சிகிச்சை', descriptionEn: 'Restorative body joints workout therapy.', descriptionTa: 'வீட்டில் உடற்பயிற்சி சிகிச்சை.', basePrice: 700, durationMinutes: 60),
        ServiceItem(id: 'lab-sample-collection', categoryId: 'healthcare-home', nameEn: 'Lab Sample Collection', nameTa: 'இரத்த மாதிரி சேகரிப்பு', descriptionEn: 'Home blood and urine sample pick up.', descriptionTa: 'வீட்டில் வந்து இரத்த மாதிரி சேகரித்தல்.', basePrice: 199, durationMinutes: 30),
        ServiceItem(id: 'ambulance-booking', categoryId: 'healthcare-home', nameEn: 'Ambulance Booking', nameTa: 'ஆம்புலன்ஸ் முன்பதிவு', descriptionEn: 'Emergency medical vehicle booking.', descriptionTa: 'அவசர ஆம்புலன்ஸ் வாகனம் முன்பதிவு.', basePrice: 1500, durationMinutes: 60),
        ServiceItem(id: 'medical-equipment-rental', categoryId: 'healthcare-home', nameEn: 'Medical Equipment Rental', nameTa: 'மருத்துவ உபகரணங்கள் வாடகை', descriptionEn: 'Oxygen and wheelchair home rentals.', descriptionTa: 'மருத்துவ உபகரணங்கள் வாடகைக்கு.', basePrice: 100, durationMinutes: 60),
      ],
    ),
    ServiceCategory(
      id: 'beauty-personal-care',
      nameEn: 'Beauty & Personal Care',
      nameTa: 'அழகு கலை',
      icon: Icons.spa_rounded,
      items: [
        ServiceItem(id: 'pet-grooming', categoryId: 'beauty-personal-care', nameEn: 'Pet Grooming', nameTa: 'செல்லப்பிராணிகள் அழகு', descriptionEn: 'Dog wash and fur trimming.', descriptionTa: 'செல்லப்பிராணிகள் குளிப்பாட்டுதல் மற்றும் முடி வெட்டுதல்.', basePrice: 799, durationMinutes: 90),
        ServiceItem(id: 'salon-at-home', categoryId: 'beauty-personal-care', nameEn: 'Beauty & Salon at Home', nameTa: 'அழகு நிலையம் அட் ஹோம்', descriptionEn: 'Home haircuts, facials, and pedicures.', descriptionTa: 'வீட்டில் ஹேர்கட் மற்றும் பேசியல்.', basePrice: 299, durationMinutes: 60),
        ServiceItem(id: 'bridal-makeup', categoryId: 'beauty-personal-care', nameEn: 'Bridal Makeup', nameTa: 'மணப்பெண் அலங்காரம்', descriptionEn: 'Exquisite marriage makeover styling.', descriptionTa: 'மணமகள் ஒப்பனை மற்றும் அலங்காரம்.', basePrice: 8000, durationMinutes: 240),
      ],
    ),
    ServiceCategory(
      id: 'moving-logistics',
      nameEn: 'Moving & Logistics',
      nameTa: 'பொருட்கள் நகர்த்தல்',
      icon: Icons.local_shipping_rounded,
      items: [
        ServiceItem(id: 'packers-movers', categoryId: 'moving-logistics', nameEn: 'Packers & Movers', nameTa: 'பேக்கர்ஸ் & மூவர்ஸ்', descriptionEn: 'Safe shifting of household goods.', descriptionTa: 'வீட்டு உபயோகப் பொருட்கள் இடமாற்றம்.', basePrice: 2999, durationMinutes: 360),
        ServiceItem(id: 'bike-service', categoryId: 'moving-logistics', nameEn: 'Bike Service', nameTa: 'இருசக்கர வாகன சேவை', descriptionEn: 'Two-wheeler diagnostic and tuning.', descriptionTa: 'பைக் இன்ஜின் ஆயில் மற்றும் பழுதுநீக்கம்.', basePrice: 799, durationMinutes: 120),
        ServiceItem(id: 'car-wash', categoryId: 'moving-logistics', nameEn: 'Car Wash & Detailing', nameTa: 'கார் வாஷ் & கிளீனிங்', descriptionEn: 'Foam wash and interior vacuuming.', descriptionTa: 'கார் போம் வாஷ் மற்றும் சுத்திகரிப்பு.', basePrice: 499, durationMinutes: 90),
      ],
    ),
    ServiceCategory(
      id: 'outdoor-services',
      nameEn: 'Outdoor Services',
      nameTa: 'வெளிப்புற சேவைகள்',
      icon: Icons.yard_rounded,
      items: [
        ServiceItem(id: 'gardening', categoryId: 'outdoor-services', nameEn: 'Gardening & Landscaping', nameTa: 'தோட்டக்கலை சேவைகள்', descriptionEn: 'Lawn trimming and weed cleanups.', descriptionTa: 'புல்வெளி சீரமைப்பு மற்றும் செடிகள் பராமரிப்பு.', basePrice: 499, durationMinutes: 120),
        ServiceItem(id: 'tree-cutting', categoryId: 'outdoor-services', nameEn: 'Tree Cutting', nameTa: 'மரம் வெட்டுதல்', descriptionEn: 'Dangerous branch trimming and removal.', descriptionTa: 'மரக்கிளைகள் மற்றும் மரங்கள் அகற்றுதல்.', basePrice: 999, durationMinutes: 120),
        ServiceItem(id: 'solar-installation', categoryId: 'outdoor-services', nameEn: 'Solar Installation', nameTa: 'சூரிய சக்தி பேனல் பொருத்துதல்', descriptionEn: 'Solar panels power grid setups.', descriptionTa: 'சூரிய மின்சக்தி பேனல்கள் அமைத்தல்.', basePrice: 0, durationMinutes: 240),
      ],
    ),
    ServiceCategory(
      id: 'it-electronics',
      nameEn: 'IT & Electronics',
      nameTa: 'தகவல் தொழில்நுட்பம்',
      icon: Icons.devices_rounded,
      items: [
        ServiceItem(id: 'laptop-repair', categoryId: 'it-electronics', nameEn: 'Laptop Repair', nameTa: 'லேப்டாப் பழுதுபார்ப்பு', descriptionEn: 'OS installation and keyboard swaps.', descriptionTa: 'மடிக்கணினி பழுது நீக்கல்.', basePrice: 499, durationMinutes: 90),
        ServiceItem(id: 'computer-repair', categoryId: 'it-electronics', nameEn: 'Computer Repair', nameTa: 'கணினி பழுதுபார்ப்பு', descriptionEn: 'Desktop RAM and SMPS diagnostics.', descriptionTa: 'கணினி பழுது மற்றும் பாகங்கள் மாற்றுதல்.', basePrice: 399, durationMinutes: 90),
        ServiceItem(id: 'mobile-repair', categoryId: 'it-electronics', nameEn: 'Mobile Repair', nameTa: 'மொபைல் பழுதுபார்ப்பு', descriptionEn: 'Screen checks and battery swaps.', descriptionTa: 'கைபேசி திரை மற்றும் பேட்டரி மாற்றுதல்.', basePrice: 299, durationMinutes: 60),
        ServiceItem(id: 'cctv-installation', categoryId: 'it-electronics', nameEn: 'CCTV Installation', nameTa: 'CCTV கேமரா பொருத்துதல்', descriptionEn: 'Dome camera setup and wiring.', descriptionTa: 'கண்காணிப்பு கேமராக்கள் அமைத்தல்.', basePrice: 999, durationMinutes: 120),
        ServiceItem(id: 'wifi-setup', categoryId: 'it-electronics', nameEn: 'Wi-Fi & Networking', nameTa: 'வைஃபை & நெட்வொர்க்கிங்', descriptionEn: 'Router configs and LAN setup.', descriptionTa: 'வைஃபை ரூட்டர் மற்றும் இன்டர்நெட் அமைப்புகள்.', basePrice: 499, durationMinutes: 60),
        ServiceItem(id: 'smart-lock-installation', categoryId: 'it-electronics', nameEn: 'Smart Lock Installation', nameTa: 'ஸ்மார்ட் லாக் பொருத்துதல்', descriptionEn: 'Fingerprint lock mounting on doors.', descriptionTa: 'டிஜிட்டல் கைரேகை பூட்டு பொருத்துதல்.', basePrice: 799, durationMinutes: 90),
      ],
    ),
    ServiceCategory(
      id: 'events-lifestyle',
      nameEn: 'Events & Lifestyle',
      nameTa: 'நிகழ்ச்சி ஏற்பாடுகள்',
      icon: Icons.celebration_rounded,
      items: [
        ServiceItem(id: 'photography', categoryId: 'events-lifestyle', nameEn: 'Photography & Videography', nameTa: 'புகைப்படக் கலை', descriptionEn: 'Event shooting and portrait editing.', descriptionTa: 'விழாக்கள் புகைப்படம் மற்றும் வீடியோ எடுத்தல்.', basePrice: 2999, durationMinutes: 300),
        ServiceItem(id: 'event-decoration', categoryId: 'events-lifestyle', nameEn: 'Event Decoration', nameTa: 'விழா மேடை அலங்காரம்', descriptionEn: 'Birthday and wedding balloon flower decors.', descriptionTa: 'வண்ண பலூன் மற்றும் மலர் மேடை அலங்காரம்.', basePrice: 5000, durationMinutes: 240),
      ],
    ),
    ServiceCategory(
      id: 'education-services',
      nameEn: 'Education Services',
      nameTa: 'கல்வி சேவைகள்',
      icon: Icons.school_rounded,
      items: [
        ServiceItem(id: 'home-tuition', categoryId: 'education-services', nameEn: 'Home Tuition', nameTa: 'வீட்டு பாடம் (டியூஷன்)', descriptionEn: 'Personal tutor for school subjects.', descriptionTa: 'வீட்டிற்கே வந்து பாடம் சொல்லித் தரும் ஆசிரியர்.', basePrice: 500, durationMinutes: 60),
      ],
    ),
    ServiceCategory(
      id: 'business-services',
      nameEn: 'Business Services',
      nameTa: 'வணிக சேவைகள்',
      icon: Icons.business_center_rounded,
      items: [
        ServiceItem(id: 'security-guard', categoryId: 'business-services', nameEn: 'Security Guard Services', nameTa: 'பாதுகாப்பு காவலர்', descriptionEn: 'Trained guards for residences.', descriptionTa: 'வீடு மற்றும் அலுவலக பாதுகாப்பு காவலர்.', basePrice: 900, durationMinutes: 480),
        ServiceItem(id: 'housekeeping-staff', categoryId: 'business-services', nameEn: 'Housekeeping Staff', nameTa: 'வீட்டு வேலை ஆட்கள்', descriptionEn: 'Daily chores support assistants.', descriptionTa: 'வீட்டு வேலை செய்ய ஆட்கள் வசதி.', basePrice: 700, durationMinutes: 480),
        ServiceItem(id: 'document-services', categoryId: 'business-services', nameEn: 'Document & Government Services', nameTa: 'ஆவண சேவைகள்', descriptionEn: 'Pan card and notary verification support.', descriptionTa: 'அரசு ஆவணங்கள் மற்றும் சான்றிதழ் உதவி.', basePrice: 199, durationMinutes: 60),
        ServiceItem(id: 'equipment-rental', categoryId: 'business-services', nameEn: 'Rental Equipment', nameTa: 'உபகரணங்கள் வாடகை', descriptionEn: 'Ladders and drills home rentals.', descriptionTa: 'வீட்டு உபகரணங்கள் வாடகைக்கு வழங்குதல்.', basePrice: 299, durationMinutes: 60),
        ServiceItem(id: 'home-essentials-delivery', categoryId: 'business-services', nameEn: 'Home Essentials Delivery', nameTa: 'வீட்டு அத்தியாவசிய பொருட்கள்', descriptionEn: 'Groceries delivery to your doorstep.', descriptionTa: 'அத்தியாவசிய வீட்டுப் பொருட்கள் விநியோகம்.', basePrice: 49, durationMinutes: 45),
        ServiceItem(id: 'custom-service', categoryId: 'business-services', nameEn: 'Custom Service Request', nameTa: 'விருப்ப சேவை', descriptionEn: 'Custom description fields (Any other services).', descriptionTa: 'விளக்கங்கள் அடிப்படையில் தனிப்பயன் சேவை.', basePrice: 0, durationMinutes: 60),
      ],
    ),
  ];

  Future<List<ServiceCategory>> getCategoriesRemote({int page = 1, int limit = 10}) async {
    if (_apiClient == null) return _bootstrapCategories;
    try {
      final response = await _apiClient!.get('/services/categories', queryParameters: {
        'page': page,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        final list = response.data['data'] as List;
        return list.map((json) => ServiceCategory.fromJson(json)).toList();
      }
    } catch (_) {}
    return _bootstrapCategories;
  }

  List<ServiceCategory> getCategories() {
    if (_categoriesList.isEmpty) return [];

    final allItems = <ServiceItem>[];
    for (var cat in _categoriesList) {
      allItems.addAll(cat.items);
    }

    final allServicesCat = ServiceCategory(
      id: 'all-services',
      nameEn: '⭐ All Services',
      nameTa: '⭐ அனைத்து சேவைகள்',
      icon: Icons.star_rounded,
      items: allItems,
    );

    return [allServicesCat, ..._categoriesList];
  }

  ServiceCategory? getCategoryById(String id) {
    if (id == 'all-services') {
      final allItems = <ServiceItem>[];
      for (var cat in _categoriesList) {
        allItems.addAll(cat.items);
      }
      return ServiceCategory(
        id: 'all-services',
        nameEn: '⭐ All Services',
        nameTa: '⭐ அனைத்து சேவைகள்',
        icon: Icons.star_rounded,
        items: allItems,
      );
    }
    try {
      return _categoriesList.firstWhere((cat) => cat.id == id);
    } catch (_) {
      return null;
    }
  }

  ServiceItem? getServiceById(String id) {
    for (var cat in _categoriesList) {
      for (var item in cat.items) {
        if (item.id == id) return item;
      }
    }
    return null;
  }

  List<ServiceItem> searchServices(String query, Locale locale) {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    final List<ServiceItem> results = [];

    for (var cat in _categoriesList) {
      for (var item in cat.items) {
        final matchEn = item.nameEn.toLowerCase().contains(lowerQuery) ||
            item.descriptionEn.toLowerCase().contains(lowerQuery);
        final matchTa = item.nameTa.contains(lowerQuery) ||
            item.descriptionTa.contains(lowerQuery);
        if (matchEn || matchTa) {
          results.add(item);
        }
      }
    }
    return results;
  }
}

final servicesRepositoryProvider = Provider<ServicesRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServicesRepository(apiClient);
});
