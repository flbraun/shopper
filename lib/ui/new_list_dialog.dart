import 'package:material_ui/material_ui.dart';

import '../data/models.dart';
import '../l10n/app_localizations.dart';

/// Asks for the name of a new list. Returns the trimmed name, or null if
/// cancelled.
///
/// [takenNames] are the existing list names; matching ignores case and
/// surrounding whitespace.
Future<String?> showNewListDialog(
  BuildContext context, {
  required Iterable<String> takenNames,
}) {
  return showDialog<String>(
    context: context,
    builder: (context) =>
        _NewListDialog(takenKeys: {for (final n in takenNames) textKey(n)}),
  );
}

class _NewListDialog extends StatefulWidget {
  const _NewListDialog({required this.takenKeys});

  final Set<String> takenKeys;

  @override
  State<_NewListDialog> createState() => _NewListDialogState();
}

class _NewListDialogState extends State<_NewListDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();
  bool get _isTaken => widget.takenKeys.contains(textKey(_name));
  bool get _isValid => _name.isNotEmpty && !_isTaken;

  void _submit() {
    if (_isValid) Navigator.of(context).pop(_name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.newList),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: l10n.listName,
          errorText: _isTaken ? l10n.listNameTaken : null,
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: _isValid ? _submit : null,
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
