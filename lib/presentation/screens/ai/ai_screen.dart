import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/ai_config.dart';
import '../../viewmodels/ai_viewmodel.dart';
import 'package:intl/intl.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _hasApiKey = false;

  final List<String> _quickPrompts = [
    '💉 Lịch tiêm cho trẻ sơ sinh?',
    '🤒 Phản ứng sau tiêm là bình thường?',
    '📅 Vaccine cúm tiêm bao lâu 1 lần?',
    '🧒 Vaccine HPV có tác dụng gì?',
  ];

  @override
  void initState() {
    super.initState();
    _checkApiKey();
  }

  Future<void> _checkApiKey() async {
    final hasKey = await AIConfig.hasCustomKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      context.read<AIViewModel>().scanImage(File(image.path));
      _scrollToBottom();
    }
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    context.read<AIViewModel>().sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AIViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6BAED6)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Trợ lý AI Tiêm chủng", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  _hasApiKey ? "Đã cấu hình ✅" : "Chưa có API key ⚠️",
                  style: TextStyle(fontSize: 10, color: _hasApiKey ? Colors.green : Colors.orange, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.key_outlined, color: AppTheme.primary), tooltip: "Cài đặt API key", onPressed: _showApiKeyDialog),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => vm.clearChat()),
        ],
      ),
      body: Column(
        children: [
          if (!_hasApiKey) _buildApiKeyBanner(),
          Expanded(
            child: vm.messages.isEmpty
                ? _buildWelcomeView()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) => _buildMessageBubble(vm.messages[index]),
                  ),
          ),
          if (vm.isLoading) const LinearProgressIndicator(minHeight: 2, color: AppTheme.primary),
          if (vm.messages.length <= 1) _buildQuickPrompts(),
          _buildInputArea(vm),
        ],
      ),
    );
  }

  Widget _buildApiKeyBanner() {
    return GestureDetector(
      onTap: _showApiKeyDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.orange.shade50,
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                "Cần API key để sử dụng AI. Nhấn để cài đặt.",
                style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.orange, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF6BAED6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text("Trợ lý AI Tiêm chủng", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              "Hỏi về lịch tiêm, tác dụng vaccine,\nhoặc tải ảnh sổ tiêm để phân tích.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _quickPrompts.map((p) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(p, style: const TextStyle(fontSize: 12)),
            onPressed: () => _sendMessage(p),
            backgroundColor: const Color(0xFFF0F7FF),
            side: const BorderSide(color: Color(0xFFCCE3FF)),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(message) {
    final isUser = message.isUser;
    final isError = !isUser && (message.text.startsWith('❌') || message.text.startsWith('⚠️') || message.text.startsWith('📡'));

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        decoration: BoxDecoration(
          color: isUser
              ? AppTheme.primary
              : isError
                  ? Colors.red.shade50
                  : const Color(0xFFF2F2F2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 16),
          ),
          border: isError ? Border.all(color: Colors.red.shade200) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text.isEmpty ? '...' : message.text,
              style: TextStyle(
                color: isUser ? Colors.white : isError ? Colors.red.shade800 : Colors.black87,
                fontSize: 14, height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(message.timestamp),
              style: TextStyle(color: isUser ? Colors.white60 : Colors.black38, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AIViewModel vm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppTheme.primary),
            tooltip: "Tải ảnh sổ tiêm",
            onPressed: _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
              decoration: InputDecoration(
                hintText: "Hỏi về vaccine...",
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppTheme.primary,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.key, color: AppTheme.primary),
            SizedBox(width: 8),
            Text("Cài đặt Gemini API Key"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Lấy API key miễn phí tại:",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Text(
              "aistudio.google.com/app/apikey",
              style: TextStyle(fontSize: 12, color: AppTheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Dán API key vào đây...",
                prefixIcon: Icon(Icons.vpn_key_outlined),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 8),
            const Text(
              "Key được lưu an toàn trên thiết bị của bạn.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isNotEmpty) {
                await AIConfig.saveApiKey(key);
                if (ctx.mounted) Navigator.pop(ctx);
                await _checkApiKey();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ API key đã lưu. Thử gửi tin nhắn!"), backgroundColor: AppTheme.success),
                  );
                }
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}
