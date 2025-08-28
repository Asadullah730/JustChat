import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String threadId;
  final String threadTitle;
  const ChatScreen({
    super.key,
    required this.threadId,
    required this.threadTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _setSeenListener();
  }

  void _setSeenListener() {
    // In a real app you'd update message "seen" when this user views messages
  }

  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty) return;
    final user = _auth.currentUser!;
    final id = const Uuid().v4();
    final msg = {
      'id': id,
      'text': text.trim(),
      'senderId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'text',
      'seenBy': [user.uid],
    };
    await _firestore
        .collection('threads')
        .doc(widget.threadId)
        .collection('messages')
        .doc(id)
        .set(msg);
    await _firestore.collection('threads').doc(widget.threadId).set({
      'lastMessage': text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    _controller.clear();
    _scroll.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Future<void> _sendImage() async {
  //   final file = File(picked.path);
  //   final id = const Uuid().v4();
  //   final ref = FirebaseStorage.instance
  //       .ref()
  //       .child('chat_images')
  //       .child('$id.jpg');
  //   await ref.putFile(file);
  //   final url = await ref.getDownloadURL();
  //   final user = _auth.currentUser!;
  //   final msg = {
  //     'id': id,
  //     'imageUrl': url,
  //     'senderId': user.uid,
  //     'createdAt': FieldValue.serverTimestamp(),
  //     'type': 'image',
  //     'seenBy': [user.uid],
  //   };
  //   await _firestore
  //       .collection('threads')
  //       .doc(widget.threadId)
  //       .collection('messages')
  //       .doc(id)
  //       .set(msg);
  //   await _firestore.collection('threads').doc(widget.threadId).set({
  //     'lastMessage': '[Image]',
  //     'updatedAt': FieldValue.serverTimestamp(),
  //   }, SetOptions(merge: true));
  //   setState(() => _sending = false);
  //   _scroll.animateTo(
  //     0,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );
  // }

  Widget _buildMessage(Map<String, dynamic> data) {
    final user = _auth.currentUser!;
    final isMe = data['senderId'] == user.uid;
    final createdAt = data['createdAt'] as Timestamp?;
    final timeStr = createdAt == null
        ? ''
        : createdAt.toDate().toLocal().toString().split('.').first;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? Colors.teal[200] : Colors.grey[300],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (data['type'] == 'text') Text(data['text'] ?? ''),
              if (data['type'] == 'image')
                GestureDetector(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) =>
                        Dialog(child: Image.network(data['imageUrl'])),
                  ),
                  child: SizedBox(
                    width: 200,
                    height: 200,
                    child: Image.network(data['imageUrl'], fit: BoxFit.cover),
                  ),
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(timeStr, style: const TextStyle(fontSize: 10)),
                  const SizedBox(width: 6),
                  if (isMe) const Icon(Icons.done_all, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.threadTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('threads')
                  .doc(widget.threadId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                return ListView.builder(
                  controller: _scroll,
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return _buildMessage(data);
                  },
                );
              },
            ),
          ),

          // input area
          SafeArea(
            child: Row(
              children: [
                IconButton(
                  // onPressed: _sendImage,
                  onPressed: () {},
                  icon: const Icon(Icons.image),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendText,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),
                _sending
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      )
                    : IconButton(
                        onPressed: () => _sendText(_controller.text),
                        icon: const Icon(Icons.send),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
