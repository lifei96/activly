import 'package:flutter/material.dart';
import 'package:card_settings/card_settings.dart';

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
        primaryColor: Colors.orange[800],
        accentColor: Colors.orange[700],
        backgroundColor: Colors.white,
        buttonColor: Colors.orange[700],
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
                Tab(icon: Icon(Icons.directions_run)),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: Text('Activ.ly'),
          ),
          body: TabBarView(
            children: [
              createCalendarTabBarView(),
              Icon(Icons.directions_run),
              createSettingsTabBarView(),
            ],
          ),
        ),
      ),
    );
  }

  Form createCalendarTabBarView() {
    return Form(
      key: Key('calendar_form'),
      child: CardSettings(
        children: <Widget>[
          CardSettingsHeader(
            label: 'Calendar',
          ),
          CardSettingsButton(
            label: 'Sign in with Google',
            backgroundColor: Colors.white,
            textColor: Colors.orange[700],
            bottomSpacing: 4.0,
            onPressed: () {

            },
          )
        ],
      ),
    );
  }

  Form createSettingsTabBarView() {
    return Form(
      key: Key('settings_form'),
      child: CardSettings(
        children: <Widget>[
          CardSettingsHeader(
            label: 'Workout Preference',
          ),
          CardSettingsSwitch(
            label: 'Inside?',
            key: Key('switch_inside'),
            initialValue: false,
            onSaved: (bool value) {

            },
          ),
          CardSettingsNumberPicker(
            label: 'Times/Week',
            key: Key('picker_times'),
            initialValue: 5,
            min: 0,
            max: 7,
            onSaved: (int value) {

            },
          ),
          CardSettingsInt(
            label: 'Length/Time',
            key: Key('int_length'),
            initialValue: 60,
            unitLabel: 'minutes',
            maxLength: 3,
            onSaved: (int value) {

            },
          ),
          CardSettingsInt(
            label: 'Reminder',
            key: Key('int_remind'),
            initialValue: 30,
            unitLabel: 'minutes before workout',
            maxLength: 3,
            onSaved: (int value) {

            },
          ),
          CardSettingsButton(
            label: 'Save',
            backgroundColor: Colors.orange[700],
            textColor: Colors.white,
            bottomSpacing: 4.0,
            onPressed: () {

            },
          )
        ],
      ),
    );
  }

  void importGoogleCalender() {

  }

}