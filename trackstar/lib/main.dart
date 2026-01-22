// TEMPORARY main.dart - runs location_test
// Replace lib/main.dart with this temporarily
// Remember to restore original main.dart after testing!

import 'package:flutter/material.dart';
import 'package:trackstar/services/location_service.dart';

void main() {
  runApp(const TrackStarApp());
}

class TrackStarApp extends StatelessWidget {
  const TrackStarApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LocationTestScreen(),
    );
  }
}

class LocationTestScreen extends StatefulWidget {
  const LocationTestScreen({Key? key}) : super(key: key);

  @override
  State<LocationTestScreen> createState() => _LocationTestScreenState();
}

class _LocationTestScreenState extends State<LocationTestScreen> {
  final LocationService _locationService = LocationService.instance;
  String _output = 'Pritisnite dugme da pokrenete test lokacije';
  bool _isTesting = false;
  bool _testComplete = false;

  Future<void> _runTest() async {
    setState(() {
      _isTesting = true;
      _testComplete = false;
      _output = 'LOCATION SERVICE TEST\n';
      _output += 'MORA DA SE KREĆETE!\n\n';
    });

    try {
      _addOutput('Test 1: Provera dozvola...\n');
      final hasPermission = await _locationService.checkPermissions();
      
      if (!hasPermission) {
        _addOutput('\nGREŠKA: Nema dozvole za lokaciju\n');
        _addOutput('Omogućite lokaciju u podešavanjima.\n');
        setState(() => _isTesting = false);
        return;
      }
      
      _addOutput('Dozvole odobrene!\n\n');

      _addOutput('Test 2: Trenutna pozicija...\n');
      final currentPos = await _locationService.getCurrentPosition();
      
      if (currentPos == null) {
        _addOutput('GREŠKA: Ne mogu da dobijem poziciju\n');
        setState(() => _isTesting = false);
        return;
      }
      
      _addOutput('Pozicija dobijena!\n');
      _addOutput('Lat: ${currentPos.latitude.toStringAsFixed(6)}\n');
      _addOutput('Lng: ${currentPos.longitude.toStringAsFixed(6)}\n');
      _addOutput('Preciznost: ${currentPos.accuracy.toStringAsFixed(1)}m\n\n');

      _addOutput('Test 3: Pokretanje praćenja...\n');
      _addOutput('Trajanje: 30 sekundi\n');
      _addOutput('HODAJTE da vidite promene!\n\n');
      
      final started = await _locationService.startTracking();
      
      if (!started) {
        _addOutput('GREŠKA: Ne mogu da pokrenem praćenje\n');
        setState(() => _isTesting = false);
        return;
      }
      
      _addOutput('Praćenje pokrenuto!\n\n');

      _addOutput('Test 4: Praćenje podataka...\n\n');
      
      for (int i = 1; i <= 6; i++) {
        await Future.delayed(const Duration(seconds: 5));
        
        _addOutput('--- ${i * 5} sekundi ---\n');
        _addOutput('Distanca: ${_locationService.totalDistance.toStringAsFixed(3)} km\n');
        _addOutput('Brzina: ${_locationService.currentSpeed.toStringAsFixed(1)} km/h\n');
        _addOutput('Trajanje: ${_locationService.duration}s\n');
        _addOutput('Pozicije: ${_locationService.positions.length}\n\n');
      }

      _addOutput('Test 5: Zaustavljanje...\n');
      await _locationService.stopTracking();
      _addOutput('Praćenje zaustavljeno!\n\n');

      _addOutput('========================================\n');
      _addOutput('KONAČNI REZULTATI\n');
      _addOutput('========================================\n');
      _addOutput('Ukupna distanca: ${_locationService.totalDistance.toStringAsFixed(3)} km\n');
      _addOutput('Ukupno trajanje: ${_locationService.duration}s\n');
      _addOutput('Ukupno pozicija: ${_locationService.positions.length}\n\n');
      
      if (_locationService.totalDistance > 0.01) {
        _addOutput('SVI TESTOVI USPEŠNI!\n');
        _addOutput('GPS praćenje radi ispravno!\n');
      } else {
        _addOutput('TESTOVI ZAVRŠENI ALI NEMA KRETANJA\n');
        _addOutput('Morate se KRETATI da bi praćenje radilo!\n');
      }

      setState(() {
        _testComplete = true;
        _isTesting = false;
      });

    } catch (e) {
      _addOutput('\nGREŠKA: $e\n');
      setState(() => _isTesting = false);
    }
  }

  void _addOutput(String text) {
    setState(() {
      _output += text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test Lokacije',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Testirajte GPS praćenje. MORATE se kretati (hodati) tokom testa!',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _isTesting ? null : _runTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.all(16),
              ),
              child: _isTesting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Pokreni Test (30s)',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
            ),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _output,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
