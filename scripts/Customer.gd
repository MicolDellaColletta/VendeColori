class_name Customer
extends Resource

@export var id: String
@export var display_name: String
@export_multiline var description: String
@export_multiline var greeting: String
@export_multiline var request: String
@export var outcome: Array[Outcome]
@export_multiline var default_response: String
