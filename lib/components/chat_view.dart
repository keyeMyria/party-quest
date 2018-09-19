import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:party_quest/globals.dart' as globals;
import 'package:flutter/services.dart';
import 'package:timeago/timeago.dart';
import '../application.dart';
import 'package:fluro/fluro.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../components/roll_button.dart';
import '../components/rating_button.dart';
import 'package:firebase_database/firebase_database.dart';


class ChatView extends StatefulWidget {
	@override
	_ChatViewState createState() => new _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
	// bool _isPlaying = false;

	@override
	void initState() {
		super.initState();
	}

	bool _showOverlay = false;
  Map _turn;
	TapUpDetails _tapDownDetails;
	DocumentSnapshot _tappedBubble;

	_ChatViewState() {
		globals.gameState.changes.listen((changes) {
			// print(changes);
			// TODO only call setState once... not for every change of gameState
			setState(() {
				_showOverlay = false;
			});
		});
	}
	final TextEditingController _textController = TextEditingController();

	@override
	Widget build(BuildContext context) {
		// CollectionReference get logs =>
		return GestureDetector(
			child: Stack(children: <Widget>[
				Column(children: <Widget>[
					_buildChatLog(),
					_buildActionButton(),
					globals.gameState['players']
						?.contains(globals.userState['userId']) ==
						true
						? _buildTextComposer()
						: _buildInfoBox('Tap any speech bubble to react to what players are saying.')
						// : _buildReactionComposer()
				]),
				_showOverlay == true ? _buildOverlay(_buildReactionComposer()) : Container()
			]),
			onVerticalDragDown: (DragDownDetails d) => closeKeyboard(d));
	}

	// TODO: optimize this...
	void closeKeyboard(DragDownDetails d) {
		// if (d.delta.distance > 20) {
		FocusScope.of(context).requestFocus(new FocusNode());
		SystemChannels.textInput.invokeMethod('TextInput.hide');
		// }
	}

	Widget _buildInfoBox(String infoText){
		return Container(
			decoration: BoxDecoration(
				color: Color(0xFF4C6296),
				// boxShadow: <BoxShadow>[
				// BoxShadow(
				// color: Colors.black12,
				// blurRadius: 10.0,
				// offset: Offset(0.0, -10.0),
				// ),
				// ],
			),
			height: 80.0,
			child: Padding(padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
				child: Text(infoText, style: TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.w400))));
	}

	Widget _buildOverlay(Widget content) {
		MediaQueryData queryData;
		queryData = MediaQuery.of(context);
		return GestureDetector(
			child: Center(
				child: Container(
					width: queryData.size.width,
					height: queryData.size.height,
					child: content,
					decoration: BoxDecoration(
						shape: BoxShape.rectangle,
						color: Colors.black.withOpacity(.4),
					)),
			),
			onTap: _closeOverlay);
		}

	void _closeOverlay() {
		setState(() {
			_showOverlay = false;
		});
	}

	Widget _buildActionButton() {
		var _gameId = globals.gameState['id'];
		if (_gameId != null) {
			return StreamBuilder<DocumentSnapshot>(
				stream: Firestore.instance
					.collection('Games')
					.document(_gameId)
					.snapshots(),
				builder:
					(BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
					if (!snapshot.hasData) return new Text("Loading");
					var document = snapshot.data;
					if (document['players'][globals.userState['userId']] == true) {
						var characters = document['characters'];
            //PICK A CHARACTER
						if (characters == null || characters[globals.userState['userId']] == null) {
							Function pickCharacter = () => Application.router.navigateTo(
								context, 'pickCharacter',
								transition: TransitionType.fadeIn);
							return _buildButton(document['imageUrl'], pickCharacter,
								'Pick a character...', 'to play as in this story!');
						}
            
            //PICK A SCENARIO
						_turn = document['turn'];
						if (_turn == null || _turn['scenario'] == null) {  
							Function onPressed = () => Application.router.navigateTo(
								context, 'pickScenario',
								transition: TransitionType.fadeIn);
							return _buildButton(document['imageUrl'], onPressed,
							'Pick a Scenario', 'Set the stage for your party quest.');
						}

            //INVITE SOMEONE
            if (document['players'].length == 1) {
							Function pickCharacter = () => Application.router.navigateTo(
								context, 'inviteFriends?code=' + document['code'],
								transition: TransitionType.fadeIn);
							return _buildButton(document['imageUrl'], pickCharacter,
								'Invite a friend!', 'Get your party together.');
						}

            // YOUR TURN
            if(_turn['playerId'] == globals.userState['userId']){
              // ACT PHASE
              if (_turn['turnPhase'] == 'act') {
                Function onPressed = () => Application.router.navigateTo(
                  context, 'pickAction',
                  transition: TransitionType.fadeIn);
                  return _buildButton(globals.userState['profilePic'], onPressed,
                    'What do you do?', "It's your turn, " + globals.userState['name'] + '.');
              }
              // DIFFICULTY
              if(_turn['turnPhase'] == 'difficulty') {
                if(document['players'].keys.length == 1){
                  //you can set your own difficulty if you're the only person in here.
                  return RatingButton(_turn);
                } else {
                  return _buildButton(_turn['playerImageUrl'], null,
                    'Waiting on...', 'Another player to set the difficulty.');
                }
              }
              // ROLL PHASE
              if(_turn['turnPhase'] == 'roll'){
                return RollButton(_turn, characters);
              }
              // RESPOND PHASE
              if(_turn['turnPhase'] == 'respond') {
                Function onPressed = () => Application.router.navigateTo(
                  context, 'pickResponse',
                  transition: TransitionType.fadeIn);
                return _buildButton(document['imageUrl'], onPressed,
                  'What happens next?', 'Tell the next part of the story.');
              }
            }
            // NOT YOUR TURN
            // RESPOND PHASE
            if(_turn['turnPhase'] == 'difficulty') {
              return RatingButton(_turn);
            }

            if(_turn['playerImageUrl'] != null){
              return _buildButton(_turn['playerImageUrl'], null,
                'Waiting on...', 'Your friend ' + _turn['playerName'] + ' to finish their turn.');
            } else{
              return _buildButton(document['imageUrl'], null,
                'Waiting on...', 'The next player to start their turn');
            }
					} else {
            if(globals.userState['requests'] == null || globals.userState['requests']?.contains(globals.gameState['code']) != true){
              //request not sent
              return _buildButton(
                document['imageUrl'],
                _handleJoinButtonPressed,
                'Request to Join...',
                'so you can adventure with this party!');
            } else {
              return _buildButton(document['imageUrl'], null,
              'Request Sent...', 'Waiting on approval from the game creator.');
            }
					}
				});
		} else {
			return Expanded(child: Container());
		}
	}

	Widget _buildReactionComposer() {
		return Stack(children: <Widget>[Positioned(top: _tapDownDetails.globalPosition.dy - 130, 
			//Column( children: <Widget>[Flexible(child: Row(children: <Widget>[Expanded(child: 
			// child: Row(children: <Widget>[ Expanded(child: Container(height: 80.0, child: ListView(
			child: Container(height: 80.0, width: 400.0, child: ListView(
				scrollDirection: Axis.horizontal,
				children: <Widget>[
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-love.png'), width: 50.0), onTap: () => _onTapReaction('love'))),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-cool.png'), width: 50.0), onTap: () => _onTapReaction('cool'))),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-lol.png'), width: 50.0), onTap: () => _onTapReaction('lol'))),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-meh.png'), width: 50.0), onTap: () => _onTapReaction('meh'))),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-wow.png'), width: 50.0), onTap: () => _onTapReaction('wow'))),
					Padding(
						padding: EdgeInsets.symmetric(horizontal: 10.0),
						child: GestureDetector(child: Container(child: Image.asset('assets/images/reaction-snooze.png'), width: 50.0), onTap: () => _onTapReaction('snooze'))),
				],
			)))]);
	}

		void _onTapReaction(String reactionType) {
			setState(() {
			  _showOverlay = false;
			});
      // TODO: only do this if the user hasn't already reacted with this type on this bubble.
      _tappedBubble.reference.get().then((bubbleDoc) {
        if(bubbleDoc.data != null){
          if(bubbleDoc.data['reactions'] != null){
            if(bubbleDoc.data['reactions'][reactionType] != null)
              bubbleDoc.data['reactions'][reactionType] += 1;
            else
              bubbleDoc.data['reactions'][reactionType] = 1;
          } else {
            bubbleDoc.data['reactions'] = {reactionType: 1};
          }
        }
      _tappedBubble.reference.updateData(bubbleDoc.data).then((onValue) {
        var _userId = bubbleDoc.data['userId'];
        var _gameId = globals.gameState['id'];
        final DocumentReference reactionsRef = Firestore.instance.collection('Games/$_gameId/Reactions').document(_userId);
        reactionsRef.get().then((reactionResult){
          if(reactionResult.data == null){
            reactionsRef.setData({ reactionType: 1 });
          } else {
            if(reactionResult.data[reactionType] == null) reactionResult.data[reactionType] = 0;
            reactionResult.data[reactionType] += 1;
            reactionsRef.updateData(reactionResult.data);
          }
        });
      });

      // This doesnt work for public games because public players dont have accesss to update the game.
      // final DocumentReference gameRef =
      // Firestore.instance.collection('Games').document(globals.gameState['id']);
      // gameRef.get().then((gameResult) {
      //   var reactions = gameResult['reactions'] == null ? {bubbleDoc.data['userId']: {reactionType: 0}} : gameResult['reactions'];
      //   if(reactions[bubbleDoc.data['userId']] == null) reactions[bubbleDoc.data['userId']] = {reactionType: 0};
      //   if(reactions[bubbleDoc.data['userId']][reactionType] == null) reactions[bubbleDoc.data['userId']][reactionType] = 0;
      //   reactions[bubbleDoc.data['userId']][reactionType] += 1;
      //   gameRef.updateData(<String, dynamic>{ 'reactions': reactions });
      // });
    });
		}

	Widget _buildChatLog() {
		var _gameId = globals.gameState['id'];
		final now = DateTime.now();
		final monthAgo = new DateTime(now.year, now.month, now.day - 30);
		if (_gameId != null) {
			return Expanded(
				child: StreamBuilder<QuerySnapshot>(
					stream: Firestore.instance
						.collection('Games/$_gameId/Logs')
						.where('dts', isGreaterThan: monthAgo)
						.orderBy('dts', descending: true)
						.snapshots(),
					builder: (BuildContext context,
						AsyncSnapshot<QuerySnapshot> snapshot) {
						if (!snapshot.hasData) return const Text('Loading...');
						final int messageCount = snapshot.data.documents.length;
						return new ListView.builder(
							reverse: true,
							itemCount: messageCount,
							itemBuilder: (_, int index) {
								final DocumentSnapshot document =
									snapshot.data.documents[index];
								DocumentSnapshot nextDocument;
								if (index + 1 < messageCount) {
									nextDocument = snapshot.data.documents[index + 1];
								} else {
									nextDocument = snapshot.data.documents[index];
								}
									if(document['type'] == 'narration'){
										return Container(child: Padding(padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0), child: 
											Column(children: <Widget>[

											document['titleImageUrl'] != null ?
                      CachedNetworkImage(
												placeholder: CircularProgressIndicator(),
												imageUrl: document['titleImageUrl'],
												height: 80.0,
												width: 80.0) : Container(),
											document['title'] != null ?
                      Padding(padding: EdgeInsets.only(top: 5.0, bottom: 10.0), child: Text(document['title'],
												style: new TextStyle(
													color: Colors.white,
													fontWeight: FontWeight.w800,
													letterSpacing: 0.5,
													fontSize: 24.0,
												))) : Container(),
												Text(document['text'].replaceAll('\\n', '\n\n'), style: TextStyle(color: Colors.white, fontSize: 20.0 ))
											]

											)));
									}
								var message = new ChatMessage(
									type: document['type'],
									title: document['title'],
									userId: document['userId'],
									userName: document['userName'],
									reactions: document['reactions'],
									text: document['text'],
									profileUrl: document['profileUrl'],
									dts: document['dts']);
								if (message.userName != null &&
									message.userId != globals.userState['userId'] &&
									message.userName != nextDocument['userName']) {
									return Column(children: <Widget>[
										_buildLabel(message.userName, message.dts),
										GestureDetector(
											child: ChatMessageListItem(message),
											onTapUp: (TapUpDetails details) => _onTapBubble(details, document)),
										// document['gif'] != null
										// ? PeggVideoPlayer(document['gif'])
										// : Container()
									]);
								} else {
									return Column(children: <Widget>[
										GestureDetector(
											child: ChatMessageListItem(message),
											onTapUp: (TapUpDetails details) => _onTapBubble(details, document)),
										// document['gif'] != null
										// ? PeggVideoPlayer(document['gif'])
										// : Container()
									]);
								}
							});
					}));
		} else {
			return Expanded(child: Container());
		}
	}

	void _onTapBubble(TapUpDetails details, DocumentSnapshot document) {
		setState(() {
			_showOverlay = true;
				_tapDownDetails = details;
					_tappedBubble = document;
		});
	}

	void _handleJoinButtonPressed() {
    var userRef = Firestore.instance.collection('Users').document(globals.userState['userId']);
		userRef.get().then((snapshot) {
			Map userRequests = snapshot.data['requests'] == null
				? new Map()
				: snapshot.data['requests'];
			userRequests[globals.gameState['code']] = true;
			userRef.updateData(<String, dynamic>{
				'requests': userRequests,
			});
      globals.userState['requests'] = userRequests.toString();
      setState(() {
        // just trigger a new build
        _showOverlay = false;
      });
    });
    FirebaseDatabase.instance.reference().child('push').push().set(<String, dynamic>{
      'title': "New request to join the party!",
      'message': globals.userState['name'] + " would like to join " + globals.gameState['title'] + '.',
      'friendId': globals.gameState['creator'],
      'gameId': globals.gameState['id'],
      'genre': globals.gameState['genre'],
      'name': globals.gameState['name'],
      'gameTitle': globals.gameState['title'],
      'code': globals.gameState['code'],
      'players': globals.gameState['players'],
      'creator': globals.gameState['creator']
    });

	}

	Widget _buildTextComposer() {
		return Container(
			decoration: BoxDecoration(color: Colors.white),
			child: IconTheme(
				data: IconThemeData(color: Theme.of(context).accentColor),
				child: Container(
					child: Row(children: <Widget>[
						Flexible(
							child: TextField(
								style: TextStyle(color: Colors.white, fontSize: 20.0, fontFamily: 'LondrinaSolid'),
								maxLines: null,
								keyboardType: TextInputType.multiline,
								controller: _textController,
								onSubmitted: _handleSubmitted,
								decoration: InputDecoration(
									contentPadding: const EdgeInsets.all(20.0),
									hintText: "Send a message",
									hintStyle: TextStyle(color: Colors.white)),
							),
						),
						Container(
							margin: EdgeInsets.only(left: 4.0),
							child: IconButton(
								icon: Icon(
									Icons.send,
									color: Colors.white,
									size: 30.0,
								),
								onPressed: () =>
									_handleSubmitted(_textController.text))),
					]),
					decoration:
						// Theme.of(context).platform == TargetPlatform.iOS
						// ?
						BoxDecoration(
							color: const Color(0xFF4C6296),
							border: Border(
								top: BorderSide(color: const Color(0xFF4C6296)))))
				// : null),
				));
	}

	void _handleSubmitted(String text) {
		var _gameId = globals.gameState['id'];
		_textController.clear();
		if (text.length > 0) {
			final DocumentReference document =
				Firestore.instance.collection('Games/$_gameId/Logs').document();
			document.setData(<String, dynamic>{
				'text': text,
				'dts': DateTime.now(),
				'profileUrl': globals.userState['profilePic'],
				'userName': globals.userState['name'],
				'userId': globals.userState['userId']
			});
		}
	}

	Widget _buildLabel(String text, DateTime dts) {
		return Row(
			// margin: const EdgeInsets.all(10.0),
			children: <Widget>[
				Expanded(
					child: Padding(
						padding: EdgeInsets.only(right: 15.0, top: 10.0),
						child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[Text(
							text,
							textAlign: TextAlign.right,
							style: TextStyle(
								color: Colors.white,
								letterSpacing: 0.5,
								fontSize: 14.0,
							),
						), Text(timeAgo(dts.toLocal()),
							style: TextStyle(
								color: Colors.white.withOpacity(.8),
								fontSize: 12.0,
							))
			])))]);
	}

	Widget _buildButton(
		String buttonImage, Function onPressed, String title, String subtitle) {
		// BuildContext context, DocumentSnapshot document) {
		return Container(
			decoration: BoxDecoration(color: const Color(0xFF4C6296)),
			child: Container(
				padding: EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0),
				child: Row(children: <Widget>[
					Expanded(
						child: Column(
							children: <Widget>[
								Padding(
									padding: EdgeInsets.all(5.0),
									child: RaisedButton(
										elevation: 4.0,
										highlightElevation: 50.0,
										padding: EdgeInsets.all(10.0),
										// onPressed: null,
										onPressed: onPressed,
										color: const Color(0xFF00b0ff),
										shape: RoundedRectangleBorder(
											borderRadius: new BorderRadius.circular(40.0)),
										child: Row(
											children: <Widget>[
												CircleAvatar(
													backgroundImage: NetworkImage(buttonImage)),
												Expanded(
													child: Padding(
														padding: EdgeInsets.only(left: 10.0),
														child: Column(
															crossAxisAlignment:
																CrossAxisAlignment.start,
															children: <Widget>[
																Text(title,
																	style: TextStyle(
																		fontSize: 22.0,
																		color: Colors.white,
																		fontWeight: FontWeight.w800,
																	)),
																Text(
																	subtitle,
																	style: TextStyle(
																		color: Colors.white,
																		// fontWeight: FontWeight.w800,
																		letterSpacing: 0.5,
																		fontSize: 14.0,
																	),
																)
															])))
											],
										))),
							],
						),
					),
				])));
	}
}

class ChatMessage {
	ChatMessage(
		{this.type,
		this.userId,
		this.userName,
		this.text,
		this.profileUrl,
		this.dts,
			this.reactions,
      this.title});
	final String type;
	final String userId;
	final String text;
	final String profileUrl;
	final String userName;
	final String title;
	final DateTime dts;
		final Map reactions;

}

class ChatMessageListItem extends StatelessWidget {
	ChatMessageListItem(this.message);

	final ChatMessage message;

	Widget build(BuildContext context) {
		var chatItem;
		if (message.userId != globals.userState['userId']) {
			chatItem = Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Expanded(
						child: Column(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: [
							Bubble(
								message: message.text,
								time: timeAgo(message.dts.toLocal()),
								delivered: true,
								isMe: true,
								type: message.type,
									reactions: message.reactions,
                title: message.title),
						],
					)),
					Container(
						margin: const EdgeInsets.only(left: 8.0),
						decoration: BoxDecoration(
							boxShadow: [
								BoxShadow(
									blurRadius: 10.0,
									spreadRadius: 1.0,
									offset: Offset(0.0, 7.0),
									color: Colors.black.withOpacity(.2))
							],
						),
						child:
							CircleAvatar(backgroundImage: NetworkImage(message.profileUrl)),
					),
				],
			);
		} else {
			chatItem = Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						margin: const EdgeInsets.only(right: 8.0),
						decoration: BoxDecoration(
							boxShadow: [
								BoxShadow(
									blurRadius: 10.0,
									spreadRadius: 1.0,
									offset: Offset(0.0, 7.0),
									color: Colors.black.withOpacity(.2))
							],
						),
						child:
							CircleAvatar(backgroundImage: NetworkImage(message.profileUrl)),
					),
					Flexible(
						child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Bubble(
								message: message.text,
								time: timeAgo(message.dts.toLocal()),
								delivered: true,
								isMe: false,
									userName: message.userName,
								type: message.type,
									reactions: message.reactions,
                  title: message.title),
						],
					)),
				],
			);
		}
		return Container(
			margin: const EdgeInsets.only(
				left: 10.0, right: 10.0, top: 5.0, bottom: 5.0),
			child: chatItem);
	}
}

class Bubble extends StatelessWidget {
	Bubble({this.message, this.time, this.delivered, this.isMe, this.type, this.userName, this.reactions, this.title});

	final String message, time, type, userName, title;
	final delivered, isMe;
		final Map reactions;

	@override
	Widget build(BuildContext context) {
		var bg = Colors.white.withOpacity(.2);
		if (type == 'characterAction') {
			bg = const Color(0xFFFFFFFF);
		} else if (type == 'win') {
			bg = const Color(0xBB9DEB0F);
		} else if (type == 'fail') {
			bg = const Color(0xBBFF694F);
		} else if (type == 'answer') {
			bg = const Color(0xFF9DEB0F);
		}
		final fontColor = type == 'characterAction'
			? Colors.black
			: Colors.white;
		final align = isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end;
		// final icon = delivered ? Icons.done_all : Icons.done;
		final radius = isMe
			? BorderRadius.only(
				topLeft: Radius.circular(20.0),
				bottomLeft: Radius.circular(20.0),
				bottomRight: Radius.circular(20.0),
				)
			: BorderRadius.only(
				topRight: Radius.circular(20.0),
				bottomLeft: Radius.circular(20.0),
				bottomRight: Radius.circular(20.0),
				);
		return Column(
			crossAxisAlignment: align,
			children: <Widget>[
				Container(
					foregroundDecoration: type == 'guess'
						? BoxDecoration(color: Colors.black, borderRadius: radius)
						: null,
					margin: const EdgeInsets.all(3.0),
					padding: const EdgeInsets.all(8.0),
					decoration: BoxDecoration(
						boxShadow: [
							BoxShadow(
								blurRadius: 10.0,
								spreadRadius: 1.0,
								offset: Offset(0.0, 10.0),
								color: Colors.black.withOpacity(.2))
						],
						color: bg,
						borderRadius: radius,
					),
					child: Stack(
						children: <Widget>[
							type == 'characterAction' || type == 'difficulty'
								? Positioned(
									top: 0.0,
									right: isMe == true ? 0.0 : null,
									left: isMe != true ? 0.0 : null,
									child: Text(title,
										style: TextStyle(
											fontSize: 14.0,
											color: fontColor,
											fontWeight: FontWeight.w600)),
									)
								: Container(width: 0.0),
							Padding(
								padding: type != null
									? EdgeInsets.only(top: 18.0, bottom: reactions != null ? 28.0 : 10.0)
									: EdgeInsets.only(bottom: reactions != null ? 28.0 : 10.0),
								child: Text(message,
									style: TextStyle(fontSize: 19.0, color: fontColor),
									textAlign: isMe == true ? TextAlign.right : TextAlign.left),
							),
							Positioned(
								bottom: 0.0,
								right: isMe == true ? 0.0 : null,
								left: isMe != true ? 0.0 : null,
								child: 
									reactions == null ? Container() : _buildReactionsIcons(reactions, type)
							)
						],
					),
				)
			],
		);
	}

		Widget _buildReactionsIcons(Map reactions, String type){
			List<Widget> reactionsListTiles = [];

			for(var key in reactions.keys){
				reactionsListTiles.add(Container(child: Image.asset('assets/images/reaction-' + key + '.png'), height: 30.0));
				reactionsListTiles.add(Padding(padding: EdgeInsets.only(right: 10.0, left: 0.0, top: 9.0), child: Text("${reactions[key]}", style: TextStyle(color: type != null ? Colors.black : Colors.white, fontWeight: FontWeight.w400, fontSize: 10.0))));
					// ListTile(
					// // leading: Container(child: Image.asset('assets/images/reaction-' + key + '.png'), height: 20.0),
					// title: Text("${reactions[key]}",
					// style: TextStyle(
					// color: Colors.black, fontWeight: FontWeight.w800)),
					// // subtitle: Text(game['name'],
					// // style: TextStyle(
					// // color: Colors.white, fontWeight: FontWeight.w100)),
					// ));
			}
			return Container(height: 20.0, child: Row(children: reactionsListTiles));
		}
}

// Widget _buildPeggFriendBox(BuildContext context, DocumentSnapshot document) {
// return Container(
// decoration: BoxDecoration(color: const Color(0xFF4C6296)),
// child: Container(
// // margin: const EdgeInsets.only(
// // bottom: 10.0, left: 10.0, right: 10.0, top: 10.0),
// // decoration: BoxDecoration(
// // color: const Color(0x22FFFFFF),
// // borderRadius: BorderRadius.all(Radius.circular(50.0))),
// // foregroundDecoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.all(Radius.circular(50.0))),
// padding: EdgeInsets.all(10.0),
// child: Row(children: <Widget>[
// Expanded(
// child: Column(
// children: <Widget>[
// // Text(
// // "Your Turn!",
// // textAlign: TextAlign.left,
// // style: TextStyle(
// // color: Colors.white,
// // fontWeight: FontWeight.w800,
// // letterSpacing: 0.5,
// // fontSize: 18.0,
// // ),
// // ),
// Padding(
// padding: EdgeInsets.all(5.0),
// child: RaisedButton(
// padding: EdgeInsets.all(10.0),
// // padding: EdgeInsets.symmetric(
// // horizontal: 60.0, vertical: 20.0),
// onPressed: () => Application.router.navigateTo(
// context,
// 'peggFriend?answerId=' +
// document['turn']['answerId'],
// transition: TransitionType.fadeIn),
// color: const Color(0xFF00b0ff),
// shape: RoundedRectangleBorder(
// borderRadius: new BorderRadius.circular(40.0)),
// child: Row(
// children: <Widget>[
// CircleAvatar(
// backgroundImage: NetworkImage(
// document['turn']['peggeeProfileUrl'])),
// Expanded(
// child: Padding(
// padding: EdgeInsets.only(left: 10.0),
// child: Text(
// "Pegg " +
// document['turn']['peggeeName'],
// style: TextStyle(
// fontSize: 22.0,
// color: Colors.white,
// fontWeight: FontWeight.w800,
// ))))
// ],
// ))),
// // Text(
// // "Guess which answer " +
// // document['turn']['peggeeName'] +
// // " picked.",
// // style: TextStyle(
// // color: Colors.white,
// // // fontWeight: FontWeight.w800,
// // letterSpacing: 0.5,
// // fontSize: 12.0,
// // ),
// // )
// ],
// ),
// ),
// // Container(
// // width: 100.0,
// // height: 100.0,
// // decoration: BoxDecoration(
// // // color: Colors.black,
// // image: DecorationImage(
// // image: NetworkImage(document['turn']['peggeeProfileUrl']),
// // // fit: BoxFit.cover,
// // ),
// // ),
// // ),
// ])));
// }

// Widget _buildPeggeeWaitingBox(
// BuildContext context, DocumentSnapshot document) {
// return Container(
// decoration: BoxDecoration(color: const Color(0xFF4C6296)),
// child: Container(
// margin: const EdgeInsets.only(
// bottom: 10.0, left: 10.0, right: 10.0, top: 10.0),
// decoration: BoxDecoration(
// color: const Color(0x22FFFFFF),
// borderRadius: BorderRadius.all(Radius.circular(50.0))),
// // foregroundDecoration: BoxDecoration(color: const Color(0xFF000000), borderRadius: BorderRadius.all(Radius.circular(50.0))),
// padding: EdgeInsets.all(10.0),
// child: Row(children: <Widget>[
// Container(
// width: 70.0,
// height: 70.0,
// decoration: BoxDecoration(
// // color: Colors.black,
// borderRadius: BorderRadius.all(Radius.circular(50.0)),
// image: DecorationImage(
// image: NetworkImage(document['turn']['peggeeProfileUrl']),
// // fit: BoxFit.cover,
// ),
// ),
// ),
// Expanded(
// child: Column(
// children: <Widget>[
// Text(
// "Waiting on...",
// textAlign: TextAlign.left,
// style: TextStyle(
// color: Colors.white,
// fontWeight: FontWeight.w800,
// letterSpacing: 0.5,
// fontSize: 22.0,
// ),
// ),
// Text(
// "your friends to pegg you.",
// style: TextStyle(
// color: Colors.white,
// // fontWeight: FontWeight.w800,
// letterSpacing: 0.5,
// fontSize: 14.0,
// ),
// ),
// ],
// ),
// ),
// ])));
// }

// Widget _buildPeggerWaitingBox(
// BuildContext context, DocumentSnapshot document) {
// return Container(
// margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
// color: const Color(0xFF00B0FF),
// child: Row(children: <Widget>[
// Expanded(
// child: Column(
// children: <Widget>[
// Text(
// "Waiting on...",
// textAlign: TextAlign.left,
// style: TextStyle(
// color: Colors.white,
// fontWeight: FontWeight.w800,
// letterSpacing: 0.5,
// fontSize: 22.0,
// ),
// ),
// Text(
// "your friends to pegg " +
// document['turn']['peggeeName'] +
// ".",
// style: TextStyle(
// color: Colors.white,
// // fontWeight: FontWeight.w800,
// letterSpacing: 0.5,
// fontSize: 14.0,
// ),
// ),
// //TODO: NUDGE BUTTON
// // Padding(
// // padding: EdgeInsets.all(10.0),
// // child: FlatButton(
// // key: null,
// // onPressed: () => Application.router.navigateTo(context,
// // 'peggFriend?answerId=' + document['answerId'],
// // transition: TransitionType.fadeIn),
// // color: const Color(0xFF00B0FF),
// // child: Text("Pegg " + document['peggeeName'],
// // style: TextStyle(
// // fontSize: 16.0,
// // color: Colors.white,
// // fontWeight: FontWeight.w800,
// // )))),
// ],
// ),
// ),
// Container(
// width: 70.0,
// height: 70.0,
// decoration: BoxDecoration(
// // color: Colors.black,
// image: DecorationImage(
// image: NetworkImage(document['turn']['peggeeProfileUrl']),
// // fit: BoxFit.cover,
// ),
// ),
// ),
// ]));
// }

// Widget _buildInviteFriendsBox(
// BuildContext context, DocumentSnapshot document) {
// return Row(children: <Widget>[
// Expanded(
// child: Container(
// height: 70.0,
// decoration: BoxDecoration(
// color: Color(0xFF00b0ff),
// boxShadow: <BoxShadow>[
// BoxShadow(
// color: Colors.black12,
// blurRadius: 10.0,
// offset: Offset(0.0, -10.0),
// ),
// ],
// ),
// child: RaisedButton.icon(
// icon: const Icon(Icons.add, size: 25.0, color: Colors.white),
// shape: new RoundedRectangleBorder(
// borderRadius: new BorderRadius.circular(0.0)),
// onPressed: () => Application.router.navigateTo(
// context, 'inviteFriends?code=' + document['code'],
// transition: TransitionType.fadeIn),
// color: const Color(0xFF00B0FF),
// label: Text("Invite Friends", //+ document['peggeeName'],
// style: TextStyle(
// fontSize: 25.0,
// color: Colors.white,
// fontWeight: FontWeight.w800,
// )))))
// ]);
// }

// Widget _buildJoinButton() {
// return Container(
// child: Row(children: <Widget>[
// Expanded(
// child: GestureDetector(
// child: Container(
// height: 60.0,
// margin: EdgeInsets.only(bottom: 10.0, left: 10.0, right: 10.0),
// padding: EdgeInsets.only(top: 15.0),
// decoration: BoxDecoration(
// color: const Color(0xFF00B0FF),
// borderRadius: BorderRadius.all(Radius.circular(50.0))),
// child: Text(
// "Request to Join",
// textAlign: TextAlign.center,
// style: TextStyle(
// fontSize: 22.0,
// fontWeight: FontWeight.w800,
// color: Colors.white),
// )),
// onTap: _handleJoinButtonPressed,
// ))
// ]));
// }
