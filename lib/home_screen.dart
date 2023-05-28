import 'package:cc_avenue_flutter/payment_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //testing mode,when you are done with test change it to false

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CCAvenue Example"),
      ),
      body: Center(
        child: TextButton(
          child: const Text("Payment start"),
          onPressed: () async {
            final res = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (builder) => const PaymentScreen(amount: 1)));
            if (res != null) {
              //handle event after payment
            }
          },
        ),
      ),
    );
  }
}
