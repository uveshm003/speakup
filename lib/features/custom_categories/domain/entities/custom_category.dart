import 'package:equatable/equatable.dart';

class CustomCategory extends Equatable {
  const CustomCategory({required this.categoryId, required this.name, required this.iconEmoji, required this.createdAt});

  final String categoryId;
  final String name;
  final String iconEmoji;
  final DateTime createdAt;

  @override
  List<Object?> get props => <Object?>[categoryId, name, iconEmoji, createdAt];
}
