// lib/screens/tags_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});
  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  late List<TagDefinition> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(context.read<AppState>().tags);
  }

  void _addTag() {
    showDialog(
      context: context,
      builder: (_) => _TagDialog(
        onSave: (name, color) {
          setState(() => _tags.add(TagDefinition(id: const Uuid().v4(), name: name, color: color)));
        },
      ),
    );
  }

  void _editTag(int i) {
    showDialog(
      context: context,
      builder: (_) => _TagDialog(
        existing: _tags[i],
        onSave: (name, color) {
          setState(() {
            _tags[i] = TagDefinition(id: _tags[i].id, name: name, color: color);
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    await context.read<AppState>().saveTags(_tags);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tags'),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _save, tooltip: 'Save'),
          IconButton(icon: const Icon(Icons.add), onPressed: _addTag, tooltip: 'Add Tag'),
        ],
      ),
      body: ReorderableListView.builder(
        itemCount: _tags.length,
        onReorder: (old, newI) {
          setState(() {
            final item = _tags.removeAt(old);
            _tags.insert(newI > old ? newI - 1 : newI, item);
          });
        },
        itemBuilder: (ctx, i) {
          final t = _tags[i];
          final color = Color(int.parse(t.color.replaceFirst('#', '0xFF')));
          return ListTile(
            key: ValueKey(t.id),
            leading: CircleAvatar(backgroundColor: color, radius: 14),
            title: Text(t.name),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editTag(i)),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => setState(() => _tags.removeAt(i)),
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TagDialog extends StatefulWidget {
  final TagDefinition? existing;
  final Function(String name, String color) onSave;

  const _TagDialog({this.existing, required this.onSave});

  @override
  State<_TagDialog> createState() => _TagDialogState();
}

class _TagDialogState extends State<_TagDialog> {
  late TextEditingController _nameCtrl;
  late String _color;

  static const _colors = [
    '#F44336', '#E91E63', '#9C27B0', '#673AB7', '#3F51B5',
    '#2196F3', '#03A9F4', '#00BCD4', '#009688', '#4CAF50',
    '#8BC34A', '#CDDC39', '#FFC107', '#FF9800', '#FF5722',
    '#795548', '#607D8B',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _color = widget.existing?.color ?? '#2196F3';
  }

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing != null ? 'Edit Tag' : 'New Tag'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(labelText: 'Tag Name', border: OutlineInputBorder()),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          const Align(alignment: Alignment.centerLeft, child: Text('Color')),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _colors.map((c) {
              final color = Color(int.parse(c.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: _color == c ? Border.all(color: Colors.black, width: 3) : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            if (_nameCtrl.text.isNotEmpty) {
              widget.onSave(_nameCtrl.text.trim(), _color);
              Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
