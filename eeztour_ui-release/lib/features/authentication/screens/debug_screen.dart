// screens/debug_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../common/config.dart';
import '../controllers/api_service.dart';
import '../controllers/auth_controller.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  Map<String, dynamic> _sharedPrefsData = {};
  Map<String, dynamic> _providerData = {};
  String _apiTestResult = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugData();
  }

  Future<void> _loadDebugData() async {
    await _loadSharedPreferencesData();
    _loadProviderData();
  }

  Future<void> _loadSharedPreferencesData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      Map<String, dynamic> data = {};
      for (String key in keys) {
        final value = prefs.get(key);
        data[key] = value;
      }

      setState(() {
        _sharedPrefsData = data;
      });
    } catch (e) {
      print('Error loading SharedPreferences: $e');
    }
  }

  void _loadProviderData() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() {
      _providerData = {
        'userId': userProvider.userId,
        'accessToken': userProvider.accessToken,
        'tokenType': userProvider.tokenType,
        'username': userProvider.username,
        'email': userProvider.email,
        'roleId': userProvider.roleId,
        'isAuthenticated': userProvider.isAuthenticated,
        'authHeaders': userProvider.authHeaders,
      };
    });
  }

  Future<void> _testApiCall() async {
    setState(() {
      _isLoading = true;
      _apiTestResult = 'Testing API call...';
    });

    try {
      // Test a simple API call that requires authentication
      // Replace '/users/profile' with an actual endpoint from your API
      final response = await ApiService.get('/users/profile', context: context);

      setState(() {
        _apiTestResult = '''
API Test Result:
Status Code: ${response.statusCode}
Headers: ${response.headers}
Body: ${response.body}
''';
      });
    } catch (e) {
      setState(() {
        _apiTestResult = 'API Test Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.clearUser();

      // Reload debug data
      await _loadDebugData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }

  Future<void> _reloadProviderFromPrefs() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.loadUser();
      _loadProviderData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider reloaded from SharedPreferences!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error reloading provider: $e')),
      );
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  Widget _buildSection(String title, Map<String, dynamic> data) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(data.toString()),
                  tooltip: 'Copy to clipboard',
                ),
              ],
            ),
            const Divider(),
            if (data.isEmpty)
              const Text(
                'No data found',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              )
            else
              ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        entry.value?.toString() ?? 'null',
                        style: TextStyle(
                          color: entry.value == null ? Colors.red : Colors.black,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildApiTestSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'API Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const Divider(),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testApiCall,
              icon: _isLoading
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.api),
              label: Text(_isLoading ? 'Testing...' : 'Test API Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            if (_apiTestResult.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SelectableText(
                  _apiTestResult,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugData,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: _providerData['isAuthenticated'] == true
                        ? Colors.green[100]
                        : Colors.red[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            _providerData['isAuthenticated'] == true
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: _providerData['isAuthenticated'] == true
                                ? Colors.green
                                : Colors.red,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _providerData['isAuthenticated'] == true
                                ? 'Authenticated'
                                : 'Not Authenticated',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    color: _sharedPrefsData.isNotEmpty
                        ? Colors.blue[100]
                        : Colors.orange[100],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            _sharedPrefsData.isNotEmpty
                                ? Icons.storage
                                : Icons.storage_outlined,
                            color: _sharedPrefsData.isNotEmpty
                                ? Colors.blue
                                : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_sharedPrefsData.length} Items Stored',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _reloadProviderFromPrefs,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Provider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  icon: const Icon(Icons.login),
                  label: const Text('Go to Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Data Sections
            _buildSection('UserProvider Data', _providerData),
            _buildSection('SharedPreferences Data', _sharedPrefsData),
            _buildApiTestSection(),

            // Additional Info
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Navigation Routes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const Divider(),
                    if (_providerData['roleId'] != null)
                      Text('Current Route: ${AuthController.getNavigationRoute(_providerData['roleId'])}'),
                    const SizedBox(height: 8),
                    const Text('Available Routes:'),
                    const Text('• Role 1 (Admin): /admin'),
                    const Text('• Role 3 (User): /homescreen'),
                    const Text('• Default: /home'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}