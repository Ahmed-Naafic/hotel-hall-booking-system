import 'package:flutter/material.dart';
import 'package:hotel_hall_core/hotel_hall_core.dart';
import 'package:hotel_hall_design_tokens/hotel_hall_design_tokens.dart';
import 'package:provider/provider.dart';

import '../../application/chat_controller.dart';
import '../../data/chat_models.dart';
import '../../data/chat_repository.dart';

/// Communication V1 — a single Booking's conversation between the Customer
/// and the Hotel Manager of its Hotel (Business Specification "Communication
/// V1"). Text only, no attachments; opening this screen marks every message
/// from the other participant read.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatController _controller;
  final _composeController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = ChatController(ChatRepository(context.read<ApiClient>()), widget.bookingId);
    _controller.addListener(_onControllerChanged);
    _controller.load();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  Future<void> _send() async {
    final text = _composeController.text;
    if (text.trim().isEmpty) return;
    _composeController.clear();
    await _controller.send(text);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _composeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<AuthController>().currentUser?.id;
    return Scaffold(
      backgroundColor: context.hh.surfacePage,
      appBar: AppBar(title: const Text('Messages')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _body(currentUserId)),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _body(String? currentUserId) {
    switch (_controller.status) {
      case ChatLoadStatus.initial:
      case ChatLoadStatus.loading:
        if (_controller.messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return _list(currentUserId);
      case ChatLoadStatus.error:
        return HHEmptyState(
          icon: Icons.error_outline,
          message: _controller.errorMessage ?? 'Something went wrong.',
          actionLabel: 'Retry',
          onAction: _controller.load,
        );
      case ChatLoadStatus.ready:
        if (_controller.messages.isEmpty) {
          return const HHEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No messages yet',
            message: 'Send a message to start the conversation.',
          );
        }
        return _list(currentUserId);
    }
  }

  Widget _list(String? currentUserId) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(HHSpacing.space5),
      itemCount: _controller.messages.length,
      itemBuilder: (context, index) {
        final message = _controller.messages[index];
        final isMine = message.senderUserId == currentUserId;
        return _bubble(message, isMine);
      },
    );
  }

  Widget _bubble(ChatMessage message, bool isMine) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: HHSpacing.space3),
        padding: const EdgeInsets.symmetric(horizontal: HHSpacing.space4, vertical: HHSpacing.space3),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? context.hh.actionPrimary : context.hh.surfaceSunken,
          borderRadius: BorderRadius.circular(HHRadii.card),
        ),
        child: Text(
          message.body,
          style: TextStyle(color: isMine ? context.hh.textInverse : context.hh.textBody),
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(HHSpacing.space4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _composeController,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Type a message…'),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: HHSpacing.space3),
            IconButton(
              icon: _controller.isSending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
              onPressed: _controller.isSending ? null : _send,
            ),
          ],
        ),
      ),
    );
  }
}
