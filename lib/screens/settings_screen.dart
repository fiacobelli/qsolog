import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../app_themes.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Station'),
            Tab(icon: Icon(Icons.radio), text: 'Rig'),
            Tab(icon: Icon(Icons.cloud), text: 'QRZ'),
            Tab(icon: Icon(Icons.tune), text: 'Prefs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _StationTab(),
          _RigTab(),
          _QrzTab(),
          _PrefsTab(),
        ],
      ),
    );
  }
}

class _StationTab extends StatefulWidget {
  const _StationTab();
  @override
  State<_StationTab> createState() => _StationTabState();
}

class _StationTabState extends State<_StationTab> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _callCtrl, _nameCtrl, _qthCtrl, _gridCtrl, _latCtrl, _lonCtrl;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().station;
    _callCtrl = TextEditingController(text: s.callsign);
    _nameCtrl = TextEditingController(text: s.operatorName);
    _qthCtrl = TextEditingController(text: s.qth);
    _gridCtrl = TextEditingController(text: s.grid);
    _latCtrl = TextEditingController(text: s.lat?.toString() ?? '');
    _lonCtrl = TextEditingController(text: s.lon?.toString() ?? '');
  }

  @override
  void dispose() {
    for (final c in [_callCtrl, _nameCtrl, _qthCtrl, _gridCtrl, _latCtrl, _lonCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    await state.saveStation(StationSettings(
      callsign: _callCtrl.text.trim().toUpperCase(),
      operatorName: _nameCtrl.text.trim(),
      qth: _qthCtrl.text.trim(),
      grid: _gridCtrl.text.trim().toUpperCase(),
      lat: double.tryParse(_latCtrl.text),
      lon: double.tryParse(_lonCtrl.text),
      activeRigId: state.station.activeRigId,
    ));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Station settings saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextFormField(
              controller: _callCtrl,
              decoration: const InputDecoration(labelText: 'My Callsign', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Operator Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _qthCtrl,
              decoration: const InputDecoration(labelText: 'QTH / Location', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gridCtrl,
              decoration: const InputDecoration(labelText: 'Grid Square (e.g. EM73)', border: OutlineInputBorder()),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lonCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _save, child: const Text('Save Station Settings'))),
          ],
        ),
      ),
    );
  }
}

class _RigTab extends StatefulWidget {
  const _RigTab();
  @override
  State<_RigTab> createState() => _RigTabState();
}

class _RigTabState extends State<_RigTab> {
  late List<RigDefinition> _rigs;
  late String _activeRigId;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _rigs = List.from(state.rigs);
    _activeRigId = state.station.activeRigId;
  }

  void _addRig() => _showRigDialog();

  void _editRig(int i) => _showRigDialog(index: i);

  void _showRigDialog({int? index}) {
    final existing = index != null ? _rigs[index] : null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final powerCtrl = TextEditingController(text: existing?.power.toStringAsFixed(0) ?? '100');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(existing != null ? 'Edit Rig' : 'Add Rig'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Rig Name',
                hintText: 'e.g. Icom IC-7300',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: powerCtrl,
              decoration: const InputDecoration(
                labelText: 'Power (Watts)',
                border: OutlineInputBorder(),
                suffixText: 'W',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                if (existing != null) {
                  _rigs[index!] = RigDefinition(
                    id: existing.id,
                    name: nameCtrl.text.trim(),
                    power: double.tryParse(powerCtrl.text) ?? 100,
                  );
                } else {
                  final newRig = RigDefinition(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    power: double.tryParse(powerCtrl.text) ?? 100,
                  );
                  _rigs.add(newRig);
                  // Auto-select if first rig
                  if (_rigs.length == 1) _activeRigId = newRig.id;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.saveRigs(_rigs);
    await state.setActiveRig(_activeRigId);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rigs saved')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: _rigs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radio, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No rigs configured yet'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _addRig,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Your First Rig'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _rigs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final rig = _rigs[i];
                    final isActive = rig.id == _activeRigId;
                    return Card(
                      elevation: isActive ? 3 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: isActive
                            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
                            : BorderSide.none,
                      ),
                      child: ListTile(
                        leading: Radio<String>(
                          value: rig.id,
                          groupValue: _activeRigId,
                          onChanged: (v) => setState(() => _activeRigId = v!),
                        ),
                        title: Text(rig.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${rig.power.toStringAsFixed(0)} W'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Active',
                                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary)),
                              ),
                            IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _editRig(i)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              onPressed: () => setState(() {
                                if (_activeRigId == rig.id) _activeRigId = '';
                                _rigs.removeAt(i);
                              }),
                            ),
                          ],
                        ),
                        onTap: () => setState(() => _activeRigId = rig.id),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addRig,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Rig'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrzTab extends StatefulWidget {
  const _QrzTab();
  @override
  State<_QrzTab> createState() => _QrzTabState();
}

class _QrzTabState extends State<_QrzTab> {
  late TextEditingController _userCtrl, _passCtrl;
  bool _obscure = true;
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    final s = context.read<AppState>().qrzSettings;
    _userCtrl = TextEditingController(text: s.username);
    _passCtrl = TextEditingController(text: s.password);
  }

  @override
  void dispose() {
    _userCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    await state.saveQrz(QrzSettings(username: _userCtrl.text.trim(), password: _passCtrl.text.trim()));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('QRZ settings saved')));
  }

  Future<void> _test() async {
    setState(() { _testing = true; _testResult = null; });
    final state = context.read<AppState>();
    final ok = await state.qrzService.login(
      QrzSettings(username: _userCtrl.text.trim(), password: _passCtrl.text.trim()));
    setState(() {
      _testing = false;
      _testResult = ok ? '✓ Connected to QRZ successfully!' : '✗ Login failed. Check credentials.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QRZ XML Subscription required for callsign lookup.\nQRZ API key required for logbook upload.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(labelText: 'QRZ Username', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'QRZ Password / API Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: _save, child: const Text('Save'))),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _testing ? null : _test,
                  child: _testing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Test Connection'),
                ),
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 12),
            Text(_testResult!, style: TextStyle(
              color: _testResult!.startsWith('✓') ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            )),
          ],
        ],
      ),
    );
  }
}

class _PrefsTab extends StatefulWidget {
  const _PrefsTab();
  @override
  State<_PrefsTab> createState() => _PrefsTabState();
}

class _PrefsTabState extends State<_PrefsTab> {
  late String _unit;
  late int _mapCount;
  late String _theme;
  late TextEditingController _mapCountCtrl;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _unit = state.distanceUnit;
    _mapCount = state.mapQsoCount;
    _theme = state.appTheme;
    _mapCountCtrl = TextEditingController(text: _mapCount.toString());
  }

  @override
  void dispose() {
    _mapCountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final state = context.read<AppState>();
    final count = int.tryParse(_mapCountCtrl.text) ?? 10;
    await state.setDistanceUnit(_unit);
    await state.setMapQsoCount(count.clamp(1, 500));
    await state.setAppTheme(_theme);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Theme ──
          const Text('Theme',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          ...kThemeLabels.entries.map((entry) {
            final id = entry.key;
            final label = entry.value;
            final icon = kThemeIcons[id]!;
            final isSelected = _theme == id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _theme = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.surface,
                  ),
                  child: Row(children: [
                    Icon(icon,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ))),
                    if (isSelected)
                      Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary),
                  ]),
                ),
              ),
            );
          }),
          const SizedBox(height: 24),

          // ── Distance Unit ──
          const Text('Distance Unit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'km',
                  label: Text('Kilometers (km)'), icon: Icon(Icons.straighten)),
              ButtonSegment(value: 'mi',
                  label: Text('Miles (mi)'), icon: Icon(Icons.straighten)),
            ],
            selected: {_unit},
            onSelectionChanged: (v) => setState(() => _unit = v.first),
          ),
          const SizedBox(height: 24),

          // ── Map QSO Count ──
          const Text('Map — Number of Recent QSOs',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('How many of the most recent QSOs to show on the map.',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _mapCountCtrl,
            decoration: const InputDecoration(
              labelText: 'Number of QSOs',
              border: OutlineInputBorder(),
              hintText: '10',
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Save Preferences'),
            ),
          ),
        ],
      ),
    );
  }
}
