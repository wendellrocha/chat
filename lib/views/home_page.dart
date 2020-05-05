import 'dart:async';

import 'package:chat/constants/constants.dart';
import 'package:chat/models/chat_message.dart';
import 'package:chat/widgets/chat_message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:meteorify/meteorify.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _messageList = <ChatMessage>[];
  final _controllerText = new TextEditingController();

  var usuario;
  var codigo;
  var codigoEmail;
  var email;
  var password;
  var passwordConfirm;
  var maskFormatter = new MaskTextInputFormatter(
      mask: '## #########', filter: {"#": RegExp(r'[0-9]')});

  bool isPassword = false;
  bool isPasswordConfirm = false;
  bool isPhone = false;
  bool isPhonePin = false;
  bool isEmail = false;
  bool isPin = false;
  bool isEmailPin = false;
  bool isVisible = true;
  bool isPreference = true;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      _addMessage(
          name: Constants.PSIU,
          text: Constants.OLA,
          type: ChatMessageType.received,
          content: MessageContent.normal);
      _addMessage(
          name: Constants.PSIU,
          text: Constants.PREFERENCIA,
          type: ChatMessageType.received,
          content: MessageContent.preference);
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controllerText.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text('Chatbot'),
      ),
      body: Column(
        children: <Widget>[
          _buildList(),
          Divider(height: 1.0),
          _buildUserInput(),
        ],
      ),
    );
  }

  // Cria a lista de mensagens (de baixo para cima)
  Widget _buildList() {
    return Flexible(
      child: ListView.builder(
        padding: EdgeInsets.all(8.0),
        reverse: true,
        itemBuilder: (_, int index) =>
            ChatMessageListItem(chatMessage: _messageList[index]),
        itemCount: _messageList.length,
      ),
    );
  }

  // Envia uma mensagem com o padrão a direita
  void _sendMessage({String text, MessageContent content}) {
    _controllerText.clear();

    if (isPassword) {
      password = text;
      _addMessage(
          name: 'Usuário',
          text: '*' * text.length,
          type: ChatMessageType.sent,
          content: content);
    } else if (isPasswordConfirm) {
      print(text);
      passwordConfirm = text;
      _addMessage(
          name: 'Usuário',
          text: '*' * text.length,
          type: ChatMessageType.sent,
          content: MessageContent.passwordConfirm);
    } else {
      _addMessage(
          name: 'Usuário',
          text: text,
          type: ChatMessageType.sent,
          content: content);
    }
  }

  // Adiciona uma mensagem na lista de mensagens
  void _addMessage(
      {String name,
      String text,
      ChatMessageType type,
      MessageContent content}) {
    var message =
        ChatMessage(text: text, name: name, type: type, content: content);
    setState(() {
      _messageList.insert(0, message);
    });

    if (type == ChatMessageType.sent) {
      _dialogResponse(query: message.text, content: content);
    }

    if (content == MessageContent.preference) {
      isPreference = true;
    }

    if (content == MessageContent.end) {
      // jogar o usuário para a tela de login
    }
  }

  void _dialogResponse({String query, MessageContent content}) async {
    if (content == MessageContent.preferenceCel) {
      isPreference = false;
      isPhone = true;
      _addMessage(
          name: 'Psiu',
          text: Constants.PREFERENCIA_CELULAR,
          type: ChatMessageType.received,
          content: MessageContent.normal);
    }

    if (content == MessageContent.preferenceEmail) {
      isPreference = false;
      isEmail = true;
      _addMessage(
          name: 'Psiu',
          text: Constants.PREFERENCIA_EMAIL,
          type: ChatMessageType.received,
          content: MessageContent.normal);
    }

    if (content == MessageContent.phone) {
      var aux = query.split(' ');
      var dddCel = aux[0];
      var celular = aux[1];
      var telefone = dddCel.trim() + celular.trim();

      usuario = await getUsuario(telefone);
      codigo = await Meteor.call('conta.verificar.telefone', [telefone]);
      isPin = true;
      isPhonePin = true;
      isPhone = false;
      _addMessage(
          name: 'Psiu',
          text: Constants.PIN_CELULAR,
          type: ChatMessageType.received,
          content: MessageContent.normal);
    }

    if (content == MessageContent.email) {
      usuario = await getUsuario(query);
      codigoEmail = await Meteor.call('conta.verificar.email', [query]);
      isPin = true;
      isEmailPin = true;
      _addMessage(
          name: 'Psiu',
          text: Constants.PIN_EMAIL,
          type: ChatMessageType.received,
          content: MessageContent.normal);
    }

    if (content == MessageContent.emailPin) {
      if (codigoEmail.toString() == query) {
        _addMessage(
            name: 'Psiu',
            text:
                'Ótimo ${usuario["nome"]}! Agora crie a sua senha enquanto eu tomo um café ☕',
            type: ChatMessageType.received,
            content: MessageContent.normal);
        isEmail = false;
        isEmailPin = false;
        isPassword = true;
      }
      isPin = false;
    }

    if (content == MessageContent.phonePin) {
      if (codigo.toString() == query) {
        _addMessage(
            name: 'Psiu',
            text:
                'Ótimo ${usuario["nome"]}! Agora crie a sua senha enquanto eu tomo um café ☕',
            type: ChatMessageType.received,
            content: MessageContent.normal);
        isEmail = false;
        isEmailPin = false;
        isPassword = true;
      }
      isPin = false;
    }

    if (isPasswordConfirm) {
      if (password == passwordConfirm) {
        var isOk = await Meteor.call(
            'conta.reseta.senha', [usuario['id'], passwordConfirm]);
        print(isOk);
        _addMessage(
            name: 'Psiu',
            text:
                'Tudo certo, ${usuario["nome"]}! 🙂👏 Agora você já pode fazer o login com a sua nova senha.',
            type: ChatMessageType.received,
            content: MessageContent.end);
      }
    }

    if (content == MessageContent.password) {
      isPasswordConfirm = true;
      _addMessage(
          name: 'Psiu',
          text: Constants.SENHA_CONFIRM,
          type: ChatMessageType.received,
          content: MessageContent.normal);
    }

    if (content == MessageContent.email) {
      email = query;
    }
  }

  // Campo para escrever a mensagem
  Widget _buildTextField() {
    if (isPhone) {
      return new Flexible(
        child: new TextField(
          keyboardType: TextInputType.phone,
          controller: _controllerText,
          inputFormatters: [maskFormatter],
          decoration: new InputDecoration.collapsed(
            hintText: "Digite seu telefone",
          ),
        ),
      );
    }

    if (isPin || isEmailPin) {
      return new Flexible(
        child: new TextField(
          keyboardType: TextInputType.number,
          controller: _controllerText,
          decoration: new InputDecoration.collapsed(
            hintText: "Digite o PIN",
          ),
          maxLength: 6,
        ),
      );
    }

    if (isPassword || isPasswordConfirm) {
      return new Flexible(
        child: new TextField(
          obscureText: isVisible,
          keyboardType: TextInputType.visiblePassword,
          controller: _controllerText,
          decoration: new InputDecoration(
            hintText: "Digite sua senha",
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                semanticLabel: isVisible ? 'Ocultar senha' : 'Mostrar senha',
              ),
              onPressed: () {
                setState(() {
                  isVisible ^= true;
                });
              },
            ),
          ),
        ),
      );
    }

    if (isEmail) {
      return new Flexible(
        child: new TextField(
          keyboardType: TextInputType.emailAddress,
          controller: _controllerText,
          decoration: new InputDecoration.collapsed(
            hintText: "Digite seu e-mail",
          ),
        ),
      );
    }

    return new Flexible(
      child: new TextField(
        keyboardType: TextInputType.text,
        controller: _controllerText,
        decoration: new InputDecoration.collapsed(
          hintText: "Enviar mensagem",
        ),
      ),
    );
  }

  // Botão para enviar a mensagem
  Widget _buildSendButton() {
    return new Container(
      margin: new EdgeInsets.only(left: 8.0),
      child: new IconButton(
          icon: new Icon(Icons.send, color: Theme.of(context).accentColor),
          onPressed: () {
            FocusScope.of(context).requestFocus(new FocusNode());
            if (_controllerText.text.isNotEmpty) {
              if (validateEmail(_controllerText.text)) {
                _sendMessage(
                    text: _controllerText.text, content: MessageContent.email);
                isEmail = true;
              } else if (isEmailPin) {
                _sendMessage(
                    text: _controllerText.text,
                    content: MessageContent.emailPin);
              } else if (isPassword) {
                _sendMessage(
                    text: _controllerText.text,
                    content: MessageContent.password);
                isPasswordConfirm = true;
                isPassword = false;
              } else if (isPasswordConfirm) {
                _sendMessage(
                    text: _controllerText.text,
                    content: MessageContent.passwordConfirm);
              } else if (isPreference) {
                if (_isPhone(_controllerText.text)) {
                  _sendMessage(
                      text: _controllerText.text,
                      content: MessageContent.preferenceCel);
                } else if (_isEmail(_controllerText.text)) {
                  _sendMessage(
                      text: _controllerText.text,
                      content: MessageContent.preferenceEmail);
                } else {
                  _sendMessage(
                      text: _controllerText.text,
                      content: MessageContent.normal);
                  _addMessage(
                      name: 'Psiu',
                      text: Constants.UNKNOWN,
                      type: ChatMessageType.received,
                      content: MessageContent.normal);
                }
              } else if (isPhone) {
                _sendMessage(
                    text: _controllerText.text, content: MessageContent.phone);
              } else if (isPhonePin) {
                _sendMessage(
                    text: _controllerText.text,
                    content: MessageContent.phonePin);
              } else {
                _sendMessage(
                    text: _controllerText.text, content: MessageContent.normal);
              }
            }
          }),
    );
  }

  // Monta uma linha com o campo de text e o botão de enviao
  Widget _buildUserInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: new Row(
        children: <Widget>[
          _buildTextField(),
          _buildSendButton(),
        ],
      ),
    );
  }

  Future getUsuario(String query) async {
    var result = await Meteor.call('conta.verifica.usuario', [query]);
    //var doc = Map<String, dynamic>.from();
    var doc = new Map<String, dynamic>.from(result);
    print('usuario: $doc');
    return doc;
  }

  bool _isEmail(String text) {
    RegExp regExp = new RegExp(r"(email|e-mail)", caseSensitive: false);
    return regExp.hasMatch(text);
  }

  bool _isPhone(String text) {
    RegExp regExp = new RegExp(r"(celular)", caseSensitive: false);
    return regExp.hasMatch(text);
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    return (!regex.hasMatch(value)) ? false : true;
  }
}
