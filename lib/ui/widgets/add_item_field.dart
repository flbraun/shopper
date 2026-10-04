import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';

/// Text field at the bottom of a list. Submitting the text or picking a
/// suggestion calls [onAdd]; the field is cleared when it returns true and
/// keeps focus so several items can be entered in a row.
class AddItemField extends StatefulWidget {
  const AddItemField({
    super.key,
    required this.onAdd,
    required this.suggestions,
  });

  final Future<bool> Function(String text) onAdd;
  final Future<List<String>> Function(String query) suggestions;

  @override
  State<AddItemField> createState() => _AddItemFieldState();
}

class _AddItemFieldState extends State<AddItemField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _add(String text) async {
    if (text.trim().isEmpty) return;
    final added = await widget.onAdd(text);
    if (!mounted) return;
    if (added) _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsViewOpenDirection: OptionsViewOpenDirection.up,
      optionsBuilder: (value) => widget.suggestions(value.text),
      onSelected: _add,
      // Own options view: Autocomplete's default highlights the first
      // suggestion, which would wrongly suggest that Enter picks it.
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.bottomLeft,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(4),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240),
            child: ListView(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              children: [
                for (final option in options)
                  ListTile(
                    title: Text(option),
                    onTap: () => onSelected(option),
                  ),
              ],
            ),
          ),
        ),
      ),
      // Enter always adds the typed text. Autocomplete's own submit
      // callback would pick the highlighted suggestion instead.
      fieldViewBuilder: (context, controller, focusNode, _) => TextField(
        controller: controller,
        focusNode: focusNode,
        textCapitalization: TextCapitalization.sentences,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context).addItemHint,
          border: const OutlineInputBorder(),
        ),
        // Keep the keyboard open after submitting.
        onEditingComplete: () {},
        onSubmitted: _add,
      ),
    );
  }
}
