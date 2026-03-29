import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';

/// [GoRouter] extra for `/custom-categories/create-card`.
class CreateCardRouteArgs {
  const CreateCardRouteArgs({required this.category, this.existingCard});

  final CustomCategory category;
  final TopicCard? existingCard;
}
