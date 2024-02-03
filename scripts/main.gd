extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	FirebaseLite.initializeFirebase(["Authentication", "Firestore", "Realtime Database"], {
  "apiKey": "AIzaSyBRzoNk0wCxjW2NRv3ldjfXqTepwEt-McY",
  "authDomain": "godot-chat-app.firebaseapp.com",
  "projectId": "godot-chat-app",
  "storageBucket": "godot-chat-app.appspot.com",
  "messagingSenderId": "835465463971",
  "appId": "1:835465463971:web:09273a54d1a4ea79e65716",
"databaseURL": "https://godot-chat-app-default-rtdb.firebaseio.com"
})


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _on_sign_up_pressed():
	var email = $Panel/email.text
	var password = $Panel/password.text
	await FirebaseLite.Authentication.initializeAuth(2, email, password )
	await FirebaseLite.Authentication.initializeAuth(3, email, password)
	var username = str(email).get_slice("@",0)
	await FirebaseLite.RealtimeDatabase.write("/chatrooms/users/"+username, {"email": email})
	
func _on_login_pressed():
	var email = $Panel/email.text
	var password = $Panel/password.text
	var error = await FirebaseLite.Authentication.initializeAuth(3, email, password)
	get_tree().change_scene_to_file("res://scenes/chat.tscn")
	$Label.text = str(error[1])
