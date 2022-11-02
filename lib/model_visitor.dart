// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//
// XYZ Engine Generators
//
// ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓

import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

// ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░

class ModelVisitor extends SimpleElementVisitor<dynamic> {
  //
  //
  //

  String? nameClass;
  final fieldsClass = <String, String>{};

  //
  //
  //

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();
    // DartType ends with '*', which needs to be eliminated
    // for the generated code to be accurate.
    this.nameClass = elementReturnType.replaceFirst("*", "");
  }

  //
  //
  //

  @override
  dynamic visitFieldElement(FieldElement element) {
    final elementType = element.type.toString();
    // DartType ends with '*', which needs to be eliminated
    // for the generated code to be accurate.
    this.fieldsClass[element.name] = elementType.replaceFirst("*", "");
  }
}
