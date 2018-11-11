import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activ.ly',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primaryColor: Colors.orange,
        accentColor: Colors.orangeAccent,
        backgroundColor: Colors.white,
        buttonColor: Colors.orange,
        buttonTheme: ButtonThemeData(
          textTheme: ButtonTextTheme.primary,
        ),
        indicatorColor: Colors.white,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.calendar_today)),
                Tab(icon: Icon(Icons.comment)),
                Tab(icon: Icon(Icons.directions_run)),
              ],
            ),
            title: Text('Activ.ly'),
          ),
          body: TabBarView(
            children: [
              createCalendarTabBarView(),
              Icon(Icons.directions_transit),
              Icon(Icons.directions_bike),
            ],
          ),
        ),
      ),
    );
  }

  Column createCalendarTabBarView() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RaisedButton(
            onPressed: importGoogleCalender,
            child: Text('Import Google Calendar'),
          )
        ],
      );
  }

  void importGoogleCalender() {

  }
}