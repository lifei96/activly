import 'package:card_settings/card_settings.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_http_client.dart';

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
      home: HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  static final String _insideName = 'inside';
  static final String _freqName = 'freq';
  static final String _lengthName = 'length';
  static final String _reminderName = 'reminder';

  static final bool _insideDefault = false;
  static final int _freqDefault = 5;
  static final int _lengthDefault = 60;
  static final int _reminderDefault = 30;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'profile',
      'email',
      'openid',
      'https://www.googleapis.com/auth/calendar',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser _currentUser;

  bool _inside = _insideDefault;
  int _freq = _freqDefault;
  int _length = _lengthDefault;
  int _reminder = _reminderDefault;

  _loadPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _inside = (prefs.getBool(_insideName) ?? _insideDefault);
      _freq = (prefs.getInt(_freqName) ?? _freqDefault);
      _length = (prefs.getInt(_lengthName) ?? _lengthDefault);
      _reminder = (prefs.getInt(_reminderName) ?? _reminderDefault);
    });
    print('preference loaded');
  }

  _savePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_insideName, _inside);
    prefs.setInt(_freqName, _freq);
    prefs.setInt(_lengthName, _length);
    prefs.setInt(_reminderName, _reminder);
    print('preference saved');
  }

  Future<FirebaseUser> _trySignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signInSilently();
    if (googleUser == null) {
      return null;
    }
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print("silently signed in " + user.displayName);
    return user;
  }

  Future<FirebaseUser> _handleSignIn() async {
    GoogleSignInAccount googleUser = await _googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    FirebaseUser user = await _auth.signInWithGoogle(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    print("signed in " + user.displayName);
    return user;
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    print("signed out");
  }

  _showSchedule() async {
    final authHeaders = await _googleSignIn.currentUser.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);

    final startDateTime = DateTime.now().add(Duration(days: 1));
    final startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );

    print('startDate: $startDate');
    print(startDate.timeZoneName);

    for (int i = 0; i < 7; i++) {
      calendar_api.CalendarApi(httpClient).events.list(
        'primary',
        singleEvents: true,
        orderBy: "startTime",
        timeMin: startDate.toUtc().add(Duration(days: i)),
        timeMax: startDate.toUtc().add(Duration(days: i + 1))
      ).then((calendar_api.Events events) {
        print(events.items.length);
        events.items.forEach((calendar_api.Event event) {
          print(event.summary);
          print(event.start.dateTime.toLocal());
        });
      }).catchError((calendar_api.Error error) => print(error.toString()));
    }
  }

  @override
  void initState() {
    super.initState();
    if (_currentUser == null) {
      _trySignIn().then((user) {
        if (user != null) {
          setState(() {
            _currentUser = user;
          });
        }
      });
    }
    _loadPreference();
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance
    // as done by the _increment method above.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    return DefaultTabController(
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
            createWorkoutTabBarView(),
            createSettingsTabBarView(),
          ],
        ),
      ),
    );
  }

  Form createCalendarTabBarView() {
    var signedIn = _currentUser == null? false : true;
    return Form(
      key: Key('calendar_form'),
      child: CardSettings(
        children: <Widget>[
          CardSettingsHeader(
            label: '${(signedIn ? _currentUser.displayName + '\'s ' : '')}Calendar',
          ),
          CardSettingsButton(
            label: 'Current account: ${(signedIn ? _currentUser.email : '')}',
            backgroundColor: Colors.white,
            bottomSpacing: 0.0,
            onPressed: null,
            visible: signedIn,
          ),
          CardSettingsButton(
            label: 'Sign in with Google',
            backgroundColor: Colors.white,
            textColor: Colors.orange[700],
            bottomSpacing: 4.0,
            onPressed: () {
              _handleSignIn()
                .then((FirebaseUser user) {
                  print(user);
                  setState(() {
                    _currentUser = user;
                  });
                })
                .catchError((e) => print(e));
            },
            visible: !signedIn,
          ),
          CardSettingsButton(
            label: 'Sign out',
            backgroundColor: Colors.red[400],
            textColor: Colors.white,
            bottomSpacing: 4.0,
            onPressed: () {
              _handleSignOut()
                .then((result) {
                  print('signed out');
                  setState(() {
                    _currentUser = null;
                  });
                })
                .catchError((e) => print(e));
            },
            visible: signedIn,
          ),
        ],
      ),
    );
  }

  Form createWorkoutTabBarView() {
    var signedIn = _currentUser == null? false : true;
    return Form(
      key: Key('workout_form'),
      child: CardSettings(
        children: <Widget>[
          CardSettingsHeader(
            label: 'Workout Schedule',
          ),
          CardSettingsButton(
            label: 'Go Schedule!',
            backgroundColor: Colors.white,
            textColor: Colors.orange[700],
            bottomSpacing: 4.0,
            onPressed: () {
              _showSchedule();
            },
            visible: signedIn,
          ),
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
            initialValue: _inside,
            onChanged: (bool value) {
              setState(() {
                _inside = value;
              });
            },
          ),
          CardSettingsNumberPicker(
            label: 'Times/Week',
            key: Key('picker_times'),
            initialValue: _freq,
            min: 0,
            max: 7,
            onChanged: (int value) {
              setState(() {
                _freq = value;
              });
            },
          ),
          CardSettingsInt(
            label: 'Length',
            key: Key('int_length'),
            initialValue: _length,
            unitLabel: 'minutes',
            maxLength: 3,
            onChanged: (int value) {
              setState(() {
                _length = value;
              });
            },
          ),
          CardSettingsInt(
            label: 'Reminder',
            key: Key('int_remind'),
            initialValue: _reminder,
            unitLabel: 'minutes before workout',
            maxLength: 3,
            onChanged: (int value) {
              setState(() {
                _reminder = value;
              });
            },
          ),
          CardSettingsButton(
            label: 'Save',
            backgroundColor: Colors.orange[700],
            textColor: Colors.white,
            bottomSpacing: 4.0,
            onPressed: () {
              _savePreference();
            },
          )
        ],
      ),
    );
  }
}