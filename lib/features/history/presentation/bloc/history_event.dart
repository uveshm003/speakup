import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class HistoryLoadRequested extends HistoryEvent {
  const HistoryLoadRequested();
}

/// When null, clears the date filter and shows all loaded sessions in the log.
final class HistoryFilterChanged extends HistoryEvent {
  const HistoryFilterChanged({this.range});

  /// Inclusive date range (date portion used); null = no filter.
  final DateTimeRange? range;

  @override
  List<Object?> get props => <Object?>[range];
}

final class SessionDeleted extends HistoryEvent {
  const SessionDeleted(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => <Object?>[sessionId];
}

final class SessionDeleteUndoRequested extends HistoryEvent {
  const SessionDeleteUndoRequested();
}

final class SessionDeleteCommitted extends HistoryEvent {
  const SessionDeleteCommitted();
}
