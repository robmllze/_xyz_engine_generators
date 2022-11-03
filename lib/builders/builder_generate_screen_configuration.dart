// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:build/build.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'package:xyz_engine_generators_annotations/xyz_engine_generators_annotations.dart';

import '../model_visitor.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Builder generateScreenConfiguration(BuilderOptions options) => BuilderGenerateScreenConfiguration();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GeneratorScreenConfiguration extends GeneratorForAnnotation<GenerateScreenConfiguration> {
  //
  //
  //

  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameClass = "${visitor.nameClass}Configuration";
    final parameters = annotation
        .read("parameters")
        .mapValue
        .map((final k, final v) => MapEntry(k!.toStringValue(), v!.toStringValue()))
        .cast<String, String>()
        .entries;
    // Prepare member variables.
    final insertMemberVariables = parameters.map((final l) {
      final fieldName = l.key;
      final fieldType = l.value;
      return "final $fieldType $fieldName;";
    }).toList()
      ..sort();

    // Prepare constructor parameters.
    final insertConstructorParameters = parameters.map((final l) {
      final fieldName = l.key;
      //final fieldType = l.value;
      return "required this.$fieldName,";
    }).toList()
      ..sort();
    buffer.writeAll(
      [
        "class $nameClass extends MyRouteConfiguration {",
        if (insertMemberVariables.isNotEmpty) ...[],
        """
        class $nameClass extends MyRouteConfiguration {
          //
          //
          //

          ${insertMemberVariables.join("\n")}

          //
          //
          //

          $nameClass({
            ${insertConstructorParameters.join("\n")}
            Map<String, String>? queryArguments,
          }) : super(_LOCATION, queryArguments: queryArguments);

        }
        """,
      ],
    );
    return buffer.toString();
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class BuilderGenerateScreenConfiguration extends SharedPartBuilder {
  BuilderGenerateScreenConfiguration()
      : super(
          [GeneratorScreenConfiguration()],
          "generate_screen_configuration",
        );
}
