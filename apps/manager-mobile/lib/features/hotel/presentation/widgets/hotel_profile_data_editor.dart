import 'package:flutter/material.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';

class _FieldRow {
  _FieldRow({String key = '', String value = ''})
      : keyController = TextEditingController(text: key),
        valueController = TextEditingController(text: value);

  final TextEditingController keyController;
  final TextEditingController valueController;

  void dispose() {
    keyController.dispose();
    valueController.dispose();
  }
}

/// A dynamic key-value editor for a Hotel's `profileData` — deliberately
/// generic, never a fixed set of fields. Required Business-Profile Content
/// is Pending Business Decision #7 (Hotel Management Business Specification
/// §11 Item 7); this widget lets the Hotel Manager record whatever
/// information they choose, without this app inventing a Hotel profile
/// schema no approved decision defines. Mirrors `HallProfileDataEditor`'s
/// identical pattern for the identical reason. Only *editing existing
/// values* and *adding new fields* is supported — not removing a field,
/// since the backend's `PATCH` merges rather than replaces `profileData`
/// (`profile.service.js`), so a "removed" field would silently persist
/// server-side; the UI does not offer an action it cannot honor.
class HotelProfileDataEditor extends StatefulWidget {
  const HotelProfileDataEditor({super.key, this.initialData, this.enabled = true});

  final Map<String, dynamic>? initialData;
  final bool enabled;

  @override
  State<HotelProfileDataEditor> createState() => HotelProfileDataEditorState();
}

class HotelProfileDataEditorState extends State<HotelProfileDataEditor> {
  final List<_FieldRow> _rows = [];

  @override
  void initState() {
    super.initState();
    final data = widget.initialData;
    if (data != null && data.isNotEmpty) {
      for (final entry in data.entries) {
        _rows.add(_FieldRow(key: entry.key, value: entry.value?.toString() ?? ''));
      }
    } else {
      _rows.add(_FieldRow());
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  void _addRow() => setState(() => _rows.add(_FieldRow()));

  /// Builds the `profileData` object from non-empty rows — a field with an
  /// empty key is silently skipped (never sent as `""`), never required.
  Map<String, dynamic> collect() {
    final result = <String, dynamic>{};
    for (final row in _rows) {
      final key = row.keyController.text.trim();
      if (key.isEmpty) continue;
      result[key] = row.valueController.text;
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _rows.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: HHSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _rows[i].keyController,
                    enabled: widget.enabled,
                    decoration: const InputDecoration(labelText: 'Field name'),
                  ),
                ),
                const SizedBox(width: HHSpacing.space3),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _rows[i].valueController,
                    enabled: widget.enabled,
                    decoration: const InputDecoration(labelText: 'Value'),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: widget.enabled ? _addRow : null,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add field'),
          ),
        ),
      ],
    );
  }
}
