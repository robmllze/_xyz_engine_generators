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
    final isOnlyAccessibleIfSignedInAndVerified //
        = annotation.read("isOnlyAccessibleIfSignedInAndVerified").boolValue;
    final isOnlyAccessibleIfSignedIn //
        = annotation.read("isOnlyAccessibleIfSignedIn").boolValue;
    final isOnlyAccessibleIfSignedOut //
        = annotation.read("isOnlyAccessibleIfSignedOut").boolValue;
    final isRedirectable //
        = annotation.read("isRedirectable").boolValue;
    final visitor = ModelVisitor();
    element.visitChildren(visitor);
    final buffer = StringBuffer();
    final nameScreenClass = visitor.nameClass.toString();
    final nameScreenConfigurationClass = "${nameScreenClass}Configuration";
    final constNameScreen = nameScreenClass.substring("Screen".length).toSnakeCase().toUpperCase();
    final location = "/${nameScreenClass.toSnakeCase().substring("screen_".length)}";

    final configuration = annotation
        .read("configuration")
        .mapValue
        .map((final k, final v) => MapEntry(k!.toStringValue(), v!.toStringValue()))
        .cast<String, String>()
        .entries;

    // Prepare member variables.
    final insertMemberVariables = configuration.map((final l) {
      final fieldName = l.key;
      final fieldType = l.value;
      return "final $fieldType $fieldName;";
    }).toList()
      ..sort();

    // Prepare constructor parameters.
    final insertConstructorParameters = configuration.map((final l) {
      final fieldName = l.key;
      //final fieldType = l.value;
      return "required this.$fieldName,";
    }).toList()
      ..sort();

    buffer.writeAll(
      [
        """
        // ignore_for_file: dead_code
        // ignore_for_file: unused_element

        const _L = "screens.$nameScreenClass";
        const _LOCATION = "$location";
        const _NAME_SCREEN_CLASS = "$nameScreenClass";

        const LOCATION_NOT_REDIRECTABLE_$constNameScreen = [${!isRedirectable ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_$constNameScreen = [${!isOnlyAccessibleIfSignedInAndVerified && !isOnlyAccessibleIfSignedIn && !isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_AND_VERIFIED_$constNameScreen = [${isOnlyAccessibleIfSignedInAndVerified ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_$constNameScreen = [${isOnlyAccessibleIfSignedIn ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_OUT_$constNameScreen = [${isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];
        

        String _tr(String key, {List<String>? args, Map<String, String>? namedArgs}) => "\$_L.\$key".toLowerCase().tr(args: args, namedArgs: namedArgs);
        
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
          if (configuration is ${nameScreenClass}Configuration || RegExp(r"^(\" + _LOCATION + r")([\?\/].*)?\$").hasMatch(configuration.uri.toString())) {
            return $nameScreenClass(configuration);
          }
          return null;
        }
        """,
        """
        class $nameScreenConfigurationClass extends MyRouteConfiguration {
          //
          //
          //

          static const LOCATION = _LOCATION;
          static const L = _L;
          static const NAME_SCREEN_CLASS = _NAME_SCREEN_CLASS;
          ${insertMemberVariables.join("\n")}

          //
          //
          //
          $nameScreenConfigurationClass({
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

class BuilderGenerateScreenAccess extends SharedPartBuilder {
  BuilderGenerateScreenAccess()
      : super(
          [GeneratorScreenAccess()],
          "generate_screen_access",
        );
}
