extends Control

enum Phase { POEM, SHOP_DARK, CUSTOMER, RESPONSE, CLOSING }

var phase: Phase = Phase.POEM
var pending_response: String = ""

var cat_moved: bool = false

func render() -> void:
	
	var shopping := (phase == Phase.CUSTOMER)
	var dark_shop := (phase == Phase.SHOP_DARK)
	
	$ButtonNeroFumo.visible = shopping
	$ButtonNeroAvorio.visible = shopping
	$ButtonCat.visible = dark_shop and not cat_moved
	$ButtonNotebook.visible = dark_shop and cat_moved
	

	
	match phase:
		Phase.POEM:
			$RichTextLabel.text = "Indosso calze bianche ostili, ma dalla finestra godo il verde diverso di tante piante. Perché ti penso?"
		Phase.SHOP_DARK:
			if cat_moved:
				$RichTextLabel.text = "[after]"
			else:
				$RichTextLabel.text = "A dark room. Smells of mold and chemicals. Everywhere dust lays on pale cloth covring the furniture. Clutter everywhere. So many objects it's difficult to make your way to the main counter …and on it, a cat, asleep on something."
				
		Phase.CUSTOMER:
			$RichTextLabel.text = customer.greeting + "\n\n" + customer.request
		Phase.RESPONSE:
			$RichTextLabel.text = pending_response
		Phase.CLOSING: 
			$RichTextLabel.text = "[end of day]"

func _unhandled_input(event: InputEvent) -> void:
	print("input seen: ", event)
	if event is InputEventMouseButton and event.pressed:
		advance()
		
func advance() -> void:
	match phase: 
		Phase.POEM: 
			phase = Phase.SHOP_DARK
		Phase.SHOP_DARK:
			phase = Phase.CUSTOMER
		Phase.RESPONSE:
			phase = Phase.CLOSING
	render()
		
@export var customer: Customer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	render()

func response_for(object_id: String) -> String:
	for entry in customer.outcome:
		if entry.object_id == object_id:
			return entry.response_line
	return customer.default_response
	

func _on_button_nero_fumo_pressed() -> void:
	pending_response = response_for("nero_fumo")
	phase = Phase.RESPONSE
	render()
	get_viewport().set_input_as_handled()


func _on_button_nero_avorio_pressed() -> void:
	pending_response = response_for("nero_avorio")
	phase = Phase.RESPONSE
	render()
	get_viewport().set_input_as_handled()


func _on_button_cat_pressed() -> void:
	cat_moved = true
	render()
	get_viewport().set_input_as_handled()


func _on_button_notebook_pressed() -> void:
	pending_response = """My Dear,
	
	I guess when you're reading this I'll be dead. That's a relief.
	Feed Mortimer. Not too much, he lies about it. 
	
	Some of these notes are mine, things I learned in years working here. 
	Some are from others, but still useful. Green ones are wrong, I never got around to fixing them. 
	Sorry for the mess, but I'm sure you'll figure it out. 
	
	Now I'm forgetting to write you something, but it will come to mind eventually. 
	
	Love you, 
	Mom 
	
	P.S. Check the calendar for acqua alta. Listen for the siren at night."""
	phase = Phase.RESPONSE
	render()
	get_viewport().set_input_as_handled()
