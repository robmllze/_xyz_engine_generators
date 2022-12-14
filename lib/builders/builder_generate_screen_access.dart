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

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Builder generateScreenAccess(BuilderOptions options) => BuilderGenerateScreenAccess();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class GeneratorScreenAccess extends GeneratorForAnnotation<GenerateScreenAccess> {
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

    final isOnlyAccessibleIfSignedInAndVerified //
        = annotation.read("isOnlyAccessibleIfSignedInAndVerified").boolValue;
    final isOnlyAccessibleIfSignedIn //
        = annotation.read("isOnlyAccessibleIfSignedIn").boolValue;
    final isOnlyAccessibleIfSignedOut //
        = annotation.read("isOnlyAccessibleIfSignedOut").boolValue;
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameScreenClass = visitor.nameClass.toString();
    final nameScreenConfigurationClass = "${nameScreenClass}Configuration";
    final constNameScreen = nameScreenClass.substring("Screen".length).toSnakeCase().toUpperCase();
    final segment = nameScreenClass.toSnakeCase().substring("screen_".length);
    //final location = "/$segment";
    final internalParameters = annotation
        .read("internalParameters")
        .mapValue
        .map((final k, final v) => MapEntry(k!.toStringValue(), v!.toStringValue()))
        .cast<String, String>()
        .entries;
    final pathSegments =
        annotation.read("pathSegments").listValue.map((final v) => v.toStringValue()!);
    final queryParameters =
        annotation.read("queryParameters").setValue.map((final v) => v.toStringValue()!);
    final isRedirectable = () {
      final temp = annotation.read("isRedirectable");
      return temp.isNull ? internalParameters.isEmpty /* true if empty */ : temp.boolValue;
    }();

    // [2] Prepare internal parameters.

    final internalParametersA = internalParameters.map((final l) {
      final fieldName = l.key;
      final fieldType = l.value;
      final fieldKey = fieldName.toSnakeCase();
      final nullable = fieldType.endsWith("?");
      final nullCheck = nullable ? "" : "!";
      final t = nullable ? fieldType.substring(0, fieldType.length - 1) : fieldType;
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      return [
        "/// Key corresponding to the value `$fieldName`",
        "static const $fieldK = \"$fieldKey\";",
        "/// Returns the **internal parameter** with the key `$fieldKey`",
        "/// or [$fieldK].",
        "$fieldType get $fieldName => super.arguments<$t>($fieldK)$nullCheck;",
      ].join("\n");
    }).toList()
      ..sort();
    final internalParametersB = internalParameters.map((final l) {
      final fieldName = l.key;
      final fieldType = l.value;
      final required = fieldType.endsWith("?") ? "" : "required ";
      return "$required$fieldType $fieldName,";
    }).toList()
      ..sort();
    final internalParametersC = internalParameters.map((final l) {
      final fieldName = l.key;
      final fieldType = l.value;
      final ifNotNull = fieldType.endsWith("?") ? "if ($fieldName != null) " : "";
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      return "$ifNotNull $fieldK: $fieldName,";
    }).toList()
      ..sort();

    // [2] Prepare query parameters.

    final queryParametersA = queryParameters.map((final l) {
      final fieldName = l;
      final fieldKey = fieldName.toSnakeCase();
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      return [
        "/// Key corresponding to the value `$fieldName`",
        "static const $fieldK = \"$fieldKey\";",
        "/// Returns the URI **query parameter** with the key `$fieldKey`",
        "/// or [$fieldK].",
        "String? get $fieldName => super.arguments<String>($fieldK);",
      ].join("\n");
    }).toList()
      ..sort();
    final queryParametersB = queryParameters.map((final l) {
      final fieldName = l;
      return "String? $fieldName,";
    }).toList()
      ..sort();
    final queryParametersC = queryParameters.map((final l) {
      final fieldName = l;
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      return "if ($fieldName != null) $fieldK: $fieldName,";
    }).toList()
      ..sort();

    // [2] Prepare path segments.

    var n = 0;
    final pathSegmentsA = pathSegments.map((final l) {
      final fieldName = l;
      final fieldK = "K_${fieldName.toSnakeCase().toUpperCase()}";
      return [
        "/// Key corresponding to the value `$fieldName`",
        "static const $fieldK = ${++n};",
        "/// Returns the URI **path segment** at position `$n` AKA the value",
        "/// corresponding to the key `$n` or [$fieldK].",
        "String? get $fieldName => super.arguments<String>($fieldK)?.nullIfEmpty();",
      ].join("\n");
    }).toList()
      ..sort();
    final pathSegmentsB = pathSegments.map((final l) {
      final fieldName = l;
      return "String? $fieldName,";
    }).toList()
      ..sort();
    final pathSegmentsC = pathSegments.map((final l) {
      final fieldName = l;
      return "$fieldName ?? \"\",";
    }).toList()
      ..sort();

    buffer.writeAll(
      [
        """
        // ignore_for_file: dead_code
        // ignore_for_file: unused_element

        // **************************************************************************

        const _L = "screens.$nameScreenClass";
        const _SEGMENT = "$segment";
        const _LOCATION = "/\$_SEGMENT";
        const _NAME_SCREEN_CLASS = "$nameScreenClass";

        T? _tr<T>(String key, [Map<dynamic, dynamic> args = const {}]) => "\$_L.\$key".toLowerCase().tr<T>(args);

        // **************************************************************************
        
        const LOCATION_NOT_REDIRECTABLE_$constNameScreen = [${!isRedirectable ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_$constNameScreen = [${!isOnlyAccessibleIfSignedInAndVerified && !isOnlyAccessibleIfSignedIn && !isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_AND_VERIFIED_$constNameScreen = [${isOnlyAccessibleIfSignedInAndVerified ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_$constNameScreen = [${isOnlyAccessibleIfSignedIn ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_OUT_$constNameScreen = [${isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];

        final cast$nameScreenConfigurationClass = Map<Type, MyRouteConfiguration Function(MyRouteConfiguration)>.unmodifiable({
          $nameScreenConfigurationClass: (MyRouteConfiguration a) => $nameScreenConfigurationClass.from(a)
        });
        
        SuperScreen? maker$nameScreenClass(
        MyRouteConfiguration configuration,
        bool isSignedInAndVerified,
        bool isSignedIn,
        bool isSignedOut,
        ) {
          if (($isOnlyAccessibleIfSignedInAndVerified && !isSignedInAndVerified) ||
              ($isOnlyAccessibleIfSignedIn && !isSignedIn) ||
              ($isOnlyAccessibleIfSignedOut && !isSignedOut)) {
                return null;
          }
          if (configuration is ${nameScreenClass}Configuration ||
            RegExp(
                r"^(\" + _LOCATION + r")([\?\/].*)?\$",
              ).hasMatch(
                Uri.decodeComponent(
                  configuration.uri.toString(),
                ),
              )) {
            return $nameScreenClass(configuration);
          }
          return null;
        }
        """,
        """
        // **************************************************************************

        class $nameScreenConfigurationClass extends MyRouteConfiguration {
          //
          //
          //

          // Some information.

          static const LOCATION = _LOCATION;
          static const L = _L;
          static const NAME_SCREEN_CLASS = _NAME_SCREEN_CLASS;
          
          """,
        if (internalParametersA.isNotEmpty)
          """
          // Internal parameters.

          ${internalParametersA.join("\n")}
          """,
        if (queryParametersA.isNotEmpty)
          """
          // Query parameters.

          ${queryParametersA.join("\n")}
          """,
        if (pathSegmentsA.isNotEmpty)
          """
          // Path segments.

          ${pathSegmentsA.join("\n")}
          """,
        """

        /// Creates a new configuration object for [$nameScreenClass]
        /// that can be passed to [G.router] to route to the screen with the applied
        /// configuration.
        /// 
        /// Use a unique [key] to allow [G.router] to push multiple instances of
        /// [$nameScreenClass] with different configurations.
        $nameScreenConfigurationClass({
          String? key,
            """,
        if (internalParametersB.isNotEmpty)
          """
          // Internal parameters.
          ${internalParametersB.join("\n")}
          """,
        if (queryParametersB.isNotEmpty)
          """
          // Query parameters.
          ${queryParametersB.join("\n")}
          """,
        if (pathSegmentsB.isNotEmpty)
          """
          // Path segments.
          ${pathSegmentsB.join("\n")}
          """,
        """}) : super(
                  _LOCATION,
                  key: key,
                  """,
        if (internalParametersC.isNotEmpty)
          """
          internalParameters: {
            ${internalParametersC.join("\n")}
          },
          """,
        if (queryParametersC.isNotEmpty)
          """
          queryParameters: {
            ${queryParametersC.join("\n")}
          },
          """,
        if (pathSegmentsC.isNotEmpty)
          """
          pathSegments: [
            _SEGMENT,
            ${pathSegmentsC.join("\n")}
          ],
          """,
        """);

          /// Creates a new [$nameScreenConfigurationClass] [from] a
          /// [MyRouteConfiguration] object.
          $nameScreenConfigurationClass.from(
              MyRouteConfiguration from,
            ): super.fromUri(
              from.uri,
              key: from.key,
              internalParameters: from.internalParameters,
            );

          /// Converts this $nameScreenConfigurationClass object [to] a
          /// [MyRouteConfiguration] object.
          @override
          MyRouteConfiguration to() {
            debugLog(
              "Converting $nameScreenConfigurationClass to MyRouteConfiguration",
            );
            return MyRouteConfiguration.fromUri(
              this.uri,
              key: this.key,
              internalParameters: this.internalParameters,
            );
          }
        }
        """,
      ],
    );

    return buffer.toString();
  }
}
// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class BuilderGenerateScreenAccess extends SharedPartBuilder {
  BuilderGenerateScreenAccess()
      : super(
          [GeneratorScreenAccess()],
          "generate_screen_access",
        );
}
