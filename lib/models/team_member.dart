class TeamMember {
  final String id;
  final String name;

  TeamMember({required this.id, required this.name});

  Map<String, dynamic> toJson() => {'id': id, 'name': name};

  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      TeamMember(id: json['id'], name: json['name']);
}
