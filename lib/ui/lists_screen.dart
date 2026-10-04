import 'package:material_ui/material_ui.dart';

import '../data/list_repository.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings.dart';
import 'list_detail_screen.dart';
import 'new_list_dialog.dart';
import 'settings_screen.dart';
import 'widgets/list_card.dart';

/// Title screen: all shopping lists.
///
/// Long-press a list to drag it. Dropping it between other lists reorders
/// them; dropping it on the bin that appears at the bottom deletes it.
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key, required this.lists, required this.settings});

  final ListRepository lists;
  final Settings settings;

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  final _reorderableKey = GlobalKey<SliverReorderableListState>();
  final _binKey = GlobalKey();

  List<ListOverview>? _overviews;

  /// Index of the list being dragged, or null when no drag is active.
  int? _dragIndex;
  bool _overBin = false;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_onSettingsChanged);
    _load();
  }

  @override
  void dispose() {
    widget.settings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _load() async {
    final overviews = await widget.lists.getOverviews();
    if (mounted) setState(() => _overviews = overviews);
  }

  Future<void> _createList() async {
    final name = await showNewListDialog(
      context,
      takenNames: [for (final o in _overviews ?? const []) o.list.name],
    );
    if (name == null) return;
    try {
      await widget.lists.createList(name);
    } on DuplicateListNameException {
      // The dialog already rejects taken names; nothing else to do.
    }
    await _load();
  }

  Future<void> _openList(ShoppingList list) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ListDetailScreen(
          list: list,
          lists: widget.lists,
          settings: widget.settings,
        ),
      ),
    );
    await _load();
  }

  void _onReorder(int oldIndex, int newIndex) {
    final overviews = _overviews!;
    setState(() => overviews.insert(newIndex, overviews.removeAt(oldIndex)));
    widget.lists.reorderLists([for (final o in overviews) o.list.id]);
  }

  // The reorderable list knows nothing about the bin, so the finger position
  // is tracked here. This Listener sees pointer events before the list's drag
  // gesture does, so a drop on the bin can cancel the reorder first.

  bool _isOverBin(Offset globalPosition) {
    final box = _binKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return false;
    return (box.localToGlobal(Offset.zero) & box.size).contains(globalPosition);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dragIndex == null) return;
    final over = _isOverBin(event.position);
    if (over != _overBin) setState(() => _overBin = over);
  }

  void _onPointerUp(PointerUpEvent event) {
    final index = _dragIndex;
    if (index == null || !_isOverBin(event.position)) return;
    _reorderableKey.currentState?.cancelReorder();
    final removed = _overviews!.removeAt(index);
    setState(() {
      _dragIndex = null;
      _overBin = false;
    });
    widget.lists.deleteList(removed.list.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overviews = _overviews;

    final addButton = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: FilledButton.tonalIcon(
        onPressed: overviews == null ? null : _createList,
        icon: const Icon(Icons.add),
        label: Text(l10n.newList),
      ),
    );

    final Widget content;
    if (overviews == null) {
      content = const SizedBox.shrink();
    } else if (overviews.isEmpty) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          addButton,
          Expanded(child: Center(child: Text(l10n.noListsYet))),
        ],
      );
    } else {
      content = CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: addButton),
          SliverReorderableList(
            key: _reorderableKey,
            itemCount: overviews.length,
            itemBuilder: (context, index) {
              final overview = overviews[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(overview.list.id),
                index: index,
                child: _cardPadding(
                  ListCard(
                    overview: overview,
                    itemOrder: widget.settings.itemOrder,
                    onTap: () => _openList(overview.list),
                  ),
                ),
              );
            },
            // Rebuilt on every drag move, so it follows _overBin. Over the
            // bin the card shrinks and fades to keep the bin visible.
            proxyDecorator: (child, index, animation) => AnimatedScale(
              scale: _overBin ? 0.5 : 1,
              duration: const Duration(milliseconds: 150),
              child: AnimatedOpacity(
                opacity: _overBin ? 0.6 : 1,
                duration: const Duration(milliseconds: 150),
                child: _cardPadding(
                  ListCard(
                    overview: overviews[index],
                    itemOrder: widget.settings.itemOrder,
                    elevation: 6,
                  ),
                ),
              ),
            ),
            onReorderStart: (index) => setState(() => _dragIndex = index),
            onReorderEnd: (_) => setState(() {
              _dragIndex = null;
              _overBin = false;
            }),
            onReorderItem: _onReorder,
          ),
          const SliverSafeArea(
            top: false,
            sliver: SliverToBoxAdapter(child: SizedBox(height: 8)),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsScreen(settings: widget.settings),
              ),
            ),
          ),
        ],
      ),
      body: Listener(
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        child: Column(
          children: [
            Expanded(child: content),
            AnimatedSize(
              duration: const Duration(milliseconds: 150),
              child: _dragIndex == null
                  ? const SizedBox(width: double.infinity)
                  : _Bin(key: _binKey, highlighted: _overBin),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _cardPadding(Widget card) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: card,
  );
}

/// Drop target for deleting a list; only shown while a list is dragged.
class _Bin extends StatelessWidget {
  const _Bin({super.key, required this.highlighted});

  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: AppLocalizations.of(context).deleteListDropTarget,
      child: ColoredBox(
        color: highlighted
            ? colors.errorContainer
            : colors.surfaceContainerHigh,
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 96,
            child: Icon(
              highlighted ? Icons.delete : Icons.delete_outline,
              size: 36,
              color: highlighted
                  ? colors.onErrorContainer
                  : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
