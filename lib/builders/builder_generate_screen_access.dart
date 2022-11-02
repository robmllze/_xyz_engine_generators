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
    final nameClass = visitor.nameClass.toString();
    final constNameScreen = nameClass.substring("Screen".length).toSnakeCase().toUpperCase();
    final location = "/${nameClass.toSnakeCase().substring("screen_".length)}";
    buffer.writeAll(
      [
        """
        const _L = "screens.$nameClass";
        const _LOCATION = "$location";
        const LOCATION_NOT_REDIRECTABLE_$constNameScreen = [${!isRedirectable ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_$constNameScreen = [${!isOnlyAccessibleIfSignedInAndVerified && !isOnlyAccessibleIfSignedIn && !isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_AND_VERIFIED_$constNameScreen = [${isOnlyAccessibleIfSignedInAndVerified ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_$constNameScreen = [${isOnlyAccessibleIfSignedIn ? "_LOCATION" : ""}];
        const LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_OUT_$constNameScreen = [${isOnlyAccessibleIfSignedOut ? "_LOCATION" : ""}];
        
        final _nameClass = "$nameClass";
        String _tr(String key, {List<String>? args, Map<String, String>? namedArgs}) => "\$_L.\$key".toLowerCase().tr(args: args, namedArgs: namedArgs);
        
        SuperScreen? maker$nameClass(
        MyRouteConfiguration configuration,
        bool isSignedInAndVerified,
        bool isSignedIn,
        bool isSignedOut,
        ) {
          if (($isOnlyAccessibleIfSignedInAndVerified && !isSignedInAndVerified) ||
              ($isOnlyAccessibleIfSignedIn && !isSignedIn) ||
              ($isOnlyAccessibleIfSignedOut && !isSignedOut))
                return null;
          final input = configuration.uri.toString();
          final hasMatch = RegExp(r"^(\\""\$_LOCATION"r")([\\?\\/].*)?\$").hasMatch(input);
          if (hasMatch) return $nameClass(configuration);
          return null;
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
