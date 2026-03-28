import 'package:equatable/equatable.dart';

class NavigationState extends Equatable {
  const NavigationState({this.selectedIndex = 0});

  /// 0 Home, 1 Favorites, 2 History, 3 Settings
  final int selectedIndex;

  @override
  List<Object?> get props => <Object?>[selectedIndex];
}
