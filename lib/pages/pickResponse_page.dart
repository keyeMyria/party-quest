import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_quest/globals.dart' as globals;
import 'package:firebase_database/firebase_database.dart';

class PickResponsePage extends StatefulWidget {
	@override
	createState() => PickResponseState();
}

class PickResponseState extends State<PickResponsePage> {
	TextEditingController _textController = TextEditingController();
  bool _buttonEnabled = false;
  List<String> _pushIds = [];

	@override
	Widget build(BuildContext context) {
    _pushIds = [];
		return Scaffold(
			appBar: new AppBar(
				automaticallyImplyLeading: false,
				leading: new IconButton(
					icon: new Icon(Icons.close, color: Colors.white),
					onPressed: () => Navigator.pop(context)),
				backgroundColor: const Color(0xFF00073F),
				elevation: -1.0,
				title: new Text(
					"What happens next?",
					style:
						TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 30.0, letterSpacing: 1.5),
				)),
			body: Container(
				decoration: BoxDecoration(
					image: DecorationImage(
						image: AssetImage("assets/images/background-gradient.png"),
						fit: BoxFit.fill)),
				child: 
        Column( children: <Widget>[Expanded(
          child: Container(child: ListView(children: <Widget>[
            Container(height: 10.0), 
            _buildCharacterList(),
            _buildDescriptionField(), 
            _buildSubmitButton(context),
            _buildSuggestions()])))])
        ));
	}

  Widget _buildCharacterList(){
    List<Widget> characterWidgets = [];
    return FutureBuilder(
			future: Firestore.instance.collection('Games').document(globals.gameState['id']).get(),
			builder: (BuildContext context, AsyncSnapshot snapshot) {
        if(snapshot.hasData){
          for(var key in snapshot.data['characters'].keys){
            characterWidgets.add(_buildCharacterWidget(key, snapshot.data['characters'][key]));
            // characterWidgets.add(_buildCharacterWidget(snapshot.data['characters'][key]));
          }
          return Container(height: 80.0, child: ListView(children: characterWidgets, scrollDirection: Axis.horizontal));
        } else {
				  return CircularProgressIndicator();
        }
    });
  }

  Widget _buildCharacterWidget(String playerId, Map character){
    return GestureDetector(child: Container(width: 100.0, 
      child: Column(children: <Widget>[
        Container(
          width: 50.0,
          height: 50.0,
					decoration: BoxDecoration(
					image: DecorationImage(
							image: AssetImage("assets/images/" + character['characterId'] + ".png"),
							fit: BoxFit.contain,
						))),
        Text(character['characterName'], style: TextStyle(color: Colors.white))
      ])),
      onTap: () => _onCharacterTap(playerId, character));
  }

  void _onCharacterTap(String playerId, Map character) {
    _textController.text += character['characterName'] + ' ';
    if(_pushIds.contains(playerId) != true) _pushIds.add(playerId);
  }

  Widget _buildSuggestions(){
    return Column(children: <Widget>[
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("Something lurks behind that tree.", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("A character gets sick.", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("One of the characters turns on the party.", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("Someone finds a magic orb.", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("What's that smell?", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("Goblins are everywhere!", style: TextStyle(color: Colors.white, fontSize: 22.0))),
       Padding(padding: EdgeInsets.only(top: 20.0), child: Text("The party eats magic mushrooms.", style: TextStyle(color: Colors.white, fontSize: 22.0)))
    ]); 
  }

  Widget _buildDescriptionField(){
    return Container(
				height: 100.0,
				margin: EdgeInsets.symmetric(horizontal: 10.0),
				padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
				child: TextField(
					maxLines: null,
					keyboardType: TextInputType.text,
					controller: _textController,
					onChanged: _handleTextChange,
					style: TextStyle(color: Colors.white, fontSize: 18.0, fontFamily: 'LondrinaSolid'),
					decoration:
						InputDecoration.collapsed(hintText: 'Tell the next part of the story...', hintStyle: TextStyle(color: const Color(0x99FFFFFF))),
				),
				decoration: BoxDecoration(
					color: const Color(0x33FFFFFF),
					borderRadius: BorderRadius.circular(8.0)),
			);
  }

	Widget _buildSubmitButton(BuildContext context){
		return Container(
			margin: EdgeInsets.symmetric(vertical: 0.0, horizontal: 10.0),
			child: Padding(
				padding: const EdgeInsets.only(top: 20.0),
				child: RaisedButton(
					padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 50.0),
						color: const Color(0xFF00b0ff),
						shape: new RoundedRectangleBorder(
							borderRadius:
								new BorderRadius.circular(
									10.0)),
						onPressed: _buttonEnabled ? () => _handleSubmitted(context) : null,
						child: new Text(
							"Submit",
							style: new TextStyle(
								fontSize: 20.0,
								color: Colors.white,
								fontWeight: FontWeight.w800,
							))))); 
			}

  void _handleTextChange(String text){
    if(_textController.text.length > 0){
      // enable submit button
      setState((){
        _buttonEnabled = true;
      });
    } else {
      setState((){
        _buttonEnabled = false;
      });
    }
  }      

	void _handleSubmitted(BuildContext context) {
    Navigator.pop(context);
		var _gameId = globals.gameState['id'];
    Firestore.instance.collection('Games/$_gameId/Logs').document()
    .setData(<String, dynamic>{
      'text': _textController.text,
      'type': 'narration',
      'dts': DateTime.now(),
      'userId': globals.userState['userId'],
			'userName': globals.userState['name']
    });
    // UPDATE Game.turn
    final DocumentReference gameRef =
        Firestore.instance.collection('Games').document(_gameId);
    gameRef.get().then((gameResult) {
      String nextPlayerId, nextPlayerName, nextPlayerImageUrl;
      List<dynamic> sortedPlayerIds = gameResult['players'].keys.toList()..sort();
      int playerIndex = sortedPlayerIds.indexOf(globals.userState['userId']);
      if(playerIndex < sortedPlayerIds.length-1){
        nextPlayerId = sortedPlayerIds[playerIndex+1];
      } else {
        nextPlayerId = sortedPlayerIds[0];
      }
      nextPlayerName = gameResult['characters'][nextPlayerId] != null ? gameResult['characters'][nextPlayerId]['characterName'] : null;
      nextPlayerImageUrl = gameResult['characters'][nextPlayerId] != null ? gameResult['characters'][nextPlayerId]['imageUrl'] : null;
      var turns = [gameResult['turn'], {
        'playerId': nextPlayerId,
        'dts': DateTime.now(), 
        'turnPhase': 'act',
        'playerImageUrl': nextPlayerImageUrl,
        'playerName': nextPlayerName}
      ];
      var combinedTurns = turns.reduce((map1, map2) => map1..addAll(map2));
      gameRef.updateData(<String, dynamic>{
        'turn': combinedTurns
      });
      FirebaseDatabase.instance.reference().child('push').push().set(<String, dynamic>{
        'title': "It's your turn!",
        'message': "Your friends are waiting on you to continue the story!",
        'friendId': nextPlayerId,
        'gameId': globals.gameState['id'],
        'genre': globals.gameState['genre'],
        'name': globals.gameState['name'],
        'gameTitle': globals.gameState['title'],
        'code': globals.gameState['code'],
        'players': globals.gameState['players'],
        'creator': globals.gameState['creator']
      });

      _pushIds.forEach((pushId) {
        FirebaseDatabase.instance.reference().child('push').push().set(<String, dynamic>{
          'title': "You're been tagged in the story.",
          'message': "Check out what's new in " + globals.gameState['title'],
          'friendId': pushId,
          'gameId': globals.gameState['id'],
          'genre': globals.gameState['genre'],
          'name': globals.gameState['name'],
          'gameTitle': globals.gameState['title'],
          'code': globals.gameState['code'],
          'players': globals.gameState['players'],
          'creator': globals.gameState['creator']
        });
      });
    });
	}
}
