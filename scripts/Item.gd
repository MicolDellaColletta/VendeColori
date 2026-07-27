class_name Item
extends Resource

@export var id: String
@export var display_name: String

@export var bucket: Array[String]
@export_enum("pigment", "binder", "support", "tool") var category: String

@export var label_text: String
@export var origin: String
@export_range(0, 5) var toxicity: int
@export_range(0, 5) var permanence: int
@export_range(0, 5) var cost: int 
@export_enum("red", "blue", "green", "yellow", "black", "brown", "white", "orange", "purple") var color_family: String
@export var conflicts_with: Array[String]
