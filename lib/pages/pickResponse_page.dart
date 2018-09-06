import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pegg_party/globals.dart' as globals;

class PickResponsePage extends StatelessWidget {
	final TextEditingController _textController = TextEditingController();

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
            Container(height: 20.0), 
            _buildDescriptionField(), 
            _buildSubmitButton(context)])))])
        ));
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
						onPressed: () => _handleSubmitted(context),
						child: new Text(
							"Submit",
							style: new TextStyle(
								fontSize: 20.0,
								color: Colors.white,
								fontWeight: FontWeight.w800,
							))))); 
			}

	void _handleSubmitted(BuildContext context) {
    Navigator.pop(context);
		var _gameId = globals.gameState['id'];
    Firestore.instance.collection('Games/$_gameId/Logs').document()
    .setData(<String, dynamic>{
      'text': _textController.text,
      'type': 'narration',
      'dts': DateTime.now(),
      'userId': globals.userState['userId']
    });
    // UPDATE Game.turn
    final DocumentReference gameRef =
        Firestore.instance.collection('Games').document(_gameId);
    gameRef.get().then((gameResult) {
      var nextPlayer = gameResult['players'];
      var turns = [gameResult['turn'], {'playerId': 'asdksajf', 'dts': DateTime.now(), 'turnPhase': 'act'}];
      var combinedTurns = turns.reduce((map1, map2) => map1..addAll(map2));
      gameRef.updateData(<String, dynamic>{
        'turn': combinedTurns
      });
    });
	}
}