import 'package:chat_application/Presentation/chat_screen.dart';
import 'package:chat_application/Presentation/profilesetup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _ensureSignedIn();
  }

  Future<void> _ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
    final user = _auth.currentUser!;
    // update presence
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'isOnline': true,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // set offline on disconnect using server timestamp (Firestore has limited onDisconnect functionality — for production use Realtime DB for robust presence)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text(
          "JustChat",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color.fromARGB(255, 19, 19, 31),
        actions: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Icon(Icons.camera_alt, color: Colors.white),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('threads')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          ;
          final threads = snapshot.data!.docs;
          if (threads.isEmpty) {
            return const Center(child: Text('No chats yet'));
          }
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final doc = threads[index];
              final threadId = doc.id;
              final title = doc['title'] ?? 'Chat';
              final lastMsg = doc['lastMessage'] ?? '';
              final updatedAt = doc['updatedAt'];
              // final photourl = doc['imageUrl'];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                    doc['photoUrl'] ??
                        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(title)}',
                  ),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: Text(
                  updatedAt == null
                      ? ''
                      : (updatedAt as Timestamp).toDate().toLocal().toString(),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ChatScreen(threadId: threadId, threadTitle: title),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _createThread().then((value) {
            if (kDebugMode) {
              print("THREAD CREATED SUCCESSFULLY ");
            }
          });
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  Future<void> _createThread() async {
    final uid = _auth.currentUser!.uid;

    // fetch user name & photo from users collection
    final userDoc = await _firestore.collection('users').doc(uid).get();
    final userName = userDoc.data()?['name'] ?? 'Unknown User';
    final photoUrl = userDoc.data()?['photoUrl'];

    // create thread with user info
    final docRef = await _firestore.collection('threads').add({
      'title': userName,
      'createdBy': uid,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(threadId: docRef.id, threadTitle: userName),
      ),
    );
  }
}
