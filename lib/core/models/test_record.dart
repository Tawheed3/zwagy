import 'dart:convert';

class TestRecord {
  final int? id;
  final String name;
  final int age;
  final String address;
  final String phone;
  final DateTime testDate;
  final double overallScore;
  final String status;
  final Map<String, double> categoryScores;
  final List<Map<String, dynamic>> strengths; // top 4 only
  final List<Map<String, dynamic>> weaknesses; // top 12 only
  final String advice;
  final Map<String, int> answers;
  final List<String> questions;

  TestRecord({
    this.id,
    required this.name,
    required this.age,
    required this.address,
    required this.phone,
    required this.testDate,
    required this.overallScore,
    required this.status,
    required this.categoryScores,
    required this.strengths,
    required this.weaknesses,
    required this.advice,
    required this.answers,
    required this.questions,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'address': address,
      'phone': phone,
      'testDate': testDate.toIso8601String(),
      'overallScore': overallScore,
      'status': status,
      'categoryScores': jsonEncode(categoryScores),
      'strengths': jsonEncode(strengths),
      'weaknesses': jsonEncode(weaknesses),
      'advice': advice,
      'answers': jsonEncode(answers),
      'questions': jsonEncode(questions),
    };
  }

  factory TestRecord.fromMap(Map<String, dynamic> map) {
    return TestRecord(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      address: map['address'],
      phone: map['phone'],
      testDate: DateTime.parse(map['testDate']),
      overallScore: map['overallScore'],
      status: map['status'],
      categoryScores: Map<String, double>.from(jsonDecode(map['categoryScores'])),
      strengths: List<Map<String, dynamic>>.from(jsonDecode(map['strengths'])),
      weaknesses: List<Map<String, dynamic>>.from(jsonDecode(map['weaknesses'])),
      advice: map['advice'],
      answers: Map<String, int>.from(jsonDecode(map['answers'])),
      questions: List<String>.from(jsonDecode(map['questions'])),
    );
  }

  // for display in list
  String get formattedDate {
    return '${testDate.day}/${testDate.month}/${testDate.year}';
  }

  String get formattedTime {
    return '${testDate.hour}:${testDate.minute.toString().padLeft(2, '0')}';
  }
}