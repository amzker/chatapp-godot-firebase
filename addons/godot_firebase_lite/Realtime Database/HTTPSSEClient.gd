#A HTTP SSE Client script based on WolfgangSenff's SSE Client script on github:
#https://github.com/WolfgangSenff/HTTPSSEClient
#full credit for this script goes to him, I just edited some things to fit
#Godot 4 and to return needed data
extends Node

signal new_sse_event(headers, event, data, path)
signal connected(name)
signal connection_error(error)

const event_tag = "event:"
const data_tag = "data:"
const continue_internal = "continue_internal"

var httpclient = HTTPClient.new()
var is_connected = false

var domain
var url_after_domain
var port
var use_ssl
var verify_host
var told_to_connect = false
var connection_in_progress = false
var request_in_progress = false
var is_requested = false
var response_body = PackedByteArray()

func connect_to_host(domain : String, url_after_domain : String, port : int = -1):
	self.domain = domain
	self.url_after_domain = url_after_domain
	self.port = port
	told_to_connect = true
	#print("url after domain: "+ url_after_domain)

func attempt_to_connect():
	var err = httpclient.connect_to_host(domain, port)
	#print("listner attempted to connect")
	if err == OK:
		#print("url connection established")
		emit_signal("connected", self.name)
		is_connected = true
	else:
		emit_signal("connection_error", str(err))

func attempt_to_request(httpclient_status):
	#print("attempting to request")
	if httpclient_status == HTTPClient.STATUS_CONNECTING or httpclient_status == HTTPClient.STATUS_RESOLVING:
		#print("failed probalay")
		return
		
	if httpclient_status == HTTPClient.STATUS_CONNECTED:
		var err = httpclient.request(HTTPClient.METHOD_POST, "/"+url_after_domain, ["Accept: text/event-stream"])
		if err == OK:
			#print("Request completed")
			is_requested = true
		else:
			pass
			#print("Request not complted")

func _process(delta):
	if !told_to_connect:
		return
		
	if !is_connected:
		if !connection_in_progress:
			attempt_to_connect()
			connection_in_progress = true
		return
		
	httpclient.poll()
	var httpclient_status = httpclient.get_status()
	
	if !is_requested:
		if !request_in_progress:
			attempt_to_request(httpclient_status)
		return
		
	var httpclient_has_response = httpclient.has_response()
	#print("CHECKING RESPONSE")
	if httpclient_has_response or httpclient_status == HTTPClient.STATUS_BODY:
		var headers = httpclient.get_response_headers_as_dictionary()

		httpclient.poll()
		var chunk = httpclient.read_response_body_chunk()
		if(chunk.size() == 0):
			#print("NO DATA")
			return
		else:
			response_body = response_body + chunk
			
		var body = response_body.get_string_from_utf8()
		if body:
			var event_data = get_event_data(body)
			if event_data.event != "keep-alive" and event_data.event != continue_internal:
				var result = JSON.new().parse_string(event_data.data)
				if response_body.size() > 0 and result: # stop here if the value doesn't parse
					response_body.resize(0)
					#print("EMMITING NEW SSE CLIENT SIGNAL")
					emit_signal("new_sse_event", headers, event_data.event, result, self.name)
			else:
				if event_data.event != continue_internal:
					response_body.resize(0)

func get_event_data(body : String) -> Dictionary:
	
	var result = {}
	var event_idx = body.find(event_tag)
	if event_idx == -1:
		result["event"] = continue_internal
		return result
	assert(event_idx != -1)
	var data_idx = body.find(data_tag, event_idx + event_tag.length())
	assert(data_idx != -1)
	var event = body.substr(event_idx, data_idx)
	event = event.replace(event_tag, "").strip_edges()
	assert(event)
	assert(event.length() > 0)
	result["event"] = event
	body.replace(str("event: " + event), "")
	var data = body.replace(body.left(body.find("{")), "")
	assert(data)
	assert(data.length() > 0)
	result["data"] = data
	return result

func _exit_tree():
	if httpclient:
		#print("client is removed")
		httpclient.close()

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_ABOUT:
		if httpclient:
			httpclient.close()
		get_tree().quit()
