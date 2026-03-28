import 'package:equatable/equatable.dart';

class VocabWord extends Equatable {
  const VocabWord({required this.word, required this.meaning});

  final String word;
  final String meaning;

  @override
  List<Object?> get props => <Object?>[word, meaning];
}
