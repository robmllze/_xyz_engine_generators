// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

typedef TMappers = Map<String, String Function(_MapperEvent)>;

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class TypeSourceMapper {
  //
  //
  //

  final TMappers mappers;

  //
  //
  //

  const TypeSourceMapper([this.mappers = const {}]);

  //
  //
  //

  factory TypeSourceMapper.withDefaultToMappers([
    TMappers moreMappers = const {},
  ]) {
    return TypeSourceMapper({...defaultToMappers, ...moreMappers});
  }

  //
  //
  //

  factory TypeSourceMapper.withDefaultFromMappers([
    TMappers moreMappers = const {},
  ]) {
    return TypeSourceMapper({...defaultFromMappers, ...moreMappers});
  }

  //
  //
  //

  String compile(String typeSource, String name) {
    final parsed = _parseTypeSource(typeSource);
    final compiled = _complieExpression(
      parsed,
      mappers: this.mappers,
    );
    return compiled.replaceFirst("p0", name);
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

List<List<String>> _parseTypeSource(String typeSource) {
  final unsorted = <int, List<String>>{};
  String? $parseTypeSource(String type) {
    var input = type.replaceAll(" ", "");
    final c0 = r"[\w\*\|\?]+";
    final c1 = r"\b(" "$c0" r")\<((" "$c0" r")(\," "$c0" r")*)\>(\?)?";
    final entries = RegExp(c1).allMatches(input).map((final l) {
      final typeLong = l.group(0)!;
      final typeShort = l.group(1)!;
      final subtypes = l.group(2)!.split(",");
      final nullable = l.group(5);
      return MapEntry(l.start, [typeLong, "$typeShort${nullable ?? ""}", ...subtypes]);
    });
    unsorted.addEntries(entries);

    for (final entry in entries) {
      final x = entry.value.first;
      input = input.replaceFirst(x, "*" * x.length);
    }
    return entries.isEmpty ? null : input;
  }

  String? $typeSource = typeSource;
  do {
    $typeSource = $parseTypeSource($typeSource!);
  } while ($typeSource != null);
  final sorted = (unsorted.entries.toList()..sort(((final a, final b) => a.key.compareTo(b.key))))
      .map((l) => l.value)
      .toList();
  return sorted;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

TMappers filterMappersForType(
  String type,
  TMappers allMappers,
) {
  return Map.fromEntries(
    allMappers.entries.where((final l) {
      return RegExp(l.key).hasMatch(type);
    }),
  );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String? _mapped(
  _MapperEvent event,
  TMappers mappers,
) {
  final type = event.type;
  if (type != null) {
    final all = filterMappersForType(type, mappers);
    assert(all.length <= 1, "Multiple mapper matches found!");
    if (all.length == 1) {
      final first = all.entries.first;
      final mapper = first.value;
      final regExp = RegExp(first.key);
      final match = regExp.firstMatch(type)!;
      event._keyMatchGroups = Iterable.generate(match.groupCount + 1, (i) => match.group(i)!);
      return mapper(event);
    }
  }
  return null;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String _complieExpression(
  List<List<String>> parsedTypeSource, {
  TMappers mappers = const {},
}) {
  var output = "#x0";
  // Loop through type elements.
  for (final typeElement in parsedTypeSource) {
    final base = MapperBaseEvent().._pTypes = typeElement.skip(2);
    final pLength = base._pTypes.length;
    base
      .._pHashes = Iterable.generate(pLength, (final i) => i).map((l) => "#p$l")
      .._pParams = Iterable.generate(pLength, (final i) => i).map((l) => "p$l")
      .._pArgs = Iterable.generate(pLength, (final i) => i).map((l) => "final p$l")
      .._type = typeElement[1];
    final argIdMatch = RegExp(r"#x(\d+)").firstMatch(output);
    base._pN = argIdMatch != null && argIdMatch.groupCount > 0 //
        ? int.tryParse(argIdMatch.group(1)!)
        : null;
    final xHash = "#x${base._pN}";
    final mapped = _mapped(base, mappers);
    if (mapped != null) {
      output = output.replaceFirst(xHash, mapped);
    } else {
      assert(false, "Base-type mapper not found!");
    }
    // Loop through subtypes.
    for (var n = 0; n < pLength; n++) {
      final sub = MapperSubEvent()
        .._pN = n
        .._type = base._pTypes.elementAt(n);
      final pHash = "#p$n";

      // If the subtype is the next type element.
      if (sub.type?[0] == "*") {
        final xHash = "#x$n";
        output = output.replaceFirst(pHash, xHash);
      }
      // If the subtype is something other, presumably a simple object like
      // num, int, double, bool or String.
      else {
        final mapped = _mapped(sub, mappers);
        if (mapped != null) {
          output = output.replaceFirst(pHash, mapped);
        } else {
          assert(false, "Sub-type mapper not found!");
        }
      }
    }
  }
  return output;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

abstract class _MapperEvent {
  String? _p;
  int? _pN;
  String? _type;
  int? get pN => this._pN;
  String? get p => this._p ?? (_pN != null ? "p${this._pN}" : null);
  String? get type => this._type;
  Iterable<String>? _keyMatchGroups;
  Iterable<String>? get keyMatchGroups => this._keyMatchGroups;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MapperBaseEvent extends _MapperEvent {
  Iterable<String> _pArgs = [];
  Iterable<String> _pHashes = [];
  Iterable<String> _pParams = [];
  Iterable<String> _pTypes = [];
  Iterable<String> get pArgs => this._pArgs;
  Iterable<String> get pHashes => this._pHashes;
  Iterable<String> get pParams => this._pParams;
  Iterable<String> get pTypes => this._pTypes;
  String get args => this._pArgs.join(", ");
  String get hashes => this._pHashes.join(", ");
  String get params => this._pParams.join(", ");
  String get types => this._pTypes.join(", ");
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class MapperSubEvent extends _MapperEvent {
  MapperSubEvent();
  MapperSubEvent.custom(String p, Iterable<String> keyMatchGroups) {
    this._p = p;
    this._keyMatchGroups = keyMatchGroups;
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String typeSourceRemoveCleaned(String typeSource) {
  var temp = typeSource.replaceAll(" ", "");
  while (true) {
    final matches = RegExp(r"\w+(\|clean)?\<([\w\[\]\+]+\??)(,[\w\[\]\+]+\??)*\>").allMatches(temp);
    if (matches.isEmpty) break;
    final match = matches.first;
    final group0 = match.group(0)!;
    temp = temp.replaceAll(
      group0,
      group0
          .replaceAll("|clean", "")
          .replaceAll("?", "")
          .replaceAll("<", "[")
          .replaceAll(">", "]")
          .replaceAll(",", "+"),
    );
  }

  return temp.replaceAll("[", "<").replaceAll("]", ">").replaceAll("+", ", ");
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final defaultToMappers = TMappers.unmodifiable({
  r"^Map$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}.map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  r"^Map\?$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}?.map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  //
  r"^List$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  r"^List\?$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  //
  r"^Set$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  r"^Set\?$": /* clean */ (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "${e.p}?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  //
  r"^(dynamic|bool|num|int|double)\??$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}";
  },
  //
  r"^String$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}.nullIfEmpty()";
  },
  r"^String\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}?.nullIfEmpty()";
  },
  //
  r"^DateTime$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}.toUtc().toIso8601String()";
  },
  r"^DateTime\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}?.toUtc().toIso8601String()";
  },
});

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final defaultFromMappers = TMappers.unmodifiable({
  r"^Map$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as Map).map((${e.args}) => MapEntry(${e.hashes},),)";
  },
  r"^Map\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<Map>(${e.p})?.map((${e.args}) => MapEntry(${e.hashes},),)";
  },
  r"^Map\|clean$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as Map).map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  r"^Map\|clean\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<Map>(${e.p})?.map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  //
  r"^List$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as List).map((${e.args}) => ${e.hashes},).toList()";
  },
  r"^List\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<List>(${e.p})?.map((${e.args}) => ${e.hashes},).toList()";
  },
  r"^List\|clean$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as List).map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  r"^List\|clean\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<List>(${e.p})?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  //
  r"^Set$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as Set).map((${e.args}) => ${e.hashes},).toSet()";
  },
  r"^Set\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<Set>(${e.p})?.map((${e.args}) => ${e.hashes},).toSet()";
  },
  r"^Set\|clean$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "(${e.p} as Set).map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toSet()";
  },
  r"^Set\|clean\?$": (e) {
    if (e is! MapperBaseEvent) throw TypeError();
    return "letAs<Set>(${e.p})?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toSet()";
  },
  //
  r"^dynamic$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}";
  },
  r"^dynamic\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}";
  },
  //
  r"^bool$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p} as bool)";
  },
  r"^bool\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letAs<bool>(${e.p})";
  },
  r"^bool\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letBool(${e.p})";
  },
  //
  r"^num$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p} as num)";
  },
  r"^num\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letAs<num>(${e.p})";
  },
  r"^num\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letNum(${e.p})";
  },
  //
  r"^int$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p} as int)";
  },
  r"^int\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letAs<int>(${e.p})";
  },
  r"^int\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letInt(${e.p})";
  },
  //
  r"^double$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p} as double)";
  },
  r"^double\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letAs<double>(${e.p})";
  },
  r"^double\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letDouble(${e.p})";
  },
  //
  r"^String$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p}.toString())";
  },
  r"^String\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "(${e.p}?.toString())";
  },
  r"^String\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letString(${e.p})";
  },
  //
  r"^DateTime$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "DateTime.parse(${e.p}.toString())";
  },
  r"^DateTime\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "DateTime.tryParse(${e.p}.toString())";
  },
  r"^DateTime\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "letDateTime(${e.p})";
  },
});
