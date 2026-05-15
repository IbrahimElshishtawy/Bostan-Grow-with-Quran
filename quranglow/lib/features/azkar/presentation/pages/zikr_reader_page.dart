import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quranglow/core/widgets/pro_app_bar.dart';
import 'package:quranglow/features/azkar/domain/azkar_model.dart';

class ZikrReaderPage extends StatefulWidget {
  final String category;
  const ZikrReaderPage({super.key, required this.category});

  @override
  State<ZikrReaderPage> createState() => _ZikrReaderPageState();
}

class _ZikrReaderPageState extends State<ZikrReaderPage> {
  late List<Zikr> _items;
  final Map<int, int> _counts = {};

  @override
  void initState() {
    super.initState();
    _items = AzkarData.getByCategory(widget.category);
    for (int i = 0; i < _items.length; i++) {
      _counts[i] = int.tryParse(_items[i].count ?? '1') ?? 1;
    }
  }

  void _increment(int index) {
    if (_counts[index]! > 0) {
      setState(() {
        _counts[index] = _counts[index]! - 1;
      });
      HapticFeedback.lightImpact();
      if (_counts[index] == 0) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: ProAppBar(
          title: widget.category,
          onBack: () => Navigator.pop(context),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final item = _items[index];
            final remaining = _counts[index]!;
            final total = int.tryParse(item.count ?? '1') ?? 1;
            final isDone = remaining == 0;

            return AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isDone ? 0.6 : 1.0,
              child: Card(
                elevation: 0,
                color: isDone ? cs.surfaceContainer : cs.surfaceContainerHigh,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isDone ? Colors.transparent : cs.primary.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: InkWell(
                  onTap: () => _increment(index),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.text,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.8,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Amiri',
                            color: isDone ? cs.onSurfaceVariant : cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.reference != null)
                              Text(
                                item.reference!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.primary.withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDone ? Colors.green.withValues(alpha: 0.1) : cs.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isDone ? 'تم القراءة' : '$remaining / $total',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDone ? Colors.green : cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
