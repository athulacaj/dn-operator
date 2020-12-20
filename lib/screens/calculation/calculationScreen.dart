import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyneedsserver/screens/orders/calculations/calculations.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

class CalculationScreen extends StatefulWidget {
  @override
  _CalculationScreenState createState() => _CalculationScreenState();
}

DateTime _lowerDate, _upperDate;
bool _showSpinner = false;

class _CalculationScreenState extends State<CalculationScreen> {
  @override
  void initState() {
    _lowerDate = DateTime.now();
    _upperDate = DateTime.now();
    _showSpinner = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ModalProgressHUD(
      inAsyncCall: _showSpinner,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Calculations'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Lower : '),
                      Material(
                        elevation: 4,
                        color: Colors.white,
                        child: GestureDetector(
                          onTap: () => _selectDate(context, _lowerDate, true),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "${_lowerDate.toLocal()}".split(' ')[0],
                              textAlign: TextAlign.center,
                            ),
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      Spacer(),
                      Text('upper : '),
                      Material(
                        elevation: 4,
                        color: Colors.white,
                        child: GestureDetector(
                          onTap: () => _selectDate(context, _upperDate, false),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Text(
                              "${_upperDate.toLocal()}".split(' ')[0],
                              textAlign: TextAlign.center,
                            ),
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  FlatButton(
                    child: Text(
                      ' View Bill ',
                      style: TextStyle(color: Colors.white),
                    ),
                    color: Colors.purple,
                    onPressed: () async {
                      _showSpinner = true;
                      setState(() {});
                      _upperDate = new DateTime(_upperDate.year,
                          _upperDate.month, _upperDate.day, 6, 30);
                      _lowerDate = new DateTime(_lowerDate.year,
                          _lowerDate.month, _lowerDate.day, 6, 30);
                      DateTime incrementDate = _lowerDate;
                      List<DateTime> dateRange = [];
                      while (incrementDate.millisecondsSinceEpoch <
                          _upperDate.millisecondsSinceEpoch) {
                        dateRange.add(incrementDate);
                        DateTime temp = incrementDate;
                        incrementDate = DateTime(
                            temp.year, temp.month, temp.day + 1, 6, 30);
                      }
                      dateRange.add(_upperDate);
                      List<DocumentSnapshot> dateRangeFirestoreData = [];
                      for (DateTime whichDay in dateRange) {
                        if (dateRange.length < 32) {
                          QuerySnapshot snap = await _firestore
                              .collection(
                                  'orders/byTime/${whichDay.toString().substring(0, 10)}')
                              .orderBy('time', descending: true)
                              .get();
                          List<DocumentSnapshot> snapshot = snap.docs;
                          dateRangeFirestoreData.addAll(snapshot);
                        }
                        print(dateRangeFirestoreData);
                        createBill(dateRangeFirestoreData, context);
                        _showSpinner = false;
                        setState(() {});
                      }
                    },
                  ),
                  SizedBox(height: 2),
                  billWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<Null> _selectDate(
      BuildContext context, DateTime _whichDay, bool isLower) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _whichDay,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime.now());
    print('$_whichDay $picked');
    if (picked != null && picked != _whichDay && isLower) _lowerDate = picked;
    if (picked != null && picked != _whichDay && !isLower) _upperDate = picked;
    setState(() {});
    // callSetStateWIthDelay();
  }
}

Widget billWidget = Text('No Data');

void createBill(
    List<DocumentSnapshot> dateRangeFirestoreData, BuildContext context) {
  Map calculatedResult = profitDetails(dateRangeFirestoreData);
  List<Map> filteredShops = calculatedResult['shops'];
  List unSupportedOrders = calculatedResult['unSupportedOrders'];
  billWidget = Material(
    color: Colors.white,
    elevation: 4,
    child: Container(
      padding: EdgeInsets.all(10),
      // height: MediaQuery.of(context).size.height - 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          unSupportedOrders.isNotEmpty
              ? Text('Not Supported: $unSupportedOrders')
              : Container(),
          Divider(),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 10000),
            child: ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: filteredShops.length,
              itemBuilder: (BuildContext context, int index) {
                Map shop = filteredShops[index];
                String shopName = filteredShops[index]['shopName'];
                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      SizedBox(
                        child: Text('${shop['shopName']} : '),
                        width: 150,
                      ),
                      Text('₹'),
                      SizedBox(
                        child: Text(
                          '${shop['total']}',
                          style: TextStyle(color: Colors.black),
                          textAlign: TextAlign.end,
                        ),
                        width: 50,
                      ),
                      Spacer(),
                      Text(
                        profitMap[shopName] != null
                            ? '₹${(shop['total'] * profitMap[shopName]) / 100}'
                            : '',
                        style: TextStyle(color: Colors.green),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                SizedBox(child: Text('Total Shops Fees :'), width: 150),
                Text('₹'),
                SizedBox(
                  child: Text(
                    '${calculatedResult['total']}',
                    style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.end,
                  ),
                  width: 50,
                ),
                Spacer(),
                Text(
                  '₹${calculatedResult['profit']}',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                SizedBox(child: Text('Total Delivery Fees :'), width: 150),
                Text('₹'),
                SizedBox(
                  child: Text(
                    '${calculatedResult['deliveryFee']}',
                    style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.end,
                  ),
                  width: 50,
                ),
              ],
            ),
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Row(
              children: [
                SizedBox(child: Text('Total :'), width: 150),
                Text('₹'),
                SizedBox(
                  child: Text(
                    '${calculatedResult['deliveryFee'] + calculatedResult['total']}',
                    style: TextStyle(color: Colors.black),
                    textAlign: TextAlign.end,
                  ),
                  width: 50,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
            child: Material(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    Text(
                      'Total Profit => ${calculatedResult['profit']} + ${calculatedResult['deliveryFee']} =  ',
                    ),
                    Text(
                      '₹${calculatedResult['profit'] + calculatedResult['deliveryFee']}',
                      style: TextStyle(color: Colors.green),
                      textAlign: TextAlign.end,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          Divider(),
          // total cash onlin and offfline
          SizedBox(
            height: 150,
            child: Row(
              children: [
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text('Cash'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                            'online  :  ₹${calculatedResult['onlineCash']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                            'offline  :  ₹${calculatedResult['offlineCash']}'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                            'Total  :  ₹${calculatedResult['onlineCash'] + calculatedResult['offlineCash']}'),
                      ),
                    ],
                  ),
                  width: MediaQuery.of(context).size.width / 2 - 15,
                ),
                VerticalDivider(
                  width: 5,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text('Cash kept by boys'),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: calculatedResult['boyDataList']
                            .map<Widget>((Map boyData) => Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: new Text(
                                      '${boyData['name']}:   ₹${boyData['cashInHand']}'),
                                ))
                            .toList(),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 50),
        ],
      ),
      // decoration: BoxDecoration(
      //     color: Colors.white,
      //     border: Border.all(color: Colors.black)),
    ),
  );
}
