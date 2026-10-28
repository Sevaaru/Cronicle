import 'package:cronicle/features/library/domain/repeat_count_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('afterStatusChange', () {
    test('suma 1 al pasar de repitiendo a completado', () {
      expect(
        RepeatCountRules.afterStatusChange(
          fromStatus: 'REPEATING',
          toStatus: 'COMPLETED',
          count: 2,
        ),
        3,
      );
    });

    test('no cambia en otras transiciones', () {
      expect(
        RepeatCountRules.afterStatusChange(
          fromStatus: 'CURRENT',
          toStatus: 'COMPLETED',
          count: 2,
        ),
        2,
      );
      expect(
        RepeatCountRules.afterStatusChange(
          fromStatus: null,
          toStatus: 'COMPLETED',
          count: 0,
        ),
        0,
      );
    });

    test('ignora mayúsculas y minúsculas', () {
      expect(
        RepeatCountRules.afterStatusChange(
          fromStatus: 'repeating',
          toStatus: 'completed',
          count: 0,
        ),
        1,
      );
    });
  });

  group('onEditorStatusChange', () {
    test('repitiendo a completado suma 1 y lo marca como automático', () {
      final r = RepeatCountRules.onEditorStatusChange(
        fromStatus: 'REPEATING',
        toStatus: 'COMPLETED',
        count: 1,
        autoBumped: false,
      );
      expect(r.count, 2);
      expect(r.autoBumped, isTrue);
    });

    test('salir de completado deshace el +1 automático', () {
      final r = RepeatCountRules.onEditorStatusChange(
        fromStatus: 'COMPLETED',
        toStatus: 'REPEATING',
        count: 2,
        autoBumped: true,
      );
      expect(r.count, 1);
      expect(r.autoBumped, isFalse);
    });

    test('reseleccionar el mismo estado no cambia nada', () {
      final r = RepeatCountRules.onEditorStatusChange(
        fromStatus: 'COMPLETED',
        toStatus: 'COMPLETED',
        count: 2,
        autoBumped: true,
      );
      expect(r.count, 2);
      expect(r.autoBumped, isTrue);
    });

    test('completar sin venir de repitiendo no suma', () {
      final r = RepeatCountRules.onEditorStatusChange(
        fromStatus: 'CURRENT',
        toStatus: 'COMPLETED',
        count: 0,
        autoBumped: false,
      );
      expect(r.count, 0);
      expect(r.autoBumped, isFalse);
    });
  });
}
