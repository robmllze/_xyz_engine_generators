// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;

import 'package:xyz_utils/xyz_utils.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

Builder generateExportsConfigs(BuilderOptions options) => BuilderGenerateExports("configs");
Builder generateExportsModels(BuilderOptions options) => BuilderGenerateExports("models");
Builder generateExportsRouting(BuilderOptions options) => BuilderGenerateExports("routing");
Builder generateExportsServices(BuilderOptions options) => BuilderGenerateExports("services");
Builder generateExportsThemes(BuilderOptions options) => BuilderGenerateExports("themes");
Builder generateExportsUtils(BuilderOptions options) => BuilderGenerateExports("utils");
Builder generateExportsWidgets(BuilderOptions options) => BuilderGenerateExports("widgets");

Builder generateExportsScreens(BuilderOptions options) => BuilderGenerateExportsScreens();

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class BuilderGenerateExports implements Builder {
  //
  //
  //

  final String name;
  BuilderGenerateExports(this.name);

  //
  //
  //

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r"$lib$": ["${this.name}/all_${this.name}.dart"],
    };
  }

  //
  //
  //

  @override
  Future<void> build(BuildStep buildStep) async {
    final lines = <String>[];
    final inputs = buildStep.findAssets(Glob("lib/${this.name}/**"));
    await for (final input in inputs) {
      final path = input.path.replaceFirst("lib/${this.name}/", "");
      final condition1 =
          // May not contain "/_"...
          !path.contains(r"/_") &&
              // ...must be all lowercalse...
              path.toLowerCase() == path &&
              // ...and must end with ".dart"
              path.endsWith(".dart");
      if (!condition1) continue;
      final line = "export \'$path\';";
      lines.add(line);
    }
    final output = (lines..sort()).join("\n");
    final id = AssetId(
      buildStep.inputId.package,
      path.join("lib", this.name, "all_${this.name}.dart"),
    );
    await buildStep.writeAsString(
      id,
      "// GENERATED CODE - DO NOT MODIFY BY HAND\n\n"
      "$output",
    );
  }
}

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class BuilderGenerateExportsScreens implements Builder {
  //
  //
  //

  @override
  Map<String, List<String>> get buildExtensions {
    return {
      r"$lib$": ["screens/all_screens.dart"],
    };
  }

  //
  //
  //

  @override
  Future<void> build(BuildStep buildStep) async {
    final linesExports = <String>[],
        linesScreenMakers = <String>[],
        linesCannotRequest = <String>[],
        linesAccessible = <String>[],
        linesAccessibleIfVerified = <String>[],
        linesAccessibleIfSignedIn = <String>[],
        linesAccessibleIfSignedOut = <String>[],
        linesScreenTypes = <String>[],
        linesScreenMetadata = <String>[];
    final paths = await buildStep
        .findAssets(Glob("lib/screens/**"))
        .map((final l) => l.path.replaceFirst("lib/screens/", ""))
        .toList()
      ..sort();
    for (final path in paths) {
      final b0 =
          // May not contain "/_"...
          path.contains(r"/_") ||
              // ...must be all lowercalse...
              path.toLowerCase() != path ||
              // ...and must end with ".dart"
              !path.endsWith(".dart");
      if (b0) continue;
      final b1 = path.endsWith(".options.dart");
      if (b1) continue;
      linesExports.add("export \'$path\';");
      final nameClass =
          RegExp(r"\/((screen_)(.+))\.dart").firstMatch(path)?.group(1)?.toCamelCaseCapitalized();
      if (nameClass != null) {
        final constNameScreen_ = nameClass.substring("Screen".length).toSnakeCase().toUpperCase();
        final constNameLocation_ = "/${constNameScreen_.toLowerCase()}";
        linesScreenMakers //
            .add("maker${nameClass},");
        linesCannotRequest //
            .add("...LOCATION_NOT_REDIRECTABLE_$constNameScreen_,");
        linesAccessible //
            .add("...LOCATION_ACCESSIBLE_$constNameScreen_,");
        linesAccessibleIfVerified //
            .add("...LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_AND_VERIFIED_$constNameScreen_,");
        linesAccessibleIfSignedIn //
            .add("...LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_IN_$constNameScreen_,");
        linesAccessibleIfSignedOut //
            .add("...LOCATION_ACCESSIBLE_ONLY_IF_SIGNED_OUT_$constNameScreen_,");
        linesScreenTypes.add("\"$constNameLocation_\": $nameClass,");
        linesScreenMetadata.add("$nameClass: null,");
      }
    }

    // ignore: prefer_interpolation_to_compose_strings
    final output = "\n\n" + //
        "import '/all.dart';\n\n" +
        "${linesExports.join("\n")}\n\n" +
        "const SCREEN_MAKERS = [\n  ${linesScreenMakers.join("\n  ")}\n];" +
        "\n\nconst LOCATIONS_NOT_REDIRECTABLE = [\n  ${linesCannotRequest.join("\n  ")}\n];" +
        "\n\nconst LOCATIONS_ACCESSIBLE = [\n  ${linesAccessible.join("\n  ")}\n];" +
        "\n\nconst LOCATIONS_ACCESSIBLE_ONLY_IF_SIGNED_IN_AND_VERIFIED = [\n  ${linesAccessibleIfVerified.join("\n  ")}\n];" +
        "\n\nconst LOCATIONS_ACCESSIBLE_ONLY_IF_SIGNED_IN = [\n  ${linesAccessibleIfSignedIn.join("\n  ")}\n];" +
        "\n\nconst LOCATIONS_ACCESSIBLE_ONLY_IF_SIGNED_OUT = [\n  ${linesAccessibleIfSignedOut.join("\n  ")}\n];";
    final id = AssetId(
      buildStep.inputId.package,
      path.join("lib", "screens", "all_screens.dart"),
    );
    await buildStep.writeAsString(
      id,
      "// GENERATED CODE - DO NOT MODIFY BY HAND"
      "$output",
    );
  }
}
