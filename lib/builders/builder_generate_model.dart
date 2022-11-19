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
    // Input.
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameClass = visitor.nameClass?.replaceFirst("_", "");
    final path = annotation.read("path").stringValue;
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

    // Prepare member variables.
    final insertMemberVariables = paramsWithoutId.map((final l) {
      final fieldName = l.key;
      final fieldKey = fieldName.toSnakeCase();
      final fieldType = typeSourceRemoveOptions(l.value);
      return [
        "/// Variable: \"$fieldName\"",
        "static const k${fieldName.capitalize()} = \"$fieldKey\";",
        "/// Key: \"$fieldKey\"",
        "$fieldType $fieldName;",
      ].join("\n");
    }).toList()
      ..sort();

    // Prepare constructor parameters.
    final insertConstructorParameters = paramsWithoutId.map((final l) {
      //final isNullable = typeSourceRemoveOptions(l.value).endsWith("?");
      final fieldName = l.key;
      return "this.$fieldName,";
      //return "${isNullable ? "" : "required "}this.$fieldName,";
    }).toList()
      ..sort();

    // Prepare fromJson.
    final insertFromJson = paramsWithId.map((final l) {
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
      return "$fieldName: $compiled,";
    }).toList()
      ..sort();

    // Prepare toJson.
    final insertToJson = paramsWithId.map((final l) {
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
      return "\"$fieldNameSnakeCase\": $compiled,";
    }).toList()
      ..sort();

    // Prepare newOverride.
    final insertNewWith = paramsWithId.map((final l) {
      final fieldName = l.key;
      return "$fieldName: other.$fieldName ?? this.$fieldName,";
    }).toList()
      ..sort();

    // Prepare updateWith.
    final insertUpdateWith = paramsWithId.map((final l) {
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
          
          /// Constructs a new instance of [$nameClass] identified by [id].
          $nameClass({
            String? id,
            ${insertConstructorParameters.join("\n")}
          }) {
            super.id = id;
          }

          /// Converts a JSON object to a $nameClass object.
          factory $nameClass.fromJson(Json json) {
            try {
              return $nameClass(${insertFromJson.join("\n")});
            } catch (e) {
               throw Exception(
                "[$nameClass.fromJson] Failed to convert JSON to $nameClass due to: \$e",
                );
            }
          }

          /// Returns a copy of `this` model.
          @overrride
          T copy<T extends GeneratedModel>(T other) {
            return ($nameClass()..updateWith(other)) as T;
          }

          @override
          /// Converts a $nameClass object to a JSON object.
          Json toJson() {
            try {
              return mapToJson(
                {
                  ${insertToJson.join("\n")}
                }..removeWhere((_, final l) => l == null),
              );
            } catch (e) {
              throw Exception(
                "[$nameClass.toJson] Failed to convert $nameClass to JSON due to: \$e",
                );
            }
          }
          
          /// Returns a copy of `this` object with the fields in [other] overriding
          /// `this` fields. NB: [other] must be of type $nameClass.
          @override
          T newOverride<T extends GeneratedModel>(T other) {
            if (other is $nameClass) {
              return $nameClass(${insertNewWith.join("\n")}) as T;
            }
            throw Exception(
              "[$nameClass.newOverride] Expected 'other' to be of type $nameClass and not \${other.runtimeType}",
              );
          }
          
          /// Returns a new empty instance of [$nameClass].
          @override
          T newEmpty<T extends GeneratedModel>() {
            return $nameClass() as T;
          }
          
          /// Updates `this` fields from the fields of [other].
          @override
          void updateWithJson(Json other) {
            this.updateWith($nameClass.fromJson(other));
          }
          
          /// Updates `this` fields from the fields of [other].
          @override
          void updateWith<T extends GeneratedModel>(T other) {
            if (other is $nameClass) {
              ${insertUpdateWith.join("\n")}
              return;
            }
            throw Exception(
              "[$nameClass.newOverride] Expected 'other' to be of type $nameClass and not \${other.runtimeType}",
              );
          }

          @override
          bool operator ==(Object other) {
            if (other is $nameClass) {
              return const DeepCollectionEquality().equals(this.toJson(), other.toJson());
            }
            return false;
          }

          @override
          int get hashCode => this.toJson().hashCode;

          @override
          String toString() => this.toJson().toString();
        """,
        if (path.isNotEmpty) ...[
          """
          // ---------------------------------------------------------------------------
          // SERVER UTILS
          // ---------------------------------------------------------------------------

          /// Incomplete path to the model on the server.
          static const SKELETON_PATH = "$path";

          /// Completes [SKELETON_PATH] by replacing the handlebars with the
          /// fields in [json].
          static String _completePath(String? pathOverride, Json json) {
            return (pathOverride ?? SKELETON_PATH).replaceHandlebars(json, "{", "}");
          }

          /// Returns a reference to this model on the server at [SKELETON_PATH] or at
          /// [pathOverride] if provided.
          @override
          DocumentReference<Json> refServer([String? pathOverride]) {
            return G.fbFirestore.documentReference(
              _completePath(pathOverride, this.toJson()),
            );
          }

        /// Redefine this function to override [toServer].
        static Future<void> Function(
            $nameClass model, {
            bool merge,
            String? pathOverride,
          }) toServerOverride = (
              final model, {
              final merge = true,
              final pathOverride,
            }) async {
            final json = model.toJson();
            final path = _completePath(pathOverride, json);
            await G.fbFirestore.documentReference(path).set(
                  json,
                  SetOptions(merge: merge),
                );
          };
          
          /// Writes this model to the server at [SKELETON_PATH] or at [pathOverride]
          /// if provided.
          @override
          Future<void> toServer({
            bool merge = true,
            String? pathOverride,
          }) async {
            try {
              await toServerOverride(
                this,
                merge: merge,
                pathOverride: pathOverride,
              );
            } catch (e) {
              throw Exception(
                "[$nameClass.newOverride] Failed to write model to server due to \$e",
              );
            }
          }

          /// Returns the model identified by [id] from the server at [SKELETON_PATH]
          /// or at [pathOverride] if provided. Redefine this function to override
          /// its behavior.
          static Future<$nameClass?> Function(
            String id, {
            String? pathOverride,
          }) fromServer = (
            String id, {
            String? pathOverride,
          }) async {
            try {
              final ref = G.fbFirestore.documentReference(
                _completePath(pathOverride, {"id": id}),
              );
              final json = (await ref.get()).data();
              return json != null ? $nameClass.fromJson(json) : null;
            } catch (e) {
              throw Exception(
                "[$nameClass.newOverride] Failed to read model from server due to \$e",
              );
            }
          };

          /// Redefine this function to override [deleteFromServer].
          static Future<void> Function(
            $nameClass model, {
              String? pathOverride
            }) deleteFromServerOverride = (final model, {final pathOverride}) async {
            await model.refServer(pathOverride).delete();
          };
          
          /// Deletes this model from the server at [SKELETON_PATH] or at
          /// [pathOverride] if provided.
          @override
          Future<void> deleteFromServer({String? pathOverride}) async {
            try {
              await deleteFromServerOverride(this, pathOverride: pathOverride);
            } catch (e) {
              throw Exception(
                "[$nameClass.newOverride] Failed to delete model from server due to \$e",
              );
            }
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
  return "null /* ERROR: Unsupported type and/or only nullable types supported */";
}
