// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

class TypeSourceMapper {
  //
  //
  //

  final Map<RegExp, String Function(_MapperEvent)> _moreMappers;

  //
  //
  //

  const TypeSourceMapper([this._moreMappers = const {}]);

  //
  //
  //

  String compile(String typeSource, String name) {
    final parsed = _parseTypeSource(typeSource);
    final compiled = _complieExpression(
      parsed,
      moreMappers: this._moreMappers,
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

String? _mapped(
  _MapperEvent event,
  Map<RegExp, String Function(_MapperEvent)> moreMappers,
) {
  final type = event.type;
  if (type != null) {
    final all = {..._defaultMappers, ...moreMappers}.entries.where((final l) {
      final exp = l.key;
      return exp.hasMatch(type);
    });
    assert(all.length <= 1, "Multiple mapper matches found!");
    if (all.length == 1) {
      final first = all.first;
      final exp = first.key;
      final mapper = first.value;
      final match = exp.firstMatch(type)!;
      event._keyMatchGroups = Iterable.generate(match.groupCount + 1, (i) => match.group(i)!);
      return mapper(event);
    }
  }
  return null;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String _complieExpression(
  List<List<String>> parsedTypeSource, {
  Map<RegExp, String Function(_MapperEvent)> moreMappers = const {},
}) {
  var output = "#x0";
  // Loop through type elements.
  for (final typeElement in parsedTypeSource) {
    final base = _MapperBaseEvent().._pTypes = typeElement.skip(2);
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
    final mapped = _mapped(base, moreMappers);
    if (mapped != null) {
      output = output.replaceFirst(xHash, mapped);
    } else {
      assert(false, "Base-type mapper not found!");
    }
    // Loop through subtypes.
    for (var n = 0; n < pLength; n++) {
      final sub = _MapperSubEvent()
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
        final mapped = _mapped(sub, moreMappers);
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
  int? _pN;
  String? _type;
  int? get pN => this._pN;
  String? get p => _pN != null ? "p${this._pN}" : null;
  String? get type => this._type;
  Iterable<String>? _keyMatchGroups;
  Iterable<String>? get keyMatchGroups => this._keyMatchGroups;
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class _MapperBaseEvent extends _MapperEvent {
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

class _MapperSubEvent extends _MapperEvent {}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final _defaultMappers = <RegExp, String Function(_MapperEvent)>{
  RegExp(r"^Map$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Map).map((${e.args}) => MapEntry(${e.hashes},),)";
  },
  RegExp(r"^Map\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Map?)?.map((${e.args}) => MapEntry(${e.hashes},),)";
  },
  RegExp(r"^Map\|clean$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Map).map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  RegExp(r"^Map\|clean\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Map?)?.map((${e.args}) => MapEntry(${e.hashes},),).nullsRemoved().nullIfEmpty()";
  },
  //
  RegExp(r"^List$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as List).map((${e.args}) => ${e.hashes},).toList()";
  },
  RegExp(r"^List\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as List?)?.map((${e.args}) => ${e.hashes},).toList()";
  },
  RegExp(r"^List\|clean$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as List).map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  RegExp(r"^List\|clean\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as List?)?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toList()";
  },
  //
  RegExp(r"^Set$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Set).map((${e.args}) => ${e.hashes},).toSet()";
  },
  RegExp(r"^Set\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Set?)?.map((${e.args}) => ${e.hashes},).toSet()";
  },
  RegExp(r"^Set\|clean$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Set).map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toSet()";
  },
  RegExp(r"^Set\|clean\?$"): (e) {
    e as _MapperBaseEvent;
    return "(${e.p} as Set?)?.map((${e.args}) => ${e.hashes},).nullsRemoved().nullIfEmpty()?.toSet()";
  },
  //
  RegExp(r"^dynamic$"): (e) {
    e as _MapperSubEvent;
    return "${e.p}";
  },
  RegExp(r"^dynamic\?$"): (e) {
    e as _MapperSubEvent;
    return "${e.p}";
  },
  //
  RegExp(r"^bool$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as bool)";
  },
  RegExp(r"^bool\?$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as bool?)";
  },
  RegExp(r"^bool\|let$"): (e) {
    e as _MapperSubEvent;
    return "letBool(${e.p})";
  },
  //
  RegExp(r"^num$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as int)";
  },
  RegExp(r"^num\?$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as num?)";
  },
  RegExp(r"^num\|let$"): (e) {
    e as _MapperSubEvent;
    return "letNum(${e.p})";
  },
  //
  RegExp(r"^int$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as int)";
  },
  RegExp(r"^int\?$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as int?)";
  },
  RegExp(r"^int\|let$"): (e) {
    e as _MapperSubEvent;
    return "letInt(${e.p})";
  },
  //
  RegExp(r"^double$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as double)";
  },
  RegExp(r"^double\?$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p} as double?)";
  },
  RegExp(r"^double\|let$"): (e) {
    e as _MapperSubEvent;
    return "letDouble(${e.p})";
  },
  //
  RegExp(r"^String$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p}.toString())";
  },
  RegExp(r"^String\?$"): (e) {
    e as _MapperSubEvent;
    return "(${e.p}?.toString())";
  },
  RegExp(r"^String\|let$"): (e) {
    e as _MapperSubEvent;
    return "letString(${e.p})";
  },
};
