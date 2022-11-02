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
    try {
      final visitor = ModelVisitor();
      element.visitChildren(visitor);
      final buffer = StringBuffer();
      final nameClass = visitor.nameClass?.replaceFirst("_", "");
      final path = annotation.read("path").stringValue;
      final parameters0 = annotation
          .read("parameters")
          .mapValue
          .map((final k, final v) => MapEntry(k!.toStringValue(), v!.toStringValue()))
          .cast<String, String>()
          .entries;
      final parameters1 = parameters0.toList()..removeWhere((final l) => l.key == "id");
      // Member variables.
      final AAA = parameters1.map((final l) {
        final fieldName = l.key;
        final fieldType = l.value;
        return "$fieldType $fieldName;";
      }).toList()
        ..sort();

      // Constructor parameters.
      final BBB = parameters1.map((final l) {
        final fieldName = l.key;
        return "this.$fieldName,";
      }).toList()
        ..sort();

      // From JSON.
      final CCC = parameters0.map((final l) {
        var fieldName = l.key;
        final fieldNameSnakeCase = fieldName.toSnakeCase();
        final fieldType = l.value.toString().replaceAll("?", "");
        switch (fieldType) {
          // Handle bool.
          case "bool":
            return "$fieldName = letBool(json[\"$fieldNameSnakeCase\"])";
          // Handle int.
          case "int":
            return "$fieldName = letInt(json[\"$fieldNameSnakeCase\"])";
          case "double":
            // Handle double.
            return "$fieldName = letDouble(json[\"$fieldNameSnakeCase\"])";
          case "num":
            // Handle num.
            return "$fieldName = letNum(json[\"$fieldNameSnakeCase\"])";
          case "String":
            // Handle String.
            return "$fieldName = letString(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
          case "DateTime":
            // Handle DateTime.
            return "$fieldName = letDateTime(json[\"$fieldNameSnakeCase\"])?.toLocal()";
        }
        // Handle Models.
        if (fieldType.startsWith("Model")) {
          final a =
              "json${fieldName[0].toUpperCase() + (fieldName.length > 1 ? fieldName.substring(1) : "")}";
          return "final $a = letMap(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty();\n"
              "$fieldName = $a != null ? $fieldType.fromJson($a): null";
        }
        // Handle Map.
        if (fieldType.startsWith("Map")) {
          final matches = RegExp(r"\<(\w+) *, *(\w+)\>").firstMatch(fieldType);
          if (matches != null && matches.groupCount == 2) {
            final t1 = matches.group(1)!;
            final t2 = matches.group(2)!;
            // Hanlde Models.
            if (t2.startsWith("Model")) {
              return "$fieldName = (letMap<$t1, dynamic>(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()?.map((final k, final v) { final a = letMap<String, dynamic>(v); return MapEntry(k, a != null ? $t2.fromJson(a): null);})?..removeWhere((_, final l) => l == null))?.nullIfEmpty()?.cast()";
            }
            return "$fieldName = letMap<$t1, $t2>(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
          }
          return "$fieldName = letMap(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
        }
        // Handle Set.
        if (fieldType.startsWith("Set")) {
          final matches = RegExp(r"\<(\w+)>").firstMatch(fieldType);
          if (matches != null && matches.groupCount == 1) {
            final t = matches.group(1)!;
            // Handle Models.
            if (t.startsWith("Model")) {
              return "$fieldName = (letSet(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()?.map((final l) { final a = letMap<String, dynamic>(l)?.nullIfEmpty(); return a != null ? $t.fromJson(a): null; })?.toSet()?..removeWhere((final l) => l == null))?.nullIfEmpty()?.cast()";
            }
            return "$fieldName = letSet<$t>(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
          }
          return "$fieldName = letSet(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
        }
        // Handle List.
        if (fieldType.startsWith("List")) {
          final matches = RegExp(r"\<(\w+)>").firstMatch(fieldType);
          if (matches != null && matches.groupCount == 1) {
            final t = matches.group(1)!;
            // Handle Models.
            if (t.startsWith("Model")) {
              return "$fieldName = (letList(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()?.map((final l) { final a = letMap<String, dynamic>(l)?.nullIfEmpty(); return a != null ? $t.fromJson(a): null; })?.toList()?..removeWhere((final l) => l == null))?.nullIfEmpty()?.cast()";
            }
            return "$fieldName = letList<$t>(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
          }
          return "$fieldName = letList(json[\"$fieldNameSnakeCase\"])?.nullIfEmpty()";
        }
        return "$fieldName = let<$fieldType>(json[\"$fieldNameSnakeCase\"])";
      }).toList()
        ..sort();

      // To JSON.
      final DDD = parameters0.map((final l) {
        var fieldName = l.key;
        final fieldNameSnakeCase = fieldName.toSnakeCase();
        final fieldType = l.value.toString();
        // Handle String.
        if (fieldType == "String") {
          fieldName = "$fieldName?.nullIfEmpty()";
        } else
        // Handle Models.
        if (fieldType.startsWith("Model")) {
          fieldName = "$fieldName?.toJson().nullIfEmpty()";
        } else
        // Handle Map.
        if (fieldType.startsWith("Map")) {
          final matches = RegExp(r"\<(\w+) *, *(\w+)\>").firstMatch(fieldType);
          if (matches != null && matches.groupCount == 2) {
            //final t1 = matches.group(1)!;
            final t2 = matches.group(2)!;
            // Handle Models.
            if (t2.startsWith("Model")) {
              fieldName = "$fieldName?.nullIfEmpty()?.map((final k, final v) => "
                  "MapEntry(k.toString(), v.toJson()))";
            } else {
              fieldName = "letMap<String, dynamic>($fieldName)?.nullIfEmpty()";
            }
          } else {
            fieldName = "letMap<String, dynamic>($fieldName)?.nullIfEmpty()";
          }
        } else
        // Handle Set.
        if (fieldType.startsWith("Set")) {
          fieldName = "$fieldName?.toList().nullIfEmpty()";
        } else
        // Handle List.
        if (fieldType.startsWith("List")) {
          fieldName = "$fieldName?.nullIfEmpty()";
        } else
        // Handle DateTime.
        if (fieldType == "DateTime?") {
          fieldName = "$fieldName?.toUtc().toIso8601String()";
        }
        return "\"$fieldNameSnakeCase\": $fieldName";
      }).toList()
        ..sort();

      // New with.
      final EEE = parameters0.map((final l) {
        final fieldName = l.key;
        return "$fieldName: other.$fieldName ?? this.$fieldName,";
      }).toList()
        ..sort();

      // Update with.
      final FFF = parameters0.map((final l) {
        final fieldName = l.key;
        return "if (other.$fieldName != null) this.$fieldName = other.$fieldName;";
      }).toList()
        ..sort();

      buffer.writeAll(
        [
          """
        class $nameClass extends GeneratedModel implements _$nameClass{
          //
          //
          //

          ${AAA.join("\n")}
          
          //
          //
          //

          $nameClass({
            String? id,
            ${BBB.join("\n")}
          }) {
            super.id = id;
          }

          //
          //
          //

          $nameClass.fromJson(Map<String, dynamic> json) {
            ${CCC.join(";\n")};
          }

          //
          //
          //

          @override
          Map<String, dynamic> toJson() {
            return {
              ${DDD.join(",\n")},
            }..removeWhere((_, final l) => l == null);
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
            return (other is $nameClass ? $nameClass(${EEE.join("\n")}): $nameClass()) as T;
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
              ${FFF.join("\n")}
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

          ${path.isNotEmpty ? """
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
          """ : ""}
        }
        """,
        ],
        "\n",
      );
      return buffer.toString();
    } catch (e) {
      print(e);
    }
    return "";
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
