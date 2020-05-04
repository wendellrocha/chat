import 'dart:async';

import 'package:chat/models/chat_message.dart';
import 'package:chat/widgets/chat_message_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dialogflow/dialogflow_v2.dart';
import 'package:meteorify/meteorify.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var objeto = {};
  final _messageList = <ChatMessage>[];
  final _controllerText = new TextEditingController();
  var maskFormatter = new MaskTextInputFormatter(
      mask: '## #########', filter: {"#": RegExp(r'[0-9]')});
  bool isPassword = false;
  bool isPasswordConfirm = false;
  bool isPhone = false;
  bool isEmail = false;
  bool isPin = false;
  bool isEmailPin = false;
  bool isVisible = true;
  var codigo;
  var codigoEmail;
  var password;
  var passwordConfirm;

  void login() async {
    await Meteor.loginWithPassword('teste@gmail.com', 'teste');
  }

  cadastrarUsuario(Object doc) async {
    var id = await Meteor.call('conta.insert', [doc]);
    return id;
  }

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      _dialogFlowRequest(query: 'nome', content: MessageContent.normal);
    });

    login();
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
          text: '********',
          type: ChatMessageType.sent,
          content: content);
    } else if (isPasswordConfirm) {
      print(text);
      passwordConfirm = text;
      _addMessage(
          name: 'Usuário',
          text: '********',
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
      // Envia a mensagem para o chatbot e aguarda sua resposta
      _dialogFlowRequest(query: message.text, content: content);
    }

    if (content == MessageContent.end) {
      cadastrarUsuario(objeto);
    }
  }

  // Método incompleto ainda
  Future _dialogFlowRequest({String query, MessageContent content}) async {
    var intent;
    var action;
    AuthGoogle authGoogle =
        await AuthGoogle(fileJson: "assets/credentials.json").build();
    Dialogflow dialogflow =
        Dialogflow(authGoogle: authGoogle, language: "pt-BR");
    AIResponse response;
    if (content == MessageContent.normal) {
      response = await dialogflow.detectIntent(query);
      intent = response.queryResult.intent.displayName;
      action = response.queryResult.action;
    }

    if (action == null && (intent != 'pergunta-nome')) {
      if (intent == 'telefone-pin') {
        if (isPhone && (codigo == query)) {
          await dialogflow.detectIntent(query);
          isPhone = false;
        } else {
          await dialogflow.detectIntent('eeeee');
        }

        isPin = false;
      }

      if (intent == 'telefone') {
        var aux = query.split(' ');
        objeto['ddd_cel'] = aux[0];
        objeto['celular'] = aux[1];
        objeto['username'] = aux[0].trim() + aux[1].trim();

        isPhone = true;

        var telefone = aux[0] + aux[1];

        codigo = await Meteor.call('conta.verificar.telefone', [telefone]);
        isPin = true;

        print('response: $codigo');
      }

      if (content == MessageContent.email) {
        codigoEmail = await Meteor.call('conta.verificar.email', [query]);
        isPin = true;
        isEmailPin = true;
        _addMessage(
            name: 'Psiu',
            text:
                'Acredito que o PIN já chegou no e-mail. Me fala o código que você recebeu.' ??
                    '',
            type: ChatMessageType.received,
            content: MessageContent.normal);
      }

      if (content == MessageContent.emailPin) {
        print('Codigo Email: $codigoEmail');
        print(codigoEmail.toString() == query);
        if (codigoEmail.toString() == query) {
          _addMessage(
              name: 'Psiu',
              text:
                  'Ótimo ${objeto["nome"]}! Seu e-mail já está confirmado em nosso sistema.' ??
                      '',
              type: ChatMessageType.received,
              content: MessageContent.normal);
          _addMessage(
              name: 'Psiu',
              text:
                  'Para finalizarmos, preciso apenas te pedir para criar uma senha. Esses serão os seus dados de acesso para o login. 🙂' ??
                      '',
              type: ChatMessageType.received,
              content: MessageContent.normal);
          _addMessage(
              name: 'Psiu',
              text:
                  'Ótimo! Agora crie sua senha. Prometo que não vou olhar! 🙈' ??
                      '',
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
          objeto['password'] = passwordConfirm;
          _addMessage(
              name: 'Psiu',
              text:
                  'Tudo certo, ${objeto["nome"]}! 🙂👏 Agora você precisa aceitar os termos de privacidade.' ??
                      '',
              type: ChatMessageType.received,
              content: MessageContent.end);
        }
      }

      if (content == MessageContent.password) {
        isPasswordConfirm = true;
        _addMessage(
            name: 'Psiu',
            text:
                'Top! Digite-a novamente para que o sistema possa validá-la.' ??
                    '',
            type: ChatMessageType.received,
            content: MessageContent.normal);
      }

      if (content == MessageContent.email) {
        objeto['email'] = query;
      } else if (content == MessageContent.emailPin) {
        objeto['emailPin'] = query;
      } else {
        if (intent != null) {
          objeto[intent] = query;
        }
      }
    }

    if (content == MessageContent.normal) {
      var respostas = response.getListMessage();
      for (var i = 0; i < respostas.length; i++) {
        _isEmail(respostas[i]['text']['text'][0]);
        _isPhone(respostas[i]['text']['text'][0]);
        _isPassword(respostas[i]['text']['text'][0]);

        _addMessage(
            name: 'Psiu',
            text: respostas[i]['text']['text'][0] ?? '',
            type: ChatMessageType.received,
            content: MessageContent.normal);
      }
    }

    print('objeto: $objeto');
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

  void _isEmail(String text) {
    text.contains('e-mail') ? isEmail = true : isEmail = false;
  }

  void _isPhone(String text) {
    text.contains('celular') ? isPhone = true : isPhone = false;
  }

  void _isPassword(String text) {
    text.contains('senha') ? isPassword = true : isPassword = false;
  }

  bool validateEmail(String value) {
    Pattern pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regex = new RegExp(pattern);
    return (!regex.hasMatch(value)) ? false : true;
  }
}
