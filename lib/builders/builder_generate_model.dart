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
    final nameClass = visitor.nameClass?.replaceFirst("_", "");
    final serverPathSkeleton = annotation.read("serverPathSkeleton").stringValue;
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
        class $nameClass extends GeneratedModel {
          //
          //
          //

          /// Related member: `this.id`;
          static const K_ID = "id";
          ${insert2.join("\n")}

          //
          //
          //
          
          /// Constructs a new instance of [$nameClass] identified by [id].
          $nameClass({
            String? id,
            ${insert3.join("\n")}
          }) {
            super.id = id;
          }

          /// Converts a [Json] object to a [$nameClass] object.
          factory $nameClass.fromJson(Json json) {
            try {
              return $nameClass(${insert4.join("\n")});
            } catch (e) {
               throw Exception(
                "[$nameClass.fromJson] Failed to convert JSON to $nameClass due to: \$e",
                );
            }
          }

          /// Returns a copy of `this` model.
          @override
          T copy<T extends GeneratedModel>(T other) {
            return ($nameClass()..updateWith(other)) as T;
          }

          /// Converts a [$nameClass] object to a [Json] object.
          @override
          Json toJson() {
            try {
              return mapToJson(
                {
                  ${insert5.join("\n")}
                }..removeWhere((_, final l) => l == null),
                typesAllowed: {Timestamp},
                // Defined in utils/timestamp.dart
                keyConverter: timestampKeyConverter,
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
              return $nameClass(${insert6.join("\n")}) as T;
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
              ${insert7.join("\n")}
              return;
            }
            throw Exception(
              "[$nameClass.updateWith] Expected 'other' to be of type $nameClass and not \${other.runtimeType}",
              );
          }

          @override
          bool operator ==(Object other) {
            return other is $nameClass ? const DeepCollectionEquality().equals(this.toJson(), other.toJson()): false;
          }

          @override
          int get hashCode => this.toJson().hashCode;

          @override
          String toString() => this.toJson().toString();
        """,

        // [9] Write server utils if needed.

        if (serverPathSkeleton.isNotEmpty) ...[
          """
          // ---------------------------------------------------------------------------
          // SERVER UTILS
          // ---------------------------------------------------------------------------

          /// Incomplete path to the model on the server.
          static const SERVER_PATH_SKELETON = "$serverPathSkeleton";

          /// Completes [SERVER_PATH_SKELETON] by replacing the handlebars with the
          /// fields in [json].
          static String _completeServerPath(String? serverPathSkeleton, Json json) {
            return (serverPathSkeleton ?? SERVER_PATH_SKELETON).replaceHandlebars(json, "{", "}");
          }

          /// Returns a reference to this model on the server at [SERVER_PATH_SKELETON] or at
          /// [serverPathSkeleton] if provided.
          @override
          DocumentReference<Json> refServer([String? serverPathSkeleton]) {
            return G.fbFirestore.documentReference(
              _completeServerPath(serverPathSkeleton, this.toJson()),
            );
          }

        /// Redefine this function to override [toServer].
        /// Pass arbitrary options via [options].
        static Future<void> Function(
            $nameClass model, {
            bool merge,
            String? serverPathSkeleton,
            Map<String, dynamic>? writeAlso,
            Map<Symbol, dynamic>? options,
          }) toServerOverride = (
              final model, {
              final merge = true,
              final serverPathSkeleton,
              final writeAlso,
              final options,
            }) async {
            final json = model.toJson();
            final serverPath = _completeServerPath(serverPathSkeleton, json);
            await G.fbFirestore.documentReference(serverPath).set(
                  {
                    ...json,
                    if (writeAlso != null) ...writeAlso,
                  },
                  SetOptions(merge: merge),
                );
          };

          /// Writes this model and the fields [writeAlso] to the server at
          /// [SERVER_PATH_SKELETON] or at [serverPathSkeleton] if provided, with the
          /// given [options].
          @override
          Future<void> toServer({
            bool merge = true,
            String? serverPathSkeleton,
            Map<String, dynamic>? writeAlso,
            Map<Symbol, dynamic>? options,
          }) async {
            try {
              await toServerOverride(
                this,
                merge: merge,
                serverPathSkeleton: serverPathSkeleton,
                writeAlso: writeAlso,
                options: options,
              );
            } catch (e) {
              throw Exception(
                "[$nameClass.toServer] Failed to write model to server: \$e",
              );
            }
          }
          /// Fetches a model from the server with the given [options].
          /// 
          /// Example:
          /// 
          /// If [SERVER_PATH_SKELETON] (or `serverPathSkeleton`) = "{collection}/{id}",
          /// and `pathParameters` = {"collection": "foo", "id": "bar"}, then the model's
          /// server path is "foo/bar".
          /// 
          /// NB: Redefine this function to override its behavior.
          static Future<$nameClass?> Function(
            Json pathParameters, {
            String? serverPathSkeleton,
          }) fromServer = (
            Json pathParameters, {
            String? serverPathSkeleton,
            Map<Symbol, dynamic>? options,
          }) async {
            try {
              final ref = G.fbFirestore.documentReference(
                _completeServerPath(serverPathSkeleton, pathParameters),
              );
              final json = (await ref.get()).data();
              return json != null ? $nameClass.fromJson(json) : null;
            } catch (e) {
              throw Exception(
                "[$nameClass.fromServer] Failed to read model from server: \$e",
              );
            }
          };

          /// Redefine this function to override [deleteFromServer].
          /// Pass arbitrary options via [options].
          static Future<void> Function(
            $nameClass model, {
              String? serverPathSkeleton,
              Map<Symbol, dynamic>? options,
            }) deleteFromServerOverride = (
              final model, {
              final serverPathSkeleton,
              final options,
            }) async {
            await model.refServer(serverPathSkeleton).delete();
          };
          
          /// Deletes this model from the server at [SERVER_PATH_SKELETON] or at
          /// [serverPathSkeleton] if provided, with the given [options].
          @override
          Future<void> deleteFromServer({String? serverPathSkeleton}) async {
            try {
              await deleteFromServerOverride(
                this,
                serverPathSkeleton: serverPathSkeleton,
              );
            } catch (e) {
              throw Exception(
                "[$nameClass.deleteFromServer] Failed to delete model from server: \$e",
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
