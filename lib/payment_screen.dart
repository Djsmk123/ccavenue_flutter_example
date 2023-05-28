import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

//change to it false when your application is in production.
bool isTesting = true;

final Set<JavascriptChannel> jsChannels = {
  JavascriptChannel(
      name: 'Print',
      onMessageReceived: (JavascriptMessage message) {
        log(message.message.toString());
      }),
};

class PaymentScreen extends StatefulWidget {
  final int amount;
  const PaymentScreen({Key? key, required this.amount}) : super(key: key);
  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  String url = "";
  bool initializedPayment = false;
  String errorMessage = "";
  String loadingMessage = "";
  late WebViewController controller;
  String cancelUrl = "CANCEL_URL";
  String redirectUrl = "REDIRECT_URL";
  String requestInitiateUrl = "REQUEST_INITIATE_URL";
  @override
  void initState() {
    initAsync();
    super.initState();
  }

  initAsync() async {
    //Generating payment order and fetching URLs for the payment
    try {
      errorMessage = "";
      loadingMessage =
          "Please Do not close window,\nprocessing your request....";
      setState(() {});
      final res = await initPayment((widget.amount ~/ 100).toString());
      url =
          "https://${isTesting ? "test" : "secure"}.ccavenue.com/transaction.do?command=initiateTransaction&encRequest=${res['enc_val']}&access_code=${res['access_code']}";
      initializedPayment = true;

      setState(() {});
    } catch (e) {
      errorMessage = "Something went wrong";
    } finally {
      loadingMessage = "";
      setState(() {});
    }
  }

  initPayment(String amount) async {
    var url = requestInitiateUrl;
    Uri uri = Uri.parse(url);
    var res = await http.post(uri, body: {
      'currency': 'INR',
      'amount': amount,
    });

    if (res.statusCode == 200) {
      var jsonData = jsonDecode(res.body);
      return jsonData;
    } else {
      throw Exception();
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Screen"),
      ),
      body: initializedPayment
          ? WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
              javascriptChannels: jsChannels,
              onWebViewCreated: (c) async {
                controller = c;
                setState(() {});
              },
              onPageFinished: (url) async {
                if (url == redirectUrl) {
                  //following javascript function,could be different as per data you sent from the server
                  final String htmlContent =
                      await controller.runJavascriptReturningResult(
                          "your javascript function to fetch data");
                  final parsedJson = parse(htmlContent);
                  final jsonData = parsedJson.body?.text;
                  controller.clearCache();
                  final result = jsonDecode(jsonDecode(jsonData!));
                  log(result.toString());
                  //TODO: ON RESULT
                }
                if (url == cancelUrl) {
                  //TODO: ON RESULT
                }
              },
              navigationDelegate: (NavigationRequest nav) async {
                if (nav.url == redirectUrl) {
                  return NavigationDecision.navigate;
                }
                if (nav.url == cancelUrl) {
                  return NavigationDecision.navigate;
                }
                return NavigationDecision.prevent;
              },
            )
          : (loadingMessage.isNotEmpty
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : (errorMessage.isNotEmpty
                  ? Center(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    )
                  : const SizedBox.shrink())),
    );
  }
}
