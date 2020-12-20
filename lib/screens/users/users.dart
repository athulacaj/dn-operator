import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tableView.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

List<DocumentSnapshot> allAddress = [];

class Users extends StatefulWidget {
  @override
  _UsersState createState() => _UsersState();
}

class _UsersState extends State<Users> {
  @override
  Widget build(BuildContext context) {
    allAddress = [];
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StreamBuilder(
              stream: _firestore.collectionGroup('address').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasData == false) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                List<QueryDocumentSnapshot> _allData = snapshot.data.documents;
                allAddress = _allData;

                print(snapshot.data);
                return Expanded(
                  child: ListView.builder(
                    itemCount: _allData.length,
                    itemBuilder: (BuildContext context, int i) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text('${i + 1} ) '),
                                  SizedBox(width: 10),
                                  Text('${_allData[i]['name']}'),
                                  Spacer(),
                                  Text('${_allData[i]['phone']}'),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(' '),
                                  SizedBox(width: 16),
                                  Text(
                                      '${_allData[i]['address']['houseName']}'),
                                  Spacer(),
                                  Text('${_allData[i]['address']['street']}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }),
          Container(
            height: 50,
            child: IconButton(
              icon: Icon(Icons.place),
              onPressed: () {
                showTableBottomSheet(context, allAddress);
              },
            ),
          )
        ],
      ),
    );
  }
}
