import 'package:flutter/material.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:contact/env/env.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Interview Game',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: InterviewScreen(),
    );
  }
}

class InterviewScreen extends StatefulWidget {
  @override
  _InterviewScreenState createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  final OpenAIService _openAIService = OpenAIService();
  String _question = "Ready for your first question?";
  String _response = "";
  TextEditingController _controller = TextEditingController();

  // AI 질문 생성
  Future<void> _getQuestion() async {
    String question = await _openAIService.generateQuestion();
    setState(() {
      _question = question;
      _response = ""; // 기존 응답 초기화
    });
  }

  // 사용자 답변을 AI로 평가
  Future<void> _evaluateAnswer() async {
    String userAnswer = _controller.text;
    String evaluation = await _openAIService.evaluateAnswer(userAnswer);

    setState(() {
      _response = evaluation; // 평가 결과 출력
    });

    // 점수가 5점인 경우 다음 질문
    if (evaluation.contains("5점")) {
      await Future.delayed(Duration(seconds: 1));
      _getQuestion();
    }
    _controller.clear();
  }

  @override
  void initState() {
    super.initState();
    _getQuestion(); // 초기 질문 생성
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Interview Game'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Question: $_question',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Type your answer',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _evaluateAnswer,
              child: Text('Submit Answer'),
            ),
            SizedBox(height: 20),
            Text(
              'Evaluation: $_response',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

class OpenAIService {
  Future<String> generateQuestion() async {
    OpenAI.apiKey = Env.apiKey;
    // 질문 요청 메시지
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You are an interviewer. Provide only one interview question in Korean.",
        ),
      ],
      role: OpenAIChatMessageRole.system,
    );

    final requestMessages = [systemMessage];

    OpenAIChatCompletionModel chatCompletion =
    await OpenAI.instance.chat.create(
      model: 'gpt-4',
      messages: requestMessages,
      maxTokens: 100,
    );

    return chatCompletion.choices.first.message.content![0].text.toString();
  }

  Future<String> evaluateAnswer(String answer) async {
    OpenAI.apiKey = Env.apiKey;

    // 평가 요청 메시지
    final systemMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          "You are an interviewer. After receiving an answer, evaluate it in Korean based on the following criteria:\n"
              "5점: 아주 좋은 답변\n"
              "4점: 살짝 좋은 답변\n"
              "3점: 보통 답변\n"
              "2점: 그저 그런 답변\n"
              "1점: 아주 안좋은 답변\n"
              "Please only respond with the score in Korean and an explanation.",
        ),
      ],
      role: OpenAIChatMessageRole.system,
    );

    final userMessage = OpenAIChatCompletionChoiceMessageModel(
      content: [
        OpenAIChatCompletionChoiceMessageContentItemModel.text(
          answer,
        ),
      ],
      role: OpenAIChatMessageRole.user,
    );

    final requestMessages = [
      systemMessage,
      userMessage,
    ];

    OpenAIChatCompletionModel chatCompletion =
    await OpenAI.instance.chat.create(
      model: 'gpt-4o',
      messages: requestMessages,
      maxTokens: 100,
    );

    return chatCompletion.choices.first.message.content![0].text.toString();
  }
}
