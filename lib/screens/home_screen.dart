import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'photo_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> photos = [];

  @override
  void initState() {
    super.initState();
    fetchPhotos();
  }

  void fetchPhotos() async {
    final result = await ApiService.fetchPhotos();
    setState(() {
      photos = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Row> photoRows = [];

    for (int i = 0; i < photos.length; i += 2) {
      final photo1 = photos[i];
      final photo2 = i + 1 < photos.length ? photos[i + 1] : null;

      photoRows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: buildPhotoCard(photo1)),
            const SizedBox(width: 14),
            Expanded(
                child: photo2 != null ? buildPhotoCard(photo2) : Container()),
          ],
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF10131A), Color(0xFF23272F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: photos.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: photoRows.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) => photoRows[index],
            ),
    );
  }

  Widget buildPhotoCard(dynamic photo) {
    final fileName = photo['image_url'] ?? '';
    final username = photo['username'] ?? 'Unknown';
    final baseUrl = ApiService.getBaseUrl();
    String imageUrl = "$baseUrl/uploads/$fileName"
        .replaceAll('//', '/')
        .replaceFirst('http:/', 'http://');

    return Card(
      color: const Color(0xFF181B22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 6,
      shadowColor: Colors.blueAccent.withOpacity(0.15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username & Avatar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueGrey[900],
                  child: Text(
                    username.isNotEmpty ? username[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                      fontSize: 15,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gambar
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white12, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueAccent.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 90, // ubah dari 120 ke 90 agar gambar sedang
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[900],
                        height: 90, // pastikan tinggi error container sama
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 48,
                            color: Colors.redAccent,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Tombol Like dan Comment
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Tombol Like
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        (photo['isLiked'] == 1)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.redAccent,
                      ),
                      onPressed: () async {
                        setState(() {
                          final isLiked = photo['isLiked'] == 1;
                          photo['isLiked'] = isLiked ? 0 : 1;
                          photo['likeCount'] = (!isLiked)
                              ? ((photo['likeCount'] ?? 0) + 1)
                              : ((photo['likeCount'] ?? 1) - 1);
                        });

                        final result = await ApiService.likePhoto(photo['id']);
                        if (result['success'] == true) {
                          fetchPhotos();
                        }

                        if (result['success'] != true) {
                          setState(() {
                            final isLiked = photo['isLiked'] == 1;
                            photo['isLiked'] = isLiked ? 0 : 1;
                            photo['likeCount'] = (!isLiked)
                                ? ((photo['likeCount'] ?? 0) + 1)
                                : ((photo['likeCount'] ?? 1) - 1);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(result['error'] ??
                                    "Gagal mengupdate like")),
                          );
                        }
                      },
                    ),
                    Text(
                      '${photo['likeCount'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontFamily: 'Montserrat',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "Likes",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Tombol Comment
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PhotoDetailScreen(photo: photo),
                      ),
                    );
                    if (result == true) {
                      fetchPhotos();
                    }
                  },
                  icon: const Icon(Icons.comment_outlined,
                      size: 18, color: Colors.blueAccent),
                  label: Text(
                    "Comment (${photo['commentCount'] ?? 0})",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontFamily: 'Montserrat',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF23272F),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    minimumSize: const Size(50, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
