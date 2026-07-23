class_name Outcome
extends Resource

@export var object_id: String
@export_enum("right", "nearly", "wrong") var rating: String
@export_multiline var response_line: String
