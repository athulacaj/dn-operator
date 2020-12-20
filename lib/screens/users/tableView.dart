import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<List> showTableBottomSheet(
    BuildContext context, List<DocumentSnapshot> allAddress) {
  Table table = Table(allAddress: allAddress);
  return showModalBottomSheet<List>(
    isScrollControlled: true,
    context: context,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10.0),
    ),
    builder: (BuildContext context) {
      int selectedDeliveryBoy = -1;
      int selectedShop = -1;
      return StatefulBuilder(builder: (context, StateSetter setState) {
        Size size = MediaQuery.of(context).size;
        return Container(
          height: size.height - 100,
          // color: Colors.white,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 5),
              SizedBox(height: 15),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('total ${table.buildTable()['places'].length}'),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView.builder(
                    itemCount: table.buildTable()['places'].length,
                    itemBuilder: (BuildContext context, int i) {
                      Map placeMap = table.buildTable();
                      String place = placeMap['places'][i];
                      return Container(
                        padding: EdgeInsets.all(6),
                        child: Row(
                          children: [
                            Text('${i + 1} ) $place'),
                            Spacer(),
                            Text('${placeMap[place]}'),
                            SizedBox(width: 15),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      });
    },
  );
}

class Table {
  List<DocumentSnapshot> allAddress = [];
  Table({this.allAddress});
  List placesList = [];
  Map placesMap = {};
  Map buildTable() {
    placesList = [];
    placesMap = {};
    for (DocumentSnapshot snap in allAddress) {
      String p = snap.data()['address']['street'];
      String place = p.split(' ')[0].toLowerCase().split(',')[0];
      if (placesMap[place] == null) {
        placesMap[place] = 1;
        placesList.add(place);
      } else {
        placesMap[place] = placesMap[place] + 1;
      }
    }
    placesList.sort();
    placesMap['places'] = placesList;
    Iterable placesSplit = placesList.getRange(150, 205);
    placesSplit.join(', ');
    List newList = [];
    for (String place in placesSplit.toList()) {
      newList.add("'$place'");
    }
    print(newList);
    return placesMap;
  }
}
