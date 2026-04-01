import 'package:amethyst/core/data/amethyst_api.dart';
import 'package:amethyst/core/theme/app_colors.dart';
import 'package:amethyst/di/injection.dart';
import 'package:amethyst/features/driver/presentation/widgets/add_return_sheet.dart';
import 'package:flutter/material.dart';

class DriverLoadsPage extends StatefulWidget {
  const DriverLoadsPage({super.key});

  @override
  State<DriverLoadsPage> createState() => _DriverLoadsPageState();
}

class _DriverLoadsPageState extends State<DriverLoadsPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await sl<AmethystApi>().driverCurrentLoad();
      if (!mounted) return;
      setState(() {
        _data = d;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current loads'),
        actions: <Widget>[
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddReturnSheet(context).then((_) => _load()),
        icon: const Icon(Icons.assignment_return),
        label: const Text('Log return'),
        backgroundColor: AppColors.primary,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final vehicle = _data?['vehicle'] as Map<String, dynamic>?;
    final loads = (_data?['loads'] as List<dynamic>? ?? <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (vehicle == null) {
      return const Center(child: Text('No vehicle assigned.'));
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text(
          'Vehicle ${vehicle['vehicleNumber'] ?? ''}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 16),
        if (loads.isEmpty)
          const Text('No open loads.')
        else
          ...loads.map(
            (l) => Card(
              child: ListTile(
                title: Text(l['product']?['name']?.toString() ?? 'Product'),
                subtitle: Text(
                  'Loaded ${l['quantityLoaded']} · Sold ${l['quantitySold']} · '
                  'Returned ${l['quantityReturned']} · Remaining ${l['remaining']}',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
