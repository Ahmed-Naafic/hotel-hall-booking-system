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

/// A dynamic key-value editor for a Hall's **custom** fields only — the
/// "ADDITIONAL INFORMATION" section of the structured Hall Profile form.
/// `BDR-016` (Approved) defines Hall Name, Capacity, Description, and
/// Location/Area as named standard fields, each with its own dedicated
/// input elsewhere in that form; this widget covers everything *beyond*
/// that fixed set, so a Hotel Manager can still record whatever
/// Hall-specific information the standard fields don't capture, without
/// this app inventing a fixed schema no approved decision defines. Only
/// *editing existing values* and *adding new fields* is supported — not
/// removing a field, since the backend's `PATCH` merges rather than
/// replaces `profileData` (`profile.service.js`), so a "removed" field
/// would silently persist server-side; the UI does not offer an action it
/// cannot honor.
class HallProfileDataEditor extends StatefulWidget {
  const HallProfileDataEditor({super.key, this.initialData, this.enabled = true});

  final Map<String, dynamic>? initialData;
  final bool enabled;

  @override
  State<HallProfileDataEditor> createState() => HallProfileDataEditorState();
}

class HallProfileDataEditorState extends State<HallProfileDataEditor> {
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
