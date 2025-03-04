import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dangerous Permissions Viewer',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const platform = MethodChannel('permission_channel');
  List<Map<String, dynamic>> userApps = [];
  List<Map<String, dynamic>> systemApps = [];

  // List of dangerous permissions
  final List<String> dangerousPermissions = [
    "android.permission.READ_CALENDAR",
    "android.permission.WRITE_CALENDAR",
    "android.permission.CAMERA",
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.GET_ACCOUNTS",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.RECORD_AUDIO",
    "android.permission.READ_PHONE_STATE",
    "android.permission.READ_PHONE_NUMBERS",
    "android.permission.CALL_PHONE",
    "android.permission.ANSWER_PHONE_CALLS",
    "android.permission.READ_CALL_LOG",
    "android.permission.WRITE_CALL_LOG",
    "android.permission.ADD_VOICEMAIL",
    "android.permission.USE_SIP",
    "android.permission.PROCESS_OUTGOING_CALLS",
    "android.permission.BODY_SENSORS",
    "android.permission.SEND_SMS",
    "android.permission.RECEIVE_SMS",
    "android.permission.READ_SMS",
    "android.permission.RECEIVE_WAP_PUSH",
    "android.permission.RECEIVE_MMS",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
  ];

  @override
  void initState() {
    super.initState();
    _getInstalledApps();
  }

  Future<void> _getInstalledApps() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getInstalledApps');
      List<Map<String, dynamic>> apps = List<Map<String, dynamic>>.from(
          result.map((app) => Map<String, dynamic>.from(app)));

      List<Map<String, dynamic>> filteredUserApps = [];
      List<Map<String, dynamic>> filteredSystemApps = [];

      for (var app in apps) {
        String packageName = app['packageName'];
        bool isSystemApp = app['isSystemApp'];
        List<dynamic> permissions = app['permissions'] ?? [];

        // Check if the app has at least one dangerous permission
        bool hasDangerousPermission = permissions.any(
                (perm) => dangerousPermissions.contains(perm));

        if (!hasDangerousPermission) {
          continue; // Skip apps without dangerous permissions
        }

        if (!isSystemApp &&
            !packageName.startsWith('android.') &&
            !packageName.startsWith('com.google.android.')) {
          filteredUserApps.add(app);
        } else {
          filteredSystemApps.add(app);
        }
      }

      setState(() {
        userApps = filteredUserApps;
        systemApps = filteredSystemApps;
      });
    } on PlatformException catch (e) {
      print("Failed to get installed apps: '${e.message}'");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dangerous Permission Apps')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('User Apps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ...userApps.map((app) => _buildAppTile(app)),

            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('System Apps', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            ...systemApps.map((app) => _buildAppTile(app)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(Map<String, dynamic> app) {
    List<dynamic> permissions = app['permissions'] ?? [];
    List<String> dangerousPerms = permissions
        .where((perm) => dangerousPermissions.contains(perm))
        .cast<String>()
        .toList();
    int dangerousPermCount = dangerousPerms.length;

    return ExpansionTile(
      title: Text(app['packageName']),
      subtitle: Text('${app['appName']} • $dangerousPermCount dangerous permissions'),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Dangerous Permissions:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        ...dangerousPerms.map((perm) => ListTile(title: Text(perm))),
      ],
    );
  }
}
