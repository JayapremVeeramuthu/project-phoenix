import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'Project Phoenix',
      'welcome': 'Welcome to Project Phoenix',
      'onboarding_1_title': 'Enterprise Field Services',
      'onboarding_1_subtitle':
          'Professional installation, electrical, plumbing & AC services at your doorstep.',
      'onboarding_2_title': 'Emergency Dispatch',
      'onboarding_2_subtitle':
          'Need immediate assistance? Toggle emergency and get allocated in under 5 minutes.',
      'onboarding_3_title': 'Offline-First Reliability',
      'onboarding_3_subtitle':
          'Book services even when offline. Our sync engines align automatically once online.',
      'login_title': 'Customer Login',
      'login_subtitle': 'Access your secure enterprise field service dashboard',
      'email_label': 'Email Address',
      'email_hint': 'Enter your corporate or personal email',
      'password_label': 'Password',
      'password_hint': 'Enter your password',
      'phone_label': 'Phone Number',
      'phone_hint': 'Enter 10-digit mobile number',
      'otp_label': 'Enter OTP',
      'otp_hint': '6-digit verification code',
      'btn_login': 'Login with Email',
      'btn_send_otp': 'Send OTP',
      'btn_verify_otp': 'Verify & Login',
      'btn_google': 'Sign in with Google',
      'btn_guest': 'Browse as Guest',
      'forgot_pwd': 'Forgot Password?',
      'home_dashboard': 'Services Dashboard',
      'search_placeholder':
          'Search services (e.g. fan repair, kitchen leak)...',
      'emergency_toggle': 'EMERGENCY BOOKING',
      'recent_services': 'Recently Booked',
      'popular_services': 'Popular Services',
      'explore_categories': 'Service Categories',
      'quick_actions': 'Quick Actions',
      'book_now': 'Book Service',
      'property_select': 'Select Property',
      'address_select': 'Select Address',
      'date_select': 'Choose Date',
      'time_select': 'Preferred Time Slot',
      'problem_description': 'Problem Description',
      'upload_images': 'Upload Images',
      'upload_voice': 'Record Voice Note (Max 30s)',
      'booking_summary': 'Booking Summary',
      'est_price': 'Estimated Price',
      'confirm_booking': 'Confirm Booking',
      'booking_success': 'Booking Confirmed!',
      'booking_id': 'Booking ID',
      'tracking_title': 'Track Service Technician',
      'technician_details': 'Technician Details',
      'eta': 'Estimated Arrival Time',
      'invoice_title': 'Digital Invoice',
      'feedback_title': 'Rate Service',
      'profile_title': 'My Profile',
      'saved_addresses': 'Saved Addresses',
      'my_properties': 'My Properties',
      'orders_store': 'Product Orders',
      'warranty_title': 'Warranty Cards',
      'booking_history': 'Booking History',
      'settings_title': 'App Settings',
      'senior_mode': 'Senior Citizen Mode',
      'high_contrast': 'High Contrast Mode',
      'language_label': 'Language / மொழி',
      'help_center': 'Help Center',
      'ai_assistant': 'AI Voice Assistant',
      'faq_title': 'Frequently Asked Questions',
      'chat_placeholder': 'Ask me anything about your home services...',
      'error_required': 'This field is required',
      'error_email': 'Enter a valid email address',
      'error_phone': 'Enter a valid 10-digit phone number',
    },
    'ta': {
      'app_title': 'புராஜெக்ட் ஃபீனிக்ஸ்',
      'welcome': 'புராஜெக்ட் ஃபீனிக்ஸ்-க்கு உங்களை வரவேற்கிறோம்',
      'onboarding_1_title': 'கார்ப்பரேட் கள சேவைகள்',
      'onboarding_1_subtitle':
          'மின்சாரம், பிளம்பிங் மற்றும் ஏசி பழுதுபார்க்கும் தொழில்முறை சேவைகள் உங்கள் வீட்டு வாசலில்.',
      'onboarding_2_title': 'அவசரக்கால சேவை',
      'onboarding_2_subtitle':
          'உடனடி உதவி தேவையா? அவசரகால பொத்தானை அழுத்தி 5 நிமிடங்களுக்குள் உதவி பெறுங்கள்.',
      'onboarding_3_title': 'ஆஃப்லைன் தொழில்நுட்பம்',
      'onboarding_3_subtitle':
          'இணையம் இல்லாதபோதும் முன்பதிவு செய்யுங்கள். இணைப்பு வந்ததும் தானாகவே ஒத்திசைக்கப்படும்.',
      'login_title': 'வாடிக்கையாளர் உள்நுழைவு',
      'login_subtitle': 'உங்கள் பாதுகாப்பான கணக்கை அணுகவும்',
      'email_label': 'மின்னஞ்சல் முகவரி',
      'email_hint': 'உங்கள் மின்னஞ்சலை உள்ளிடவும்',
      'password_label': 'கடவுச்சொல்',
      'password_hint': 'கடவுச்சொல்லை உள்ளிடவும்',
      'phone_label': 'தொலைபேசி எண்',
      'phone_hint': '10 இலக்க மொபைல் எண்ணை உள்ளிடவும்',
      'otp_label': 'OTP குறியீடு',
      'otp_hint': '6 இலக்க குறியீட்டை உள்ளிடவும்',
      'btn_login': 'மின்னஞ்சல் மூலம் உள்நுழையவும்',
      'btn_send_otp': 'OTP அனுப்பவும்',
      'btn_verify_otp': 'சரிபார்த்து உள்நுழையவும்',
      'btn_google': 'கூகிள் மூலம் உள்நுழைக',
      'btn_guest': 'பார்வையாளராக தொடரவும்',
      'forgot_pwd': 'கடவுச்சொல் மறந்துவிட்டதா?',
      'home_dashboard': 'சேவைகள் முகப்பு',
      'search_placeholder':
          'மின்விசிறி, குழாய் பழுது போன்ற சேவைகளைத் தேடுங்கள்...',
      'emergency_toggle': 'அவசர முன்பதிவு',
      'recent_services': 'சமீபத்திய முன்பதிவுகள்',
      'popular_services': 'பிரபலமான சேவைகள்',
      'explore_categories': 'சேவை வகைகள்',
      'quick_actions': 'விரைவுச் செயல்கள்',
      'book_now': 'முன்பதிவு செய்',
      'property_select': 'சொத்து தேர்வு',
      'address_select': 'முகவரி தேர்வு',
      'date_select': 'தேதி தேர்வு',
      'time_select': 'விருப்பமான நேரம்',
      'problem_description': 'பிரச்சனையின் விளக்கம்',
      'upload_images': 'படங்களை பதிவேற்றுக',
      'upload_voice': 'குரல் பதிவு (அதிகபட்சம் 30 நொடி)',
      'booking_summary': 'முன்பதிவு விவரம்',
      'est_price': 'மதிப்பிடப்பட்ட விலை',
      'confirm_booking': 'முன்பதிவை உறுதிசெய்',
      'booking_success': 'முன்பதிவு உறுதி செய்யப்பட்டது!',
      'booking_id': 'முன்பதிவு எண்',
      'tracking_title': 'தொழில்நுட்ப வல்லுநர் கண்காணிப்பு',
      'technician_details': 'தொழில்நுட்ப வல்லுநர் விவரங்கள்',
      'eta': 'வருகை நேரம்',
      'invoice_title': 'மின்னணு விலைப்பட்டியல்',
      'feedback_title': 'மதிப்பீடு வழங்கவும்',
      'profile_title': 'எனது சுயவிவரம்',
      'saved_addresses': 'முகவரிகள்',
      'my_properties': 'எனது சொத்துக்கள்',
      'orders_store': 'தயாரிப்பு ஆர்டர்கள்',
      'warranty_title': 'உத்தரவாத அட்டை',
      'booking_history': 'முன்பதிவு வரலாறு',
      'settings_title': 'செயலி அமைப்புகள்',
      'senior_mode': 'முதியோர் எளிய முறை',
      'high_contrast': 'அதிக மாறுபட்ட நிறங்கள்',
      'language_label': 'மொழி / Language',
      'help_center': 'உதவி மையம்',
      'ai_assistant': 'AI குரல் உதவி',
      'faq_title': 'அடிக்கடி கேட்கப்படும் கேள்விகள்',
      'chat_placeholder': 'உங்கள் வீட்டு சேவைகள் பற்றி கேளுங்கள்...',
      'error_required': 'இப்புலம் கட்டாயமாகும்',
      'error_email': 'சரியான மின்னஞ்சலை உள்ளிடவும்',
      'error_phone': 'சரியான தொலைபேசி எண்ணை உள்ளிடவும்',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ta'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
