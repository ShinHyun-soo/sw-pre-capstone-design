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
          "Using the characteristics of appropriate and inappropriate responses below, please evaluate the interviewee’s interview demeanor and the quality of their responses as evidenced by the given question and answer information to determine the appropriateness of the answer. Please circle an O for appropriate and an X for inappropriate. And also include 3–4 lines of your analysis."

            "###"
            "1. Characteristics of an appropriate answer:
                Clear and specific: The answer is direct and clear, making it easy for the interviewer to understand.
                Relevant: The answer stays on topic and directly addresses the question, without including unnecessary information.
                Based on real experience: The response is grounded in actual experience or concrete examples, adding credibility.
                Confident yet humble: The answer is delivered with confidence, but not arrogance, and conveys a clear, assured tone.
                Concise and respectful: The response is brief and to the point, avoiding overly lengthy explanations, while maintaining politeness."
            "2. Characteristics of an inappropriate answer:
                Unclear or vague: The answer lacks clarity or is too vague, making it difficult for the interviewer to understand.
                Includes irrelevant information: The answer diverges from the question and introduces unrelated topics.
                Lacks real-life examples: The answer is theoretical, hypothetical, or overly general without any actual examples or concrete experience.
                Lack of confidence: The answer is unsure or hesitant, possibly lacking conviction or appearing unprepared.
                Unnecessarily long-winded: The response is overly detailed or lengthy, including irrelevant information that distracts from the main points."
            "3. Expertise essential considerations:
                Knowledge and experience relevant to the job: The answer demonstrates a solid understanding of the skills and experiences required for the job.
                Awareness of industry trends: The response shows an understanding of the latest trends, challenges, or developments within the industry related to the job.
                Problem-solving ability: The ability to approach and solve job-related challenges is a key indicator of expertise.
                Communication skills: Being able to clearly communicate complex ideas or issues in a way that’s easy for others to understand is an essential part of expertise.
                Teamwork and collaboration: In modern roles, the ability to work effectively within a team is often just as important as individual skills, so examples of collaboration and team experience are important."
            "###"

            "###"
            "<<Interview question and answers with answer breakdown>>"
            "Question: {question}"
            "Answer: {answer}"
            "###"
            """
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
