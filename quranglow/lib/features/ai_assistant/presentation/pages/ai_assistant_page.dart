import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design_system/colors/app_palette.dart';
import '../../../design_system/spacing/app_spacing.dart';
import '../../domain/entities/ai_chat_message.dart';

class AiAssistantPage extends StatefulWidget {
  const AiAssistantPage({super.key});

  @override
  State<AiAssistantPage> createState() => _AiAssistantPageState();
}

class _AiAssistantPageState extends State<AiAssistantPage> {
  final TextEditingController _controller = TextEditingController();
  final List<AiChatMessage> _messages = [
    AiChatMessage(
      id: 'welcome_1',
      text: 'السلام عليكم ورحمة الله وبركاته! أنا مرشدك القرآني الذكي في تطبيق بستان. كيف يمكنني مساعدتك اليوم في تلاوة القرآن أو تنظيم الختمة أو خطط الحفظ؟',
      sender: MessageSender.assistant,
      timestamp: DateTime.now(),
    ),
  ];

  void _sendMessage() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add(
        AiChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          text: query,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _controller.clear();
    });

    // Simulated trusted response
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          AiChatMessage(
            id: 'bot_${DateTime.now().millisecondsSinceEpoch}',
            text: 'بارك الله فيك. يمكنك دوماً تنظيم قراءتك عبر خطط الختمة المتاحة في التطبيق (7، 15، 30 يوماً). نسأل الله أن يجعل القرآن ربيع قلوبنا.',
            sender: MessageSender.assistant,
            timestamp: DateTime.now(),
            quranReference: '﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾ [الإسراء: 9]',
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('المرشد القرآني', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: AppSpacing.pagePadding,
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.82),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppPalette.primary : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isUser ? Colors.white : null,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        if (msg.quranReference != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            msg.quranReference!,
                            style: GoogleFonts.amiri(
                              color: AppPalette.goldDark,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withAlpha(20))),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'اسأل عن خطة أو سورة أو تفسير...',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppPalette.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
