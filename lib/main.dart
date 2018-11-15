import 'package:flutter/material.dart';
import 'package:card_settings/card_settings.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'profile',
      'email',
      'openid',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirebaseUser _currentUser;

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


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance
    // as done by the _increment method above.
    // The Flutter framework has been optimized to make rerunning
    // build methods fast, so that you can just rebuild anything that
    // needs updating rather than having to individually change
    // instances of widgets.
    if (_currentUser == null) {
      _trySignIn().then((user) {
        if (user != null) {
          setState(() {
            _currentUser = user;
          });
        }
      });
    }
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
            Icon(Icons.directions_run),
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
            label: 'Calendar',
          ),
          CardSettingsButton(
            label: 'Current account: ' + (signedIn ? _currentUser.email : ''),
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
}