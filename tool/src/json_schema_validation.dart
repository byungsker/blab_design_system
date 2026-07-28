const _supportedSchemaKeywords = <String>{
  r'$schema',
  r'$id',
  r'$defs',
  r'$ref',
  'title',
  'description',
  'type',
  'additionalProperties',
  'required',
  'properties',
  'const',
  'oneOf',
  'enum',
  'minLength',
  'pattern',
  'minimum',
  'minItems',
  'items',
};

const _supportedJsonTypes = <String>{
  'object',
  'array',
  'string',
  'integer',
  'number',
  'boolean',
  'null',
};

/// Validates [instance] against the checked-in JSON Schema vocabulary used by
/// the BLDS doctor envelope.
///
/// The validator fails closed when the schema contains a validation keyword
/// that this implementation does not support. This keeps schema evolution
/// explicit instead of silently accepting documents under a partial validator.
List<String> validateJsonAgainstSchema(Object? instance, Object? schema) {
  final validator = _JsonSchemaValidator(schema);
  return validator.validate(instance);
}

class _JsonSchemaValidator {
  _JsonSchemaValidator(this.rootSchema) {
    _validateSchemaDefinition(rootSchema, r'$');
  }

  final Object? rootSchema;

  List<String> validate(Object? instance) {
    final errors = <String>[];
    _validateInstance(instance, rootSchema, r'$', errors);
    return errors;
  }

  void _validateSchemaDefinition(Object? rawSchema, String path) {
    if (rawSchema is bool) {
      return;
    }
    final schema = _schemaMap(rawSchema, path);
    for (final key in schema.keys) {
      if (!_supportedSchemaKeywords.contains(key)) {
        throw FormatException('Unsupported JSON Schema keyword at $path.');
      }
    }

    final type = schema['type'];
    if (type != null) {
      final types = type is List ? type : <Object?>[type];
      if (types.isEmpty ||
          types.any(
            (value) => value is! String || !_supportedJsonTypes.contains(value),
          )) {
        throw FormatException('Invalid JSON Schema type at $path.');
      }
    }

    final required = schema['required'];
    if (required != null &&
        (required is! List ||
            required.any((value) => value is! String) ||
            required.toSet().length != required.length)) {
      throw FormatException('Invalid JSON Schema required list at $path.');
    }

    final properties = schema['properties'];
    if (properties != null) {
      final propertySchemas = _schemaMap(properties, '$path.properties');
      for (final entry in propertySchemas.entries) {
        _validateSchemaDefinition(entry.value, '$path.properties.${entry.key}');
      }
    }

    final definitions = schema[r'$defs'];
    if (definitions != null) {
      final definitionSchemas = _schemaMap(definitions, '$path.\$defs');
      for (final entry in definitionSchemas.entries) {
        _validateSchemaDefinition(entry.value, '$path.\$defs.${entry.key}');
      }
    }

    final alternatives = schema['oneOf'];
    if (alternatives != null) {
      if (alternatives is! List || alternatives.isEmpty) {
        throw FormatException('Invalid JSON Schema oneOf at $path.');
      }
      for (var index = 0; index < alternatives.length; index += 1) {
        _validateSchemaDefinition(alternatives[index], '$path.oneOf[$index]');
      }
    }

    final items = schema['items'];
    if (items != null) {
      _validateSchemaDefinition(items, '$path.items');
    }

    final additionalProperties = schema['additionalProperties'];
    if (additionalProperties != null &&
        additionalProperties is! bool &&
        additionalProperties is! Map) {
      throw FormatException(
        'Invalid JSON Schema additionalProperties at $path.',
      );
    }
    if (additionalProperties is Map) {
      _validateSchemaDefinition(
        additionalProperties,
        '$path.additionalProperties',
      );
    }

    final reference = schema[r'$ref'];
    if (reference != null &&
        (reference is! String || !reference.startsWith('#/'))) {
      throw FormatException('Only local JSON Schema references are supported.');
    }

    final values = schema['enum'];
    if (values != null && (values is! List || values.isEmpty)) {
      throw FormatException('Invalid JSON Schema enum at $path.');
    }

    final minLength = schema['minLength'];
    if (minLength != null && (minLength is! int || minLength < 0)) {
      throw FormatException('Invalid JSON Schema minLength at $path.');
    }

    final pattern = schema['pattern'];
    if (pattern != null) {
      if (pattern is! String) {
        throw FormatException('Invalid JSON Schema pattern at $path.');
      }
      try {
        RegExp(pattern);
      } on FormatException {
        throw FormatException('Invalid JSON Schema pattern at $path.');
      }
    }

    final minimum = schema['minimum'];
    if (minimum != null && minimum is! num) {
      throw FormatException('Invalid JSON Schema minimum at $path.');
    }

    final minItems = schema['minItems'];
    if (minItems != null && (minItems is! int || minItems < 0)) {
      throw FormatException('Invalid JSON Schema minItems at $path.');
    }
  }

  void _validateInstance(
    Object? instance,
    Object? rawSchema,
    String path,
    List<String> errors,
  ) {
    if (rawSchema is bool) {
      if (!rawSchema) {
        errors.add('$path: rejected by the schema.');
      }
      return;
    }
    final schema = _schemaMap(rawSchema, path);

    final reference = schema[r'$ref'];
    if (reference is String) {
      _validateInstance(instance, _resolveReference(reference), path, errors);
    }

    final type = schema['type'];
    if (type != null && !_matchesType(instance, type)) {
      errors.add('$path: type constraint failed.');
      return;
    }

    if (schema.containsKey('const') &&
        !_jsonValuesEqual(instance, schema['const'])) {
      errors.add('$path: constant constraint failed.');
    }

    final enumValues = schema['enum'];
    if (enumValues is List &&
        !enumValues.any((value) => _jsonValuesEqual(instance, value))) {
      errors.add('$path: enum constraint failed.');
    }

    final alternatives = schema['oneOf'];
    if (alternatives is List) {
      var matches = 0;
      for (final alternative in alternatives) {
        final branchErrors = <String>[];
        _validateInstance(instance, alternative, path, branchErrors);
        if (branchErrors.isEmpty) {
          matches += 1;
        }
      }
      if (matches != 1) {
        errors.add('$path: oneOf constraint failed.');
      }
    }

    if (instance is Map) {
      _validateObject(instance, schema, path, errors);
    }
    if (instance is List) {
      final minItems = schema['minItems'];
      if (minItems is int && instance.length < minItems) {
        errors.add('$path: minItems constraint failed.');
      }
      final items = schema['items'];
      if (items != null) {
        for (var index = 0; index < instance.length; index += 1) {
          _validateInstance(instance[index], items, '$path[$index]', errors);
        }
      }
    }
    if (instance is String) {
      final minLength = schema['minLength'];
      if (minLength is int && instance.runes.length < minLength) {
        errors.add('$path: minLength constraint failed.');
      }
      final pattern = schema['pattern'];
      if (pattern is String && !RegExp(pattern).hasMatch(instance)) {
        errors.add('$path: pattern constraint failed.');
      }
    }
    if (instance is num) {
      final minimum = schema['minimum'];
      if (minimum is num && instance < minimum) {
        errors.add('$path: minimum constraint failed.');
      }
    }
  }

  void _validateObject(
    Map<Object?, Object?> instance,
    Map<String, Object?> schema,
    String path,
    List<String> errors,
  ) {
    final required = schema['required'];
    if (required is List) {
      for (final property in required.cast<String>()) {
        if (!instance.containsKey(property)) {
          errors.add('$path.$property: required property is missing.');
        }
      }
    }

    final properties = schema['properties'];
    final propertySchemas = properties is Map
        ? _schemaMap(properties, '$path.properties')
        : const <String, Object?>{};
    for (final entry in propertySchemas.entries) {
      if (instance.containsKey(entry.key)) {
        _validateInstance(
          instance[entry.key],
          entry.value,
          '$path.${entry.key}',
          errors,
        );
      }
    }

    final additionalProperties = schema['additionalProperties'];
    for (final entry in instance.entries) {
      if (entry.key is! String) {
        errors.add('$path: object property name must be a string.');
        continue;
      }
      if (propertySchemas.containsKey(entry.key)) {
        continue;
      }
      if (additionalProperties == false) {
        errors.add('$path: additional property is not allowed.');
      } else if (additionalProperties is Map) {
        _validateInstance(
          entry.value,
          additionalProperties,
          '$path.<additional>',
          errors,
        );
      }
    }
  }

  Object? _resolveReference(String reference) {
    Object? current = rootSchema;
    for (final encodedSegment in reference.substring(2).split('/')) {
      final segment = encodedSegment
          .replaceAll('~1', '/')
          .replaceAll('~0', '~');
      if (current is! Map || !current.containsKey(segment)) {
        throw FormatException('Unresolved local JSON Schema reference.');
      }
      current = current[segment];
    }
    return current;
  }
}

Map<String, Object?> _schemaMap(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('JSON Schema node at $path must be an object.');
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('JSON Schema node at $path has a non-string key.');
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

bool _matchesType(Object? instance, Object? rawType) {
  final types = rawType is List
      ? rawType.cast<String>()
      : <String>[rawType! as String];
  return types.any(
    (type) => switch (type) {
      'object' => instance is Map,
      'array' => instance is List,
      'string' => instance is String,
      'integer' => instance is int,
      'number' => instance is num,
      'boolean' => instance is bool,
      'null' => instance == null,
      _ => false,
    },
  );
}

bool _jsonValuesEqual(Object? left, Object? right) {
  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }
    for (var index = 0; index < left.length; index += 1) {
      if (!_jsonValuesEqual(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }
  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (!right.containsKey(entry.key) ||
          !_jsonValuesEqual(entry.value, right[entry.key])) {
        return false;
      }
    }
    return true;
  }
  return left == right;
}
