import 'package:flutter/material.dart';
import 'package:peer_chat_flutter/peer_chat_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeerChat Flutter Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final PeerChatFlutter _peerChat = PeerChatFlutter();
  final TextEditingController _peerIdController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final List<String> _messages = [];
  PeerConnectionState _connectionState = PeerConnectionState.closed;

  @override
  void initState() {
    super.initState();
    _initializePeerChat();
  }

  Future<void> _initializePeerChat() async {
    print('Requesting location permission');
    await Permission.location.request();

    print('Initializing PeerChat');
    bool initialized = await _peerChat.initialize();
    print('PeerChat initialized: $initialized');
    if (initialized) {
      setState(() {
        _messages.add('Initialized with Peer ID: ${_peerChat.myPeerId}');
      });
      print('Peer ID from PeerChatFlutter: ${_peerChat.myPeerId}');
      _listenForMessages();
      _listenForConnectionStateChanges();
    } else {
      setState(() {
        _messages.add('Failed to initialize PeerChat');
      });
      print('Failed to initialize PeerChat');
    }
  }

  void _listenForMessages() {
    _peerChat.messageStream.listen((message) {
      setState(() {
        _messages.add('Received: $message');
      });
    });
  }

  void _listenForConnectionStateChanges() {
    _peerChat.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
        _messages.add('Connection state changed: $state');
      });
    });
  }

  Future<void> _connectToPeer() async {
    String peerId = _peerIdController.text;
    bool connected = await _peerChat.connectToPeer(peerId);
    setState(() {
      _messages.add(connected ? 'Connected to $peerId' : 'Failed to connect to $peerId');
    });
  }

  Future<void> _sendMessage() async {
    String message = _messageController.text;
    bool sent = await _peerChat.sendMessage(message);
    if (sent) {
      setState(() {
        _messages.add('Sent: $message');
        _messageController.clear();
      });
    } else {
      setState(() {
        _messages.add('Failed to send message');
      });
    }
  }

  Future<void> _reconnect() async {
    bool reconnected = await _peerChat.reconnect();
    setState(() {
      _messages.add(reconnected ? 'Reconnected successfully' : 'Failed to reconnect');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PeerChat Flutter Example'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text('Connection State: $_connectionState'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(_messages[index]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _peerIdController,
                    decoration: const InputDecoration(hintText: 'Enter Peer ID'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _connectToPeer,
                  child: const Text('Connect'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _reconnect,
            child: const Text('Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _peerChat.dispose();
    _peerIdController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
