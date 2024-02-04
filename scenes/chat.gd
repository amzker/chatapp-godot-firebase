extends Control

var data = ""
var email = ""
var UID = ""
var nickname = ""
var activechat = "/chatrooms/global"
var initreq = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	update_userdata()
	get_chatrooms()
	
	FirebaseLite.RealtimeDatabase.connect("refUpdated",chatmanager)
	await FirebaseLite.RealtimeDatabase.listen(activechat)

	
func update_userdata():
	data = await FirebaseLite.Authentication.getUserData()
	#print(data)
	email = data[1]["users"][0]["email"]
	UID = data[1]["users"][0]["localId"]
	$profile/email.text =  email
	var keys = data[1]["users"][0].keys()
	
	if  keys.has("displayName"):
		nickname = data[1]["users"][0]["displayName"]
		$profile/name.text = "Nickname: "+nickname
	else:
		$profile/name.text = "no nickname please set"

func get_chatrooms():
	var rooms = await FirebaseLite.RealtimeDatabase.read("/chatrooms/users")
	#print(rooms)
	$chatrooms.clear()
	
	for i in rooms[1].keys():
		$chatrooms.add_item(i)

func _on_chatrooms_item_activated(index):
	pass
	#activechat = $chatrooms.get_item_text(index)
	#FirebaseLite.RealtimeDatabase.listen(activechat)
	
func _on_update_pressed():
	nickname = $nickname.text
	await FirebaseLite.Authentication.updateDisplayName(nickname)
	update_userdata()


func _on_refresh_pressed():
	await update_userdata()
	await get_chatrooms()


func _on_send_pressed():
	var msg = $messege.text
	$messege.text = ""
	await FirebaseLite.RealtimeDatabase.push(activechat,{nickname:msg})



func chatmanager(req):
	var chats = req["data"]
	print(chats)
	# because at first it gets all data
	# laterwards only changes , thats why
	var timestamps = chats.keys()
	if initreq == 0:
		for i in timestamps:
			var sender = chats[i].keys()[0]
			var msg = chats[i][sender]
			$chat.add_item(sender+": "+msg)
		initreq = initreq+1
	else:
		#print(chats)
		for i in timestamps:
			var sender = i
			var msg = chats[i]
			$chat.add_item(sender+": "+msg)

