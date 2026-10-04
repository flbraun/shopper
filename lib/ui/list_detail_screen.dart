import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../data/item_sorting.dart';
import '../data/list_repository.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'widgets/add_item_field.dart';
import 'widgets/item_tile.dart';

/// Items of one list.
///
/// Tapping an item strikes or unstrikes it. The broom deletes all struck
/// items; for [undoDuration] afterwards it turns into an undo button. The
/// field at the bottom adds items, with suggestions from the dictionary.
class ListDetailScreen extends StatefulWidget {
  const ListDetailScreen({
    super.key,
    required this.list,
    required this.lists,
    required this.settings,
  });

  final ShoppingList list;
  final ListRepository lists;
  final Settings settings;

  static const undoDuration = Duration(seconds: 5);

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  List<Item>? _items;

  /// Items removed by the last broom tap while undo is still possible.
  List<Item>? _undoItems;
  Timer? _undoTimer;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
    _load();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    _undoTimer?.cancel();
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _load() async {
    final items = await widget.lists.getItems(widget.list.id);
    if (mounted) setState(() => _items = items);
  }

  void _toggle(Item item) {
    final updated = item.copyWith(struck: !item.struck);
    setState(() {
      _items = [
        for (final i in _items!)
          if (i.id == item.id) updated else i,
      ];
    });
    widget.lists.setStruck(item.id, updated.struck);
  }

  /// Adds [text] as a new unstruck item. If the list already has it (struck
  /// or not), asks first. Returns whether the item was added.
  Future<bool> _addItem(String text) async {
    final lists = widget.lists;
    final listId = widget.list.id;
    if (await lists.containsItem(listId, text)) {
      if (!mounted || !await _confirmDuplicate(text.trim())) return false;
    }
    await lists.addItem(listId, text);
    await _load();
    return true;
  }

  Future<bool> _confirmDuplicate(String text) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.duplicateItemTitle),
        content: Text(l10n.duplicateItemMessage(text)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.addAnyway),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _removeStruck() async {
    final removed = await widget.lists.removeStruckItems(widget.list.id);
    if (!mounted || removed.isEmpty) return;
    _undoTimer?.cancel();
    setState(() {
      _items = _items!.where((i) => !i.struck).toList();
      _undoItems = removed;
    });
    _undoTimer = Timer(ListDetailScreen.undoDuration, () {
      if (mounted) setState(() => _undoItems = null);
    });
  }

  Future<void> _undo() async {
    final restore = _undoItems;
    if (restore == null) return;
    _undoTimer?.cancel();
    setState(() => _undoItems = null);
    await widget.lists.restoreItems(restore);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = _items;
    final hasStruck = items?.any((i) => i.struck) ?? false;

    final Widget action = _undoItems != null
        ? IconButton(
            key: const ValueKey('undo'),
            icon: const Icon(Icons.undo),
            tooltip: l10n.undo,
            onPressed: _undo,
          )
        : IconButton(
            key: const ValueKey('broom'),
            icon: const Icon(Icons.cleaning_services),
            tooltip: l10n.removeStruckItems,
            onPressed: hasStruck ? _removeStruck : null,
          );

    final Widget body;
    if (items == null) {
      body = const SizedBox.shrink();
    } else if (items.isEmpty) {
      body = Center(child: Text(l10n.noItemsYet));
    } else {
      final sorted = sortItems(
        items,
        widget.settings.itemOrder,
        widget.settings.struckPlacement,
      );
      body = ListView.builder(
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final item = sorted[index];
          return ItemTile(
            key: ValueKey(item.id),
            item: item,
            onTap: () => _toggle(item),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        actions: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 150),
            child: action,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: body),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(8),
            child: AddItemField(
              onAdd: _addItem,
              suggestions: widget.lists.dictionary.suggestions,
            ),
          ),
        ],
      ),
    );
  }
}
