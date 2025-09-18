import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final supabase = Supabase.instance.client;
  final nameController = TextEditingController();
  final kelasController = TextEditingController();
  final jadwalController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data != null) {
      nameController.text = data['full_name'] ?? '';
      kelasController.text = data['kelas'] ?? '';
      jadwalController.text = data['jadwal_piket'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase.from('profiles').update({
      'full_name': nameController.text,
      'kelas': kelasController.text,
      'jadwal_piket': jadwalController.text,
    }).eq('id', user.id);

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Data berhasil disimpan")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Lengkap'),
            ),
            TextField(
              controller: kelasController,
              decoration: const InputDecoration(labelText: 'Kelas'),
            ),

            TextField(
              controller: jadwalController,
              decoration: const InputDecoration(labelText: 'Jadwal Piket'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _updateProfile,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Perubahan'),
            )
          ],
        ),
      ),
    );
  }
}
