import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _store = FirebaseFirestore.instance;
User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = '/chat';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _controller = TextEditingController();
  String textMessage;

  final _auth = FirebaseAuth.instance;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        textMessage = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                      style: TextStyle(
                        color: Colors.black,
                      ),
                      controller: _controller,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _store.collection('message').add({
                        'text': textMessage,
                        'sender': loggedInUser.email,
                        'createdTime': FieldValue.serverTimestamp(),
                      });
                      _controller.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  const MessageStream({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _store.collection('message').orderBy('createdTime').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        final messages = snapshot.data.docs.reversed;
        List<Widget> messageBubbles = [];
        for (var message in messages) {
          Map<String, dynamic> data = message.data() as Map<String, dynamic>;
          String text = data['text'];
          String sender = data['sender'];
          int seconds = data['createdTime'].seconds;
          int nanoseconds = data['createdTime'].nanoseconds;

          // Convert the timestamp to microseconds
          int microseconds = (seconds * 1000000) + (nanoseconds / 1000).round();

          // Create a DateTime object from the microseconds
          DateTime dateTime = DateTime.fromMicrosecondsSinceEpoch(microseconds);

// Extract the day and hour from the DateTime object
          int hour = dateTime.hour;
          int minute = dateTime.minute;
          int day = dateTime.day;
          int month = dateTime.month;
          int year = dateTime.year;

          var currentUser = loggedInUser.email;
          if (currentUser == sender) {}
          var messageBubble = MessageBubble(
            sender: sender,
            text: text,
            isMe: currentUser == sender,
            time: "$hour:$minute $day/$month/$year",
          );
          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatefulWidget {
  String text;
  String sender;
  bool isMe;
  String time;
  MessageBubble({this.text, this.sender, this.isMe, this.time});
  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _showTime = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _showTime = !_showTime;
              print(widget.time);
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  widget.sender,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Material(
                  color: widget.isMe ? Colors.lightBlueAccent : Colors.white,
                  borderRadius: widget.isMe ? kRightBubble : kLeftBubble,
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 20),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                          color: widget.isMe ? Colors.white : Colors.black,
                          fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showTime == true)
          Text(
            widget.time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
      ],
    );
  }
}
