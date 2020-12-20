import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dailyneedsserver/functions/sendFcm.dart';

FirebaseFirestore _firestore = FirebaseFirestore.instance;

Future<void> switchDeliveryBoyAndShop(
    Map data,
    String date,
    List<DocumentSnapshot> boyDetailsMap,
    int oderNo,
    String fcmId,
    List<DocumentSnapshot> shopDetailsMap,
    int sBoy,
    int sShop) async {
  var boyDetails;
  var shopDetails;
  if (sBoy != -1) {
    boyDetails = boyDetailsMap[sBoy].data();
  }
  if (sShop != -1) {
    shopDetails = shopDetailsMap[sShop].data();
  }

  WriteBatch batch = _firestore.batch();

  if (sBoy != -1 && sShop != -1) {
    batch.update(data['reference'], {
      'boyDetails': boyDetails,
      'refNo': data['refNo'],
      'shopDetails': shopDetails
    });
    await batch.commit();
  } else if (sBoy != -1) {
    batch.update(
        data['reference'], {'boyDetails': boyDetails, 'refNo': data['refNo']});
    await batch.commit();
  } else if (sShop != -1) {
    batch.update(data['reference'],
        {'shopDetails': shopDetails, 'refNo': data['refNo']});
    await batch.commit();
  }
  if (sBoy != -1) {
    sendAndRetrieveMessage(boyDetails['token'],
        'There is a new order ${boyDetails['name']}', 'New order');
    sendAndRetrieveMessage(fcmId, 'Your order is confirmed', 'Order Update');
  }
  if (sShop != -1) {
    sendAndRetrieveMessage(shopDetails['token'],
        'There is a new order ${shopDetails['name']}', 'New order');
  }
}

Future<void> switchShop(Map data, String date, DocumentSnapshot shopDetailsMap,
    int oderNo, String fcmId) async {
  var shopDetails = shopDetailsMap.data();
  // DocumentReference firstRef =
  //     _firestore.collection('orders/byTime/$date').doc('$docId');
  // DocumentReference secondRef = _firestore
  //     .collection('orders/byDeliverBoy/2020-10-15/${boyDetails['uid']}')
  //     .doc('$docId');
  WriteBatch batch = _firestore.batch();
  batch.update(
      data['reference'], {'shopDetails': shopDetails, 'refNo': data['refNo']});
  await batch.commit();

  sendAndRetrieveMessage(fcmId, 'Your order is confirmed', 'Order Update');
}
