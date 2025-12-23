import 'package:flutter/material.dart';

class PhotoCard extends StatefulWidget {
  final String imageUrl;

  const PhotoCard({super.key, required this.imageUrl});

  @override
  _PhotoCardState createState() => _PhotoCardState();
}

class _PhotoCardState extends State<PhotoCard> {
  int likes = 0;
  List<String> comments = [];
  TextEditingController commentController = TextEditingController();

  void addLike() {
    setState(() {
      likes++;
    });
  }

  void addComment(String comment) {
    setState(() {
      comments.add(comment);
    });
    commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(widget.imageUrl, fit: BoxFit.cover, width: double.infinity, height: 200),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.favorite, color: Colors.red),
                      onPressed: addLike,
                    ),
                    Text('$likes Likes'),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: commentController,
                  decoration: InputDecoration(
                    hintText: "Tambahkan komentar...",
                    suffixIcon: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        if (commentController.text.isNotEmpty) {
                          addComment(commentController.text);
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: 10),
                ...comments.map((comment) => Text(comment)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
