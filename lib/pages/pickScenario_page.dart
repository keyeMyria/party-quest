import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:party_quest/globals.dart' as globals;
// import 'dart:math';

class PickScenarioPage extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: new AppBar(
				automaticallyImplyLeading: false,
				leading: new IconButton(
					icon: new Icon(Icons.close, color: Colors.white),
					onPressed: () => Navigator.pop(context)),
				backgroundColor: const Color(0xFF00073F),
				elevation: -1.0,
				title: new Text(
					"Pick a Scenario",
					style:
						TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
				)),
			body: Container(
				decoration: BoxDecoration(
					image: DecorationImage(
						image: AssetImage("assets/images/background-gradient.png"),
						fit: BoxFit.fill)),
				child: _buildPickScenario()));
	}

	Widget _buildPickScenario() {
		var _genre = globals.gameState['genre'];
    return StreamBuilder<QuerySnapshot>(
			stream: Firestore.instance
				.collection('Genres/$_genre/Scenarios')
				.snapshots(),
			builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
				if (!snapshot.hasData) return const Text('Loading...');
				final int messageCount = snapshot.data.documents.length;
				return ListView.builder(
					itemCount: messageCount,
					itemBuilder: (_, int index) {
						final DocumentSnapshot document =
							snapshot.data.documents[index];
						return GestureDetector(
							child: Container(
								padding: EdgeInsets.all(20.0),
								child: Text(
									document['title'],
									style: TextStyle(
										color: Colors.white,
										fontSize: 20.0),
								)),
							onTap: () => _selectScenario(context, document));
					});
			});
		}

	void _selectScenario(BuildContext context, DocumentSnapshot document) {
		Navigator.pop(context);
		var _gameId = globals.gameState['id'];
		// ADD Scenario to Chat Logs
		final DocumentReference newChat =
			Firestore.instance.collection('Games/$_gameId/Logs').document();
		newChat.setData(<String, dynamic>{
			'text': document.data['description'],
			'type': 'narration',
			'dts': DateTime.now(),
			'profileUrl': globals.userState['profilePic'],
			'userName': globals.userState['name'],
			'userId': globals.userState['userId']
		});
    // UPDATE Logs.turn
    final DocumentReference turn =
        Firestore.instance.collection('Games').document(_gameId);
    turn.updateData(<String, dynamic>{
      'turn': {
        'playerId': globals.userState['userId'],
        'turnPhase': 'act',
        'scenario': document.data['title'],
        'dts': DateTime.now(),
      }
    });
	}
}
