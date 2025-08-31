## Flutter local Notification

# Android Side 
 -  `⚠️  first need to test on physical device not on emulator`

* required some permissisions
* go to path: `android/app/src/main/AndroidManifest.xml`

### 🟢 1. Android Side Permission 
* Required: before <Applicationn> Tag
```xml
     <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

     <!-- for schedualing notifications only -->
     <uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
```

* Required: in `<Applicationn>` Tag
* 📍 1. For  simple
```xml
    <receiver
        android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver"
        android:enabled="true"
        android:exported="false">
        <intent-filter>
            <action android:name="android.intent.action.BOOT_COMPLETED" />
            <action android:name="android.intent.action.MY_PACKAGE_REPLACED" />
        </intent-filter>
    </receiver> 
```

* 📍 2. For schedul notification permision (`if need only`)
```xml
        <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
         <receiver android:exported="false" 
           android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
            <intent-filter>
                <action android:name="android.intent.action.BOOT_COMPLETED"/>
                <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
                <action android:name="android.intent.action.QUICKBOOT_POWERON" />
                <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
            </intent-filter>
        </receiver>
```

### for icon
* better is to `generate icons` from flutter package 
```yaml
dev_dependencies:
  android_notification_icons:
```
* `should be transparent` Iocn other wise sometime not work
```dart
        <meta-data
            android:name="com.dexterous.flutterlocalnotifications.default_notification_icon"
            android:resource="@drawable/ic_notification" />
```

================================================================================
## 🟢 2. Flutter Packages
* add this package
### 2 dependencies:

```dart
 flutter_local_notifications: ^13.0.0
 timezone: ^0.9.3 # for schedual type notifications
```
==================================================================================

## 🟢 3. main.dart page setup

```dart
        # permission: For upto Android version 10
        import 'package:permission_handler/permission_handler.dart';
        # for schedualing notifications
        import 'package:timezone/data/latest.dart' as tz;
```

* make a global variable on main function
```dart
   FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();
```

<code> 
  void main() async {
</code>

```dart
 WidgetsFlutterBinding.ensureInitialized();
    InitializationSettings initializationSettings = const InitializationSettings(
       android: AndroidInitializationSettings("@mipmap/ic_launcher"),
       iOS: DarwinInitializationSettings(
           requestAlertPermission: true,
           requestBadgePermission: true,
           requestCriticalPermission: true,
           requestSoundPermission: true));

    bool? initialized = await notificationsPlugin.initialize(
    // onDidReceiveBackgroundNotificationResponse: (response) {
    //   log("👉 Background BG Notify: $response");
    // },
      initializationSettings, onDidReceiveNotificationResponse: (NotificationResponse response) async {
        log("👉 notificationsPlugin payload: ${response.payload} ");
        
        Map<String, dynamic>? payloadData;
        if (response.payload != null) {
          try {
            payloadData = jsonDecode(response.payload!);
            log("👉 Parsed payload data: $payloadData");
          } catch (e) {
            log("❌ Error parsing payload: $e");
          }
        }

        if(response.actionId == 'close_id'){
            notificationsPlugin.cancel(786);
        } else if(response.actionId == 'reply_id'){
          log("✌replyid input: ${response.input!}" ?? "no input");
          if (payloadData != null) {
            await FirebaseFirestore.instance.collection(DbCollectionNames.usersChats).add({
                  "isRead": false,
                  "toUid": payloadData['toUid'],
                  "fromUid": payloadData['fromUid'],
                  "toUidName":"",
                  "fromUidName": "",
                  "toProfileImg": "",
                  "fromProfileImg": payloadData['toProfile'],
                  "msg": response.input ?? "...",
                  "file": "",
                  "voice": "",
                  "participants": [payloadData['fromUid'], payloadData['toUid']],
                  "date": DateTime.now(),
                  "chatFrom": "newMsg",
                });
          } else {
            log("❌ No payload data available for reply");
          }
        }
    });
   debugPrint("📱 check Initiliazed Notification: $initialized");
```
* for scheduling notifiactions only
```dart
     # permission: For upto Android version 10
     if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
     }
     tz.initializeTimeZones();
```

<code>
   runApp(const Home());
 }
</code>

=============================================================================
# 🟢 4. Make New File 

* for simple notification
 ```dart
 void showNotification(
      {String title = "Title Abc",
      String body = "body Message",
      var data,
      String imageUrl = "https://www.iconpacks.net/icons/2/free-discount-icon-2045-thumb.png"}) async {
    final String largeIconPath = await _downloadAndSaveFile(
        "https://www.iconpacks.net/icons/2/free-discount-icon-2045-thumb.png",
        'largeIcon'); // for right side icon like for brands icon or company icon etc
    final String bigPicturePath = await _downloadAndSaveFile(imageUrl,
        'bigPicture'); // show the large image like for blog post and for description

    await notificationsPlugin.show(
        786,
        title,
        body,

        NotificationDetails(
            android: AndroidNotificationDetails(
              "channel id",
              "Channel name",
              priority: Priority.max,
              importance: Importance.high,
                actions: pageType == "newMsg" ? [
                 AndroidNotificationAction("reply_id", "Reply",
                 allowGeneratedReplies: true,
                 showsUserInterface: true,
                  inputs:[ AndroidNotificationActionInput(
                   label: "Reply...", 
                   allowedMimeTypes : {'text/plain'}
                   )]),
                 AndroidNotificationAction("close_id", "Close"),
               ]: null),
              payload: jsonEncode(data)
              sound: RawResourceAndroidNotificationSound("one_minute") //  Custom Sound From: Android/App/src/main/res/raw/one_minute.mp3
              ///////// optional if need action button on right side
                    actions: [
                           AndroidNotificationAction("reply_id", "Reply",
                           allowGeneratedReplies: true,
                           showsUserInterface: true,
                            inputs:[ AndroidNotificationActionInput(
                             label: "Write Someting", 
                             allowedMimeTypes : {'text/plain'}
                             )]),
                           AndroidNotificationAction("close_id", "Close"),
                  ],
              // optional: for show right side company or brand icon
              largeIcon: FilePathAndroidBitmap(largeIconPath),
              // optional: show the large image like for blog post and for description
              styleInformation: BigPictureStyleInformation(
                FilePathAndroidBitmap(bigPicturePath),
                hideExpandedLargeIcon:
                    false, // if true then large icon on collapse then show if expanded then then hide
                contentTitle: '<b>big</b> content title', // can in html format
                htmlFormatContentTitle: true,
                summaryText: 'summary <i>text</i>', // can in html format
                htmlFormatSummaryText: true,
              ),
            ),
            iOS: const DarwinNotificationDetails(
                presentAlert: true, presentBadge: true, presentSound: true,sound: "one_minute.mp3"), // Custom Sound From: open ios folder in XCode runner in mid section build phase in this in bottom mid copy bundle resources add this wav or .aiff music type file one_minute.wav
            )));
  }
```

* for schedual notifications if need only
```dart
showScehduledNotification(
   {String title = "Title Abc", String body = "body Message", int executionTimeMilliseconds = 1000}) async {
 try {
   await notificationsPlugin.zonedSchedule(
       786,
       title,
       body,
       tz.TZDateTime.now(tz.local).add(Duration(milliseconds: executionTimeMilliseconds)),
       const NotificationDetails(
           android: AndroidNotificationDetails("channel id", "Channel name",
            ///////// optional if need action button on right side
              actions: [
                           AndroidNotificationAction("reply_id", "Reply",
                           allowGeneratedReplies: true,
                           showsUserInterface: true,
                            inputs:[ AndroidNotificationActionInput(
                             label: "Write Someting", 
                             allowedMimeTypes : {'text/plain'}
                             )]),
                           AndroidNotificationAction("close_id", "Close"),
                       ],
               priority: Priority.max, importance: Importance.high, sound: RawResourceAndroidNotificationSound("one_minute"),  // Custom Sound From: Android/App/src/main/res/raw/one_minute.mp3
         ),
           iOS: DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true,sound: "one_minute.mp3"))), //  Custom Sound From: open ios folder in XCode runner in mid section build phase in this in bottom mid copy bundle resources add this wav or .aiff music type file one_minute.wav
       uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
 } catch (e, stackTrace) {
   print("💥 showNotification->tryCatch Error: $e, stackTrace:$stackTrace");
 }
}
```

* cancel all 
```dart
void cancelNotificationF() {
  notificationsPlugin.cancelAll();
}
```

* cancel only one by id 
```dart
void cancelNotificationF({int id = 786}) {
  notificationsPlugin.cancel(id);
}
```
