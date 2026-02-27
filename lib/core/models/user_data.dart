class UserData {
  final String name;
  final int age;
  final String address;
  final String phone;
  final DateTime testDate;

  UserData({
    required this.name,
    required this.age,
    required this.address,
    required this.phone,
    required this.testDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'address': address,
      'phone': phone,
      'testDate': testDate.toIso8601String(),
    };
  }

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      name: json['name'],
      age: json['age'],
      address: json['address'],
      phone: json['phone'],
      testDate: DateTime.parse(json['testDate']),
    );
  }
}