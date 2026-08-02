extends Control

@export var all_items: Array[Item] = []
@export var all_entries: Array[NotebookEntry] = []

@export var days: Array[Day] = []
var day_index := 0
var customer_index := 0

var shelf: Array[Item] = []
var storage: Array[Item] = []

const SHELF_SIZE := 8

enum Phase { POEM, SHOP_DARK, BOX, CUSTOMER, NOTEBOOK, RESPONSE, STORAGE, CLOSING, ENDING }

var phase: Phase = Phase.POEM
var pending_response: String = ""

var cat_moved: bool = false

var notebook_text := """My Dear,
	
	I guess when you're reading this I'll be dead. That's a relief.
	Feed Mortimer. Not too much, he lies about it. 
	
	Some of these notes are mine, things I learned in years working here. 
	Some are from others, but still useful. Green ones are wrong, I never got around to fixing them. 
	Sorry for the mess, but I'm sure you'll figure it out. 
	
	Now I'm forgetting to write you something, but it will come to mind eventually. 
	
	Love you, 
	Mom 
	
	P.S. Check the calendar for acqua alta. Listen for the siren at night.
	"""

func render() -> void:
	
	var shopping := (phase == Phase.CUSTOMER)
	var dark_shop := (phase == Phase.SHOP_DARK)
	var storing := (phase == Phase.STORAGE)
	
	$ShelfContainer.visible = shopping or storing
	$StorageContainer.visible = storing 
	$ButtonCat.visible = dark_shop and not cat_moved
	$ButtonNotebook.visible = dark_shop and cat_moved
	$ButtonStorage.visible = dark_shop
	
	match phase:
		Phase.POEM:
			$RichTextLabel.text = """
			Indosso calze bianche ostili, 
				ma dalla finestra godo il verde diverso 
				di tante piante. 
				Perché ti penso?
				"""
		Phase.SHOP_DARK:
			if cat_moved:
				$RichTextLabel.text = "The cat has moved somewhere else. Now the old notebook is visible on the counter."
			else:
				$RichTextLabel.text = "A dark room. Smells of mold and chemicals. Everywhere dust lays on pale cloth covring the furniture. Clutter everywhere. So many objects it's difficult to make your way to the main counter …and on it, a cat, asleep on something."
				
		Phase.CUSTOMER:
			$RichTextLabel.text = current_customer().greeting + "\n\n" + current_customer().request
			
		Phase.NOTEBOOK:
			$RichTextLabel.text = notebook_text
			
		Phase.RESPONSE:
			$RichTextLabel.text = pending_response
			
		Phase.STORAGE:
			$RichTextLabel.text = "What stays out, and what goes in the back."

		Phase.CLOSING:
			$RichTextLabel.text = current_day().closing_text
		Phase.ENDING:
			$RichTextLabel.text = "[ending]"

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		advance()
		

		
func advance() -> void:
	print("advance from phase ", phase, " day ", day_index, " customers ", current_day().customers.size())
	save_game()
	match phase: 
		Phase.POEM: 
			phase = Phase.SHOP_DARK
			
		Phase.SHOP_DARK:
			phase = Phase.CUSTOMER
			
		Phase.NOTEBOOK:
			phase = Phase.SHOP_DARK
			
		Phase.STORAGE: 
			phase = Phase.SHOP_DARK
			build_shelf_buttons()

		Phase.RESPONSE:
			customer_index += 1
			if customer_index < current_day().customers.size():
				phase = Phase.CUSTOMER
			else:
				phase = Phase.CLOSING
				
		Phase.CLOSING:
			day_index += 1
			save_game()
			if day_index < days.size():
				start_day()
			else:
				phase = Phase.ENDING
	render()

func build_shelf_buttons(for_storage: bool = false) -> void:
	for child in $ShelfContainer.get_children():
		child.queue_free()
	for item in shelf:
		var b := Button.new()
		b.text = item.display_name
		if for_storage:
			b.pressed.connect(move_to_storage.bind(item))
		else:
			b.pressed.connect(_on_object_pressed.bind(item.id))
		$ShelfContainer.add_child(b)
		
func build_storage_buttons() -> void:
	for child in $StorageContainer.get_children():
		child.queue_free()
	for item in storage:
		var b := Button.new()
		b.text = item.display_name
		b.pressed.connect(_on_storage_item_pressed.bind(item))
		$StorageContainer.add_child(b)
		
func _on_storage_item_pressed(item: Item) -> void:
	if shelf.size() >= SHELF_SIZE:
		return
	shelf.append(item)
	storage.erase(item)
	build_shelf_buttons(true)
	build_storage_buttons()
	render()

func _ready() -> void:
	if FileAccess.file_exists("user://save.json"):
		load_game()
	else:
		for item in all_items:
			if shelf.size() < SHELF_SIZE:
				shelf.append(item)
			else:
				storage.append(item)
	build_shelf_buttons()
	render()
	
func move_to_storage(item: Item) -> void:
	shelf.erase(item)
	storage.append(item)
	build_shelf_buttons(true)
	build_storage_buttons()
	render()

func response_for(object_id: String) -> String:
	for entry in current_customer().outcome:
		if entry.object_id == object_id:
			return entry.response_line
	return current_customer().default_response
	
func _on_object_pressed(object_id: String) -> void:
	pending_response = response_for(object_id)
	phase = Phase.RESPONSE
	render()
	
func _on_button_cat_pressed() -> void:
	cat_moved = true
	render()

func _on_button_notebook_pressed() -> void:
	phase = Phase.NOTEBOOK
	render()
	
func entry_for(item_id: String) -> NotebookEntry:
	for e in all_entries:
		if e.item_id == item_id:
			return e
	return null
	
func _on_button_storage_pressed() -> void:
	phase = Phase.STORAGE
	build_shelf_buttons(true)
	build_storage_buttons()
	render()
	
func current_day() -> Day:
	return days[day_index]

func current_customer() -> Customer:
	return current_day().customers[customer_index]
	
func start_day() -> void:
	customer_index = 0
	cat_moved = false
	phase = Phase.SHOP_DARK
	for item in current_day().box_items:
		storage.append(item)
		
func save_game() -> void:
	var data := {
		"day_index": day_index,
		"customer_index": customer_index,
		"phase": phase,
		"cat_moved": cat_moved,
		"shelf_ids": shelf.map(func(i): return i.id),
		"storage_ids": storage.map(func(i): return i.id),
	}
	var file := FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	
func item_for(id: String) -> Item:
	for i in all_items:
		if i.id == id:
			return i
	return null
	
func load_game() -> void:
	if not FileAccess.file_exists("user://save.json"):
		return
	var file := FileAccess.open("user://save.json", FileAccess.READ)
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	day_index = int(data["day_index"])
	customer_index = int(data["customer_index"])
	phase = data["phase"] as Phase
	cat_moved = data["cat_moved"]

	shelf.clear()
	for id in data["shelf_ids"]:
		shelf.append(item_for(id))
	storage.clear()
	for id in data["storage_ids"]:
		storage.append(item_for(id))
