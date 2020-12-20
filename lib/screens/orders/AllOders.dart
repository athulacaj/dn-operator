import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dailyneedsserver/screens/individualOrders/individualOrders.dart';
import 'package:dailyneedsserver/screens/individualOrders/timeComparison.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import 'calculations/calculations.dart';
import 'dataBase.dart';
import 'functions.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;
List _orders = [];
List<DocumentSnapshot> deliveryBoys = [];
List<DocumentSnapshot> shops = [];
List<DocumentSnapshot> _allOrders;
List<Map> _allOrdersFiltered = [];
var _whichDay;
String _whichType = 'all';
List whichTypeList = ['all', 'ordered', 'canceled', 'delivered'];
int selectedIndex = -1;
bool _showSpinner = false;
List<Map> filteredShops = [];
List unSupportedOrders = [];
Map calculatedResult;
bool showBill = false;

class AllOrders extends StatefulWidget {
  @override
  _AllOrdersState createState() => _AllOrdersState();
}

class _AllOrdersState extends State<AllOrders> {
  @override
  void initState() {
    _showSpinner = false;
    _whichType = 'all';
    showBill = false;
    selectedIndex = -1;
    _whichDay = DateTime.now();
    getDeliverBoysList();
    getShopsList();
    super.initState();
  }

  void getDeliverBoysList() async {
    QuerySnapshot snap =
        await _firestore.collection('admin/admin/deliveryBoys').get();
    deliveryBoys = snap.docs;
  }

  void getShopsList() async {
    QuerySnapshot snap = await _firestore.collection('admin/admin/shops').get();
    shops = snap.docs;
  }

  Future<Null> _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: _whichDay,
        firstDate: DateTime(2015, 8),
        lastDate: DateTime.now());
    if (picked != null && picked != _whichDay) _whichDay = picked;
    setState(() {});
    callSetStateWIthDelay();
  }

  void callSetStateWIthDelay() async {
    await Future.delayed(Duration(milliseconds: 400));
    setState(() {});
  }

  List filterOrder(String whichType, List<DocumentSnapshot> allOrders) {
    List<Map> _allOrders = [];
    int i = 0;
    for (DocumentSnapshot dataMap in allOrders) {
      final Map<String, dynamic> toAdd = dataMap.data();
      toAdd['refNo'] = allOrders.length - i;
      toAdd['docID'] = dataMap.id;
      toAdd['reference'] = dataMap.reference;
      _allOrders.add(toAdd);
      i++;
    }
    if (whichType == 'all') {
      return _allOrders;
    }
    return _allOrders.where((value) => value['status'] == whichType).toList();
  }

  @override
  Widget build(BuildContext context) {
    filteredShops = [];

    return ModalProgressHUD(
      inAsyncCall: _showSpinner,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: Text('All orders'),
          actions: <Widget>[
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.all(8),
                child: Text(
                  "${_whichDay.toLocal()}".split(' ')[0],
                  textAlign: TextAlign.center,
                ),
                alignment: Alignment.center,
                height: double.infinity,
              ),
            ),
          ],
        ),
        body: StreamBuilder(
          stream: _firestore
              .collection(
                  'orders/byTime/${_whichDay.toString().substring(0, 10)}')
              .orderBy('time', descending: true)
              .snapshots(),
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
            _allOrders = snapshot.data.documents;
            _allOrdersFiltered = filterOrder(_whichType, _allOrders);
            calculatedResult = profitDetails(_allOrders);
            filteredShops = calculatedResult['shops'];
            unSupportedOrders = calculatedResult['unSupportedOrders'];

            print(filteredShops);
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Container(
                      height: 50,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border(
                              bottom: BorderSide(color: Colors.black26))),
                      child: ListView.builder(
                        padding: EdgeInsets.all(0),
                        scrollDirection: Axis.horizontal,
                        itemCount: whichTypeList.length,
                        itemBuilder: (context, i) {
                          return FlatButton(
                            onPressed: () {
                              setState(() {
                                columWidget = [];
                                _whichType = whichTypeList[i];
                              });
                            },
                            child: Container(
                              height: 50,
                              // width: 50,
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Container(
                                    child: Text(
                                        odersCountByStatus(
                                                whichTypeList[i], _allOrders)
                                            .toString(),
                                        style: TextStyle(
                                            color: Colors.white, fontSize: 10)),
                                    decoration: BoxDecoration(
                                        color: _whichType == whichTypeList[i]
                                            ? Color(0xfff25d9c)
                                            : Colors.lightBlueAccent,
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(4))),
                                    width: 20,
                                    height: 15,
                                    alignment: Alignment.center,
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${whichTypeList[i]}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: _whichType == whichTypeList[i]
                                            ? Color(0xfff25d9c)
                                            : Colors.black),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      )),
                  Expanded(
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      itemCount: _allOrdersFiltered.length,
                      itemBuilder: (context, index) {
                        String status = _allOrdersFiltered[index]['status'];

                        var orderedTime = _allOrdersFiltered[index]['time'];
                        var fcmId = _allOrdersFiltered[index]['fcmId'];
                        Timestamp deliveredTime =
                            _allOrdersFiltered[index]['deliveredTime'] ?? null;
                        return _whichType == status || _whichType == 'all'
                            ? GestureDetector(
                                onLongPress: () async {
                                  selectedIndex = index;
                                  setState(() {});
                                  List data = await showBottomSheet();
                                  int selectedDeliveryBoy = data[0];
                                  int selectedShops = data[1];
                                  switchDeliveryBoyAndShop(
                                      _allOrdersFiltered[index],
                                      '${_whichDay.toString().substring(0, 10)}',
                                      deliveryBoys,
                                      0,
                                      fcmId,
                                      shops,
                                      selectedDeliveryBoy,
                                      selectedShops);

                                  // _showSpinner = true;
                                  setState(() {});
                                },
                                child: ExtractedAllOrdersContainer(
                                  index: index,
                                  status: status,
                                  orderedTime: orderedTime,
                                  deliveredTime: deliveredTime,
                                  totalOrders: _allOrdersFiltered.length,
                                  orderDetails: _allOrdersFiltered[index],
                                ),
                              )
                            : Container();
                      },
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          childAspectRatio: .75),
                    ),
                  ),
                  showBill
                      ? Material(
                          color: Colors.white,
                          elevation: 4,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            height: MediaQuery.of(context).size.height / 1.6,
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: 20),
                                  unSupportedOrders.isNotEmpty
                                      ? Text(
                                          'Not Supported: $unSupportedOrders')
                                      : Container(),
                                  Divider(),
                                  ConstrainedBox(
                                    constraints:
                                        BoxConstraints(maxHeight: 10000),
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: filteredShops.length,
                                      itemBuilder:
                                          (BuildContext context, int index) {
                                        Map shop = filteredShops[index];
                                        String shopName =
                                            filteredShops[index]['shopName'];
                                        return Padding(
                                          padding: const EdgeInsets.all(4.0),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                child: Text(
                                                    '${shop['shopName']} : '),
                                                width: 150,
                                              ),
                                              Text('₹'),
                                              SizedBox(
                                                child: Text(
                                                  '${shop['total']}',
                                                  style: TextStyle(
                                                      color: Colors.black),
                                                  textAlign: TextAlign.end,
                                                ),
                                                width: 40,
                                              ),
                                              Spacer(),
                                              Text(
                                                profitMap[shopName] != null
                                                    ? '₹${(shop['total'] * profitMap[shopName]) / 100}'
                                                    : '',
                                                style: TextStyle(
                                                    color: Colors.green),
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
                                        SizedBox(
                                            child: Text('Total Shops Fees :'),
                                            width: 150),
                                        Text('₹'),
                                        SizedBox(
                                          child: Text(
                                            '${calculatedResult['total']}',
                                            style:
                                                TextStyle(color: Colors.black),
                                            textAlign: TextAlign.end,
                                          ),
                                          width: 40,
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
                                        SizedBox(
                                            child:
                                                Text('Total Delivery Fees :'),
                                            width: 150),
                                        Text('₹'),
                                        SizedBox(
                                          child: Text(
                                            '${calculatedResult['deliveryFee']}',
                                            style:
                                                TextStyle(color: Colors.black),
                                            textAlign: TextAlign.end,
                                          ),
                                          width: 40,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(),
                                  Padding(
                                    padding: const EdgeInsets.all(4.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                            child: Text('Total :'), width: 150),
                                        Text('₹'),
                                        SizedBox(
                                          child: Text(
                                            '${calculatedResult['deliveryFee'] + calculatedResult['total']}',
                                            style:
                                                TextStyle(color: Colors.black),
                                            textAlign: TextAlign.end,
                                          ),
                                          width: 40,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 0, vertical: 6),
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
                                              style: TextStyle(
                                                  color: Colors.green),
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text('Cash'),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                    'online  :  ₹${calculatedResult['onlineCash']}'),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                    'offline  :  ₹${calculatedResult['offlineCash']}'),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.all(4.0),
                                                child: Text(
                                                    'Total  :  ₹${calculatedResult['onlineCash'] + calculatedResult['offlineCash']}'),
                                              ),
                                            ],
                                          ),
                                          width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  2 -
                                              15,
                                        ),
                                        VerticalDivider(
                                          width: 5,
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.all(4.0),
                                              child: Text('Cash kept by boys'),
                                            ),
                                            Expanded(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: calculatedResult[
                                                        'boyDataList']
                                                    .map<Widget>(
                                                        (Map boyData) =>
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(4.0),
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
                            ),
                            // decoration: BoxDecoration(
                            //     color: Colors.white,
                            //     border: Border.all(color: Colors.black)),
                          ),
                        )
                      : Container(),
                ],
              ),
            );
          },
        ),
        floatingActionButton: selectedIndex == -1
            ? FloatingActionButton(
                child: Icon(Icons.book_online_outlined),
                onPressed: () {
                  showBill = !showBill;
                  setState(() {});
                },
              )
            : FloatingActionButton(
                child: Icon(Icons.cancel),
                onPressed: () {
                  selectedIndex = -1;
                  setState(() {});
                  selectedIndex = -1;
                },
              ),
      ),
    );
  }

  Future<List> showBottomSheet() {
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
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        child: Text(
                          ' ${_allOrders.length - selectedIndex}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white),
                        ),
                        height: 40,
                        width: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius:
                                BorderRadius.all(Radius.circular(20))),
                      ),
                      Spacer(),
                      Material(
                        elevation: 3,
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Text(
                            '${_allOrdersFiltered[selectedIndex]['email']}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      SizedBox(width: 5),
                    ],
                  ),
                ),
                Divider(),
                SizedBox(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          onTap: (index) {
                            // Tab index when user select it, it start from zero
                          },
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(text: 'Boys'),
                            Tab(text: 'Shops'),
                          ],
                        ),
                        SizedBox(
                          height: size.height - 294,
                          child: TabBarView(children: [
                            ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 10000),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    padding: EdgeInsets.all(8),
                                    itemCount: deliveryBoys.length,
                                    itemBuilder: (context, i) {
                                      return Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            selectedDeliveryBoy = i;
                                            setState(() {});
                                          },
                                          child: Material(
                                            elevation: 4,
                                            color: selectedDeliveryBoy == i
                                                ? Colors.green.withOpacity(0.6)
                                                : Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 20,
                                                  top: 3,
                                                  bottom: 3),
                                              child: Row(
                                                children: [
                                                  Text(
                                                      '${deliveryBoys[i].data()['name']}'),
                                                  Spacer(),
                                                  IconButton(
                                                      icon: Icon(
                                                        Icons.phone,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () =>
                                                          launchCaller(
                                                              deliveryBoys[i]
                                                                      .data()[
                                                                  'phone'])),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    })),
                            ConstrainedBox(
                                constraints: BoxConstraints(maxHeight: 10000),
                                child: ListView.builder(
                                    shrinkWrap: true,
                                    physics: ClampingScrollPhysics(),
                                    padding: EdgeInsets.all(8),
                                    itemCount: shops.length,
                                    itemBuilder: (context, i) {
                                      return Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: GestureDetector(
                                          onTap: () {
                                            selectedShop = i;
                                            setState(() {});
                                          },
                                          child: Material(
                                            elevation: 4,
                                            color: selectedShop == i
                                                ? Colors.green.withOpacity(0.6)
                                                : Colors.white,
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 16,
                                                  right: 20,
                                                  top: 3,
                                                  bottom: 3),
                                              child: Row(
                                                children: [
                                                  Text(
                                                      '${shops[i].data()['name']}'),
                                                  Spacer(),
                                                  IconButton(
                                                      icon: Icon(
                                                        Icons.phone,
                                                        color: Colors.blue,
                                                      ),
                                                      onPressed: () =>
                                                          launchCaller(
                                                              shops[i].data()[
                                                                  'phone'])),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    })),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: Material(
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                    child: InkWell(
                      onTap: () {
                        // print(selectedDeliveryBoy);
                        Navigator.pop(
                            context, [selectedDeliveryBoy, selectedShop]);
                      },
                      borderRadius: BorderRadius.all(Radius.circular(6)),
                      child: Container(
                        height: 50,
                        alignment: Alignment.center,
                        width: MediaQuery.of(context).size.width,
                        child: Text('Switch',
                            style: TextStyle(color: Colors.purple)),
                        decoration: BoxDecoration(
                            // color: Colors.purple,
                            border: Border.all(color: Colors.purple),
                            borderRadius: BorderRadius.all(Radius.circular(6))),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          );
        });
      },
    );
  }
}

int odersCountByStatus(String status, List allOrders) {
  int count = 0;
  if (status == 'all') {
    return count = allOrders.length;
  }
  for (DocumentSnapshot orders in allOrders) {
    String ostatus = orders.data()['status'];
    if (status == ostatus) {
      count++;
    }
  }

  return count;
}

class ExtractedAllOrdersContainer extends StatelessWidget {
  final int index;
  final String status;
  final orderedTime;
  final deliveredTime;
  final int totalOrders;
  final Map orderDetails;
  ExtractedAllOrdersContainer(
      {this.index,
      this.status,
      this.orderedTime,
      this.deliveredTime,
      this.orderDetails,
      this.totalOrders});
  @override
  Widget build(BuildContext context) {
    int _nowInMS = DateTime.now().millisecondsSinceEpoch;
    Map boyDetails = orderDetails['boyDetails'];
    Map shopDetails = orderDetails['shopDetails'];
    int _total = calcTotalMoney(orderDetails, orderDetails['refNo']);
    bool shopViewed = orderDetails['shopViewed'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => IndividualOrders(
                        email: '${_allOrders[index].data()['email']}',
                        orderedTimeFrmPrvsScreen: orderedTime,
                        orderNumber: orderDetails['refNo'],
                        byTimeId: '${_allOrders[index].id}',
                        totalFromPrvsScreen: _total,
                      )));
        },
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.all(Radius.circular(10)),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        width: 40,
                        color: status == 'ordered'
                            ? Colors.purple
                            : status == 'delivered'
                                ? status == 'shipped'
                                    ? Colors.orange
                                    : Colors.green
                                : status == 'canceled'
                                    ? Colors.grey
                                    : Colors.orange,
                        child: Text(
                          '${orderDetails['refNo']}',
                          style: TextStyle(color: Colors.white),
                        )),
                    SizedBox(width: 6),
                    Text(status,
                        style: TextStyle(
                            fontSize: 12,
                            color: status == 'ordered'
                                ? Colors.purple
                                : status == 'delivered'
                                    ? status == 'shipped'
                                        ? Colors.orange
                                        : Colors.green
                                    : status == 'canceled'
                                        ? Colors.grey
                                        : Colors.orange)),
                    Spacer(),
                    orderDetails['prepared'] == true
                        ? Icon(
                            Icons.check,
                            size: 25,
                            color: Colors.green,
                          )
                        : Container(),
                  ],
                ),
                Divider(),
                Text('${orderDetails['email']}'),
                SizedBox(height: 10),
                Text(
                  'Ordered: ${timeConvertor(_nowInMS - orderedTime.millisecondsSinceEpoch, orderedTime)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      fontSize: 11),
                ),
                SizedBox(height: 5),
                deliveredTime != null
                    ? Expanded(
                        child: Text(
                          'Delivered:${timeConvertor(_nowInMS - deliveredTime.millisecondsSinceEpoch, deliveredTime)}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                              fontSize: 11),
                        ),
                      )
                    : Container(),
                boyDetails != null
                    ? GestureDetector(
                        onTap: () {
                          launchCaller(boyDetails['phone']);
                        },
                        child: Material(
                          color: Colors.white,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Row(
                              children: [
                                Icon(Icons.directions_bike_outlined),
                                Text(
                                  ' ${boyDetails['name']}',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(),
                shopDetails != null
                    ? SizedBox(
                        height: 5,
                      )
                    : Container(),
                shopDetails != null
                    ? GestureDetector(
                        onTap: () {
                          launchCaller(shopDetails['phone']);
                        },
                        child: Material(
                          color: Colors.white,
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Row(
                              children: [
                                Icon(Icons.shop),
                                Text(
                                  ' ${shopDetails['name']}',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Spacer(),
                                shopViewed == true
                                    ? Icon(
                                        Icons.remove_red_eye_outlined,
                                        size: 20,
                                        color: Colors.green,
                                      )
                                    : Container()
                              ],
                            ),
                          ),
                        ),
                      )
                    : Container(),
                SizedBox(height: 5),
                Text('Total : $_total'),
              ],
            ),
            decoration: BoxDecoration(
                border: Border.all(
                    color: status == 'ordered'
                        ? Colors.purple
                        : status == 'delivered'
                            ? Colors.green
                            : status == 'canceled'
                                ? Colors.grey
                                : Colors.orange,
                    width: 1.5),
                color: selectedIndex == index ? Colors.yellow : Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(5))),
          ),
        ),
      ),
    );
  }
}
