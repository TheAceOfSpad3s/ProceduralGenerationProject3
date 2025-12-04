extends OptionButton

# Define the options array as a class variable so we can access it in _ready and _on_item_selected
var options = [1.0, 0.75, 0.5, 0.25]

func _ready():
	# Get the current scaling scale from the root viewport
	var current_scale = get_tree().root.scaling_3d_scale
	
	# Find the index that matches this scale
	var matching_index = -1
	
	# We loop through our options to find the one that is closest to the current setting
	for i in range(options.size()):
		# Use is_equal_approx for floating point comparisons to avoid tiny errors
		if is_equal_approx(current_scale, options[i]):
			matching_index = i
			break
	
	# If we found a match, set the selected item
	if matching_index != -1:
		selected = matching_index
	else:
		# Fallback: If the current scale isn't in our list, maybe default to 1.0 (index 0)
		selected = 0 

func _on_item_selected(index):
	var value = options[index]
	get_tree().root.scaling_3d_scale = value
