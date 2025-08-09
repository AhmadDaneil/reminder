class Reminder{
  final int? id;
  final String title;
  final String content;
  final String dateTime;

  Reminder({
    this.id,
    required this.title,
    required this.content,
    required this.dateTime,
  });

  Map<String, dynamic> toMap(){
    return {
      'id' : id,
      'title' : title,
      'content' : content,
      'dateTime' : dateTime,
    };
  } 

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      dateTime: map['dateTime'],
    );
  }
}