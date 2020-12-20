import 'package:url_launcher/url_launcher.dart';

launchCaller(int phoneNo) async {
  var _url = "tel:$phoneNo";
  if (await canLaunch(_url)) {
    await launch(_url);
  } else {
    throw 'Could not launch $_url';
  }
}
