# Fix App Navigation Flow

## Tasks
- [x] Edit lib/pages/splash_screen.dart: Change navigation from '/auth' to '/welcome'
- [x] Edit lib/pages/welcome_page.dart: Change "Mulai" button navigation from '/login' to '/auth'
- [x] Edit lib/auth/auth_gate.dart: Remove the if (isFirstTimeUser == true) return const WelcomePage(); block
- [x] Add assets/images/ to pubspec.yaml to fix image loading
- [ ] Test the flow: Run the app to verify Splash -> Welcome -> "Mulai" -> Login (if not logged in)
