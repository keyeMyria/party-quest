import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'application.dart';
import 'package:fluro/fluro.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_view.dart';
import 'account_drawer.dart';

class HomePage extends StatefulWidget {
  static String tag = 'home-page';

  @override
  createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();
  bool _isComposing = false;
  CollectionReference get logs => Firestore.instance.collection('Logs');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: AccountDrawer(), // left side
        // endDrawer: CharactersDrawer(), // right side
        appBar: AppBar(
          title: Text('Pegg Party'),
          elevation: -1.0,
          // leading: IconButton(
          //     icon: Icon(Icons.explore),
          //     onPressed: _scaffoldKey.currentState.openDrawer
          //     ),
          actions: <Widget>[
            IconButton(
                icon: Icon(Icons.info_outline),
                tooltip: 'Info about this Quest.',
                onPressed: _openInfoView)
          ],
        ),
        body: Column(children: <Widget>[
          ChatView(),
          Divider(height: 1.0),
          new Container(
              decoration: new BoxDecoration(color: Theme.of(context).cardColor),
              child: _buildTextComposer())
        ]));
  }

  void _openInfoView() {
    Application.router
        .navigateTo(context, 'info', transition: TransitionType.native);
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).accentColor),
      child: Container(
          margin: const EdgeInsets.only(left: 20.0, right: 10.0, bottom: 10.0),
          child: Row(children: <Widget>[
            Flexible(
              child: TextField(
                maxLines: null,
                keyboardType: TextInputType.multiline,
                controller: _textController,
                onChanged: _handleMessageChanged,
                onSubmitted: _handleSubmitted,
                decoration:
                    InputDecoration.collapsed(hintText: "Send a message"),
              ),
            ),
            Container(
                margin: EdgeInsets.only(left: 4.0),
                child: Theme.of(context).platform == TargetPlatform.iOS
                    ? CupertinoButton(
                        child: Text("Send"),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )
                    : IconButton(
                        icon: Icon(Icons.send),
                        onPressed: _isComposing
                            ? () => _handleSubmitted(_textController.text)
                            : null,
                      )),
          ]),
          decoration: Theme.of(context).platform == TargetPlatform.iOS
              ? BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200])))
              : null),
    );
  }

  void _handleMessageChanged(String text) {
    setState(() {
      _isComposing = text.length > 0;
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    // setState(() {
    //   _isComposing = false;
    // });
    // await _ensureLoggedIn();
    if (text.length > 0) {
      final DocumentReference document = logs.document();
      document.setData(<String, dynamic>{
        'text': text,
        'dts': DateTime.now(),
        'profileUrl':
            'https://lh3.googleusercontent.com/-DsBDODH3QXk/AAAAAAAAAAI/AAAAAAAAAAA/AAnnY7q3aaQQkR02rDq6Csf-UX4bg1c_-A/s192-c-mo/photo.jpg',
        'userName': 'Augustin Bralley'
      });
    }
  }
}
