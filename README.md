# cc_avenue_flutter
In today's digital era, businesses are constantly seeking secure and reliable payment gateways to facilitate seamless transactions. [CCAvenue](https://www.ccavenue.com/) is a popular payment gateway in India, offering a wide range of payment options for online businesses. In this blog, we will explore how to integrate CCAvenue into a Flutter application using PHP server.

> Note: There is no official SDK available for flutter, so we are going to integrate through Flutter Webview.

## Prerequisites:
Before we begin, make sure you have the following requirements in place:

- Flutter SDK installed on your machine
- Basic knowledge of Flutter and PHP
- CCAvenue merchant account credentials

> Note: CCAvenue does not allow payment transaction in live or test mode until you whitelist your Domain/IP. For Whitelisting your domain, you can email them.

## Lets understand how does transaction Handle through CCAvenue?

CCAvenue has two phase for completing transaction

![image 1](https://dev-to-uploads.s3.amazonaws.com/uploads/articles/ddg7nzhefnbhw4piiusp.png)

- **Initiate Payment** : In this step,client send `amount` and `currency` and other required details to server and than server encrypt these values to a single encrypted(lets says `enc_val`) string and send `enc_val` and `access_code` to client.

> Note: When your CCAvenue approved and whitelisted for transaction then you can get following `access_code`,`working_key` and `merchant_id` from CCAvenue.

- Generate enc_val: Merchant need to encrypt following set of parameters using encryption tool provided by CCAvenue(We will use PHP)

We will encrypt following String:

```
merchant_id=123&order_id=123456redirect_url=www.amazonaws.com/payment
/ccav_resp.phpcancel_url=www.amazonaws.com/payment/ccav_resp.phpamount=1.00&currency=INR

```

after encryption we will get string like

```
a5eed2d2a51358773bb1de741b0b2f1261308043c2a8f78bf59d9d3d5081f785792599d64876
220964ebdd1578ce633aae959b804f2b2d53cda3821baf5480b3a082ea89a0e6784af4fef98e0
54f3a5c78f0ec9e611a01dd7666e9903e6b5d62c7a11d8db869d665c0077a292cfa6aba80a1ab
a94882168ede009b2c3806a4b08c781e2e5a7d54411b5a288ff28d499bc9de
```


| Parameter Name | Description | Type (length) |
| --- | --- | --- |
| Merchant Id | Merchant Id is a unique identifier generated by CCAvenue for each activated merchant. | Numeric |
| Order Id | This ID is used by merchants to identify the order. Ensure that you send a unique id with each request. CCAvenue will not check the uniqueness of this order id. As it generates a unique payment reference number for each order which is sent by the merchant. | Alphanumeric (30) |
| Redirect Url | CCAvenue will post the status of the order along with the parameters to this URL. | Alphanumeric (100) |
| Cancel Url | CCAvenue will redirect the customer to this URL if the customer cancels the transaction on the billing page. | Alphanumeric (100) |
| Amount | Order amount | Numeric (12, 2) |
| Currency | Currency in which you want to process the transaction. <br> AED - Arab Emirates dirham <br> USD - United States Dollar <br> SAR - Saudi Arabia Riyal <br> INR – Indian Rupee <br> SGD – Singapore Dollar <br> GBP – Pound Sterling <br> EUR – Euro, official currency of Eurozone | Alphabets (3) |

> Note: we will talk about `cancel_url` and `redirect_url` in the next steps.

- Start payment in WebView: you can start payment in webview through following url

```
https://secure.ccavenue.com/transaction.do?command=initiateTransaction&encRequest=enc_val&access_code=access_code

```

> Note for testing replace `secure.ccavenue.com` to `test.ccavenue.com`.


- Response Handler: When a user completes a payment, either in case of failure or success, CCAvenue will send an encrypted string to either the redirect_url or cancel_url using a POST request.

    - `redirect_url`: It refers to a webpage hosted on your server's domain/IP, which must be whitelisted by CCAVenue. This webpage will handle the necessary steps after the payment request is completed, including handling both failure and success scenarios.

    - `cancel_url`: Similar to the `redirect_url`, the `cancel_url` is also hosted on your server's domain/IP. However, it specifically handles requests where the user cancels the payment.

Now we will use decryption tool to decrypt string given by CCAvenue
after payment complete.


## Lets Start Integration (Server Side)

- We need encryption and decryption function to encrypt and decrypted request.

create `crypto.php` and with following content:

{% gist https://gist.github.com/Djsmk123/d13f3dded32764a80d97fd40981fcc68 %}

Install required Library:

```
sudo apt-get install php7.4-openssl
```

- Now we need to create a page that accept `POST` request and return `enc_val` and `access_code`.

`ccAvenueRequestHandler.php`

{% gist https://gist.github.com/Djsmk123/015bf832a6ac651f0cabc4dab11606cf %}

> Note: you can edit page as per your requirement,but later on flutter side you need JavaScript function to get desired result.

- We also need to create a page like above which accept `POST` request and return decrypted data.


`ccavResponseHandler.php`
{% gist https://gist.github.com/Djsmk123/f4a2d3012efb1af87cc0cb6ba8718612 %}

> Note: Following url should be accessible through whitelisted domain `https://your-domain/ccavResponseHandler.php`.



## Integration in Flutter(Client):

- Adding following to `pubspec.yaml`
```
dependencies:
  http: ^0.13.6
  webview_flutter: ^2.0.6 
  html: 
```

- Android Configuration: Change in `build.gradle`(android/app)

```
android {
    defaultConfig {
        minSdkVersion 19
    }
}
```

- Create Payment handler Screen with following content:
  lets say `payment_screen.dart`:

{% gist https://gist.github.com/Djsmk123/926c94e77dd2a964a73999b74d215013 %}


1. `isTesting` (Variable):
    - Description: A boolean variable used to indicate whether the application is in testing mode or production mode.
    - Type: `bool`

2. `jsChannels` (Variable):
    - Description: A set of `JavascriptChannel` objects that define the JavaScript channels available for communication between the Flutter app and the WebView.
    - Type: `Set<JavascriptChannel>`

3. `initPayment` (Method):
    - Description: This method is responsible for initializing the payment by making an HTTP POST request to the `requestInitiateUrl` with the specified amount.
    - Parameters:
        - `amount` (Type: `String`): The amount for the payment.
    - Returns: A Future object that resolves to the payment data in JSON format.
    - Type: `Future<dynamic>`

4. `onPageFinished` (Method):
    - Description: This method is called when the WebView finishes loading a page.
    - Parameters:
        - `url` (Type: `String`): The URL of the loaded page.
    - Returns: `void`
    - Type: `void`

5. `navigationDelegate` (Method):
    - Description: This method is used to control the navigation behavior of the WebView based on the requested URL.
    - Parameters:
        - `nav` (Type: `NavigationRequest`): The navigation request object containing information about the requested URL.
    - Returns: A `NavigationDecision` that determines whether to allow or prevent the navigation.
    - Type: `NavigationDecision`



## Follow me on

- [Twitter](https://twitter.com/smk_winner)

- [Instagram](https://www.instagram.com/smkwinner/)

- [Github](https://www.github.com/djsmk123)

- [linkedin](https://www.linkedin.com/in/md-mobin-bb928820b/)

- [dev.to](https://dev.to/djsmk123)

- [Medium](https://medium.com/@djsmk123)












































 














