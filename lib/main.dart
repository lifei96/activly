import 'dart:convert';
import 'dart:math';
import 'package:card_settings/card_settings.dart';
import 'package:googleapis/calendar/v3.dart' as calendar_api;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
  static final String _startTimeName = 'start_time';
  static final String _endTimeName = 'end_time';

  static final bool _insideDefault = true;
  static final int _freqDefault = 5;
  static final int _lengthDefault = 60;
  static final int _reminderDefault = 30;
  static final int _startTimeDefault = 8;
  static final int _endTimeDefault = 22;

  static final String _accuweatherUrl =
    'http://apidev.accuweather.com/forecasts/v1/hourly/240hour/349727?'
    'apikey=4bcffe798a234fd1a7eae74871328918';

  static final List<int> _goodWeatherNum = [
    1, 2, 3, 4, 5, 6, 7, 8, 33, 34, 35, 36];

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
  int _startTime = _startTimeDefault;
  int _endTime = _endTimeDefault;

  List<List<DateTime>> _slots = [];

  List<DateTime> _schedule = [];
  List<String> _weather = [];

  _loadPreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _inside = (prefs.getBool(_insideName) ?? _insideDefault);
      _freq = (prefs.getInt(_freqName) ?? _freqDefault);
      _length = (prefs.getInt(_lengthName) ?? _lengthDefault);
      _reminder = (prefs.getInt(_reminderName) ?? _reminderDefault);
      _startTime = (prefs.getInt(_startTimeName) ?? _startTimeDefault);
      _endTime = (prefs.getInt(_endTimeName) ?? _endTimeDefault);
    });
    print('preference loaded');
  }

  _savePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(_insideName, _inside);
    prefs.setInt(_freqName, _freq);
    prefs.setInt(_lengthName, _length);
    prefs.setInt(_reminderName, _reminder);
    prefs.setInt(_startTimeName, _startTime);
    prefs.setInt(_endTimeName, _endTime);
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

  Map<DateTime, dynamic> _processWeatherResponse(
    http.Response weatherResponse) {
    var responseBody = json.decode(weatherResponse.body);
    Map<DateTime, dynamic> res = {};
    try {
      for (final hourlyForecast in responseBody) {
        res[DateTime.parse(
          hourlyForecast['DateTime']).toUtc()] = hourlyForecast;
      }
    } catch (error) {
      print(error.toString());
    }
    return res;
  }

  _showSchedule() async {
    Future<http.Response> weatherFuture = http.get(_accuweatherUrl);
    setState(() {
      _schedule = [];
      _weather = [];
    });
    final authHeaders = await _googleSignIn.currentUser.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);

    final startDateTime = DateTime.now().add(Duration(days: 1));
    final startDate = DateTime(
      startDateTime.year,
      startDateTime.month,
      startDateTime.day,
    );

    List<List<DateTime>> slots = [];

    http.Response weatherResponse = await weatherFuture;
    Map<DateTime, dynamic> weatherDict = _processWeatherResponse(
      weatherResponse);

    for (int i = 0; i < 7; i++) {
      calendar_api.Events events = await calendar_api.CalendarApi(
        httpClient).events.list(
        'primary',
        singleEvents: true,
        orderBy: "startTime",
        timeMin: startDate.toUtc().add(Duration(days: i)),
        timeMax: startDate.toUtc().add(Duration(days: i + 1))
      );
      List<DateTime> curSlots = _generateDailySchedule(
        startDate.toUtc().add(Duration(days: i)),
        events,
        weatherDict,
      );
      if (curSlots.length > 0) {
        slots.add(curSlots);
        print(curSlots.length);
      }
    }

    setState(() {
      _slots = slots;
    });

    _displaySchedule(weatherDict);
  }

  List<DateTime> _generateDailySchedule(
    DateTime curDate,
    calendar_api.Events events,
    Map<DateTime, dynamic> weatherDict) {
    List<DateTime> res = [];
    DateTime curDateTime = curDate.add(Duration(hours: _startTime));
    while (curDateTime.add(Duration(minutes: _length)).isBefore(
      curDate.add(Duration(hours: _endTime)))) {
      if (_isFree(curDateTime, events) &&
        (_inside || _isGoodWeather(curDateTime, weatherDict))) {
        res.add(curDateTime);
      }
      curDateTime = curDateTime.add(Duration(minutes: 5));
    }
    return res;
  }

  bool _isFree(DateTime curDateTime, calendar_api.Events events) {
    for(final event in events.items) {
      if (event.start.dateTime.compareTo(curDateTime) >= 0
        && event.start.dateTime.compareTo(
          curDateTime.add(Duration(minutes: _length))) <= 0) {
        return false;
      }
      if (event.end.dateTime.compareTo(curDateTime) >= 0
        && event.end.dateTime.compareTo(
          curDateTime.add(Duration(minutes: _length))) <= 0) {
        return false;
      }
      if (curDateTime.compareTo(event.start.dateTime) >= 0
        && curDateTime.compareTo(event.end.dateTime) <= 0) {
        return false;
      }
      if (curDateTime.add(Duration(minutes: _length)).compareTo(
        event.start.dateTime) >= 0
        && curDateTime.add(Duration(minutes: _length)).compareTo(
          event.end.dateTime) <= 0) {
        return false;
      }
    }
    return true;
  }

  bool _isGoodWeather(
    DateTime curDateTime, Map<DateTime, dynamic> weatherDict) {
    DateTime key = _weatherDictKey(curDateTime);
    if (weatherDict.containsKey(key)
      && !_goodWeatherNum.contains(weatherDict[key]['WeatherIcon'])) {
      return false;
    }
    return true;
  }

  DateTime _weatherDictKey(DateTime curDateTime) {
    return DateTime(
      curDateTime.year,
      curDateTime.month,
      curDateTime.day,
      curDateTime.hour).toUtc();
  }

  _displaySchedule(Map<DateTime, dynamic> weatherDict) {
    var rnd = Random(DateTime.now().millisecondsSinceEpoch);
    List<DateTime> resSchedule = [];
    List<String> resWeather = [];
    List<List<DateTime>> slots = _slots;
    slots.shuffle();
    for (int i = 0; i < min(_freq, slots.length); i++) {
      resSchedule.add(slots[i][rnd.nextInt(slots[i].length)]);
      DateTime key = _weatherDictKey(resSchedule.last);
      if (weatherDict.containsKey(key)) {
        resWeather.add(
          weatherDict[key]['IconPhrase']
            + ', '
            + weatherDict[key]['Temperature']['Value'].toInt().toString()
            + '°F'
        );
      }
    }
    resSchedule.sort();
    resSchedule.forEach((dateTime) => print(dateTime.toLocal()));
    setState(() {
      _schedule = resSchedule;
      _weather = resWeather;
    });
  }

  _addCalendar() async {
    final authHeaders = await _googleSignIn.currentUser.authHeaders;
    final httpClient = GoogleHttpClient(authHeaders);
    for (int i = 0; i < _schedule.length; i++) {
      calendar_api.Event event = calendar_api.Event.fromJson(
        {
          'summary': 'Workout with Activ.ly',
          'description': 'Workout powered by Activ.ly.',
          'start': {
            'dateTime': _schedule[i].toLocal().toIso8601String(),
            'timeZone': _schedule[i].toLocal().timeZoneName,
          },
          'end': {
            'dateTime': _schedule[i].add(
              Duration(minutes: _length)).toLocal().toIso8601String(),
            'timeZone': _schedule[i].toLocal().timeZoneName,
          },
          'attendees': [
            {'email': _currentUser.email},
            {'email': 'activly@googlegroups.com'},
          ],
          'reminders': {
            'useDefault': false,
            'overrides': [
              {'method': 'email', 'minutes': _reminder},
              {'method': 'popup', 'minutes': _reminder},
            ],
          },
        }
      );
      calendar_api.Event insertedEvent = await calendar_api
        .CalendarApi(httpClient).events.insert(
        event,
        'primary',
        sendNotifications: true,
      );
      if (insertedEvent != null) {
        print('inserted ${_schedule[i].toLocal().toIso8601String()}');
      }
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
            label:
            '${(signedIn ? _currentUser.displayName + '\'s ' : '')}Calendar',
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
    List<Widget> children = [];
    children.add(
      CardSettingsHeader(
        label: 'Workout Schedule',
      )
    );
    if (!signedIn) {
      children.add(
        CardSettingsButton(
          label: 'Please sign in first!',
          backgroundColor: Colors.white,
          onPressed: null,
          bottomSpacing: 1.0,
          visible: !signedIn,
        )
      );
    }
    if (_schedule.length <= 0) {
      children.add(
        CardSettingsButton(
          label: 'You don\'t have schedule currently',
          backgroundColor: Colors.white,
          onPressed: null,
          bottomSpacing: 1.0,
          visible: signedIn,
        )
      );
    }
    var MEd_formatter = DateFormat('MEd');
    var jm_formatter = DateFormat('jm');
    for (int i = 0; i < _schedule.length; i++) {
      final dateTime = _schedule[i];
      String label = MEd_formatter.format(dateTime.toLocal())
        + ', '
        + jm_formatter.format(dateTime.toLocal())
        + ' - '
        + jm_formatter.format(
          dateTime.toLocal().add(Duration(minutes: _length)));
      if (_weather.length == _schedule.length) {
        label += '\n' + (' ' * ((label.length - _weather[i].length - 1))) + _weather[i];
      }
      children.add(
        CardSettingsButton(
          label: label,
          backgroundColor: Colors.white,
          onPressed: null,
          bottomSpacing: 1.0,
        )
      );
    }
    if (_schedule.length > 0) {
      children.add(
        CardSettingsButton(
          label: 'Add to Google Calendar!',
          backgroundColor: Colors.orange[700],
          textColor: Colors.white,
          bottomSpacing: 4.0,
          onPressed: () {
            _addCalendar();
          },
          visible: signedIn,
        )
      );
    }
    children.add(
      CardSettingsButton(
        label: _schedule.length > 0 ? 'Reschedule Now!' : 'Schedule Now!',
        backgroundColor: Colors.orange[500],
        textColor: Colors.white,
        bottomSpacing: 4.0,
        onPressed: () {
          _showSchedule();
        },
        visible: signedIn,
      )
    );
    return Form(
      key: Key('workout_form'),
      child: CardSettings(
        children: children,
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
            label: 'Outside?',
            key: Key('switch_outside'),
            initialValue: !_inside,
            onChanged: (bool value) {
              setState(() {
                _inside = !value;
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
          CardSettingsInt(
            label: 'Earliest Time',
            key: Key('int_earliest'),
            initialValue: _startTime,
            unitLabel: "o'clock",
            maxLength: 2,
            onChanged: (int value) {
              setState(() {
                _startTime = value;
              });
            },
          ),
          CardSettingsInt(
            label: 'Latest Time',
            key: Key('int_latest'),
            initialValue: _endTime,
            unitLabel: "o'clock",
            maxLength: 2,
            onChanged: (int value) {
              setState(() {
                _endTime = value;
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