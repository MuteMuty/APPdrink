import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/subjects.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

NotificationAppLaunchDetails notificationAppLaunchDetails;

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

class Quotes {
  final String quote;
  final String author;

  Quotes({this.quote, this.author});
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  notificationAppLaunchDetails =
      await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

  var initializationSettingsIOS = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = InitializationSettings(
      initializationSettingsAndroid, initializationSettingsIOS);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
    if (payload != null) {
      debugPrint('notification payload: ' + payload);
    }
    selectNotificationSubject.add(payload);
  });
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    ),
  );
}

class PaddedRaisedButton extends StatelessWidget {
  final Text buttonText;
  final Color color;
  final VoidCallback onPressed;
  final RoundedRectangleBorder shape;

  const PaddedRaisedButton({
    @required this.buttonText,
    this.color,
    @required this.onPressed,
    this.shape,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 8.0),
      child: RaisedButton(
        child: buttonText,
        color: color,
        onPressed: onPressed,
        shape: shape,
      ),
    );
  }
}

//Living Coral (#FC766AFF) and Pacific Coast (#5B84B1FF) and green #B7EABC ? red #FF7D95
//yellow ffda8f
final Color myRed = Color(0xFFFF7D95);
final Color myBlue = Color(0xFF5B84B1);
final Color myGreen = Color(0xFFB7EABC);
final Color myYellow = Color(0xFFffda8f);

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _from = "8:00";
  String _to = "20:00";
  /* String _interval = "60"; */
  bool _notifications = true;

  final MethodChannel platform =
      MethodChannel('crossingthestreams.io/resourceResolver');
  @override
  void initState() {
    super.initState();
    _setTime();
    _requestIOSPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecondScreen(),
                  ),
                );
              },
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecondScreen()),
      );
    });
  }

  void _setTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _from = (prefs.getString('from') ?? "8:00");
      _to = (prefs.getString('to') ?? "17:00");
      /* _interval = (prefs.getString('interval') ?? "60"); */
      _notifications = (prefs.getBool('notifications') ?? true);
    });
    await _cancelNotification();
    for (var i = int.parse(_from.substring(0, _from.indexOf(":"))) + 1;
        i <= int.parse(_to.substring(0, _to.indexOf(":"))) && _notifications;
        i++) {
      print(i);
      await _showDaylyAtTime(i);
    }
  }

  void _changeTime(who, time) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('$who', time);
      _setTime();
    });
  }

  void _changeSwitch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setBool('notifications', !_notifications);
      _setTime();
    });
  }

  /* void _changeInterval(inter) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      prefs.setString('interval', inter);
      _setTime();
    });
  } */

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: myBlue,
        appBar: AppBar(
          centerTitle: true,
          title: Text(
            'DRINK',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                letterSpacing: 2,
                color: Colors.black),
          ),
          backgroundColor: myRed,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Hero(
                tag: 'water',
                child: Image.asset(
                  'assets/app_icon.png',
                  scale: 2.5,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: myYellow,
                    color: myRed,
                    child: InkWell(
                      child: Container(
                        height: 100,
                        width: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "FROM",
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  letterSpacing: 2,
                                  color: Colors.black),
                            ),
                            Text(
                              _from,
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  letterSpacing: 2,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          child: CupertinoAlertDialog(
                            title: Column(
                              children: <Widget>[
                                Text("Time to start reminding"),
                                Container(
                                  height: 200,
                                  width: 250,
                                  child: CupertinoDatePicker(
                                    initialDateTime: DateTime(
                                        0,
                                        0,
                                        0,
                                        int.parse(_from.substring(
                                            0, _from.indexOf(":"))),
                                        int.parse(_from.substring(
                                            _from.indexOf(":") + 1))),
                                    use24hFormat: true,
                                    mode: CupertinoDatePickerMode.time,
                                    onDateTimeChanged: (dateTime) {
                                      String minut = dateTime.minute.toString();
                                      if (dateTime.minute < 10) {
                                        minut = "0" + minut;
                                      }
                                      _changeTime(
                                          "from",
                                          dateTime.hour.toString() +
                                              ":" +
                                              minut);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    shadowColor: myYellow,
                    color: myRed,
                    child: InkWell(
                      child: Container(
                        height: 100,
                        width: 150,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Text(
                              "TO",
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  letterSpacing: 2,
                                  color: Colors.black),
                            ),
                            Text(
                              _to,
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 32,
                                  letterSpacing: 2,
                                  color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      onTap: () {
                        showDialog(
                          context: context,
                          child: CupertinoAlertDialog(
                            title: Column(
                              children: <Widget>[
                                Text("Time to stop reminding"),
                                Container(
                                  height: 200,
                                  width: 250,
                                  child: CupertinoDatePicker(
                                    initialDateTime: DateTime(
                                        0,
                                        0,
                                        0,
                                        int.parse(
                                            _to.substring(0, _to.indexOf(":"))),
                                        int.parse(_to
                                            .substring(_to.indexOf(":") + 1))),
                                    use24hFormat: true,
                                    mode: CupertinoDatePickerMode.time,
                                    onDateTimeChanged: (dateTime) {
                                      String minut = dateTime.minute.toString();
                                      if (dateTime.minute < 10) {
                                        minut = "0" + minut;
                                      }
                                      _changeTime(
                                          "to",
                                          dateTime.hour.toString() +
                                              ":" +
                                              minut);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              /* Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: myYellow,
                color: myRed,
                child: InkWell(
                  child: Container(
                    height: 50,
                    width: 350,
                    child: Text(
                      "INTERVAL ${_interval} min",
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                          letterSpacing: 2,
                          color: Colors.black),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      child: CupertinoAlertDialog(
                        title: Column(
                          children: <Widget>[
                            Text("Time between two reminders"),
                            Container(
                              height: 150,
                              width: 250,
                              child: CupertinoPicker(
                                useMagnifier: true,
                                itemExtent: 30,
                                onSelectedItemChanged: (int index) {
                                  print(index);
                                },
                                children: <Widget>[
                                  Text("15 min"),
                                  Text("20 min"),
                                  Text("30 min"),
                                  Text("60 min"),
                                  Text("2 hours"),
                                  Text("3 hours"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ), */
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  PaddedRaisedButton(
                    buttonText: Text(
                      'Notifications',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black),
                    ),
                    color: _notifications ? myGreen : myRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    onPressed: () {
                      _changeSwitch();
                    },
                  ),
                  CupertinoSwitch(
                    value: _notifications,
                    onChanged: (value) {
                      _changeSwitch();
                    },
                    activeColor: myGreen,
                    trackColor: myRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'drinkId',
      'Drink',
      'Refresh yourself',
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'drink',
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'Drink now!',
      'Refresh yourself.',
      platformChannelSpecifics,
    );
  } */

  Future<void> _showDaylyAtTime(int hour) async {
    var time = Time(hour, 0, 0);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'drinkId',
      'Drink',
      'Refresh yourself',
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'drink',
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.showDailyAtTime(
      0,
      'Drink now!',
      'Refresh yourself.',
      time,
      platformChannelSpecifics,
    );
  }

  /* Future<void> _showInsistentNotification() async {
    var insistentFlag = 4;
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'drinkId',
      'Drink',
      'Refresh yourself',
      importance: Importance.Max,
      priority: Priority.High,
      ticker: 'drink',
      additionalFlags: Int32List.fromList([insistentFlag]),
    );
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      /* periodicallyShow */
      0,
      'Drink now!',
      'Refresh yourself.',
      /*RepeatInterval.EveryMinute, */
      platformChannelSpecifics,
    );
  } */

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

class SecondScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => SecondScreenState();
}

class SecondScreenState extends State<SecondScreen> {
  List<Quotes> quotes = <Quotes>[
    Quotes(
        quote:
            'Drinking water is like washing out your insides. The water will cleanse the system, fill you up, decrease your caloric load and improve the function of all your tissues.',
        author: 'Kevin R. Stone'),
    Quotes(
        quote: 'If there is magic on this planet, it is contained in water.',
        author: 'Loren Eiseley'),
    Quotes(
        quote:
            'Water is life\'s matter and matrix, mother and medium. There is no life without water.',
        author: 'Albert Szent-Gyorgyi'),
    Quotes(
        quote: 'I believe that water is the only drink for a wise man.',
        author: 'Henry David Thoreau'),
    Quotes(quote: 'Water is the soul of the Earth.', author: 'W. H. Auden'),
    Quotes(
        quote: 'Thousands have lived without love, not one without water.',
        author: 'W. H. Auden'),
    Quotes(
        quote:
            'Wanna lose 1200 Calories a month? Drink a liter of ice water a day. You burn the energy just raising the water to body temp.',
        author: 'Neil deGrasse Tyson'),
    Quotes(quote: 'Water is the best of all things.', author: 'Pindar'),
    Quotes(
        quote:
            'Anyone who can solve the problems of water will be worthy of two Nobel prizes - one for peace and one for science.',
        author: 'John F. Kennedy'),
    Quotes(
        quote: 'We forget that the water cycle and the life cycle are one.',
        author: 'Jacques Yves Cousteau'),
    Quotes(
        quote: 'Whiskey is for drinking; water is for fighting over.',
        author: 'Mark Twain'),
    Quotes(
        quote:
            'Thirst drove me down to the water\nwhere I drank the moon\'s reflection.',
        author: 'Rumi'),
    Quotes(
        quote:
            'The health of our waters is the principle measure of how we live on the land.',
        author: 'Luna Leopold'),
    Quotes(
        quote: 'We never know the worth of water till the well is dry.',
        author: 'Thomas Fuller'),
    Quotes(
        quote:
            'I fear the man who drinks water and so remembers this morning what the rest of us said last night',
        author: 'Benjamin Franklin'),
    Quotes(
        quote:
            'Water, thou hast no taste, no color, no odor; canst not be defined, art relished while ever mysterious. Not necessary to life, but rather life itself, thou fillest us with a gratification that exceeds the delight of the senses.',
        author: 'Antoine de Saint-Exupery'),
    Quotes(
        quote:
            'For many of us, water simply flows from a faucet, and we think little about it beyond this point of contact. We have lost a sense of respect for the wild river, for the complex workings of a wetland, for the intricate web of life that water supports.',
        author: 'Sandra Postel'),
    Quotes(
        quote:
            'What makes the desert beautiful is that somewhere it hides a well.',
        author: 'Antoine de Saint-Exupery'),
    Quotes(
        quote:
            'The true practice to meditation is to sit as if you where drinking water when you are thirsty.',
        author: 'Shunryu Suzuki'),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    int len = quotes.length;
    Random rand = new Random();
    int now = rand.nextInt(len);
    return Scaffold(
      backgroundColor: myBlue,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: myRed,
        title: Text(
          'Nice job, refreshing!',
          style: GoogleFonts.dmSans(
              fontWeight: FontWeight.bold, fontSize: 26, color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Hero(
              tag: 'water',
              child: Image.asset(
                'assets/app_icon.png',
                scale: 3,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Text(
                '"${quotes[now].quote}"',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.black),
              ),
            ),
            Text(
              '~ ${quotes[now].author}',
              style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              color: myGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Go back!',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
