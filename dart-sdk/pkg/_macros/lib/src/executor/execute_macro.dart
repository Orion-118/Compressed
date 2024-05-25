// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../api.dart';
import '../executor.dart';
import 'builder_impls.dart';
import 'exception_impls.dart';
import 'introspection_impls.dart';

/// Runs [macro] in the types phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeTypesMacro(
    Macro macro, Object target, TypePhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting.
  late final TypeBuilderBase builder;

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    // Shared code for most branches. If we do create it, assign it to
    // `builder`.
    late final TypeBuilderImpl typeBuilder =
        builder = TypeBuilderImpl(introspector);
    switch ((target, macro)) {
      case (Library target, LibraryTypesMacro macro):
        await macro.buildTypesForLibrary(target, typeBuilder);
      case (ConstructorDeclaration target, ConstructorTypesMacro macro):
        await macro.buildTypesForConstructor(target, typeBuilder);
      case (MethodDeclaration target, MethodTypesMacro macro):
        await macro.buildTypesForMethod(target, typeBuilder);
      case (FunctionDeclaration target, FunctionTypesMacro macro):
        await macro.buildTypesForFunction(target, typeBuilder);
      case (FieldDeclaration target, FieldTypesMacro macro):
        await macro.buildTypesForField(target, typeBuilder);
      case (VariableDeclaration target, VariableTypesMacro macro):
        await macro.buildTypesForVariable(target, typeBuilder);
      case (ClassDeclaration target, ClassTypesMacro macro):
        await macro.buildTypesForClass(
            target,
            builder = ClassTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumDeclaration target, EnumTypesMacro macro):
        await macro.buildTypesForEnum(
            target,
            builder = EnumTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (ExtensionDeclaration target, ExtensionTypesMacro macro):
        await macro.buildTypesForExtension(target, typeBuilder);
      case (ExtensionTypeDeclaration target, ExtensionTypeTypesMacro macro):
        await macro.buildTypesForExtensionType(target, typeBuilder);
      case (MixinDeclaration target, MixinTypesMacro macro):
        await macro.buildTypesForMixin(
            target,
            builder = MixinTypeBuilderImpl(
                target.identifier as IdentifierImpl, introspector));
      case (EnumValueDeclaration target, EnumValueTypesMacro macro):
        await macro.buildTypesForEnumValue(target, typeBuilder);
      case (TypeAliasDeclaration target, TypeAliasTypesMacro macro):
        await macro.buildTypesForTypeAlias(target, typeBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    if (e is DiagnosticException) {
      builder.report(e.diagnostic);
    } else if (e is MacroExceptionImpl) {
      // Preserve `MacroException`s thrown by SDK tools.
      builder.failWithException(e);
    } else {
      // Convert exceptions thrown by macro implementations into diagnostics.
      builder.report(_unexpectedExceptionDiagnostic(e, s));
    }
  }
  return builder.result;
}

/// Runs [macro] in the declaration phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDeclarationsMacro(Macro macro,
    Object target, DeclarationPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting.
  late final DeclarationBuilderBase builder;

  // At most one of these will be used below.
  late MemberDeclarationBuilderImpl memberBuilder =
      builder = MemberDeclarationBuilderImpl(
          switch (target) {
            MemberDeclaration() => target.definingType as IdentifierImpl,
            TypeDeclarationImpl() => target.identifier,
            _ => throw StateError(
                'Can only create member declaration builders for types or '
                'member declarations, but got $target'),
          },
          introspector);
  late DeclarationBuilderImpl topLevelBuilder =
      builder = DeclarationBuilderImpl(introspector);
  late EnumDeclarationBuilderImpl enumBuilder =
      builder = EnumDeclarationBuilderImpl(
          switch (target) {
            EnumDeclarationImpl() => target.identifier,
            EnumValueDeclarationImpl() => target.definingEnum,
            _ => throw StateError(
                'Can only create enum declaration builders for enum or enum '
                'value declarations, but got $target'),
          },
          introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDeclarationsMacro macro):
        await macro.buildDeclarationsForLibrary(target, topLevelBuilder);
      case (ClassDeclaration target, ClassDeclarationsMacro macro):
        await macro.buildDeclarationsForClass(target, memberBuilder);
      case (EnumDeclaration target, EnumDeclarationsMacro macro):
        await macro.buildDeclarationsForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDeclarationsMacro macro):
        await macro.buildDeclarationsForExtension(target, memberBuilder);
      case (
          ExtensionTypeDeclaration target,
          ExtensionTypeDeclarationsMacro macro
        ):
        await macro.buildDeclarationsForExtensionType(target, memberBuilder);
      case (MixinDeclaration target, MixinDeclarationsMacro macro):
        await macro.buildDeclarationsForMixin(target, memberBuilder);
      case (EnumValueDeclaration target, EnumValueDeclarationsMacro macro):
        await macro.buildDeclarationsForEnumValue(target, enumBuilder);
      case (ConstructorDeclaration target, ConstructorDeclarationsMacro macro):
        await macro.buildDeclarationsForConstructor(target, memberBuilder);
      case (MethodDeclaration target, MethodDeclarationsMacro macro):
        await macro.buildDeclarationsForMethod(target, memberBuilder);
      case (FieldDeclaration target, FieldDeclarationsMacro macro):
        await macro.buildDeclarationsForField(target, memberBuilder);
      case (FunctionDeclaration target, FunctionDeclarationsMacro macro):
        await macro.buildDeclarationsForFunction(target, topLevelBuilder);
      case (VariableDeclaration target, VariableDeclarationsMacro macro):
        await macro.buildDeclarationsForVariable(target, topLevelBuilder);
      case (TypeAliasDeclaration target, TypeAliasDeclarationsMacro macro):
        await macro.buildDeclarationsForTypeAlias(target, topLevelBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    if (e is DiagnosticException) {
      builder.report(e.diagnostic);
    } else if (e is MacroExceptionImpl) {
      // Preserve `MacroException`s thrown by SDK tools.
      builder.failWithException(e);
    } else {
      // Convert exceptions thrown by macro implementations into diagnostics.
      builder.report(_unexpectedExceptionDiagnostic(e, s));
    }
  }
  return builder.result;
}

/// Runs [macro] in the definition phase and returns a  [MacroExecutionResult].
Future<MacroExecutionResult> executeDefinitionMacro(Macro macro, Object target,
    DefinitionPhaseIntrospector introspector) async {
  // Must be assigned, used for error reporting and returning a value.
  late final DefinitionBuilderBase builder;

  // At most one of these will be used below.
  late FunctionDefinitionBuilderImpl functionBuilder = builder =
      FunctionDefinitionBuilderImpl(
          target as FunctionDeclarationImpl, introspector);
  late VariableDefinitionBuilderImpl variableBuilder = builder =
      VariableDefinitionBuilderImpl(
          target as VariableDeclaration, introspector);
  late TypeDefinitionBuilderImpl typeBuilder = builder =
      TypeDefinitionBuilderImpl(target as TypeDeclaration, introspector);

  // TODO(jakemac): More robust handling for unawaited async errors?
  try {
    switch ((target, macro)) {
      case (Library target, LibraryDefinitionMacro macro):
        LibraryDefinitionBuilderImpl libraryBuilder =
            builder = LibraryDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForLibrary(target, libraryBuilder);
      case (ClassDeclaration target, ClassDefinitionMacro macro):
        await macro.buildDefinitionForClass(target, typeBuilder);
      case (EnumDeclaration target, EnumDefinitionMacro macro):
        EnumDefinitionBuilderImpl enumBuilder =
            builder = EnumDefinitionBuilderImpl(target, introspector);
        await macro.buildDefinitionForEnum(target, enumBuilder);
      case (ExtensionDeclaration target, ExtensionDefinitionMacro macro):
        await macro.buildDefinitionForExtension(target, typeBuilder);
      case (
          ExtensionTypeDeclaration target,
          ExtensionTypeDefinitionMacro macro
        ):
        await macro.buildDefinitionForExtensionType(target, typeBuilder);
      case (MixinDeclaration target, MixinDefinitionMacro macro):
        await macro.buildDefinitionForMixin(target, typeBuilder);
      case (EnumValueDeclaration target, EnumValueDefinitionMacro macro):
        EnumValueDefinitionBuilderImpl enumValueBuilder = builder =
            EnumValueDefinitionBuilderImpl(
                target as EnumValueDeclarationImpl, introspector);
        await macro.buildDefinitionForEnumValue(target, enumValueBuilder);
      case (ConstructorDeclaration target, ConstructorDefinitionMacro macro):
        ConstructorDefinitionBuilderImpl constructorBuilder = builder =
            ConstructorDefinitionBuilderImpl(
                target as ConstructorDeclarationImpl, introspector);
        await macro.buildDefinitionForConstructor(target, constructorBuilder);
      case (MethodDeclaration target, MethodDefinitionMacro macro):
        await macro.buildDefinitionForMethod(
            target as MethodDeclarationImpl, functionBuilder);
      case (FieldDeclaration target, FieldDefinitionMacro macro):
        await macro.buildDefinitionForField(target, variableBuilder);
      case (FunctionDeclaration target, FunctionDefinitionMacro macro):
        await macro.buildDefinitionForFunction(target, functionBuilder);
      case (VariableDeclaration target, VariableDefinitionMacro macro):
        await macro.buildDefinitionForVariable(target, variableBuilder);
      default:
        throw UnsupportedError('Unsupported macro type or invalid target:\n'
            'macro: $macro\ntarget: $target');
    }
  } catch (e, s) {
    if (e is DiagnosticException) {
      builder.report(e.diagnostic);
    } else if (e is MacroExceptionImpl) {
      // Preserve `MacroException`s thrown by SDK tools.
      builder.failWithException(e);
    } else {
      // Convert exceptions thrown by macro implementations into diagnostics.
      builder.report(_unexpectedExceptionDiagnostic(e, s));
    }
  }
  return builder.result;
}

// It's a bug in the macro but we need to show something to the user; put the
// debug detail in a context message and suggest reporting to the author.
Diagnostic _unexpectedExceptionDiagnostic(
        Object thrown, StackTrace stackTrace) =>
    Diagnostic(
        DiagnosticMessage(
            'Macro application failed due to a bug in the macro.'),
        Severity.error,
        contextMessages: [
          DiagnosticMessage('$thrown\n$stackTrace'),
        ],
        correctionMessage: 'Try reporting the failure to the macro author.');
