import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TestNewPipeChannel extends StatefulWidget {
  const TestNewPipeChannel({super.key});

  @override
  State<TestNewPipeChannel> createState() => _TestNewPipeChannelState();
}

class _TestNewPipeChannelState extends State<TestNewPipeChannel> {
  static const _channel = MethodChannel('com.myapp/newpipe_data_source');
  String _result = 'Not tested';

  Future<void> _testChannel() async {
    try {
      final result = await _channel.invokeMethod('search', {'query': 'test'});
      setState(() => _result = 'Success: $result');
    } catch (e) {
      setState(() => _result = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test NewPipe Channel')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_result),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _testChannel,
              child: const Text('Test Channel'),
            ),
          ],
        ),
      ),
    );
  }
}
