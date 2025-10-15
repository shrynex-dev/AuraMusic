import 'package:flutter/material.dart';

class DataSourceSettingsPage extends StatelessWidget {
  const DataSourceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Source Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('YouTube (NewPipe)'),
            subtitle: const Text('Primary music source via YouTube'),
            trailing: const Icon(Icons.check_circle, color: Colors.green),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text('Archive.org'),
            subtitle: const Text('Fallback source for rare tracks'),
            trailing: const Icon(Icons.info_outline),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'AuraMusic uses YouTube as the primary source and Archive.org as fallback for better music discovery.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
