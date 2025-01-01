type FakeRBXScriptConnection = {Connected : boolean, Disconnect : (FakeRBXScriptConnection) -> ()}

local ASSERTION_TABLE = {
	[true] = {
		OnServerEvent = true,
		OnServerInvoke = true,
		FireClient = true
	},
	[false] = {
		OnClientEvent = true,
		FireServer = true,
		InvokeServer = true
	}
}

local RunService = game:GetService("RunService")

local t = require(script:WaitForChild("t"))

local IsServer = RunService:IsServer()

local function GetRemote(Name : string, ClassName : string)
	if IsServer then
		if script:FindFirstChild(Name) then
			return script:FindFirstChild(Name)
		end

		local Remote = Instance.new(ClassName)
		Remote.Name = Name
		Remote.Parent = script
		
		return Remote
	else
		return script:WaitForChild(Name)
	end
end

local function GetCallbackWithTypeChecking(Callback : (...any) -> (...any?), TypeCheckCallbacks : {(...any) -> (boolean, string?)}?)
	return typeof(TypeCheckCallbacks) == "table" and function(...)
		local Status, Message = t.tuple(table.unpack(TypeCheckCallbacks))(table.unpack({...}, IsServer and 2 or 1))
		
		if Status == true then
			Callback(...)
		else
			warn(Message)
		end
	end or Callback
end

local function CallRemoteMethod(
	Name : string,
	ClassName : string,
	MethodName : string,
	... : any
) : ...any?
	assert(
		ASSERTION_TABLE[IsServer][MethodName],
		`cannot call method '{ClassName}.{MethodName}' on the {IsServer and "server" or "client"}`
	)
	
	local Remote = GetRemote(Name, ClassName)
	
	return Remote[MethodName](Remote, ...)
end

local function ConnectToRemote(
	Name : string,
	ClassName : string,
	EventName : string,
	Callback : (...any) -> (...any?),
	TypeCheckCallbacks : {
		(...any) -> (boolean, string?)
	}?
) : RBXScriptConnection
	assert(
		ASSERTION_TABLE[IsServer][EventName],
		`cannot connect to event '{ClassName}.{EventName}' on the {IsServer and "server" or "client"}`
	)
	
	local TypeCheckedCallback = GetCallbackWithTypeChecking(Callback, TypeCheckCallbacks)
	
	return GetRemote(Name, ClassName)[EventName]:Connect(TypeCheckedCallback)
end

local function CreateFakeConnection(Remote : RemoteFunction) : FakeRBXScriptConnection
	local CurrentCallback = Remote.OnServerInvoke
	
	return {
		Connected = true,
		Disconnect = function(self)
			if self.Connected and Remote.OnServerInvoke == CurrentCallback then
				self.Connected = false

				Remote.OnServerInvoke = nil :: any
			end
		end,
	}
end

local NetworkService = {
	t = t
}

function NetworkService.FireServer(Name : string, ... : any)
	CallRemoteMethod(Name, "RemoteEvent", "FireServer", ...)
end

function NetworkService.InvokeServer(Name : string, ... : any) : ...any
	return CallRemoteMethod(Name, "RemoteFunction", "InvokeServer", ...)
end

function NetworkService.OnServerEvent(
	Name : string,
	Callback : (Player : Player, ...any) -> (),
	TypeCheckCallbacks : {
		(...any) -> (boolean, string?)
	}?
) : RBXScriptConnection
	return ConnectToRemote(Name, "RemoteEvent", "OnServerEvent", Callback, TypeCheckCallbacks)
end

function NetworkService.OnServerInvoke(
	Name : string,
	Callback : (Player : Player, ...any) -> (...any),
	TypeCheckCallbacks : {
		(...any) -> (boolean, string?)
	}?
) : FakeRBXScriptConnection
	local TypeCheckedCallback = GetCallbackWithTypeChecking(Callback, TypeCheckCallbacks)
	local Remote = GetRemote(Name, "RemoteFunction")
	
	Remote.OnServerInvoke = TypeCheckedCallback
	
	return CreateFakeConnection(Remote)
end

function NetworkService.FireClient(Name : string, Player : Player, ... : any)
	CallRemoteMethod(Name, "RemoteEvent", "FireClient", Player, ...)
end

function NetworkService.FireClients(Name : string, Players : {Player}, ... : any)
	for _, Player in Players do
		task.spawn(CallRemoteMethod, Name, "RemoteEvent", "FireClient", Player, ...)
	end
end

function NetworkService.LoadRemote(Name : string, ClassName : string)
	assert(IsServer, `cannot call function on the client`)
	
	GetRemote(Name, ClassName)
end

function NetworkService.OnClientEvent(Name : string, Callback : (...any) -> ()) : RBXScriptConnection
	return ConnectToRemote(Name, "RemoteEvent", "OnClientEvent", Callback)
end

return NetworkService