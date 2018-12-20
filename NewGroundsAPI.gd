extends HTTPRequest

const NEW_GROUNDS_API_URL = 'https://www.newgrounds.io/gateway_v3.php'

export(bool) var verbose
export(String) var applicationId

signal ng_request_complete

var Gateway
var ScoreBoard
var App

var session_id

func _ready():
	use_threads = OS.get_name() != "HTML5"
	
	connect("request_completed", self, "_request_completed")
	
	Gateway = ComponentGateway.new(self)
	ScoreBoard = ComponentScoreBoard.new(self)
	App = ComponentApp.new(self)
	
	if OS.get_name() == 'HTML5':
		session_id = JavaScript.eval('var urlParams = new URLSearchParams(window.location.search); urlParams.get("ngio_session_id")', true)
		print('Session id: ' + str(session_id))
		print('Location hostname: ' + str(JavaScript.eval('location.hostname')))
	pass

func _call_ng_api(component, function, _session_id=null, parameters=null, debug=null, echo=null):
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	var requestData = {}
	
	requestData.app_id = applicationId
	if debug:
		requestData.debug = true
	if session_id:
		requestData.session_id = _session_id
	requestData.call = {}
	requestData.call.component = component + '.' + function
	requestData.call.parameters = parameters
	
	var requestJson = JSON.print(requestData)
	if verbose:
		print(requestJson)
	var requestResult = request(NEW_GROUNDS_API_URL, headers, true, HTTPClient.METHOD_POST, 'input=' + requestJson.percent_encode())
	if requestResult != OK:
		emit_signal('ng_request_complete', {'error': 'Request result = ' + str(requestResult)})
	pass
	
func _request_completed(result, response_code, headers, body):
	var responseBody = body.get_string_from_utf8()
	if verbose:
		print('Response code: ' + str(response_code))
		print('Response body: ' + responseBody)
	if result != OK:
		emit_signal('ng_request_complete', {'error': 'Response result = ' + str(result)})
		return
	if response_code >= 300:
		emit_signal('ng_request_complete', {'error': 'Response status code = ' + str(response_code)})
		return
		
	var jsonBody = JSON.parse(responseBody)
	if jsonBody.error != OK:
		emit_signal('ng_request_complete', {'error': 'Response has wrong JSON body'})
		return
	if !jsonBody.result.success:
		emit_signal('ng_request_complete', {'error': 'New Grounds error: ' + str(jsonBody.result.error.code) + ' ' + str(jsonBody.result.error.message)})
		return
	if !jsonBody.result.result.data.success:
		emit_signal('ng_request_complete', {'error': 'New Grounds data error: ' + str(jsonBody.result.result.data.error.code) + ' ' + str(jsonBody.result.result.data.error.message)})
		return
	var response = jsonBody.result.result.data
	emit_signal('ng_request_complete', {'response': response, 'error': null})
	pass

class ComponentApp:
	const NAME = 'App'
	var api
	func _init(_api):
		api = _api
		
	func checkSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'checkSession', sessionId)
		pass
		
	func endSession(sessionId=api.session_id):
		api._call_ng_api(NAME, 'endSession', sessionId)
		pass
		
	func getCurrentVersion(version=null):
		api._call_ng_api(NAME, 'getCurrentVersion', null, {'version' : version})
		pass
		
	func getHostLicense(host=null):
		api._call_ng_api(NAME, 'getHostLicense', null, {'host' : host})
		pass
		
	func logView(host):
		api._call_ng_api(NAME, 'logView', null, {'host' : host})
		pass
		
	func startSession(force=null):
		api._call_ng_api(NAME, 'startSession', null, {'force' : force})
		pass
	

class ComponentGateway:
	const NAME = 'Gateway'
	var api
	func _init(_api):
		api = _api

	func getVersion():
		api._call_ng_api(NAME, 'getVersion')
		pass
		
	func getDatetime():
		api._call_ng_api(NAME, 'getDatetime')
		pass
		
	func ping():
		api._call_ng_api(NAME, 'ping')
		pass

class ComponentScoreBoard:
	const NAME = 'ScoreBoard'
	var api
	func _init(_api):
		api = _api
	func getBoards():
		api._call_ng_api(NAME, 'getBoards')
		pass
