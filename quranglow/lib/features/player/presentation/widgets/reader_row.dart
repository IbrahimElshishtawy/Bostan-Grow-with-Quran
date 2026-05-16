import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

class ReaderRow extends StatelessWidget {
  const ReaderRow({
    super.key,
    required this.editions,
    required this.surahs,
    required this.selectedEditionId,
    required this.selectedSurah,
    required this.onEditionChanged,
    required this.onChapterChanged,
  });

  final AsyncValue<List<dynamic>> editions;
  final AsyncValue<List<Surah>> surahs;
  final String selectedEditionId;
  final int selectedSurah;
  final ValueChanged<String> onEditionChanged;
  final ValueChanged<int> onChapterChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SelectionButton(
            label: 'القارئ',
            value: editions.when(
              data: (list) {
                final item = list.firstWhere(
                  (m) =>
                      (m['identifier'] ?? '').toString() == selectedEditionId,
                  orElse: () => {'name': selectedEditionId},
                );
                return (item['name'] ??
                        item['englishName'] ??
                        selectedEditionId)
                    .toString();
              },
              loading: () => '...',
              error: (_, _) => 'خطأ',
            ),
            icon: Icons.person_outline_rounded,
            onTap: () => showSelectionSheet(
              context,
              title: 'اختر القارئ',
              items: editions.maybeWhen(
                data: (list) => list
                    .whereType<Map>()
                    .map(
                      (m) => {
                        'id': (m['identifier'] ?? '').toString(),
                        'name': (m['name'] ?? m['englishName'] ?? '')
                            .toString(),
                      },
                    )
                    .toList(),
                orElse: () => [],
              ),
              selectedId: selectedEditionId,
              onSelected: (id) => onEditionChanged(id as String),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SelectionButton(
            label: 'السورة',
            value: surahs.maybeWhen(
              data: (list) =>
                  list.firstWhere((s) => s.number == selectedSurah).name,
              orElse: () => 'سورة $selectedSurah',
            ),
            icon: Icons.auto_stories_outlined,
            onTap: () => showSelectionSheet(
              context,
              title: 'اختر السورة',
              items: surahs.maybeWhen(
                data: (list) => list
                    .map(
                      (s) => {
                        'id': s.number,
                        'name': s.name,
                        'subtitle': 'سورة رقم ${s.number}',
                      },
                    )
                    .toList(),
                orElse: () => [],
              ),
              selectedId: selectedSurah,
              onSelected: (id) => onChapterChanged(id as int),
            ),
          ),
        ),
      ],
    );
  }

  void showSelectionSheet(
    BuildContext context, {
    required String title,
    required List<Map<String, dynamic>> items,
    required dynamic selectedId,
    required ValueChanged<dynamic> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SelectionSheet(
        title: title,
        items: items,
        selectedId: selectedId,
        onSelected: onSelected,
      ),
    );
  }
}

void showSelectionSheet(
  BuildContext context, {
  required String title,
  required List<Map<String, dynamic>> items,
  required dynamic selectedId,
  required ValueChanged<dynamic> onSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => SelectionSheet(
      title: title,
      items: items,
      selectedId: selectedId,
      onSelected: onSelected,
    ),
  );
}

class _SelectionButton extends StatelessWidget {
  const _SelectionButton({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.tealAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionSheet extends StatefulWidget {
  const SelectionSheet({
    super.key,
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelected,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final dynamic selectedId;
  final ValueChanged<dynamic> onSelected;

  @override
  State<SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<SelectionSheet> {
  late List<Map<String, dynamic>> filteredItems = widget.items;
  final TextEditingController _searchController = TextEditingController();

  void _filter(String query) {
    setState(() {
      filteredItems = widget.items
          .where(
            (item) =>
                item['name'].toString().contains(query) ||
                (item['subtitle']?.toString().contains(query) ?? false),
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: _filter,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'بحث...',
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38)),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: widget.items.isEmpty
                  ? const SelectionShimmer()
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = item['id'] == widget.selectedId;
                        return ListTile(
                          onTap: () {
                            widget.onSelected(item['id']);
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal
                                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.check_rounded
                                  : Icons.music_note_rounded,
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                            ),
                          ),
                          title: Text(
                            item['name'],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.tealAccent
                                  : Colors.white,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: item['subtitle'] != null
                              ? Text(
                                  item['subtitle'],
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
                                    fontSize: 12,
                                  ),
                                )
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class SelectionShimmer extends StatelessWidget {
  const SelectionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 10,
      itemBuilder: (context, index) => ShimmerLoading(
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          title: Container(
            width: 100,
            height: 12,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          subtitle: Container(
            width: 150,
            height: 10,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
