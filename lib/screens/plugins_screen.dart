// lib/screens/plugins_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../plugins/plugin_registry.dart';
import '../services/app_state.dart';

class PluginsScreen extends StatefulWidget {
  const PluginsScreen({super.key});
  @override
  State<PluginsScreen> createState() => _PluginsScreenState();
}

class _PluginsScreenState extends State<PluginsScreen> {
  late List<String> _order;
  late Set<String> _visible;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _order = List.from(state.pluginOrder);
    _visible = Set.from(state.visiblePluginIds);
  }

  void _persist() {
    context.read<AppState>().savePluginSettings(_order, _visible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugins')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Check the plugins to show on the main screen. Drag to reorder them.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false,
              padding: const EdgeInsets.only(bottom: 12),
              itemCount: _order.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final id = _order.removeAt(oldIndex);
                  _order.insert(newIndex, id);
                });
                _persist();
              },
              itemBuilder: (context, index) {
                final id = _order[index];
                final info = pluginById(id);
                if (info == null) return const SizedBox.shrink(key: ValueKey('missing'));
                final isVisible = _visible.contains(id);
                return ListTile(
                  key: ValueKey(id),
                  leading: Icon(info.icon),
                  title: Text(info.label),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: isVisible,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _visible.add(id);
                            } else {
                              _visible.remove(id);
                            }
                          });
                          _persist();
                        },
                      ),
                      ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
