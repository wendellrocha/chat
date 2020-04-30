enum ChatMessageType { sent, received }
enum MessageContent { normal, email, emailPin, password, passwordConfirm }

class ChatMessage {
  final String name;
  final String text;
  final ChatMessageType type;
  final MessageContent content;

  ChatMessage(
      {this.name,
      this.text,
      this.type = ChatMessageType.sent,
      this.content = MessageContent.normal});
}
