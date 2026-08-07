class_name VehicleDefinitionValidator
extends RefCounted
static func validate(definition:VehicleDefinition)->PackedStringArray:return PackedStringArray(["definition missing"]) if definition==null else definition.validation_errors()
