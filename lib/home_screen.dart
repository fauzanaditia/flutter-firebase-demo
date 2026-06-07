import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_note_screen.dart';
import 'edit_note_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }

  Future<void> _deleteNote(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Catatan'),
        content: const Text('Catatan ini akan dihapus permanen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('notes')
          .doc(docId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan berhasil dihapus.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          '📚 StudyNotes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.primaryContainer,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Query sederhana tanpa orderBy untuk hindari error index
        stream: FirebaseFirestore.instance
            .collection('notes')
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
                    const SizedBox(height: 8),
                    Text('Error: ${snapshot.error}',
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }

          // Sort di client side, tidak perlu index
          final docs = snapshot.data?.docs ?? [];
          docs.sort((a, b) {
            final aTime =
                (a.data() as Map)['createdAt'] as Timestamp;
            final bTime =
                (b.data() as Map)['createdAt'] as Timestamp;
            return bTime.compareTo(aTime);
          });

          return Column(
            children: [
              // Info user + jumlah catatan
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colorScheme.primaryContainer.withOpacity(0.5),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primary,
                      child:
                          Icon(Icons.person, color: colorScheme.onPrimary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Halo,',
                              style: TextStyle(fontSize: 12)),
                          Text(
                            user?.email ?? 'Pengguna',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${docs.length} Catatan',
                        style: TextStyle(
                            color: colorScheme.onPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

              // List catatan
              Expanded(
                child: docs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.note_outlined,
                                size: 80,
                                color: colorScheme.onSurfaceVariant
                                    .withOpacity(0.3)),
                            const SizedBox(height: 16),
                            Text(
                              'Belum ada catatan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap tombol + untuk menambah catatan',
                              style: TextStyle(
                                  color: colorScheme.onSurfaceVariant
                                      .withOpacity(0.7)),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        itemBuilder: (ctx, index) {
                          final doc = docs[index];
                          final data =
                              doc.data() as Map<String, dynamic>;

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: colorScheme.outlineVariant),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .secondaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          data['subject'] ?? '',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        data['createdAt'] != null
                                            ? _formatDate(data[
                                                    'createdAt']
                                                as Timestamp)
                                            : '',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme
                                                .onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['content'] ?? '',
                                    style: TextStyle(
                                        color:
                                            colorScheme.onSurfaceVariant,
                                        fontSize: 13),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditNoteScreen(
                                                docId: doc.id,
                                                title:
                                                    data['title'] ?? '',
                                                subject:
                                                    data['subject'] ??
                                                        '',
                                                content:
                                                    data['content'] ??
                                                        '',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.edit,
                                            size: 16),
                                        label: const Text('Edit'),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        onPressed: () => _deleteNote(
                                            context, doc.id),
                                        icon: const Icon(Icons.delete,
                                            size: 16),
                                        label: const Text('Hapus'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddNoteScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Tambah Catatan'),
      ),
    );
  }
}