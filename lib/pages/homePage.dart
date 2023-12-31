import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:budgettrack/pages/plans.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:budgettrack/pages/Notification.dart';
import 'package:badges/badges.dart' as badges;
import 'package:shared_preferences/shared_preferences.dart';
import '../components/tranaction.dart';
import 'Profile.dart';
import 'Savings.dart';
import 'expenceAndIncome.dart';
import 'goals.dart';
import 'TextScanner.dart';
import 'Summery.dart';

int expensevalue=0;
int incomevalue=0;
double percentage1=0.0;
class HomePage extends StatelessWidget {
  const HomePage({Key? key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(325, 812),
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
 home: Controller(balance: 0,), //call to the class work
      ),
    );
  }
}

String username = '';
String email = '';
int count = 0;
double percent = 0.0;
String name='';



class Controller extends StatefulWidget {
  int newbalance=0;
  Controller({Key? key, required int balance }) : super(key: key) //one of the constructor to get the following values from Menu,Notification files
  {
    newbalance=balance;
  }

  @override
  _ControllerState createState() => _ControllerState(
    newbalance: newbalance,

    //pass the values to the _ControllerState private class
  );
}

class _ControllerState extends State<Controller> {
  String counID='';
  int flag = 0;
  String name='';
  FirebaseMessaging msg = FirebaseMessaging.instance;
  String? mtoken = " ";
  String titleText='';
  String bodyText=' ';
  StreamSubscription? subscription;
  bool isDeviceConnected = false;
  bool isAlertSet = false;
  Uint8List? minpic;
  bool isContainerVisible = false;
  int newbalance = 0;
  String currency='';
  MyTransaction? latestincome;
  MyTransaction? latestexpense;
  _ControllerState(
      {required this.newbalance});

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> saveToken(String token) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    User? user = _auth.currentUser;
    String username = user!.uid;
    final CollectionReference incomeCollection = firestore.collection('userDetails')
        .doc(username)
        .collection('Tokens');

    // Check if the token already exists in the database
    final existingToken = await incomeCollection.where('token', isEqualTo: token).get();

    if (existingToken.docs.isEmpty) {
      // Token does not exist, so save it
      final DocumentReference newDocument = await incomeCollection.add({
        'token': token,
        'State':'invalid'
      });

      // Perform any additional actions you need

    } else {
      // Token already exists, no need to save it again
      print("Token already exists in the database");
    }
    firstprocess(token);
  }

  Future<void> getToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        mtoken = token;
      });
      if (mtoken != null) {
        print("FCM Token: $mtoken");
        saveToken(mtoken!);
      } else {
        print("FCM Token is null");
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }
  Future<void> initNotification() async {
    AndroidInitializationSettings initializationSettingsAndroid = const AndroidInitializationSettings('@mipmap/ic_launcher');

    var initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification:
            (int id, String? title, String? body, String? payload) async {});

    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await notificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse:
            (NotificationResponse notificationResponse) async {});
  }

  notificationDetails() {
    return const NotificationDetails(
        android: AndroidNotificationDetails('channelId', 'channelName',
            importance: Importance.max),
        iOS: DarwinNotificationDetails());
  }
  Future showNotification(
      {int id = 0, String? title, String? body, String? payLoad}) async {
    return notificationsPlugin.show(
        id, title, body, await notificationDetails());
  }


  Future<void>firstprocess(String token)async {

    User? user = _auth.currentUser;
    String username = user!.uid;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final incomeSnapshot = await firestore.collection('userDetails').doc(username).collection('Tokens').where('State',isEqualTo:'invalid').get();
    print(token);
    if (incomeSnapshot.docs.isNotEmpty) {
      bodyText = 'Hello! Welcome back to have an great experiance on budget Managing';
      titleText = 'Welcome!';

      final existingEntry = await getExistingEntry('invalid');

      if (existingEntry != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        final DocumentReference documentReference = firestore
            .collection('userDetails')
            .doc(username)
            .collection('Tokens')
            .doc(existingEntry);

        // Use the update method to update the "Balance" field
        await documentReference.update({
          'State':'valid',
        });
        String message='Hello! Welcome back to have an great experiance on budget Managing';
        DateTime time=DateTime.now();
        showNotification(
          id:1,
          title: 'Hello!!',
          body: message,
        );
        updateCount();
        addNotificationToFirestore(message,time);
      }

    }

  }
  Future<String?> getExistingEntry(String state) async {
    User? user = _auth.currentUser;
    String username = user!.uid;
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Tokens')
          .where('State',isEqualTo: state)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Return the document ID of the existing entry
        return querySnapshot.docs.first.id;
      } else {
        return null;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return null;
    }
  }
  static Future<String> getUserName() async {
    //get the username from Profile file
    User? user = _auth.currentUser; //created an instance to the User of Firebase authorized
    email = user!.email!; //get the user's email
    if (user != null) {
      QuerySnapshot qs = await FirebaseFirestore.instance
          .collection('userDetails')
          .where('email', isEqualTo: email)
          .limit(1)
          .get(); //need to filter the current user's name by matching with the users male at the authentication and the username

      if (qs.docs.isNotEmpty) {
        // Loop through the documents to find the one with the matching email
        for (QueryDocumentSnapshot doc in qs.docs) {
          if (doc.get('email') == email) {
            // Get the 'username' field from the matching document
            String username = doc.get('username');
            return username;
          }
        }
      }
      // Handle the case when no matching documents are found for the current user
      print('No matching document found for the current user.');
      return ''; // Return an empty string or null based on your requirements
    } else {
      // Handle the case when the user is not authenticated
      print('User not authenticated.');
      return ''; // Return an empty string or null based on your requirements
    }
  }

  Future<void> fetchLatestTransactions() async {// This method is for get the recent expense and income name
    User? user = _auth.currentUser;
    String username = user!.uid;
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      //fetch the latest income
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('incomeID')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (incomeSnapshot.docs.isNotEmpty) {
        final income = incomeSnapshot.docs[0];
        setState(() {
          this.latestincome= MyTransaction(
            transactionName: income.get('transactionName'),
            transactionAmount: income.get('transactionAmount'),
            transactionType: 'Income',
            timestamp: income.get('timestamp').toDate(),
            currencySymbol:currency,
          );
        });
      }

      //fetch the latest expenses according to the transaction page
      final expenceSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('expenceID')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (expenceSnapshot.docs.isNotEmpty) {
        final expence = expenceSnapshot.docs[0];
        setState(() {
          this.latestexpense = MyTransaction(
            transactionName: expence.get('transactionName'),
            transactionAmount: expence.get('transactionAmount'),
            transactionType: 'Expence',
            timestamp: expence.get('timestamp').toDate(),
            currencySymbol: currency,
          );
        });
      }
    } catch (ex) {
      print('fetching latest transactions failed');
    }
    print(  latestexpense?.transactionName);
  }
  Future<int>getcountfromdb()async{
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('NotificationCount')
          .get();

      if (querySnapshot.docs.isNotEmpty) {

        int count = querySnapshot.docs.first['Count'];

        print(count);
        return  count;

      } else {
        // No entry found
        return 0;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return 0;
    }
  }
  Future<String> getCurrency() async {

    User? user = _auth.currentUser;
    email = user!.email!;
    if (user != null) {
      QuerySnapshot qs = await FirebaseFirestore.instance.collection(
        //the query check wither the authentication email match with the email which is taken at the user details
          'userDetails').where('email', isEqualTo: email).limit(1).get();

      if (qs.docs.isNotEmpty) {
        // Loop through the documents to find the one with the matching email
        for (QueryDocumentSnapshot doc in qs.docs) {
          if (doc.get('email') == email) {
            // Get the 'username' field from the matching document
            currency = doc.get('currency');
            print(currency);
            if(currency=='SLR'){
              currency='Rs.';
            }
            else if(currency=='USD'){
              currency='\$';
            }
            else if(currency=='EUR'){
              currency='€';
            }
            else if(currency=='INR'){
              currency='₹';
            }
            else if(currency=='GBP'){
              currency='£';
            }
            else if(currency== 'AUD'){
              currency='A\$';
            }
            else if(currency=='CAD'){
              currency='C\$';
            }

            return currency; //return the currency
          }
        }
      }
      // Handle the case when no matching documents are found for the current user
      print('No matching document found for the current user.');
      return ''; // Return an empty string or null based on your requirements
    } else {
      // Handle the case when the user is not authenticated
      print('User not authenticated.');
      return ''; // Return an empty string or null based on your requirements
    }
  }
  Future<int> getBalance() async {
    int totalIncome = await  getIncome();
    int totalExpence = await  getExpence();


    int difference = (totalIncome - totalExpence).toInt();

    if(difference<0) {
      setState(() {
        newbalance = 0;
      });
      return newbalance;
    }
    else {
      setState(() {
        newbalance =difference;
      });
      return newbalance;
    }

  }
  Future<int> getIncome() async {
    User? user = _auth.currentUser;
    String username = user!.uid;
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Balance')
          .get();

      if (querySnapshot.docs.isNotEmpty) {

        incomevalue = querySnapshot.docs.first['Income'];
        return  incomevalue;
      } else {
        // No entry found
        return 0;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return 0;
    }
  }
  Future<int> getExpence() async {
    User? user = _auth.currentUser;
    String username = user!.uid;
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Balance')
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Assuming 'Balance' is a field in your Firestore document
        expensevalue = querySnapshot.docs.first['Expences'];
        return expensevalue;
      } else {
        // No entry found
        return 0;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return 0;
    }
  }

  void addNotificationToFirestore(String message,DateTime time) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {

      try {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        final CollectionReference incomeCollection = firestore
            .collection('userDetails')
            .doc(username)
            .collection('ReceivedNotifications');

        final DocumentReference newDocument = await incomeCollection.add({
          'message': message,
          'Time':time, // Use the formatted time as a DateTime
        });

        final String newDocumentId = newDocument.id;
        print('New document created with ID: $newDocumentId');
      } catch (ex) {
        print('Notification adding failed: $ex');
        // Handle the error appropriately, e.g., show a message to the user
      }
      // }
    }
    catch (ex) {
      print('Error occurs: $ex');
      // Handle any unexpected errors here
    }
  }

  void addNotificationcountToFirestore() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {

      try {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        final CollectionReference incomeCollection = firestore
            .collection('userDetails')
            .doc(username)
            .collection('NotificationCount');

        final DocumentReference newDocument = await incomeCollection.add({
          'Count':await counter(),
          // Use the formatted time as a DateTime
        });

        final String newDocumentId = newDocument.id;
        print('New document created with ID: $newDocumentId');
      } catch (ex) {
        print('Notification adding failed: $ex');
        // Handle the error appropriately, e.g., show a message to the user
      }
      // }
    }
    catch (ex) {
      print('Error occurs: $ex');
      // Handle any unexpected errors here
    }
  }
  Future<void> updateCount() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;
    String username = user!.uid;
    try {
      final existingEntry = await  getCountExist();

      if (existingEntry != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        final DocumentReference documentReference = firestore
            .collection('userDetails')
            .doc(username)
            .collection('NotificationCount')
            .doc(existingEntry);

        // Use the update method to update the "Balance" field
        await documentReference.update({
          'Count':await counter(),
        });

        print('Count updated successfully!');
      } else {
        addNotificationcountToFirestore();
      }
    } catch (ex) {
      print('Error updating noticount: $ex');
    }
    // setState(() {});
  }


  Future<String?> getCountExist() async {
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('NotificationCount')
          .where('Count', isEqualTo:await getcountfromdb() )
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Return the document ID of the existing entry
        return querySnapshot.docs.first.id;
      } else {
        // No entry found
        return null;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return null;
    }
  }

  Future<int> counter() async {
    final newCount = await getcountfromdb() + 1;
    setState(() {
      flag = newCount;
    });
    return flag;
  }
  void initState() {

    super.initState();
    checkConnectivity();
    WidgetsFlutterBinding.ensureInitialized();
    initNotification();
    getToken();
    getCurrency();
    loadStoredImage();
    fetchLatestTransactions();
    getBalance();
    getIncome();
    getExpence();
    countPercenntage();
    updatePercentage();//call to the countpercentage method
  }


  void dispose() {
    subscription?.cancel();
    super.dispose();
  }
  void checkConnectivity() {
    subscription = Connectivity().onConnectivityChanged.listen(
          (ConnectivityResult result) async {
        isDeviceConnected = await InternetConnectionChecker().hasConnection;
        if (!isDeviceConnected && isAlertSet ==false) {
          setState(() => isAlertSet = true);
          showConnectionDialog();
        }
        if(isDeviceConnected==true){
          setState(() => isAlertSet = false);

        }
      },
    );
  }

  void showConnectionDialog() {
    showCupertinoDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('No Connection'),
        content: const Text('Please check your internet connectivity'),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.pop(context, 'OK');
              setState(() => isAlertSet = false);
              isDeviceConnected = await InternetConnectionChecker().hasConnection;
              if (!isDeviceConnected && isAlertSet == false) {
                showConnectionDialog();
                setState(() => isAlertSet = true);
              }
              else if(isDeviceConnected==true){
                setState(() => isAlertSet =false);
              }
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> updatePercentage() async {
    double percentage = await countPercenntage();
    setState(() {
      percentage1 = percentage;
    });
  }

  Future<double> countPercenntage() async {
    //count the percentage by subtracting expense from income and divide it from the income value
    double difference = (await getIncome() - await getExpence()).toDouble();
    percent = difference /(await getIncome()).toDouble();
    if (percent >= 0 && percent <= 1) {

      return percent;
    }
    else {
      percent = 0.0;
      return percent;
    }

  }


  void ContainerVisibility() {

    showDialog(context: context,
        builder: (BuildContext context){
          return Stack(
            children: [
              AlertDialog(
                content: Container(
                  alignment: Alignment.center,
                  height:100,
                  width:400,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      Row(

                        children: [

                          Text(
                            'Total Income:',
                            style: TextStyle(
                              fontSize:15,
                              color:Color(0xFF090950),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.only(left:15.0),
                            child: FutureBuilder<int>(
                                future:getIncome(),
                                builder: (context, snapshot) {

                                  return Text(
                                    '${snapshot.data}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color:Color(0xFF090950),
                                    ),
                                  );
                                }
                            ),

                          ),
                          Icon(
                            Icons.arrow_upward,
                            color: Colors.green,
                            size: 28,
                          ),
                        ],
                      ),
                      SizedBox(height:5),
                      Row(
                        children: [
                          Text(
                            'Total Expense:',
                            style: TextStyle(
                              fontSize:15,
                              color: Color(0xFF090950),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left:8.0),
                            child:FutureBuilder<int>(
                                future: getExpence(),
                                builder: (context, snapshot) {
                                  return Text(
                                    '${snapshot.data}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Color(0xFF090950),
                                    ),
                                  );
                                }

                            ),

                          ),
                          Icon(
                            Icons.arrow_downward,
                            color: Colors.red,
                            size: 28,
                          ),
                        ],
                      )

                    ],
                  ),
                ),
              ),
            ],

          );
        }
    );

  }
  Future<Uint8List?> getImageFromFirestore() async {
    try {
      User? user = _auth.currentUser;
      String username = user!.uid;

      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final CollectionReference profileImageCollection = firestore
          .collection('userDetails')
          .doc(username)
          .collection('ProfileImage');

      QuerySnapshot imageDocuments = await profileImageCollection.get();

      if (imageDocuments.docs.isNotEmpty) {
        // If there are image documents, retrieve the first one (assuming only one exists)
        String base64Image = imageDocuments.docs.first['Userimage'];

        // Decode the base64-encoded image data and return it as Uint8List
        Uint8List imageBytes = base64Decode(base64Image);
        return imageBytes;
      } else {
        return null; // Return null if no image documents are found
      }
    } catch (ex) {
      print('Image retrieval from Firestore failed: $ex');
      return null; // Return null to indicate failure
    }
  }


  void loadStoredImage() async {

    Uint8List? profileImage = await getImageFromFirestore();

    if (profileImage != null) {
      setState(() {
        minpic= profileImage;
      });
    } else {
      minpic=null;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(
          color: Color(0xFF090950),
          size: 30,
        ),
        leading: Padding(
          padding: EdgeInsets.only(left:20),
          child: IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>
                        Check()), //if the user click on the menu icon then move
              );
            },
            icon: const Icon(Icons.menu),
          ),
        ),
        titleSpacing:20.0,
        centerTitle: true,
        title: Row(
            children: [

              Container(
                width:40,
                height:40,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:const Color(0xFF090950),
                    width: 3.0,
                  ),
                ),
                margin: EdgeInsets.only(top:5,right:5),
                child:minpic != null
                    ? CircleAvatar(
                    radius:40,
                    backgroundImage: MemoryImage(minpic!))
                    : CircleAvatar(
                  radius:40,
                 backgroundImage:  AssetImage('lib/images/Profile.png')),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left:5,),
                  child: Column(
                    children: [
                  Text(
                  "Welcome!",
                    textAlign: TextAlign.center,
                    //print the user name who are currently using with
                    style: TextStyle(
                      letterSpacing: 5.0,
                      fontFamily:'Lexend-VariableFont',
                      color: Color(0xFF090950),
                      fontSize:14,
                    ),
                  ),
                      FutureBuilder<String>(
                          future: getUserName(),
                          builder: (context, snapshot) {
                            return Text(
                              "${snapshot.data}",
                              textAlign: TextAlign.center,
                              //print the user name who are currently using with
                              style: TextStyle(
                                letterSpacing: 5.0,
                                fontFamily:'Lexend-VariableFont',
                                color:Color(0xFF090950),
                                fontSize:18,
                                fontWeight: FontWeight.bold,

                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ),

              Icon(
                  Icons.waving_hand,
                  size:20,
                  color: Color(0xFF090950)
              ),


            ],

        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right:30),
            child: FutureBuilder<int>(
              future: getcountfromdb(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // While the future is still loading, you can show a loading indicator or placeholder
                  return CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
                  );
                } else if (snapshot.hasError) {
                  // If there's an error, you can handle it here
                  return Text('Error: ${snapshot.error}');
                } else {
                  // If the future has completed successfully, display the data
                  return snapshot.data==0 ? IconButton(
                    //if the count value is 0 then badge won't show otherwise it dissplays the unseen notification count
                    onPressed: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                            builder: (context) => Holder(
                              totalBalance: newbalance,
                            )), //create a constructor to the Holder class to display the notification list
                      );
                    },
                    icon: Icon(
                      Icons.notifications_outlined,
                      size: 40,
                    ),

                  )
                      : badges.Badge(
                    badgeContent: Text('${snapshot.data}'),
                    position: badges.BadgePosition.topEnd(top:2, end: 0),
                    badgeAnimation: badges.BadgeAnimation.slide(),
                    badgeStyle: badges.BadgeStyle(
                      shape: badges.BadgeShape.circle,
                      padding: EdgeInsets.all(8.0),
                      badgeColor: Colors.red,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => Holder(
                                totalBalance: newbalance,
                              )),
                        );
                      },
                      icon: Icon(
                        Icons.notifications_outlined,
                        size: 40,
                      ),

                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),

      //bottom navigation bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20), bottomRight: Radius.circular(20),bottomLeft:Radius.circular(20) )),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 3,
          ),
          child: GNav(
            backgroundColor: Colors.transparent,
            color: const Color(0xFF090950),
            activeColor: const Color.fromARGB(255, 31, 96, 192),
            tabBackgroundColor: Colors.white,
            gap:6,
            onTabChange: (Index) {
              //if the user click on the bottom navigation bar then it will move to the following pages
              if (Index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomePage()),
                );
              } else if (Index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>Pro()),
                );
              } else if (Index == 2) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>PlansApp()),
                );
              } else if (Index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Goals()),
                );
              } else if (Index ==4) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TextScanner(newBalance:newbalance)),
                );
              }
            },
            padding: const EdgeInsets.all(15),
            tabs: const [
              GButton(
                icon: Icons.home,
                //text: 'Home',
              ),
              GButton(
                icon: Icons.align_vertical_bottom_outlined,
                //text: 'Summary',
              ),
              GButton(
                icon: Icons.assignment,
                //text: 'Savings',
              ),
              GButton(
                icon: Icons.track_changes_rounded,
                //text: 'Plans',
              ),
              GButton(
                icon: Icons.document_scanner_outlined,
                //text: 'Scan',
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(

        child: Container(
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                margin:EdgeInsets.only(left:20,top:20,right:20,),
                height:280,
                width: 450,
                decoration: BoxDecoration(
                  color:Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.8),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: Offset(0,3),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(20),
                ),
                // margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  margin:EdgeInsets.only(top:15,bottom:15),
                  width:100,
                  height:100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:const Color(0xFF5C6C84), // Set the border color
                      width:4.0, // Set the border width
                    ),
                  ),
                  child: CircularPercentIndicator(
                    radius: 120,
                    lineWidth:30,
                    percent:percentage1,
                    animation: true,
                    animationDuration: 1000,
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: const Color(0xFFEEEEEE),// Progress color
                    backgroundColor: Color(0xFFC2DAFF),
                    center: Container(
                      width:180,
                      height:180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:const Color(0xFF5C6C84), // Set the border color
                          width:2.0, // Set the border width
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('MMM dd').format(DateTime.now()),
                            //time and date format
                            style: const TextStyle(
                              fontFamily:'Lexend-VariableFont',
                              fontSize:30,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF090950),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ContainerVisibility();
                            },
                            child:FutureBuilder<double>(
                              future: countPercenntage(),
                              builder: (context, snapshot) {  if (snapshot.connectionState == ConnectionState.waiting) {
                                // Handle the case where the Future is still running
                                return CircularProgressIndicator();
                              } else if (snapshot.hasError) {
                                // Handle any errors that occurred during the Future execution
                                return Text('Error: ${snapshot.error}');
                              } else {
                                // Perform a null check before using snapshot.data
                                if (snapshot.data != null) {

                                  final percentage = (snapshot.data!*100).toStringAsFixed(0);

                                  return Text(
                                    '${percentage}%',
                                    style: TextStyle(
                                      fontFamily:'Lexend-VariableFont',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 50,
                                      color: Color(0xFF090950),
                                    ),
                                  );
                                } else {
                                  // Handle the case where snapshot.data is null
                                  return Text('Data is null');
                                }
                              }
                              },
                            ),
                          ),
                          Text(
                            'Remaining',
                            style: TextStyle(
                              fontFamily:'Lexend-VariableFont',
                              fontSize:15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF090950),
                            ),
                          ),
                        ],
                      ),
                    ),

                  ),
                ),
              ),
              SizedBox(height:10),
              Container(
                  width:375,
                  height:220,

                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/images/mastercard NEW.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),


                  child:Column(
                    children: [
                      Align(
                        alignment:Alignment.topLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top:5,left:5),
                          child: Text(
                              'Balance',
                              style:TextStyle(
                                fontFamily:'Lexend-VariableFont',
                                fontSize: 20,
                                color:const Color(0xFF090950),
                              )
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top:125,left:5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${currency}${newbalance}',
                              style: TextStyle(
                                fontFamily:'Lexend-VariableFont',
                                fontSize: 40,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '${DateFormat('dd/MM').format(DateTime.now())}',
                              style:TextStyle(
                                fontFamily:'Lexend-VariableFont',
                                fontSize:20,
                                color:Color(0xFF090950),
                              ),
                            ),
                          ],
                        ),
                      ),


                    ],
                  )

              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left:15),
                  child: Text(
                    'Featured',
                    style: TextStyle(
                      fontFamily:'Lexend-VariableFont',
                      fontSize: 20,
                      color:Color(0xFF090950),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width:double.infinity,
                height:140,
                color:Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: 120,
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.8),
                            spreadRadius: 0,
                            blurRadius:8,
                            offset: Offset(0,3),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Stack(children: [
                        const Align(
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: EdgeInsets.only(top: 5, left: 5),
                            child: Text(
                              'TRANSACTION', //print the text as 'Recent'
                              style: TextStyle(
                                fontFamily:'Lexend-VariableFont',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:Color(0xFF090950),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Container(
                              //this container is for the recent transactions
                              width: 60.0,
                              height: 60.0,
                              margin:
                              const EdgeInsets.only(top: 35),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:const Color(0xFF090950),
                                  width: 3.0,
                                ),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: this.latestexpense?.transactionName=='Transport'? Icon(
                                    CupertinoIcons.car_detailed,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Food'?Icon(
                                    FontAwesomeIcons.burger,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Health'?Icon(
                                  Icons.monitor_heart_rounded,
                                    size: 30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Education'?Icon(
                                    Icons.cast_for_education,
                                    size: 30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Fuel'?Icon(
                                    FontAwesomeIcons.oilCan,
                                    size: 30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Donations'?Icon(
                                    FontAwesomeIcons.donate,
                                    size: 30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Bills'?Icon(
                                    FontAwesomeIcons.prescription,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Entertainment'?Icon(
                                    FontAwesomeIcons.microphone,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Others'?Icon(
                                    FontAwesomeIcons.handsAslInterpreting,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Shopping'?Icon(
                                    FontAwesomeIcons.shoppingCart,
                                    size:30,
                                    color:const Color(0xFF090950)
                                )
                                    :this.latestexpense?.transactionName=='Rental'?Icon(
                                    FontAwesomeIcons.house,
                                    size: 30,
                                    color:const Color(0xFF090950)
                                )
                                    :Container(
                                ),
                              ),
                            ),
                            Container(
                              width: 60.0,
                              height: 60.0,
                              margin:
                              const EdgeInsets.only(top: 35),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:Color(0xFF3AC6D5),
                                  width: 3.0,
                                ),
                              ),
                              child: Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                                child: this.latestincome?.transactionName=='Salary'? Icon(
                                  FontAwesomeIcons.wallet,
                                  size: 30,
                                  color:Color(0xFF3AC6D5),
                                )
                                    :this.latestincome?.transactionName=='Bonus'?Icon(
                                  FontAwesomeIcons.clockRotateLeft,
                                  size:30,
                                  color:Color(0xFF3AC6D5),
                                )
                                    :this.latestincome?.transactionName=='Gifts'?Icon(
                                  FontAwesomeIcons.gift,
                                  size:30,
                                  color:Color(0xFF3AC6D5),
                                )
                                    :this.latestincome?.transactionName=='Rental'?Icon(
                                  Icons.add_card_rounded,
                                  size: 30,
                                  color:Color(0xFF3AC6D5),
                                )
                                    :this.latestincome?.transactionName=='Others'?Icon(
                                  FontAwesomeIcons.handsClapping,
                                  size: 30,
                                  color:Color(0xFF3AC6D5),
                                )
                                    :Container(),
                              ),
                            ),
                            Container(
                              width: 60.0,
                              height: 60.0,
                              margin:
                              const EdgeInsets.only(top: 35,),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:const Color(0xFFC2DAFF),
                                  width: 3.0,
                                ),
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  FontAwesomeIcons.plus,
                                  size: 30,
                                  color:Colors.blue,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Expence(
                                          nume: count,
                                        )),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ]),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                Savings(),
                          ),
                        );
                        //user can move to the Savings file
                      },
                      child: Container(
                        //this container is for the bottom buttons for the Svaings,Summery profile and scanner
                        height: 120,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.8),
                              spreadRadius: 0,
                              blurRadius:8,
                              offset: Offset(0,3),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Stack(
                          children: [
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: EdgeInsets.only(top:5.0),
                                child: Text(
                                  'SAVINGS',
                                  style: TextStyle(
                                    fontFamily:'Lexend-VariableFont',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color:Color(0xFF090950),
                                  ),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.center,
                              child:Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 50,
                                color: Color(0xFF85B6FF),
                              ),
                            )

                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),


            ],
          ),
        ),
      ),
    );
  }
}