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
      appBar: AppBar(
        title: const Text("Chats"),
        actions: [
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('users')
                .doc(_auth.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final user = snapshot.data!.data() as Map<String, dynamic>;

              return IconButton(
                icon: CircleAvatar(
                  backgroundImage: user['photoUrl'] != ''
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: user['photoUrl'] == '' ? Text(user['name'][0]) : null,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text(user['name']),
                      content: Text(user['email']),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('threads')
            .orderBy('updatedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final threads = snapshot.data!.docs;
          if (threads.isEmpty) return const Center(child: Text('No chats yet'));
          return ListView.builder(
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final doc = threads[index];
              final threadId = doc.id;
              final title = doc['title'] ?? 'Chat';
              final lastMsg = doc['lastMessage'] ?? '';
              final updatedAt = doc['updatedAt'];
              return ListTile(
                title: Text(title),
                subtitle: Text(
                  lastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Text(
                  updatedAt == null
                      ? ''
                      : (updatedAt as Timestamp).toDate().toLocal().toString(),
                ),
                onTap: () {
                  if (kDebugMode) {
                    print("THREAD ID : $threadId");
                  }
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
    final docRef = await _firestore.collection('threads').add({
      'title': 'New Chat',
      'createdBy': uid,
      'updatedAt': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    if (kDebugMode) {
      print('USER ID : $uid');
    }
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) =>
    //         ChatScreen(threadId: docRef.id, threadTitle: 'New Chat'),
    //   ),
    // );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen(uid: uid)),
    );
  }
}
