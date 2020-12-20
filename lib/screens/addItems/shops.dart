import 'package:flutter/material.dart';
import 'addItems.dart';

class ShopsIndex extends StatefulWidget {
  final Map allInfo;
  ShopsIndex({this.allInfo});
  @override
  _ShopsIndexState createState() => _ShopsIndexState();
}

class _ShopsIndexState extends State<ShopsIndex> {
  @override
  Widget build(BuildContext context) {
    List shops = widget.allInfo['shops'];
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 50),
          Expanded(
            child: ListView.builder(
              itemCount: shops.length,
              itemBuilder: (BuildContext context, int i) {
                return TextButton(
                  child: Text(shops[i]['name']),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AddItems(widget.allInfo, i)));
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
