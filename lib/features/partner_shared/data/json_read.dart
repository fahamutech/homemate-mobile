/// Small readers for API JSON, so every model parses numbers, dates and
/// lists the same way. Money arrives as strings ("900000.00") from numeric
/// columns and as numbers from jsonb — both are read here.
double readNum(Object? value) => switch (value) {
      null => 0,
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0,
      _ => 0,
    };

int readInt(Object? value) => readNum(value).round();

DateTime? readDate(Object? value) => value == null ? null : DateTime.tryParse('$value');

Map<String, dynamic> readMap(Object? value) => value is Map<String, dynamic> ? value : const {};

List<T> readList<T>(Object? value, T Function(Map<String, dynamic>) parse) => [
      for (final item in (value as List? ?? const []))
        if (item is Map<String, dynamic>) parse(item),
    ];
