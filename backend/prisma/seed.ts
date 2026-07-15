import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding database with updated Project Phoenix service catalog...');

  // 1. Seed default customer first to obtain their UUID
  const defaultUser = await prisma.user.upsert({
    where: { phoneNumber: '+919876543210' },
    update: {
      name: 'Rajesh Kumar',
      email: 'rajesh.kumar@phoenix.in',
      role: 'CUSTOMER',
    },
    create: {
      phoneNumber: '+919876543210',
      name: 'Rajesh Kumar',
      email: 'rajesh.kumar@phoenix.in',
      role: 'CUSTOMER',
    },
  });

  // 2. Seed default customer property
  const defaultProperty = await prisma.property.upsert({
    where: { id: 'b87fa109-178c-42b7-8977-628d08cb5f09' },
    update: {
      customerId: defaultUser.id,
      name: 'Home',
      address: 'Flat 405, Phoenix Tower B, OMR Road, Thoraipakkam, Chennai - 600096',
      installedAppliances: ['Ceiling Fan', 'Water Motor', 'AC'],
      notes: 'Main residential property',
    },
    create: {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f09',
      customerId: defaultUser.id,
      name: 'Home',
      address: 'Flat 405, Phoenix Tower B, OMR Road, Thoraipakkam, Chennai - 600096',
      installedAppliances: ['Ceiling Fan', 'Water Motor', 'AC'],
      notes: 'Main residential property',
    },
  });

  // 3. Seed Service Categories & Items
  const categories = [
    {
      id: 'home-services',
      nameEn: 'Home Services',
      nameTa: 'வீட்டு சேவைகள்',
      icon: 'home_repair_service',
      items: [
        { id: 'painting', nameEn: 'Painting Services', nameTa: 'வண்ணம் பூசுதல்', descriptionEn: 'Premium interior and exterior wall painting.', descriptionTa: 'வீட்டின் உள்புற பெயிண்டிங்.', basePrice: 12, durationMinutes: 180 },
        { id: 'carpenter-service', nameEn: 'Carpenter Services', nameTa: 'தச்சர் வேலைகள்', descriptionEn: 'Furniture installation and wood repairs.', descriptionTa: 'மரச்சாமான்கள் தச்சர் வேலை.', basePrice: 399, durationMinutes: 120 },
        { id: 'furniture-assembly', nameEn: 'Furniture Assembly', nameTa: 'மரச்சாமான்கள் பொருத்துதல்', descriptionEn: 'Assembly of modular cupboards and beds.', descriptionTa: 'மரச்சாமான்கள் அசெம்பிள் செய்தல்.', basePrice: 499, durationMinutes: 90 },
        { id: 'modular-kitchen', nameEn: 'Modular Kitchen Service', nameTa: 'மாடுலர் சமையலறை சேவை', descriptionEn: 'Modular kitchen assembly and fixes.', descriptionTa: 'சமையலறை மாடுலர் அமைப்புகள்.', basePrice: 799, durationMinutes: 150 },
        { id: 'aluminium-glass-work', nameEn: 'Aluminium & Glass Work', nameTa: 'அலுமினியம் & கண்ணாடி வேலை', descriptionEn: 'Custom framing and windows replacement.', descriptionTa: 'அலுமினியம் மற்றும் கண்ணாடி கதவுகள்.', basePrice: 0, durationMinutes: 60 },
        { id: 'door-lock-repair', nameEn: 'Door & Lock Repair', nameTa: 'கதவு & பூட்டு பழுதுபார்ப்பு', descriptionEn: 'Fixing handle alignment and locks.', descriptionTa: 'பூட்டு மற்றும் கைப்பிடிகள் சீரமைப்பு.', basePrice: 399, durationMinutes: 60 },
        { id: 'waterproofing', nameEn: 'Waterproofing', nameTa: 'நீர் கசிவு தடுப்பு', descriptionEn: 'Terrace and bathroom leakage protection.', descriptionTa: 'சுவர்களில் நீர் கசிவு தடுப்பு.', basePrice: 30, durationMinutes: 180 },
        { id: 'laundry-ironing', nameEn: 'Laundry & Ironing', nameTa: 'சலவை & இஸ்திரி', descriptionEn: 'Premium laundry wash, fold, and iron.', descriptionTa: 'துணிகள் சலவை மற்றும் இஸ்திரி.', basePrice: 15, durationMinutes: 60 },
        { id: 'home-cook', nameEn: 'Home Cook Services', nameTa: 'சமையல்காரர் சேவை', descriptionEn: 'Healthy custom home cooking service.', descriptionTa: 'வீட்டில் சமைத்து தரும் சமையல்காரர்.', basePrice: 800, durationMinutes: 180 }
      ]
    },
    {
      id: 'repairs-maintenance',
      nameEn: 'Repairs & Maintenance',
      nameTa: 'பழுதுபார்ப்பு மற்றும் பராமரிப்பு',
      icon: 'handyman',
      items: [
        { id: 'electrical-repair', nameEn: 'Electrical Services', nameTa: 'மின்சார பழுதுபார்ப்பு', descriptionEn: 'Switchboard installation and wiring (Materials extra).', descriptionTa: 'மின்சார சுவிட்சுகள் பழுதுபார்ப்பு.', basePrice: 299, durationMinutes: 60 },
        { id: 'plumbing-repair', nameEn: 'Plumbing Services', nameTa: 'குழாய் வேலைகள் (பிளம்பிங்)', descriptionEn: 'Tap fixes and leak troubleshooting (Materials extra).', descriptionTa: 'தண்ணீர் குழாய் பழுதுபார்ப்பு.', basePrice: 299, durationMinutes: 60 },
        { id: 'ac-service', nameEn: 'AC Service', nameTa: 'ஏசி சர்வீஸ்', descriptionEn: 'Filter cleaning and cooling checkup.', descriptionTa: 'ஏசி பில்டர் சர்வீஸ் மற்றும் பராமரிப்பு.', basePrice: 599, durationMinutes: 90 },
        { id: 'ac-install', nameEn: 'AC Installation', nameTa: 'ஏசி நிறுவுதல்', descriptionEn: 'Mounting split or window AC units.', descriptionTa: 'ஏசி சாதனம் சுவரில் பொருத்துதல்.', basePrice: 1499, durationMinutes: 120 },
        { id: 'refrigerator-repair', nameEn: 'Refrigerator Repair', nameTa: 'குளிர்சாதனப் பெட்டி பழுதுபார்ப்பு', descriptionEn: 'Thermostat and gas recharge fixes.', descriptionTa: 'பிரிட்ஜ் கம்ப்ரஸர் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90 },
        { id: 'washing-machine-repair', nameEn: 'Washing Machine Repair', nameTa: 'சலவை இயந்திரம் பழுதுபார்ப்பு', descriptionEn: 'Drum spin and inlet water diagnostics.', descriptionTa: 'வாஷிங் மெஷின் டிரம் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90 },
        { id: 'tv-repair', nameEn: 'TV Repair', nameTa: 'தொலைக்காட்சி பழுதுபார்ப்பு', descriptionEn: 'Panel repairs and sound adjustments.', descriptionTa: 'டிவி டிஸ்ப்ளே பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 90 },
        { id: 'microwave-repair', nameEn: 'Microwave Repair', nameTa: 'மைக்ரோவேவ் ஓவன் பழுதுபார்ப்பு', descriptionEn: 'Magnetron and tray repairs.', descriptionTa: 'மைக்ரோவேவ் ஓவன் பழுதுபார்த்தல்.', basePrice: 399, durationMinutes: 60 },
        { id: 'geyser-repair', nameEn: 'Geyser Repair', nameTa: 'கீசர் பழுதுபார்ப்பு', descriptionEn: 'Heating element and thermostat swap.', descriptionTa: 'கீசர் தெர்மோஸ்டாட் மாற்றுதல்.', basePrice: 399, durationMinutes: 60 },
        { id: 'inverter-service', nameEn: 'Inverter & Battery Service', nameTa: 'இன்வெர்ட்டர் & பேட்டரி பராமரிப்பு', descriptionEn: 'Distilled water top-up and test check.', descriptionTa: 'இன்வெர்ட்டர் பேட்டரி பராமரிப்பு.', basePrice: 499, durationMinutes: 60 }
      ]
    },
    {
      id: 'cleaning-services',
      nameEn: 'Cleaning Services',
      nameTa: 'சுத்தம் செய்யும் சேவைகள்',
      icon: 'cleaning_services',
      items: [
        { id: 'home-cleaning', nameEn: 'Home Cleaning', nameTa: 'வீடு சுத்தம் செய்தல்', descriptionEn: 'Standard apartment broom and mop.', descriptionTa: 'வீட்டை கூட்டி பெருக்கி சுத்தம் செய்தல்.', basePrice: 999, durationMinutes: 120 },
        { id: 'deep-cleaning', nameEn: 'Deep Cleaning', nameTa: 'ஆழமான சுத்தம் செய்தல்', descriptionEn: 'Intense sanitization and scale removal.', descriptionTa: 'வீட்டின் ஒட்டுமொத்த ஆழமான சுத்தம்.', basePrice: 2999, durationMinutes: 240 },
        { id: 'sofa-cleaning', nameEn: 'Sofa Cleaning', nameTa: 'சோபா சுத்தம் செய்தல்', descriptionEn: 'Fabric shampooing and stain extraction.', descriptionTa: 'சோபா துணிகளை சுத்தம் செய்தல்.', basePrice: 499, durationMinutes: 90 },
        { id: 'mattress-cleaning', nameEn: 'Mattress Cleaning', nameTa: 'மெத்தை சுத்தம் செய்தல்', descriptionEn: 'Dust mite extraction and UV clean.', descriptionTa: 'மெத்தை கிருமி நீக்க தூசி வெளிகொணரல்.', basePrice: 599, durationMinutes: 90 },
        { id: 'glass-cleaning', nameEn: 'Glass Cleaning', nameTa: 'கண்ணாடி சுத்தம் செய்தல்', descriptionEn: 'Window panels scrub and squeegee.', descriptionTa: 'ஜன்னல் கண்ணாடிகள் சுத்தம் செய்தல்.', basePrice: 499, durationMinutes: 60 },
        { id: 'bathroom-cleaning', nameEn: 'Bathroom Cleaning', nameTa: 'குளியலறை சுத்தம் செய்தல்', descriptionEn: 'Tile grout clean and sanitization.', descriptionTa: 'குளியலறை தரை மற்றும் டைல்ஸ் சுத்தம்.', basePrice: 599, durationMinutes: 60 },
        { id: 'kitchen-cleaning', nameEn: 'Kitchen Cleaning', nameTa: 'சமையலறை சுத்தம் செய்தல்', descriptionEn: 'Stove, chimney, and cabinets deep scrub.', descriptionTa: 'சமையலறை மேடைகள் மற்றும் அடுப்பு சுத்தம்.', basePrice: 999, durationMinutes: 120 },
        { id: 'sanitization', nameEn: 'Sanitization Services', nameTa: 'கிருமிநாசினி தெளிப்பு', descriptionEn: 'Sanitizing rooms and high-touch areas.', descriptionTa: 'வீடு முழுவதும் கிருமிநாசினி தெளித்தல்.', basePrice: 799, durationMinutes: 45 },
        { id: 'pest-control', nameEn: 'Pest Control', nameTa: 'பூச்சி கட்டுப்பாடு', descriptionEn: 'Cockroach, bedbug and termite treatment.', descriptionTa: 'கரையான் மற்றும் பூச்சி கட்டுப்பாடு.', basePrice: 899, durationMinutes: 90 },
        { id: 'water-tank-cleaning', nameEn: 'Borewell & Water Tank Cleaning', nameTa: 'தண்ணீர் தொட்டி சுத்தம் செய்தல்', descriptionEn: 'Overhead and underground water tank scrub.', descriptionTa: 'தண்ணீர் தொட்டி சுத்தம் செய்யும் சேவை.', basePrice: 999, durationMinutes: 120 }
      ]
    },
    {
      id: 'healthcare-home',
      nameEn: 'Healthcare at Home',
      nameTa: 'வீட்டு மருத்துவம்',
      icon: 'medical_services',
      items: [
        { id: 'home-nursing', nameEn: 'Home Nursing', nameTa: 'வீட்டு செவிலியர்', descriptionEn: 'Professional nursing care at home.', descriptionTa: 'வீட்டில் செவிலியர் பராமரிப்பு சேவை.', basePrice: 1200, durationMinutes: 480 },
        { id: 'elder-care', nameEn: 'Elder Care', nameTa: 'முதியோர் பராமரிப்பு', descriptionEn: 'Compassionate assistance for senior citizens.', descriptionTa: 'முதியோர்களுக்கு உதவி மற்றும் பராமரிப்பு.', basePrice: 1000, durationMinutes: 480 },
        { id: 'baby-care', nameEn: 'Baby Care', nameTa: 'குழந்தை பராமரிப்பு', descriptionEn: 'Trusted newborn and infant babysitting.', descriptionTa: 'குழந்தைகள் மற்றும் பச்சிளம் காப்பகம்.', basePrice: 900, durationMinutes: 480 },
        { id: 'physiotherapy', nameEn: 'Physiotherapy at Home', nameTa: 'வீட்டு உடற்பயிற்சி சிகிச்சை', descriptionEn: 'Restorative body joints workout therapy.', descriptionTa: 'வீட்டில் உடற்பயிற்சி சிகிச்சை.', basePrice: 700, durationMinutes: 60 },
        { id: 'lab-sample-collection', nameEn: 'Lab Sample Collection', nameTa: 'இரத்த மாதிரி சேகரிப்பு', descriptionEn: 'Home blood and urine sample pick up.', descriptionTa: 'வீட்டில் வந்து இரத்த மாதிரி சேகரித்தல்.', basePrice: 199, durationMinutes: 30 },
        { id: 'ambulance-booking', nameEn: 'Ambulance Booking', nameTa: 'ஆம்புலன்ஸ் முன்பதிவு', descriptionEn: 'Emergency medical vehicle booking.', descriptionTa: 'அவசர ஆம்புலன்ஸ் வாகனம் முன்பதிவு.', basePrice: 1500, durationMinutes: 60 },
        { id: 'medical-equipment-rental', nameEn: 'Medical Equipment Rental', nameTa: 'மருத்துவ உபகரணங்கள் வாடகை', descriptionEn: 'Oxygen and wheelchair home rentals.', descriptionTa: 'மருத்துவ உபகரணங்கள் வாடகைக்கு.', basePrice: 100, durationMinutes: 60 }
      ]
    },
    {
      id: 'beauty-personal-care',
      nameEn: 'Beauty & Personal Care',
      nameTa: 'அழகு மற்றும் தனிநபர் பராமரிப்பு',
      icon: 'spa',
      items: [
        { id: 'pet-grooming', nameEn: 'Pet Grooming', nameTa: 'செல்லப்பிராணிகள் அழகு', descriptionEn: 'Dog wash and fur trimming.', descriptionTa: 'செல்லப்பிராணிகள் குளிப்பாட்டுதல் மற்றும் முடி வெட்டுதல்.', basePrice: 799, durationMinutes: 90 },
        { id: 'salon-at-home', nameEn: 'Beauty & Salon at Home', nameTa: 'அழகு நிலையம் அட் ஹோம்', descriptionEn: 'Home haircuts, facials, and pedicures.', descriptionTa: 'வீட்டில் ஹேர்கட் மற்றும் பேசியல்.', basePrice: 299, durationMinutes: 60 },
        { id: 'bridal-makeup', nameEn: 'Bridal Makeup', nameTa: 'மணப்பெண் அலங்காரம்', descriptionEn: 'Exquisite marriage makeover styling.', descriptionTa: 'மணமகள் ஒப்பனை மற்றும் அலங்காரம்.', basePrice: 8000, durationMinutes: 240 }
      ]
    },
    {
      id: 'moving-logistics',
      nameEn: 'Moving & Logistics',
      nameTa: 'இடமாற்றம் மற்றும் தளவாடங்கள்',
      icon: 'local_shipping',
      items: [
        { id: 'packers-movers', nameEn: 'Packers & Movers', nameTa: 'பேக்கர்ஸ் & மூவர்ஸ்', descriptionEn: 'Safe shifting of household goods.', descriptionTa: 'வீட்டு உபயோகப் பொருட்கள் இடமாற்றம்.', basePrice: 2999, durationMinutes: 360 },
        { id: 'bike-service', nameEn: 'Bike Service', nameTa: 'இருசக்கர வாகன சேவை', descriptionEn: 'Two-wheeler diagnostic and tuning.', descriptionTa: 'பைக் இன்ஜின் ஆயில் மற்றும் பழுதுநீக்கம்.', basePrice: 799, durationMinutes: 120 },
        { id: 'car-wash', nameEn: 'Car Wash & Detailing', nameTa: 'கார் வாஷ் & கிளீனிங்', descriptionEn: 'Foam wash and interior vacuuming.', descriptionTa: 'கார் போம் வாஷ் மற்றும் சுத்திகரிப்பு.', basePrice: 499, durationMinutes: 90 }
      ]
    },
    {
      id: 'outdoor-services',
      nameEn: 'Outdoor Services',
      nameTa: 'வெளிப்புற சேவைகள்',
      icon: 'yard',
      items: [
        { id: 'gardening', nameEn: 'Gardening & Landscaping', nameTa: 'தோட்டக்கலை சேவைகள்', descriptionEn: 'Lawn trimming and weed cleanups.', descriptionTa: 'புல்வெளி சீரமைப்பு மற்றும் செடிகள் பராமரிப்பு.', basePrice: 499, durationMinutes: 120 },
        { id: 'tree-cutting', nameEn: 'Tree Cutting', nameTa: 'மரம் வெட்டுதல்', descriptionEn: 'Dangerous branch trimming and removal.', descriptionTa: 'மரக்கிளைகள் மற்றும் மரங்கள் அகற்றுதல்.', basePrice: 999, durationMinutes: 120 },
        { id: 'solar-installation', nameEn: 'Solar Installation', nameTa: 'சூரிய சக்தி பேனல் பொருத்துதல்', descriptionEn: 'Solar panels power grid setups.', descriptionTa: 'சூரிய மின்சக்தி பேனல்கள் அமைத்தல்.', basePrice: 0, durationMinutes: 240 }
      ]
    },
    {
      id: 'it-electronics',
      nameEn: 'IT & Electronics',
      nameTa: 'தகவல் தொழில்நுட்பம் மற்றும் மின்னணுவியல்',
      icon: 'devices',
      items: [
        { id: 'laptop-repair', nameEn: 'Laptop Repair', nameTa: 'லேப்டாப் பழுதுபார்ப்பு', descriptionEn: 'OS installation and keyboard swaps.', descriptionTa: 'மடிக்கணினி பழுது நீக்கல்.', basePrice: 499, durationMinutes: 90 },
        { id: 'computer-repair', nameEn: 'Computer Repair', nameTa: 'கணினி பழுதுபார்ப்பு', descriptionEn: 'Desktop RAM and SMPS diagnostics.', descriptionTa: 'கணினி பழுது மற்றும் பாகங்கள் மாற்றுதல்.', basePrice: 399, durationMinutes: 90 },
        { id: 'mobile-repair', nameEn: 'Mobile Repair', nameTa: 'மொபைல் பழுதுபார்ப்பு', descriptionEn: 'Screen checks and battery swaps.', descriptionTa: 'கைபேசி திரை மற்றும் பேட்டரி மாற்றுதல்.', basePrice: 299, durationMinutes: 60 },
        { id: 'cctv-installation', nameEn: 'CCTV Installation', nameTa: 'CCTV கேமரா பொருத்துதல்', descriptionEn: 'Dome camera setup and wiring.', descriptionTa: 'கண்காணிப்பு கேமராக்கள் அமைத்தல்.', basePrice: 999, durationMinutes: 120 },
        { id: 'wifi-setup', nameEn: 'Wi-Fi & Networking', nameTa: 'வைஃபை & நெட்வொர்க்கிங்', descriptionEn: 'Router configs and LAN setup.', descriptionTa: 'வைஃபை ரூட்டர் மற்றும் இன்டர்நெட் அமைப்புகள்.', basePrice: 499, durationMinutes: 60 },
        { id: 'smart-lock-installation', nameEn: 'Smart Lock Installation', nameTa: 'ஸ்மார்ட் லாக் பொருத்துதல்', descriptionEn: 'Fingerprint lock mounting on doors.', descriptionTa: 'டிஜிட்டல் கைரேகை பூட்டு பொருத்துதல்.', basePrice: 799, durationMinutes: 90 }
      ]
    },
    {
      id: 'events-lifestyle',
      nameEn: 'Events & Lifestyle',
      nameTa: 'நிகழ்ச்சி ஏற்பாடுகள்',
      icon: 'celebration',
      items: [
        { id: 'photography', nameEn: 'Photography & Videography', nameTa: 'புகைப்படக் கலை', descriptionEn: 'Event shooting and portrait editing.', descriptionTa: 'விழாக்கள் புகைப்படம் மற்றும் வீடியோ எடுத்தல்.', basePrice: 2999, durationMinutes: 300 },
        { id: 'event-decoration', nameEn: 'Event Decoration', nameTa: 'விழா மேடை அலங்காரம்', descriptionEn: 'Birthday and wedding balloon flower decors.', descriptionTa: 'வண்ண பலூன் மற்றும் மலர் மேடை அலங்காரம்.', basePrice: 5000, durationMinutes: 240 }
      ]
    },
    {
      id: 'education-services',
      nameEn: 'Education Services',
      nameTa: 'கல்வி சேவைகள்',
      icon: 'school',
      items: [
        { id: 'home-tuition', nameEn: 'Home Tuition', nameTa: 'வீட்டு பாடம் (டியூஷன்)', descriptionEn: 'Personal tutor for school subjects.', descriptionTa: 'வீட்டிற்கே வந்து பாடம் சொல்லித் தரும் ஆசிரியர்.', basePrice: 500, durationMinutes: 60 }
      ]
    },
    {
      id: 'business-services',
      nameEn: 'Business Services',
      nameTa: 'வணிக சேவைகள்',
      icon: 'business',
      items: [
        { id: 'security-guard', nameEn: 'Security Guard Services', nameTa: 'பாதுகாப்பு காவலர்', descriptionEn: 'Trained guards for residences.', descriptionTa: 'வீடு மற்றும் அலுவலக பாதுகாப்பு காவலர்.', basePrice: 900, durationMinutes: 480 },
        { id: 'housekeeping-staff', nameEn: 'Housekeeping Staff', nameTa: 'வீட்டு வேலை ஆட்கள்', descriptionEn: 'Daily chores support assistants.', descriptionTa: 'வீட்டு வேலை செய்ய ஆட்கள் வசதி.', basePrice: 700, durationMinutes: 480 },
        { id: 'document-services', nameEn: 'Document & Government Services', nameTa: 'ஆவண சேவைகள்', descriptionEn: 'Pan card and notary verification support.', descriptionTa: 'அரசு ஆவணங்கள் மற்றும் சான்றிதழ் உதவி.', basePrice: 199, durationMinutes: 60 },
        { id: 'equipment-rental', nameEn: 'Rental Equipment', nameTa: 'உபகரணங்கள் வாடகை', descriptionEn: 'Ladders and drills home rentals.', descriptionTa: 'வீட்டு உபகரணங்கள் வாடகைக்கு வழங்குதல்.', basePrice: 299, durationMinutes: 60 },
        { id: 'home-essentials-delivery', nameEn: 'Home Essentials Delivery', nameTa: 'வீட்டு அத்தியாவசிய பொருட்கள்', descriptionEn: 'Groceries delivery to your doorstep.', descriptionTa: 'அத்தியாவசிய வீட்டுப் பொருட்கள் விநியோகம்.', basePrice: 49, durationMinutes: 45 },
        { id: 'custom-service', nameEn: 'Custom Service Request', nameTa: 'விருப்ப சேவை', descriptionEn: 'Custom description fields (Any other services).', descriptionTa: 'விளக்கங்கள் அடிப்படையில் தனிப்பயன் சேவை.', basePrice: 0, durationMinutes: 60 }
      ]
    }
  ];

  for (const cat of categories) {
    const serviceCategory = await prisma.serviceCategory.upsert({
      where: { id: cat.id },
      update: {
        nameEn: cat.nameEn,
        nameTa: cat.nameTa,
        icon: cat.icon,
      },
      create: {
        id: cat.id,
        nameEn: cat.nameEn,
        nameTa: cat.nameTa,
        icon: cat.icon,
      },
    });

    for (const item of cat.items) {
      await prisma.serviceItem.upsert({
        where: { id: item.id },
        update: {
          nameEn: item.nameEn,
          nameTa: item.nameTa,
          descriptionEn: item.descriptionEn,
          descriptionTa: item.descriptionTa,
          basePrice: item.basePrice,
          durationMinutes: item.durationMinutes,
        },
        create: {
          id: item.id,
          categoryId: serviceCategory.id,
          nameEn: item.nameEn,
          nameTa: item.nameTa,
          descriptionEn: item.descriptionEn,
          descriptionTa: item.descriptionTa,
          basePrice: item.basePrice,
          durationMinutes: item.durationMinutes,
        },
      });
    }
  }

  // 5. Seed Products
  const products = [
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f01',
      category: 'Electrical Switches',
      name: 'Phoenix Smart Switch 6-Gang',
      description: 'Elegant modular touch switch board, compatible with Alexa & Google Assistant.',
      price: 2499.00,
      imageUrl: 'assets/products/switch.png',
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f02',
      category: 'Water Pumps',
      name: 'Phoenix Super Suction 1HP Pump',
      description: 'Heavy duty copper-winding water pump, self-priming with automatic float trigger.',
      price: 6899.00,
      imageUrl: 'assets/products/pump.png',
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f03',
      category: 'Fans',
      name: 'Phoenix BLDC Premium Ceiling Fan',
      description: 'Energy-saving 28W BLDC motor fan with remote control, noiseless operations.',
      price: 3499.00,
      imageUrl: 'assets/products/fan.png',
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f04',
      category: 'Safety Equipment',
      name: 'Phoenix MCB Distribution Board',
      description: 'Dual-door IP43 protection distribution board with pre-fitted busbar.',
      price: 1899.00,
      imageUrl: 'assets/products/mcb_box.png',
    },
    {
      id: 'b87fa109-178c-42b7-8977-628d08cb5f05',
      category: 'Lights',
      name: 'Phoenix 20W LED Batten Light',
      description: 'Cool day light 2000lm output tube light, surge protection up to 4kV.',
      price: 299.00,
      imageUrl: 'assets/products/light.png',
    },
  ];

  for (const prod of products) {
    await prisma.product.upsert({
      where: { id: prod.id },
      update: {
        category: prod.category,
        name: prod.name,
        description: prod.description,
        price: prod.price,
        imageUrl: prod.imageUrl,
      },
      create: {
        id: prod.id,
        category: prod.category,
        name: prod.name,
        description: prod.description,
        price: prod.price,
        imageUrl: prod.imageUrl,
      },
    });
  }

  console.log('Database seeded successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
