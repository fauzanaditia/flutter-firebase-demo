import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNoteScreen extends StatefulWidget {
  const AddNoteScreen({super.key});

  @override
  State<AddNoteScreen> createState() => _AddNoteScreenState();
}

class _AddNoteScreenState extends State<AddNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isSaving = false;

  // Daftar mata kuliah untuk dropdown
  final List<String> _subjects = [
    'Pemrograman Mobile',
    'Basis Data',
    'Algoritma',
    'Jaringan Komputer',
    'Kecerdasan Buatan',
    'Rekayasa Perangkat Lunak',
    'Lainnya',
  ];
  String _selectedSubject = 'Pemrograman Mobile';

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('notes').add({
        'title': _titleController.text.trim(),
        'subject': _selectedSubject,
        'content': _contentController.text.trim(),
        'createdAt': Timestamp.now(),
        'userId': user?.uid,
        'userEmail': user?.email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Catatan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Judul
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Judul Catatan',
                  hintText: 'Contoh: Materi Pertemuan 5',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Mata Kuliah (Dropdown)
              DropdownButtonFormField<String>(
                value: _selectedSubject,
                decoration: const InputDecoration(
                  labelText: 'Mata Kuliah',
                  prefixIcon: Icon(Icons.school),
                ),
                items: _subjects
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedSubject = value!);
                },
              ),
              const SizedBox(height: 16),

              // Isi Catatan
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Isi Catatan',
                  hintText: 'Tulis catatan belajar Anda di sini...',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Isi catatan tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Menyimpan...' : 'Simpan Catatan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}