// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:xyz_engine_generators_annotations/xyz_engine_generators_annotations.dart';
import 'package:xyz_utils/xyz_utils.dart';

import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import '/model_visitor.dart';
import '/type_source_mapper.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Builder generateModel(BuilderOptions options) => BuilderGenerateModel();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GeneratorModel extends GeneratorForAnnotation<GenerateModel> {
  //
  //
  //

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // [1] Read the input for the generator.

    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameSuperClass = visitor.nameClass;
    var nameChildClass = nameSuperClass?.replaceFirst("_", "").replaceFirst("Utils", "");
    if (nameChildClass == nameSuperClass) {
      nameChildClass = "Generated$nameChildClass";
    }
    final params = annotation
        .read("parameters")
        .mapValue
        .map(
          (final k, final v) => MapEntry(
            k?.toStringValue()?.trim(),
            v?.toStringValue()?.trim(),
          ),
        )
        .cast<String, String>()
        .entries;

    final paramsWithoutId = params.toList()..removeWhere((final l) => l.key == "id");
    final paramsWithId = List.of(paramsWithoutId)..add(MapEntry("id", "String?"));

    // [2] Prepare member variables.

    final insert2 = paramsWithoutId.map((final l) {
      final fieldName = l.key;
      final fieldKey = fieldName.toSnakeCase();
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      final fieldType = typeSourceRemoveOptions(l.value);
      return [
        "/// Key corresponding to the value `$fieldName`.",
        "static const $fieldK = \"$fieldKey\";",
        "/// Value corresponding to the key `$fieldKey` or [$fieldK].",
        "$fieldType $fieldName;",
      ].join("\n");
    }).toList()
      ..sort();

    // [3] Prepare constructor parameters.

    final insert3 = paramsWithoutId.map((final l) {
      final fieldName = l.key;
      return "this.$fieldName,";
    }).toList()
      ..sort();

    // [4] Prepare fromJson.

    final insert4 = paramsWithId.map((final l) {
      final fieldName = l.key;
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      final fieldTypeSource = l.value;
      final p = "json[$fieldK]";
      final compiled = TypeSourceMapper.withDefaultFromMappers(modelFromMappers)
          .compile(fieldTypeSource, p)
          .replaceFirst(
              "#x0",
              _subEventReplacement(fieldTypeSource, p, {
                ...defaultFromMappers,
                ...modelFromMappers,
              }));
      return "$fieldName: $compiled,";
    }).toList()
      ..sort();

    // [5] Prepare toJson.

    final insert5 = paramsWithId.map((final l) {
      final fieldName = l.key;
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      final fieldTypeSource = l.value;
      final fieldType = typeSourceRemoveOptions(fieldTypeSource);
      final p = fieldName;
      final compiled = TypeSourceMapper.withDefaultToMappers(modelToMappers) //
          .compile(fieldType, p)
          .replaceFirst(
            "#x0",
            _subEventReplacement(fieldType, p, {
              ...defaultToMappers,
              ...modelToMappers,
            }),
          );
      return "$fieldK: $compiled,";
    }).toList()
      ..sort();

    // [6] Prepare newOverride.

    final insert6 = paramsWithId.map((final l) {
      final fieldName = l.key;
      return "$fieldName: other.$fieldName ?? this.$fieldName,";
    }).toList()
      ..sort();

    // [7] Prepare updateWith.

    final insert7 = paramsWithId.map((final l) {
      final fieldName = l.key;
      return "if (other.$fieldName != null) { this.$fieldName = other.$fieldName; }";
    }).toList()
      ..sort();

    // [8] Write the output for the generator.

    buffer.writeAll(
      [
        """
        class $nameChildClass extends $nameSuperClass {
          //
          //
          //

          /// Related member: `this.id`;
          static const K_ID = "id";
          ${insert2.join("\n")}

          //
          //
          //
          
          /// Constructs a new instance of [$nameChildClass] identified by [id].
          $nameChildClass({
            String? id,
            ${insert3.join("\n")}
          }): super._() {
            super.id = id;
          }

          /// Converts a [Json] object to a [$nameChildClass] object.
          factory $nameChildClass.fromJson(Json json) {
            try {
              return $nameChildClass(${insert4.join("\n")});
            } catch (e) {
               throw Exception(
                "[$nameChildClass.fromJson] Failed to convert JSON to $nameChildClass due to: \$e",
                );
            }
          }

          /// Returns a copy of `this` model.
          @override
          T copy<T extends XyzModel>(T other) {
            return ($nameChildClass()..updateWith(other)) as T;
          }

          /// Converts a [$nameChildClass] object to a [Json] object.
          @override
          Json toJson() {
            try {
              return mapToJson(
                {
                  ${insert5.join("\n")}
                }..removeWhere((_, final l) => l == null),
                typesAllowed: {Timestamp, FieldValue},
                // Defined in utils/timestamp.dart
                keyConverter: timestampKeyConverter,
              );
            } catch (e) {
              throw Exception(
                "[$nameChildClass.toJson] Failed to convert $nameChildClass to JSON due to: \$e",
                );
            }
          }
          
          /// Returns a copy of `this` object with the fields in [other] overriding
          /// `this` fields. NB: [other] must be of type $nameChildClass.
          @override
          T newOverride<T extends XyzModel>(T other) {
            if (other is $nameChildClass) {
              return $nameChildClass(${insert6.join("\n")}) as T;
            }
            throw Exception(
              "[$nameChildClass.newOverride] Expected 'other' to be of type $nameChildClass and not \${other.runtimeType}",
              );
          }
          
          /// Returns a new empty instance of [$nameChildClass].
          @override
          T newEmpty<T extends XyzModel>() {
            return $nameChildClass() as T;
          }
          
          /// Updates `this` fields from the fields of [other].
          @override
          void updateWithJson(Json other) {
            this.updateWith($nameChildClass.fromJson(other));
          }
          
          /// Updates `this` fields from the fields of [other].
          @override
          void updateWith<T extends XyzModel>(T other) {
            if (other is $nameChildClass) {
              ${insert7.join("\n")}
              return;
            }
            throw Exception(
              "[$nameChildClass.updateWith] Expected 'other' to be of type $nameChildClass and not \${other.runtimeType}",
              );
          }

          @override
          bool operator ==(Object other) {
            return other is $nameChildClass ? const DeepCollectionEquality().equals(this.toJson(), other.toJson()): false;
          }

          @override
          int get hashCode => this.toString().hashCode;

          @override
          String toString() => this.toJson().toString();
        }
        """,
      ],
      "\n",
    );
    return buffer.toString();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class BuilderGenerateModel extends SharedPartBuilder {
  BuilderGenerateModel()
      : super(
          [GeneratorModel()],
          "generate_model",
        );
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final modelToMappers = TMappers.unmodifiable({
  r"^Model\w+\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}?.toJson().nullsRemoved().nullIfEmpty()";
  },
  r"^Model\w+$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    return "${e.p}.toJson().nullsRemoved().nullIfEmpty()";
  },
});

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

final modelFromMappers = TMappers.unmodifiable({
  r"^Model\w+\?$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    final className = e.keyMatchGroups?.first;
    return "(){final l = letAs<Map>(${e.p}); return l != null ? $className.fromJson(l.map((final p0, final p1,) => MapEntry(p0.toString(), p1,),),): null; }()";
  },
  r"^Model\w+$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    final className = e.keyMatchGroups?.first;
    return "$className.fromJson((${e.p} as Map).map((final p0, final p1,) => MapEntry(p0.toString(), p1,),),)";
  },
  r"^Model\w+\|let$": (e) {
    if (e is! MapperSubEvent) throw TypeError();
    final className = e.keyMatchGroups?.first;
    return "(){final l = letMap<String, dynamic>(${e.p}); return l != null ? $className.fromJson(l): null; }()";
  },
});

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

String _subEventReplacement(
  String fieldType,
  String p,
  TMappers allMappers,
) {
  final filtered = filterMappersForType(
    fieldType,
    allMappers,
  );
  if (filtered.isNotEmpty) {
    final regExp = RegExp(filtered.entries.first.key);
    final match = regExp.firstMatch(fieldType);
    if (match != null) {
      final event = MapperSubEvent.custom(
        p,
        Iterable.generate(match.groupCount + 1, (i) => match.group(i)!),
      );
      return filtered.entries.first.value(event);
    }
  }
  return "null /* ERROR: Unsupported type and/or only nullable types supported */";
}
