extends Node

## --- API CONFIGURATION ---
const API_BASE_URL = "https://api.simpleboards.dev/api/" # Base URL with 'api/'
const API_KEY = "43757bc8-b0de-4b57-9fcb-e947e5199b74" # Your project API key
const LEADERBOARD_ID = "db95a91f-a7ad-47e0-e071-08de1d43138c" # Your specific leaderboard ID

## --- HTTP REQUEST NODES ---
# Using separate nodes for POST and GET is a reliable way to handle simultaneous requests
var http_request_post: HTTPRequest
var http_request_get: HTTPRequest

## --- LeaderBoard UI Data and Config ---
var playerScores: Array = [] # Stores fetched entries as an Array of Dictionaries
@export var MaxLeaderBoardEntries : int = 10 # How many scores to display

# IMPORTANT: Check this path against your scene tree (LeaderBoardMenu/LeaderBoardList)
@onready var leaderboard_list = $"LeaderBoardMenu/LeaderBoardList" 
@onready var loading_text = $LeaderBoardMenu/LoadingText
@onready var username = $SubmitScoreButtons/UsernameEdit
@onready var submit_button = $SubmitScoreButtons/Submit

# --- NEW: Color definitions for ranks ---
const COLOR_GOLD = "#FFD700"
const COLOR_SILVER = "#C0C0C0"
const COLOR_BRONZE = "#CD7F32"
const COLOR_DEFAULT = "#ffffff"
# --- Score Data ---
var final_score
var player_username

func _ready():
	# 1. Initialize and connect the POST request node
	http_request_post = HTTPRequest.new()
	add_child(http_request_post)
	http_request_post.request_completed.connect(_on_request_completed) 

	# 2. Initialize and connect the GET request node
	http_request_get = HTTPRequest.new()
	add_child(http_request_get)
	http_request_get.request_completed.connect(_on_request_completed)

	# --- Execute Requests ---
	
	# POST: Example submission (uncomment to test posting a score)
	# submit_entry("player_222", "Horizon Pilot 5", 100, "Test entry in milliseconds")
	
	# Wait for a short moment before fetching the list
	await get_tree().create_timer(1.5).timeout 
	
	# GET: Retrieve the full leaderboard
	#get_leaderboard()


## -----------------------------------------------------------------
## API CALL FUNCTIONS
## -----------------------------------------------------------------

# Function to submit a score entry (POST request)
func submit_entry(player_id: String, display_name: String, score: int, metadata: String):
	var url = API_BASE_URL + "entries"
	var headers = ["x-api-key: " + API_KEY, "Content-Type: application/json"]
	
	var body = {
		"LeaderboardId": LEADERBOARD_ID,
		"PlayerId": player_id,
		"PlayerDisplayName": display_name,
		"Score": score,
		"Metadata": metadata
	}
	print("Submitting entry...")
	submit_button.text = "submitting..."
	loading_text.show()
	http_request_post.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(body))


# Function to retrieve the full leaderboard (GET request)
func get_leaderboard():
	# The endpoint is /leaderboards/{id}/entries
	var url = API_BASE_URL + "leaderboards/" + LEADERBOARD_ID + "/entries"
	var headers = ["x-api-key: " + API_KEY] 
	
	print("Retrieving leaderboard...")
	loading_text.show()
	# Use the dedicated GET node for the request
	http_request_get.request(url, headers, HTTPClient.METHOD_GET)


## -----------------------------------------------------------------
## RESPONSE HANDLER
## -----------------------------------------------------------------

func _on_request_completed(result, response_code, headers, body):
	var response_text = body.get_string_from_utf8()
	
	if response_code == 200:
		var response = JSON.parse_string(response_text)
		
		# --- 1. Handle the POST Response (Single Entry Creation) ---
		if response is Dictionary and response.has("id"): 
			print("⭐ Single Entry Created Successfully! ID: ", response.id)
			submit_button.text = "Submitted"
			submit_button.disabled = true
		# --- 2. Handle the GET Response (Leaderboard List) ---
		elif response is Array: 
			var entries_list = response 
			
			print("✅ Leaderboard Retrieved Successfully! (Total Entries: ", entries_list.size(), ")")
			
			# CLEAR THE LIST before adding new scores
			playerScores.clear() 

			# Iterate and store the data in a cleaner format
			for i in range(min(MaxLeaderBoardEntries, entries_list.size())):
				var entry = entries_list[i]
				
				# Store data as a Dictionary for cleaner UI access later
				var record = {
					"rank": i + 1,
					"name": entry.playerDisplayName,
					"score": int(entry.score) # Convert score to number for internal use
				}
				playerScores.append(record)
			loading_text.hide()
			updateLeaderBoard()
		
		else:
			print("API Response successful, but format is unexpected: ", response_text)
	
	else:
		# Always print the error message if the request fails
		print("❌ HTTP Request failed: ", response_code, " | Server Message: ", response_text)
		submit_button.text = "Submit_score"

## -----------------------------------------------------------------
## UI UPDATE FUNCTION (Ranks and Font Updated)
## -----------------------------------------------------------------

func updateLeaderBoard():
	# 1. Clear existing list items (important for refreshing!)
	for child in leaderboard_list.get_children():
		child.queue_free()
		
	# Define a common font size for all entries
	const FONT_SIZE = 22
	
	# 2. Create and add new entries
	for i in range(playerScores.size()):
		var record = playerScores[i] # Get the current Dictionary entry
		
		var entry = RichTextLabel.new()
		entry.bbcode_enabled = true
		entry.custom_minimum_size = Vector2(0, FONT_SIZE + 5) # Set minimum height based on font size
		entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		entry.scroll_active = false
		var rank = record.rank
		var name = record.name
		var score = record.score
		
		# Determine the color based on rank
		var rank_color = COLOR_DEFAULT
		match rank:
			1:
				rank_color = COLOR_GOLD
			2:
				rank_color = COLOR_SILVER
			3:
				rank_color = COLOR_BRONZE
		
		# Build the base text: Rank in its color, Name, Score in its color
		# We wrap the whole string in a size tag for easy font size control
		var base_text = "[font_size=%d][color=%s]%d. [/color][color=#7ae7ff]%s[/color]: [color=#ffe74c]%d [/color][/font_size]" % [FONT_SIZE, rank_color, rank, name, score]
		
		
		# 3. Apply special effects for top 3
		if rank <= 1:
			# Apply bold and the wave effect to the whole entry
			entry.text = "[b][wave amp=20 freq=3]" + base_text + "[/wave][/b]"
		else:
			entry.text = base_text
			
		leaderboard_list.add_child(entry)




func _on_submit_pressed():
	player_username = username.text.to_lower()
	var submit_score = final_score
	submit_entry(player_username, player_username, submit_score, "")
	await get_tree().create_timer(3.0).timeout
	get_leaderboard()
	
	
func _on_score_manager_final_score(score):
	final_score = score
	await get_tree().create_timer(0.5).timeout
	get_leaderboard()
