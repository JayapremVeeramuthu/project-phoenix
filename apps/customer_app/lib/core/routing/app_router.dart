import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/features/auth/presentation/email_login_screen.dart';
import 'package:project_phoenix_customer/features/auth/presentation/login_selection_screen.dart';
import 'package:project_phoenix_customer/features/auth/presentation/otp_login_screen.dart';
import 'package:project_phoenix_customer/features/auth/presentation/forgot_password_screen.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_flow_screen.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_success_screen.dart';
import 'package:project_phoenix_customer/features/emergency/presentation/emergency_booking_screen.dart';
import 'package:project_phoenix_customer/features/help_ai/presentation/ai_assistant_screen.dart';
import 'package:project_phoenix_customer/features/help_ai/presentation/help_center_screen.dart';
import 'package:project_phoenix_customer/features/home/presentation/home_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/booking_history_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/invoices_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/profile_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/edit_profile_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/properties_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/settings_screen.dart';
import 'package:project_phoenix_customer/features/profile/presentation/warranties_screen.dart';
import 'package:project_phoenix_customer/features/services/presentation/services_catalog_screen.dart';
import 'package:project_phoenix_customer/features/splash_onboarding/presentation/onboarding_screen.dart';
import 'package:project_phoenix_customer/features/splash_onboarding/presentation/splash_screen.dart';
import 'package:project_phoenix_customer/features/store/presentation/product_store_screen.dart';
import 'package:project_phoenix_customer/features/tracking/presentation/tracking_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authSelection = '/auth';
  static const String emailLogin = '/email-login';
  static const String otpLogin = '/otp-login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String services = '/services';
  static const String booking = '/booking';
  static const String emergency = '/emergency';
  static const String tracking = '/tracking';
  static const String store = '/store';
  static const String profile = '/profile';
  static const String profileInvoices = '/profile/invoices';
  static const String profileProperties = '/profile/properties';
  static const String profileWarranties = '/profile/warranties';
  static const String profileBookings = '/profile/bookings';
  static const String profileSettings = '/profile/settings';
  static const String profileEdit = '/profile/edit';
  static const String helpCenter = '/help-center';
  static const String aiAssistant = '/ai-assistant';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: authSelection,
        builder: (context, state) => const LoginSelectionScreen(),
      ),
      GoRoute(
        path: emailLogin,
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: otpLogin,
        builder: (context, state) => const OtpLoginScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '$services/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId'] ?? '';
          return ServicesCatalogScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '$booking/success',
        builder: (context, state) {
          final bookingId = state.uri.queryParameters['id'] ?? '';
          final isOffline = state.uri.queryParameters['offline'] == 'true';
          return BookingSuccessScreen(
              bookingId: bookingId, isOffline: isOffline);
        },
      ),
      GoRoute(
        path: '$booking/:serviceId',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId'] ?? '';
          return BookingFlowScreen(serviceId: serviceId);
        },
      ),
      GoRoute(
        path: emergency,
        builder: (context, state) => const EmergencyBookingScreen(),
      ),
      GoRoute(
        path: '$tracking/:bookingId',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'] ?? '';
          return TrackingScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: store,
        builder: (context, state) => const ProductStoreScreen(),
      ),
      GoRoute(
        path: profile,
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'invoices',
            builder: (context, state) => const InvoicesScreen(),
          ),
          GoRoute(
            path: 'properties',
            builder: (context, state) => const PropertiesScreen(),
          ),
          GoRoute(
            path: 'warranties',
            builder: (context, state) => const WarrantiesScreen(),
          ),
          GoRoute(
            path: 'bookings',
            builder: (context, state) => const BookingHistoryScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: helpCenter,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: aiAssistant,
        builder: (context, state) => const AiAssistantScreen(),
      ),
    ],
  );
}
