import 'package:chat/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:meteorify/meteorify.dart';

void main() async {
  try {
    await Meteor.connect('ws://192.168.88.248:3000/websocket');

    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.deepOrange),
      home: HomePage(),
    ));
  } catch (error) {
    print(error);
  }
}
