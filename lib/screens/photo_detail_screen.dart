import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PhotoDetailScreen extends StatefulWidget {
  final dynamic photo;

  const PhotoDetailScreen({Key? key, required this.photo}) : super(key: key);

  @override
  State<PhotoDetailScreen> createState() => _PhotoDetailScreenState();
}

class _PhotoDetailScreenState extends State<PhotoDetailScreen> {
  List<Map<String, dynamic>> comments = [];
  final TextEditingController _commentController = TextEditingController();
  bool isLoading = false;
  bool hasNewComment = false;
  int? currentUserId;

  Future<bool> showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF181B22),
            title: const Text("Hapus Komentar?",
                style:
                    TextStyle(color: Colors.white, fontFamily: 'Montserrat')),
            content: const Text("Yakin ingin menghapus komentar ini?",
                style:
                    TextStyle(color: Colors.white70, fontFamily: 'Montserrat')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Batal",
                    style: TextStyle(fontFamily: 'Montserrat')),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Hapus",
                    style: TextStyle(
                        color: Colors.redAccent, fontFamily: 'Montserrat')),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
    fetchComments();
  }

  void fetchCurrentUser() async {
    final id = await ApiService.getUserId();
    setState(() {
      currentUserId = id;
    });
  }

  Future<void> fetchComments() async {
    setState(() => isLoading = true);
    final result = await ApiService.getComments(widget.photo['id']);
    setState(() {
      comments = result;
      isLoading = false;
    });
  }

  Future<void> submitComment() async {
    final userId = await ApiService.getUserId();
    final text = _commentController.text.trim();

    if (userId != null && text.isNotEmpty) {
      final res =
          await ApiService.commentPhoto(widget.photo['id'], userId, text);

      if (res.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menambahkan komentar')),
        );
      } else {
        _commentController.clear();
        hasNewComment = true;
        await fetchComments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.photo['image_url'];
    final username = widget.photo['username'] ?? 'Unknown';
    final baseUrl = ApiService.getBaseUrl();
    String imageUrl = "$baseUrl/uploads/$fileName"
        .replaceAll('//', '/')
        .replaceFirst('http:/', 'http://');

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, hasNewComment);
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B0D13),
        resizeToAvoidBottomInset: true, // <-- tambahkan ini
        appBar: AppBar(
          backgroundColor: const Color(0xFF10131A),
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white, // <-- tombol back jadi putih
          ),
          title: const Text(
            "DETAIL FOTO",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white12, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.10),
                            blurRadius: 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 180, // <--- batasi tinggi gambar di sini
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      size: 60, color: Colors.redAccent),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blueGrey[900],
                          radius: 18,
                          child: Text(
                            username.isNotEmpty
                                ? username[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat',
                              fontSize: 16,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    // Ganti dari Expanded ke Flexible
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181B22),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.blueAccent))
                          : comments.isEmpty
                              ? const Center(
                                  child: Text(
                                    "Belum ada komentar.",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontFamily: 'Montserrat',
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding: const EdgeInsets.all(12),
                                  itemCount: comments.length,
                                  separatorBuilder: (_, __) => const Divider(
                                      color: Colors.white12, height: 18),
                                  itemBuilder: (context, index) {
                                    final comment = comments[index];
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 2, horizontal: 4),
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blueGrey[800],
                                        child: Text(
                                          (comment['username'] ?? 'A')[0]
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Montserrat',
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        comment['username'] ?? 'Anonim',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Montserrat',
                                          fontSize: 15,
                                        ),
                                      ),
                                      subtitle: Text(
                                        comment['comment'],
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'Montserrat',
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: comment['user_id'] ==
                                              currentUserId
                                          ? IconButton(
                                              icon: const Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () async {
                                                final confirm =
                                                    await showDeleteDialog(
                                                        context);
                                                if (confirm == true) {
                                                  final success =
                                                      await ApiService
                                                          .deleteComment(
                                                              comment['id']);
                                                  if (success) {
                                                    fetchComments();
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Komentar dihapus")),
                                                    );
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text(
                                                              "Gagal menghapus komentar")),
                                                    );
                                                  }
                                                }
                                              },
                                            )
                                          : null,
                                    );
                                  },
                                ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF23272F),
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: Colors.white12, width: 1),
                            ),
                            child: TextField(
                              controller: _commentController,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Montserrat'),
                              decoration: const InputDecoration(
                                hintText: "Tambahkan komentar...",
                                hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'Montserrat'),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: submitComment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                            textStyle: const TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              fontSize: 15,
                            ),
                          ),
                          child: const Text("Kirim",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
