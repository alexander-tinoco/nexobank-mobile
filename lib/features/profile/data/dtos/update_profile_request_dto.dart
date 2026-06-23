class UpdateProfileRequestDto {
  const UpdateProfileRequestDto({this.name, this.phone});

  final String? name;
  final String? phone;

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
      };
}
