/// Reglas del contador de repeticiones (rewatch / relectura / rejugado).
abstract final class RepeatCountRules {
  /// +1 al terminar una repetición (REPEATING → COMPLETED); en otro caso igual.
  static int afterStatusChange({
    required String? fromStatus,
    required String toStatus,
    required int count,
  }) {
    final from = fromStatus?.toUpperCase();
    final to = toStatus.toUpperCase();
    if (from == 'REPEATING' && to == 'COMPLETED') return count + 1;
    return count;
  }

  /// Cambio de estado en el editor. [autoBumped] indica si ya se sumó +1 por
  /// pasar a COMPLETED; si se sale de COMPLETED se deshace ese +1.
  static ({int count, bool autoBumped}) onEditorStatusChange({
    required String fromStatus,
    required String toStatus,
    required int count,
    required bool autoBumped,
  }) {
    final from = fromStatus.toUpperCase();
    final to = toStatus.toUpperCase();
    if (from == to) return (count: count, autoBumped: autoBumped);
    if (!autoBumped) {
      final next = afterStatusChange(
        fromStatus: from,
        toStatus: to,
        count: count,
      );
      return (count: next, autoBumped: next != count);
    }
    if (to == 'COMPLETED') return (count: count, autoBumped: true);
    return (count: count > 0 ? count - 1 : 0, autoBumped: false);
  }
}
