// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'package:xyz_engine_generators_annotations/xyz_engine_generators_annotations.dart';
import 'package:xyz_utils/xyz_utils.dart';

import '../model_visitor.dart';
import '../type_source_mapper.dart';

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
    // Input.
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameClass = visitor.nameClass?.replaceFirst("_", "");
    final path = annotation.read("path").stringValue;
    final parameters0 = annotation
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
    final parameters1 = parameters0.toList()..removeWhere((final l) => l.key == "id");

    // Prepare member variables.
    final insertMemberVariables = parameters1.map((final l) {
      final fieldName = l.key;
      final fieldType = typeSourceRemoveOptions(l.value);
      return "$fieldType $fieldName;";
    }).toList()
      ..sort();

    // // Prepare constructor parameters.
    final insertConstructorParameters = parameters1.map((final l) {
      final fieldName = l.key;
      return "this.$fieldName,";
    }).toList()
      ..sort();

    // Prepare fromJson.
    final insertFromJson = parameters0.map((final l) {
      final fieldName = l.key;
      final fieldNameSnakeCase = fieldName.toSnakeCase();
      final fieldTypeSource = l.value;
      //final fieldType = typeSourceRemoveCleaned(fieldTypeSource);
      final p = "json[\"$fieldNameSnakeCase\"]";
      final compiled = TypeSourceMapper.withDefaultFromMappers(modelFromMappers)
          .compile(fieldTypeSource, p)
          .replaceFirst(
              "#x0",
              _subEventReplacement(fieldTypeSource, p, {
                ...defaultFromMappers,
                ...modelFromMappers,
              }));
      return "$fieldName = $compiled";
    }).toList()
      ..sort();

    // Prepare toJson.
    final insertToJson = parameters0.map((final l) {
      final fieldName = l.key;
      final fieldNameSnakeCase = fieldName.toSnakeCase();
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
      return "\"$fieldNameSnakeCase\": $compiled";
    }).toList()
      ..sort();

    // Prepare newWith.
    final insertNewWith = parameters0.map((final l) {
      final fieldName = l.key;
      return "$fieldName: other.$fieldName ?? this.$fieldName,";
    }).toList()
      ..sort();

    // Prepare updateWith.
    final insertUpdateWith = parameters0.map((final l) {
      final fieldName = l.key;
      return "if (other.$fieldName != null) { this.$fieldName = other.$fieldName; }";
    }).toList()
      ..sort();

    // Output.
    buffer.writeAll(
      [
        """
        class $nameClass extends GeneratedModel {
          //
          //
          //

          ${insertMemberVariables.join("\n")}
          
          //
          //
          //

          $nameClass({
            String? id,
            ${insertConstructorParameters.join("\n")}
          }) {
            super.id = id;
          }

          //
          //
          //

          $nameClass.fromJson(Map<String, dynamic> json) {
            try {
              ${insertFromJson.join(";\n")};
            } catch (e) {
              assert(
                false,
                "Exception (\${e.runtimeType}) caught at $nameClass.fromJson",
              );
              rethrow;
            }
          }

          //
          //
          //

          @override
          Map<String, dynamic> toJson() {
            try {
              return mapToJson(
                {
                  ${insertToJson.join(",\n")},
                }..removeWhere((_, final l) => l == null),
              );
            } catch (e) {
              assert(
                false,
                "Exception (\${e.runtimeType}) caught at $nameClass.toJson",
              );
              rethrow;
            }
          }

          //
          //
          //

          /// Returns a new instance of [$nameClass] with the fields in
          /// [other] merged with/overriding the current fields.
          @override
          T newWithJson<T extends GeneratedModel>(Map<String, dynamic> other) {
            return $nameClass.fromJson(this.toJson()..addAll(other)) as T;
          }

          //
          //
          //
          
          /// Returns a new instance of [$nameClass] with the fields in
          /// [other] merged with/overriding  the current fields.
          @override
          T newWith<T extends GeneratedModel>(T other) {
            assert(other is $nameClass);
            return (other is $nameClass ? $nameClass(${insertNewWith.join("\n")}): $nameClass()) as T;
          }

          //
          //
          //
          
          /// Returns a new instance of [$nameClass] with empty fields.
          @override
          T newEmpty<T extends GeneratedModel>() {
            return $nameClass() as T;
          }

          //
          //
          //
          
          /// Updates fields from the fields of [other].
          @override
          void updateWithJson(Map<String, dynamic> other) {
            this.updateWith($nameClass.fromJson(other));
          }

          //
          //
          //
          
          /// Updates fields from the fields of [other].
          @override
          void updateWith<T extends GeneratedModel>(T other) {
            assert(other is $nameClass);
            if (other is $nameClass) {
              ${insertUpdateWith.join("\n")}
            }
          }

          //
          //
          //

          @override
          bool operator ==(Object other) {
            if (other is $nameClass) {
              return const DeepCollectionEquality().equals(this.toJson(), other.toJson());
            }
            return false;
          }

          //
          //
          //

          @override
          int get hashCode => this.toJson().hashCode;

          //
          //
          //

          @override
          String toString() => this.toJson().toString();
        """,

        // Utils for Firebase
        if (path.isNotEmpty) ...[
          """
          // ---------------------------------------------------------------------------
          // Utils for Firebase
          // ---------------------------------------------------------------------------

          static const PATH = "$path";

          //
          //
          //

          static String _p(String? path, Map<String, dynamic> json) {
            return (path ?? PATH).replaceHandlebars(json, "{", "}");
          }

          //
          //
          //

          @override
          DocumentReference<Map<String, dynamic>> refFirebase([String? path]) {
            return G.fbFirestore.documentReference(_p(path, this.toJson()));
          }

          //
          //
          //

          @override
          Future<void> toFirebase({
            bool merge = true,
            String? path,
          }) async {
            final json = this.toJson();
            await G.fbFirestore.documentReference(_p(path, json)).set(
              json,
              SetOptions(merge: merge),
            );
          }

          //
          //
          //

          static Future<$nameClass?> fromFirebase({
            String? id,
            String? path,
          }) async {
            final ref = G.fbFirestore.documentReference(_p(path, {"id": id}));
            final json = (await ref.get()).data();
            return json != null ? $nameClass.fromJson(json) : null;
          }

          //
          //
          //

          @override
          Future<void> deleteFromFirebase({String? path}) async {
            await this.refFirebase(path).delete();
          }
          """
        ],
        "}"
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
  return "null /* error */";
}
