import 'dart:async';
import 'dart:math';
import 'package:peerdart/peerdart.dart';

class PeerChatPlugin {
  Peer? _peer;
  DataConnection? _dataConnection;
  final _messageController = StreamController<String>.broadcast();
  final _connectionStateController = StreamController<PeerConnectionState>.broadcast();
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  String? _lastConnectedPeerId;
  bool _isReconnecting = false;

  Stream<String> get messageStream => _messageController.stream;
  Stream<PeerConnectionState> get connectionStateStream => _connectionStateController.stream;

  Future<void> initialize({String? id, String? host, int? port, String? path}) async {
    try {
      _peer = Peer(
        id: id,
        options: PeerOptions(
          host: host ?? '0.peerjs.com',
          port: port ?? 443,
          path: path ?? '/',
          secure: true,
        ),
      );

      await _peer!.on('open').first.timeout(Duration(seconds: 30));
      _setupPeerListeners();
      _startHeartbeat();
      _connectionStateController.add(PeerConnectionState.connected);
    } catch (e) {
      _connectionStateController.add(PeerConnectionState.error);
      throw PeerInitializationError('Failed to initialize peer', e);
    }
  }

  void _setupPeerListeners() {
    _peer!.on<DataConnection>('connection').listen((event) {
      _dataConnection = event;
      _setupDataConnection();
    });
    
    _peer!.on('disconnected').listen((_) {
      _connectionStateController.add(PeerConnectionState.disconnected);
      if (!_isReconnecting) _attemptReconnect();
    });

    _peer!.on('close').listen((_) {
      _connectionStateController.add(PeerConnectionState.closed);
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(Duration(seconds: 5), (_) {
      if (_peer?.open != true && !_isReconnecting) {
        _connectionStateController.add(PeerConnectionState.disconnected);
        _attemptReconnect();
      }
    });
  }

  Future<void> _attemptReconnect() async {
    if (_isReconnecting) return;
    _isReconnecting = true;

    while (_reconnectAttempts < _maxReconnectAttempts) {
      try {
        await initialize(id: _peer?.id);
        if (_lastConnectedPeerId != null) {
          await connectToPeer(_lastConnectedPeerId!);
        }
        _reconnectAttempts = 0;
        _isReconnecting = false;
        _connectionStateController.add(PeerConnectionState.connected);
        return;
      } catch (e) {
        _reconnectAttempts++;
        await Future.delayed(Duration(seconds: pow(2, _reconnectAttempts).toInt()));
      }
    }

    _connectionStateController.add(PeerConnectionState.closed);
    _isReconnecting = false;
  }

  Future<void> reconnect() async {
    _reconnectAttempts = 0;
    await _attemptReconnect();
  }

  Future<String?> getPeerId() async {
    if (_peer == null) throw StateError('Peer not initialized. Call initialize() first.');
    return _peer!.id;
  }

  Future<void> connectToPeer(String peerId) async {
    if (_peer == null) throw StateError('Peer not initialized. Call initialize() first.');
    try {
      _dataConnection = await _peer!.connect(peerId);
      _setupDataConnection();
      _lastConnectedPeerId = peerId;
      _connectionStateController.add(PeerConnectionState.connected);
    } catch (e) {
      _connectionStateController.add(PeerConnectionState.error);
      throw PeerConnectionError('Failed to connect to peer: $peerId', e);
    }
  }

  void _setupDataConnection() {
    _dataConnection!.on<dynamic>('data').listen((data) {
      if (data is String) _messageController.add(data);
    });

    _dataConnection!.on('close').listen((_) {
      _connectionStateController.add(PeerConnectionState.disconnected);
      _attemptReconnect();
    });
  }

  Future<void> sendMessage(String message) async {
    if (_dataConnection == null) throw StateError('No active connection. Connect to a peer first.');
    try {
      _dataConnection!.send(message);
    } catch (e) {
      throw MessageSendError('Failed to send message', e);
    }
  }

  Future<void> closeConnection() async {
    if (_dataConnection != null) {
      _dataConnection!.close();
      _dataConnection = null;
    }
    if (_peer != null) {
      _peer!.disconnect();
      _peer = null;
    }
    _lastConnectedPeerId = null;
    _connectionStateController.add(PeerConnectionState.closed);
  }

  void dispose() {
    _heartbeatTimer?.cancel();
    _peer?.dispose();
    _messageController.close();
    _connectionStateController.close();
  }
}

enum PeerConnectionState { connected, disconnected, closed, error }

class PeerChatError extends Error {
  final String message;
  final dynamic originalError;
  PeerChatError(this.message, this.originalError);
  @override
  String toString() => '${runtimeType.toString()}: $message\nOriginal error: $originalError';
}

class PeerInitializationError extends PeerChatError {
  PeerInitializationError(String message, dynamic originalError) : super(message, originalError);
}

class PeerConnectionError extends PeerChatError {
  PeerConnectionError(String message, dynamic originalError) : super(message, originalError);
}

class MessageSendError extends PeerChatError {
  MessageSendError(String message, dynamic originalError) : super(message, originalError);
}
