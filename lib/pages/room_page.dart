import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/appwrite_service.dart';
import 'game_guess_page.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart'; // برای مدل Document

class RoomPage extends StatefulWidget {
  final String roomCode;
  final String playerName;
  final bool isCreator;

  const RoomPage({
    super.key,
    required this.roomCode,
    required this.playerName,
    this.isCreator = false,
  });

  @override
  State<RoomPage> createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  final appwrite = AppwriteService();
  List<String> players = [];
  RealtimeSubscription? _subscription;
  String? documentId;
  int countdown = 3;
  Timer? _timer;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    _initRoom();
  }

  Future<void> _initRoom() async {
    try {
      if (widget.isCreator) {
        final doc = await appwrite.databases.createDocument(
          databaseId: 'jamal1_',
          collectionId: 'rooms',
          documentId: ID.unique(),
          data: {
            'roomCode': widget.roomCode,
            'players': [widget.playerName],
          },
        );
        documentId = doc.$id;
        players = List<String>.from(doc.data['players']);
      } else {
        await _refreshRoom(joinRoom: true);
      }

      // فعال‌سازی ریل‌تایم
      _subscription = appwrite.realtime.subscribe([
        'databases.jamal1_.collections.rooms.documents.$documentId'
      ]);

      _subscription!.stream.listen((event) {
        final type = event.events.first;
        final payload = event.payload;
        if (type.contains('update') && mounted) {
          setState(() {
            players = List<String>.from(payload['players']);
          });
          _checkStartCondition(payload: payload);
        }
      });

      if (documentId != null) {
        final doc = await appwrite.databases.getDocument(
          databaseId: 'jamal1_',
          collectionId: 'rooms',
          documentId: documentId!,
        );
        _checkStartCondition(payload: doc.data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _refreshRoom({bool joinRoom = false}) async {
    final list = await appwrite.databases.listDocuments(
      databaseId: 'jamal1_',
      collectionId: 'rooms',
      queries: [Query.equal('roomCode', widget.roomCode)],
    );

    if (list.documents.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("اتاق پیدا نشد")),
        );
      }
      return;
    }

    final doc = list.documents.first;
    documentId = doc.$id;
    players = List<String>.from(doc.data['players']);

    if (joinRoom && !players.contains(widget.playerName) && players.length < 2) {
      players.add(widget.playerName);
      if (mounted) setState(() {});
      await appwrite.databases.updateDocument(
        databaseId: 'jamal1_',
        collectionId: 'rooms',
        documentId: documentId!,
        data: {'players': players},
      );
    }
    if (mounted) setState(() {});
  }

  Future<void> _checkStartCondition({Map<String, dynamic>? payload}) async {
    if (players.length == 2 && !gameStarted && documentId != null) {
      gameStarted = true;
      String? starter;
      String? guesser;

      Document? doc;
      if (payload == null) {
        doc = await appwrite.databases.getDocument(
          databaseId: 'jamal1_',
          collectionId: 'rooms',
          documentId: documentId!,
        );
      }
      final data = payload ?? doc!.data;

      starter = data['starter'] as String?;

      if (starter == null) {
        starter = players[Random().nextInt(players.length)];
        guesser = players.firstWhere((p) => p != starter);

        await appwrite.databases.updateDocument(
          databaseId: 'jamal1_',
          collectionId: 'rooms',
          documentId: documentId!,
          data: {'starter': starter, 'guesser': guesser},
        );
      } else {
        guesser = data['guesser'] as String?;
      }

      if (starter != null && guesser != null) {
        _startCountdown(starter, guesser);
      }
    }
  }

  void _startCountdown(String starter, String guesser) {
    if (_timer != null && _timer!.isActive) return;

    if (mounted) setState(() => countdown = 3);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        _timer?.cancel();
        _goToGame(starter, guesser);
      } else {
        if (mounted) setState(() => countdown--);
      }
    });
  }

  void _goToGame(String starter, String guesser) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameGuessPage(
          roomCode: widget.roomCode,
          players: players,
          currentPlayerName: widget.playerName,
          starterName: starter,
          documentId: documentId!,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.close();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${widget.roomCode}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async => await _refreshRoom(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "بازیکنان حاضر در اتاق:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (players.length < 2)
              const Text(
                'منتظر بازیکن دوم...',
                style: TextStyle(fontSize: 16, color: Colors.orange),
              ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (_, index) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(players[index],
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
            ),
            if (players.length == 2 && countdown > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 20, top: 20),
                child: Text(
                  "شروع بازی در: $countdown",
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
