import 'dart:async';
import 'package:budgettrack/pages/plans.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Summery.dart';
import 'TextScanner.dart';
import 'goals.dart';
import 'homePage.dart';

class Savings extends StatefulWidget {

  Savings({Key? key}) : super(key: key) {
  }


  @override
  State<Savings> createState() => _SavingsState(

  );
}

String documentId = '';

class _SavingsState extends State<Savings> {
  double percent=0.0;
  SharedPreferences? _prefs;
  String? selectedyear = "2023";
  int savingbalance=0,incomev=0,expensev=0;
  String month='';
  String username='';
  DateTime now=DateTime.now();
  List<dynamic> mon=[];

  final items = [
    '2023',
    '2024',
    '2025',
    '2026',
    '2027',
    '2028',
    '2029',
    '2030',
    '2032',
    '2033',
    '2034',
    '2035',

    // ADD MORE
  ];
  // Default time: 12:00

  String currencySymbol='';
  DateTime lastDate = DateTime.now();
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  void initState() {
    super.initState();
    loadYear();
    getDocIds();
    getSelectedMonth(DateFormat('MMMM').format(DateTime.now()));
    updateBalance();
    // getthesavingfromDB(getLastTwoDigitsOfCurrentYear().toString(),DateFormat('MMMM').format(DateTime.now()));
    // gettheexpensefromDB(getLastTwoDigitsOfCurrentYear().toString(),DateFormat('MMMM').format(DateTime.now()));

    countpercent(getLastTwoDigitsOfCurrentYear().toString(),DateFormat('MMMM').format(DateTime.now()));
  }


  Future<String> getDocIds() async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
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
            currencySymbol = doc.get('currency');
            print(currencySymbol);
            if(currencySymbol=='SLR'){
              currencySymbol='Rs.';
            }
            else if(currencySymbol=='USD'){
              currencySymbol='\$';
            }
            else if(currencySymbol=='EUR'){
              currencySymbol='€';
            }
            else if(currencySymbol=='INR'){
              currencySymbol='₹';
            }
            else if(currencySymbol=='GBP'){
              currencySymbol='£';
            }
            else if(currencySymbol== 'AUD'){
              currencySymbol='A\$';
            }
            else if(currencySymbol=='CAD'){
              currencySymbol='C\$';
            }

            return currencySymbol; //return the currency
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
  Future<int> getTotalIncomeForMonth() async {
    try {
      int sum=0;
      User? user = _auth.currentUser;
      if (user == null) return 0;

      String username = user.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      DateTime now = DateTime.now();
      int currentYear = now.year;

      int currentMonth = now.month;

      DateTime lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

      int daysInMonth = lastDayOfMonth.day;
      List<int> monthlyIncome = List.filled(daysInMonth, 0);

      final expenseSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('incomeID')
          .get();

      expenseSnapshot.docs.forEach((income2Doc) {
        final timestamp = income2Doc.get('timestamp') as Timestamp;
        final timestampDate = timestamp.toDate();

        if (timestampDate.year == currentYear &&
            timestampDate.month == currentMonth) {
          int dayOfMonth = timestampDate.day - 1;
          monthlyIncome[dayOfMonth] +=
              (income2Doc.get('transactionAmount') as num).toInt();
        }
      });
      for(int i=0;i<monthlyIncome.length;i++){
        sum=sum+monthlyIncome[i];
      }
      return sum;
    } catch (ex) {
      print('Calculating monthly income failed: $ex');
      return 0;
    }
  }
  int getLastTwoDigitsOfCurrentYear() {
    DateTime now = DateTime.now();
    int currentYear = now.year;


    return currentYear;
  }


  void getSelectedMonth(String month) {
    this.month= month;

  }

  Future<int> gettheincomefromDB(String year,String month) async {

    int income = 0;
    User? user = _auth.currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .where('Month', isEqualTo: month)
          .get();


      incomeSnapshot.docs.forEach((cDoc) {
        income=(cDoc.get('Income'));
      });

      return income;
    } catch (ex) {
      print('calculating total income failed');
      return 0;
    }
  }
  Future<int> getthesavingfromDB(String year,String month) async {

    int balance = 0;
    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;


    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .where('Month', isEqualTo: month)
          .get();


      incomeSnapshot.docs.forEach((cDoc) {
        balance=(cDoc.get('Balance'));
      });

      return balance;
    } catch (ex) {
      print('calculating total balance failed');
      return 0;
    }
  }


  Future<int> gettheexpensefromDB(String year,String month) async {

    int expense = 0;

    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .where('Month', isEqualTo: month)
          .get();


      incomeSnapshot.docs.forEach((cDoc) {
        expense=(cDoc.get('Expense'));
      });


      return expense;
    } catch (ex) {
      print('calculating total expense failed');
      return 0;
    }
  }
  Future<int>changeexpense(String year,String month,int expensevalue)async{
    List<int>currentExpense=[];
    int expense = 0;
    int sum=0;
    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .orderBy('Timest', descending: true)
          .get();


      incomeSnapshot.docs.forEach((cDoc) {
        currentExpense.insert(0,cDoc.get('Expense'));
      });


      for (int i = 0; i < currentExpense.length-1; i++) {
        sum=sum+currentExpense[i];
      }
      expense=await getExpence()-sum;
      print(expense);



      return expense;
    } catch (ex) {
      print('calculating total expense failed');
      return 0;
    }
  }
  Future<int>changeincome(String year,String month,int incomevalue)async{//change the income of the user
    List<int>currentIncome=[];
    int income = 0;
    int sum=0;
    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .orderBy('Timest', descending: true)
          .get();


      incomeSnapshot.docs.forEach((cDoc) {
        currentIncome.insert(0,cDoc.get('Income'));
      });


      for (int i = 0; i < currentIncome.length-1; i++) {
        sum=sum+currentIncome[i];
      }
      income=await getIncome()-sum;
      print(income);


      return income;
    } catch (ex) {
      print('calculating total expense failed');
      return 0;
    }
  }

  Future<List> getthebalancefromDB(String year) async {//get the total balance upto now
    List<int> currentBalance = [];
    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .orderBy('Timest', descending: true)
          .get()
          .catchError((error) {
        print('Error executing Firestore query: $error');
      });


      incomeSnapshot.docs.forEach((cDoc) {
        currentBalance.insert(0,cDoc.get('Balance'));
      });

      return currentBalance;
    } catch (ex) {
      print('calculating total balance failed');
      return [];
    }
  }
  Future<int> getExpence() async {//get the total expense upto now
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
        expensev = querySnapshot.docs.first['Expences'];
        print(expensev);
        return expensev;
      } else {
        // No entry found
        return 0;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return 0;
    }
  }
  Future<int> getIncome() async {//get the total income upto now
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

        incomev = querySnapshot.docs.first['Income'];
        print(incomev);
        return  incomev;

      } else {
        // No entry found
        return 0;
      }
    } catch (ex) {
      print('Error getting existing entry: $ex');
      return 0;
    }
  }
  Future<List> gettheMonthfromDB(String year) async {// get the month to a list

    List<String> currentMonth = [];
    User? user = _auth
        .currentUser; //created an instance to the User of Firebase authorized
    username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final incomeSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Year', isEqualTo: int.parse(year))
          .orderBy('Timest', descending: true)
          .get()
          .catchError((error) {
        print('Error executing Firestore query: $error');
      });


      incomeSnapshot.docs.forEach((dDoc) {
        currentMonth.insert(0,dDoc.get('Month'));
      });

      return  currentMonth;
    } catch (ex) {
      print('Getting the month failed');
      return [];
    }
  }

Future<int>Balancet()async{
    int savings=await getTotalIncomeForMonth()-await getTotalExpenseForMonth();
    if(savings<0){
      savings=0;
      return savings;
    }
    else{
      return savings;
    }
}

  Future<void> updateBalance() async {

    final currentMonth = DateFormat('MMMM').format(DateTime.now());


    // Update the balance for the current month
    try {
      final existingEntry = await getExistingEntry(
          currentMonth, int.parse(selectedyear!));

      if (existingEntry != null) {
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        final DocumentReference documentReference = firestore
            .collection('userDetails')
            .doc(username)
            .collection('Savings')
            .doc(existingEntry);

        // Use the update method to update the "Balance" field
        await documentReference.update({
          'Balance':await Balancet(),
          'Income':await getTotalIncomeForMonth(),
          'Expense':await getTotalExpenseForMonth(),
        });

        print('Balance updated successfully!');
      } else {
        // No entry for the current month, add a new one
        documentId = await addSavingsToFireStore(
          await Balancet(),
          DateFormat('MMMM').format(DateTime.now()),
          int.parse(selectedyear!),
          await getTotalIncomeForMonth(),
          await getTotalExpenseForMonth(),
          DateTime.now(),
        ).toString();
      }
    } catch (ex) {
      print('Error updating balance: $ex');
    }
    setState(() {});
  }


  Future<String?> getExistingEntry(String month, int year) async {
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final QuerySnapshot querySnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings')
          .where('Month', isEqualTo: month)
          .where('Year', isEqualTo: year)
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


  Future<int> loadYear() async {
    _prefs = await SharedPreferences.getInstance();
    final selectedYear = _prefs?.getString('selectedYear');
    if (selectedYear != null && items.contains(selectedYear)) {
      setState(() {
        selectedyear = selectedYear;
      });
    }

    return int.parse(selectedyear!);
  }



  Future<String> addSavingsToFireStore(
      int balance,
      String Day,
      int year,
      int income,int expense,DateTime time
      ) async {
    User? user = _auth.currentUser;
    String username = user!.uid;

    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      final CollectionReference incomeCollection = firestore
          .collection('userDetails')
          .doc(username)
          .collection('Savings');

      final DocumentReference newDocument = await incomeCollection.add({
        'Balance': balance,
        'Month': Day,
        'Year': year,
        'Income':income,
        'Expense':expense,
        'Timest':time,
      });

      final String newDocumentId = newDocument.id;
      print('New document created with ID: $newDocumentId');

      return newDocumentId;
    } catch (ex) {
      print('Income adding failed: $ex');
      return ''; // Return an empty string to indicate failure
    }
  }
  Future<int> getTotalExpenseForMonth() async {
    try {
      int sum=0;
      User? user = _auth.currentUser;
      if (user == null) return 0;

      String username = user.uid;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      DateTime now = DateTime.now();
      int currentYear = now.year;
      int currentMonth = now.month;

      DateTime lastDayOfMonth = DateTime(currentYear, currentMonth + 1, 0);

      int daysInMonth = lastDayOfMonth.day;
      List<int> monthlyExpense = List.filled(daysInMonth, 0);

      final expenseSnapshot = await firestore
          .collection('userDetails')
          .doc(username)
          .collection('expenceID')
          .get();

      expenseSnapshot.docs.forEach((expense2Doc) {
        final timestamp = expense2Doc.get('timestamp') as Timestamp;
        final timestampDate = timestamp.toDate();

        if (timestampDate.year == currentYear &&
            timestampDate.month == currentMonth) {
          int dayOfMonth = timestampDate.day - 1;
          monthlyExpense[dayOfMonth] +=
              (expense2Doc.get('transactionAmount') as num).toInt();
        }
      });
        for(int i=0;i<monthlyExpense.length;i++){
          sum=sum+monthlyExpense[i];
        }
      return sum;
    } catch (ex) {
      print('Calculating monthly income failed: $ex');
      return 0;
    }
  }
  Future<void>countpercent(String year,String month)async{
    final income=(await gettheincomefromDB(year, month)).toDouble();
    final expense=(await gettheexpensefromDB(year, month)).toDouble();
    double percentage =(income-expense)/income;
    if (percentage >= 0 && percentage <= 1) {
      setState(() {
        this.percent=percentage;
      });
    }
    else if(percentage>1){
      setState(() {
        this.percent=1.0;
      });
    }
    else {
      percentage = 0.0;
      setState(() {
        this.percent=percentage;
      });
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.grey[100],
           leading: Padding(
             padding: const EdgeInsets.only(left:18),
             child: IconButton(
               icon: const Icon(Icons.arrow_back),
               color:const Color(0xFF090950),
               onPressed: () {
                 Navigator.push(
                   context,
                   MaterialPageRoute(
                     builder: (context) => const HomePage(),
                   ),
                 );
               },
             ),
           ),
           title:Padding(
             padding: const EdgeInsets.only(left:55.0),
             child: Row(
               children: [

                 const Text(
                   'S A V I N G S',
                   style: TextStyle(
                     fontFamily: 'Lexend-VariableFont',
                     color: const Color(0xFF090950),
                   ),
                 ),

               ],
             ),
           ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right:30),
              child:Icon(Icons.account_balance_wallet_outlined, size: 30, color: const Color(0xFF090950),),
            ),
          ],
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBar:Container(
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
          child: Column(
            children: [
              Divider( // Add a Divider here
                height: 3, // You can adjust the height of the divider
                thickness:1, // You can adjust the thickness of the divider
                color: Colors.grey, // You can set the color of the divider
              ),
              Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 20,),
                    height:40,
                    width:130,
                    decoration: BoxDecoration(

                      border: Border.all(
                        color: Colors.grey,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left:30),
                      child: DropdownButton<String>(
                        value: selectedyear,
                        onChanged: (String? newValue) async {
                          setState(() {
                            selectedyear = newValue!;
                          });
                          _prefs?.setString('selectedYear', selectedyear!);
                        },
                        underline: Container(),
                        itemHeight: 70, // Adjust the item height as needed
                        items: items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical:0), // Adjust the padding as needed
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontFamily: 'Lexend-VariableFont',
                                  fontSize: 20, // Adjust the font size as needed
                                  // Add more styling properties here if desired
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Container(

                    margin: EdgeInsets.only(top: 20),
                    height:400,
                    width:350,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.8),
                            spreadRadius: 5,
                            blurRadius: 10,
                            offset: Offset(0,10),
                          ),
                        ]
                    ),
                    child: Column(
                      children: [
                        Align(
                          alignment:Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top:15.0,left:10),
                            child: Text(
                                this.month,
                                style:TextStyle(
                                  fontFamily:'Lexend-VariableFont',
                                  fontSize: 20,
                                  color:const Color(0xFF090950),
                                )
                            ),
                          ),
                        ),
                        Container(
                          // Container which carries the percentage indicator
                          height:240,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Container(
                                margin:EdgeInsets.only(left:20),
                                width: 210, // Adjust the width and height as needed
                                height:210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:const Color(0xFF5C6C84), // Set the border color
                                    width:4.5, // Set the border width
                                  ),
                                ),

                                child: CircularPercentIndicator(
                                  center: Container(
                                    width:140,
                                   height:140,
                                   decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color:const Color(0xFF5C6C84), // Set the border color
                                        width:2.0, // Set the border width
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        SizedBox(height:20),
                                        Text(
                                          DateFormat('MMM dd').format(DateTime.now()),
                                          //time and date format
                                          style: const TextStyle(
                                            fontFamily:'Lexend-VariableFont',
                                            fontSize:25,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF090950),
                                          ),
                                        ),
                                        SizedBox(height:5),
                                        Text(
                                          '${ double.parse(percent.toStringAsFixed(2))*100}%',
                                          //time and date format
                                          style: const TextStyle(
                                            fontFamily:'Lexend-VariableFont',
                                            fontSize:30,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF090950),
                                          ),
                                        ),
                                        Text(
                                          'Remaining',
                                          //time and date format
                                          style: const TextStyle(
                                            fontFamily:'Lexend-VariableFont',
                                            fontSize:15,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF090950),
                                          ),
                                        ),
                                        // Text(
                                        //   '${this.i}'
                                        // )
                                      ],
                                    ),
                                  ),
                                  radius: 100,
                                  lineWidth: 30,
                                  percent:percent,
                                  circularStrokeCap: CircularStrokeCap.round,
                                  progressColor: const Color(0xFFEEEEEE),// Progress color
                                  backgroundColor: Color(0xFFC2DAFF),
                                  animation: true,
                                  animationDuration: 1000, // Start from 12 o'clock
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin:EdgeInsets.only(left:8,top:50),
                                  width: 10, // Adjust the width and height as needed
                                  height:10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:  const Color(0xFFEEEEEE),
                                  ),
                                ),
                              ),
                              FractionallySizedBox(
                                // This is for displaying the current date and time
                                widthFactor: 1.0,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 50.0, left: 20), // Adjust top padding here
                                    child: Text(
                                      'Savings',
                                      style: const TextStyle(
                                        fontFamily:'Lexend-VariableFont',
                                        fontSize: 10,
                                        color: Color(0xFF5C6C84),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin:EdgeInsets.only(left:8,top:90),
                                  width: 10, // Adjust the width and height as needed
                                  height:10,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:Color(0xFFC2DAFF),
                                  ),
                                ),
                              ),
                              const FractionallySizedBox(
                                // This is for displaying 'Expenses' as a word
                                widthFactor: 1.0,
                                child: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 90.0, left: 22), // Adjust top padding here
                                    child: Text(
                                      'Expenses',
                                      style: TextStyle(
                                        fontFamily:'Lexend-VariableFont',
                                        fontSize: 10,
                                        color:Color(0xFF5C6C84)
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 60),
                          child: Row(
                            children: [
                              Text(
                                'Savings',
                                style: TextStyle(
                                  fontFamily:'Lexend-VariableFont',
                                  color: const Color(0xFF090950),
                                  fontSize: 20,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left:60.0), // Adjust left padding here
                                child: Row(
                                  children: [
                                    Text(
                                      '$currencySymbol',
                                      style: TextStyle(
                                        fontFamily:'Lexend-VariableFont',
                                        color: const Color(0xFF090950),
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    FutureBuilder<int>(
                                      future: getthesavingfromDB(selectedyear!, month),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          // While the future is still loading, you can show a loading indicator or placeholder
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          // If there's an error, you can handle it here
                                          return Text('Error: ${snapshot.error}');
                                        } else {
                                          // If the future has completed successfully, display the data
                                          return Text(
                                            snapshot.data!.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontFamily: 'Lexend-VariableFont',
                                              fontSize: 20,
                                              color: const Color(0xFF090950),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: Align(
                            alignment:Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              height:70,
                              decoration: const BoxDecoration(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(20),

                                ),
                                color: Color(0xffEEEEEE),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width:165,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment:Alignment.topLeft,
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top:10.0,left:30),
                                                  child: Icon(
                                                      Icons.add_card_rounded,
                                                      color:const Color(0xFF090950)
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top:10.0,left:10),
                                                  child: Text(

                                                    'Expense',
                                                    style: TextStyle(
                                                      color: Color(0xFF5C6C84),
                                                      fontFamily:'Lexend-VariableFont',
                                                      fontSize:20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                          ),
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment:Alignment.topLeft,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding: const EdgeInsets.only(top:5.0,left:30.0),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                          '$currencySymbol',//curency of income
                                                          style: TextStyle(
                                                              fontFamily:'Lexend-VariableFont',
                                                              fontSize:20,
                                                              fontWeight: FontWeight.bold,
                                                              color:const Color(0xFF090950)
                                                          ),
                                                        ),

                                                        FutureBuilder<int>(
                                                          future: gettheexpensefromDB(selectedyear!,month),
                                                          builder: (context, snapshot) {
                                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                                              // While the future is still loading, you can show a loading indicator or placeholder
                                                              return CircularProgressIndicator();
                                                            } else if (snapshot.hasError) {
                                                              // If there's an error, you can handle it here
                                                              return Text('Error: ${snapshot.error}');
                                                            } else {
                                                              // If the future has completed successfully, display the data
                                                              return Text(
                                                                snapshot.data!.toStringAsFixed(2),
                                                                style: TextStyle(
                                                                  fontFamily: 'Lexend-VariableFont',
                                                                  fontSize: 20,
                                                                  color: const Color(0xFF090950),
                                                                ),
                                                              );
                                                            }
                                                          },
                                                        ),

                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  VerticalDivider(
                                    width: 10,
                                    color:Colors.black,
                                  ),
                                  Container(
                                    width:175,
                                    height: double.infinity,
                                    color: Colors.transparent,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: Align(
                                            alignment:Alignment.topRight,
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top:10.0,left:20,),
                                                  child: Icon(
                                                    Icons.add_card_rounded,
                                                    color:Color(0xFF3AC6D5),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(top:10.0,left:10),
                                                  child: Text(

                                                    'Income',
                                                    style: TextStyle(
                                                      color: Color(0xFF5C6C84),
                                                      fontFamily:'Lexend-VariableFont',
                                                      fontSize:20,

                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),

                                          ),
                                        ),
                                        Expanded(
                                          child: Align(
                                            alignment:Alignment.topLeft,
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.only(top:5.0,left:20.0),
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        '$currencySymbol',//curency of expense
                                                        style: TextStyle(
                                                            fontFamily:'Lexend-VariableFont',
                                                            fontSize:20,
                                                            fontWeight: FontWeight.bold,
                                                            color:const Color(0xFF090950)
                                                        ),
                                                      ),
                                                      FutureBuilder<int>(
                                                        future: gettheincomefromDB(selectedyear!, month),
                                                        builder: (context, snapshot) {
                                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                                            // While the future is still loading, you can show a loading indicator or placeholder
                                                            return CircularProgressIndicator();
                                                          } else if (snapshot.hasError) {
                                                            // If there's an error, you can handle it here
                                                            return Text('Error: ${snapshot.error}');
                                                          } else {
                                                            // If the future has completed successfully, display the data
                                                            return Text(
                                                              snapshot.data!.toStringAsFixed(2),
                                                              style: TextStyle(
                                                                fontFamily: 'Lexend-VariableFont',
                                                                fontSize: 20,
                                                                color: const Color(0xFF090950),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height:15,
                  ),
                  Divider( // Add a Divider here
                    height: 3, // You can adjust the height of the divider
                    thickness:1, // You can adjust the thickness of the divider
                    color: Colors.grey, // You can set the color of the divider
                  ),
                  Align(
                    alignment:Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top:15.0,left:30),
                      child: Text(
                          'All savings',
                          style:TextStyle(
                            fontFamily:'Lexend-VariableFont',
                            fontSize: 20,
                            color:const Color(0xFF090950),
                          )
                      ),
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 20),
                    height: 320,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.8),
                          spreadRadius: 5,
                          blurRadius: 10,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: FutureBuilder<List>(
                      future: getthebalancefromDB(selectedyear!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(),
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                            'Error: ${snapshot.error}',
                            style: TextStyle(
                                fontFamily: 'Lexend-VariableFont',
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                            ),
                          );
                        } else if (!snapshot.hasData || snapshot.data?.isEmpty == true) {
                          return Text(
                            'No data available.',
                            style: TextStyle(
                                fontFamily: 'Lexend-VariableFont',
                                fontSize: 16,
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                            ),
                          );
                        } else {
                          final balanceList = snapshot.data!;
                          return Scrollbar(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                await updateBalance();
                              },
                              child: ListView.builder(
                                itemCount: balanceList.length,
                                itemBuilder: (context, index) {
                                  return Column(
                                    children: [
                                      ListTile(
                                        title: SingleChildScrollView(
                                          scrollDirection:Axis.horizontal,
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width:100,
                                                child: FutureBuilder<List>(
                                                  future: gettheMonthfromDB(selectedyear!),
                                                  builder: (context, snapshot) {
                                                    final MonthList = snapshot.data;
                                                    mon = MonthList ?? [];
                                                    return Padding(
                                                      padding: const EdgeInsets.only(left: 5.0),
                                                      child: Align(
                                                        alignment: Alignment.center,
                                                        child: Text(
                                                          '${MonthList?[index]}',
                                                          style: TextStyle(
                                                            fontFamily: 'Lexend-VariableFont',
                                                            color: const Color(0xFF5C6C84),
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                              SizedBox(width:20),
                                              SizedBox(
                                                width:120,
                                                child: Text(
                                                  '$currencySymbol ${balanceList[index].toStringAsFixed(2)}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontFamily: 'Lexend-VariableFont',
                                                    color: const Color(0xFF3AC6D5),
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                onPressed: () {
                                                  countpercent(selectedyear!, mon[index]);
                                                  getSelectedMonth(mon[index]);
                                                },
                                                style: ButtonStyle(
                                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                                                  shape: MaterialStateProperty.all<OutlinedBorder>(
                                                    RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(30.0),
                                                      side: BorderSide(color: const Color(0xFFAAB2BE)),
                                                    ),
                                                  ),
                                                  elevation: MaterialStateProperty.all<double>(0),
                                                ),
                                                child: Text(
                                                  'View',
                                                  style: TextStyle(
                                                    fontFamily: 'Lexend-VariableFont',
                                                    color: const Color(0xFFAAB2BE),
                                                  ),
                                                ),
                                              ),

                                            ],
                                          ),
                                        ),
                                      ),
                                      if (index < balanceList.length - 1) Divider(height: 0),
                                    ],
                                  );
                                },
                              ),
                            ),
                          );


                        }
                      },
                    ),
                  ),

                ],
              ),
            ],
          ),
        ));
  }
}




