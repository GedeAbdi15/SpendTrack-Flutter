import 'package:flutter/material.dart';
import '../core/supabase_client.dart';
import '../features/items/view/items_list_screen.dart';
import '../features/upload/view/upload_screen.dart';
import '../features/auth/view/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void logout(BuildContext context) async {
    await SupabaseConfig.client.auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseConfig.client.auth.currentUser;

    final screens = [
      const ItemsListScreen(), // Tab 1
      const UploadScreen(), // Tab 2
      ProfileScreen(
        email: user?.email ?? 'Unknown',
        avatarUrl: user?.userMetadata?['avatar_url'],
        onLogout: () => logout(context),
      ), // Tab 3
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Receipt',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// --- PROFILE SCREEN ---
class ProfileScreen extends StatelessWidget {
  final String email;
  final String? avatarUrl;
  final VoidCallback onLogout;

  const ProfileScreen({
    super.key,
    required this.email,
    required this.onLogout,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 16),
          Text(
            email,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onLogout,
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
