import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditNoteScreen extends StatefulWidget {
  final String docId;
  final String title;
  final String subject;
  final String content;

  const EditNoteScreen({
    super.key,
    required this.docId,
    required this.title,
    required this.subject,
    required this.content,
  });

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isSaving = false;

  final List<String> _subjects = [
    'Pemrograman Mobile',
    'Basis Data',
    'Algoritma',
    'Jaringan Komputer',
    'Kecerdasan Buatan',
    'Rekayasa Perangkat Lunak',
    'Lainnya',
  ];
  late String _selectedSubject;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _contentController = TextEditingController(text: widget.content);
    _selectedSubject = _subjects.contains(widget.subject)
        ? widget.subject
        : 'Lainnya';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateNote() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(widget.docId)
          .update({
        'title': _titleController.text.trim(),
        'subject': _selectedSubject,
        'content': _contentController.text.trim(),
        'updatedAt': Timestamp.now(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil diupdate!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengupdate: ${e.toString()}')),
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
        title: const Text('Edit Catatan',
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

              // Tombol Update
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _updateNote,
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
                      : const Icon(Icons.update),
                  label: Text(_isSaving ? 'Mengupdate...' : 'Update Catatan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}