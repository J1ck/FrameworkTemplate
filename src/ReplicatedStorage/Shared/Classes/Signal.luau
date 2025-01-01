--!strict
--!native
--!optimize 2

export type Connection = {
	Connected : boolean,
	Disconnect : (Connection) -> ()
}
export type Signal = typeof(setmetatable({} :: {
	_Connections : {[(...any) -> ()] : any}
}, {} :: {
	Connect : (Signal, Callback : (...any?) -> ()) -> (Connection),
	Once : (Signal, Callback : (...any?) -> ()) -> (Connection),
	Wait : (Signal) -> (...any),
	Fire : (Signal, ...any?) -> (),
	Destroy : (Signal) -> ()
}))

local function NewConnection(Callback : () -> ()) : Connection
	return {
		Connected = true,
		Disconnect = function(self)
			if not self.Connected then
				return
			end

			self.Connected = false

			task.spawn(Callback)
		end,
	}
end

local Signal = {}
Signal.__index = Signal

function Signal.new() : Signal
	return setmetatable({
		_Connections = {}
	}, Signal)
end

function Signal:Destroy()
	table.clear(self._Connections)
end

function Signal:Connect(Callback)
	self._Connections[Callback] = true

	return NewConnection(function()
		self._Connections[Callback] = nil
	end)
end

function Signal:Once(Callback)
	local Connection : Connection = nil

	local function Wrapper(... : any)
		Connection:Disconnect()

		Callback(...)
	end

	self._Connections[Wrapper] = true

	Connection = NewConnection(function()
		self._Connections[Wrapper] = nil
	end)

	return Connection
end

function Signal:Wait() : ...any
	local CurrentThread : thread = coroutine.running()

	local function Callback(... : any)
		self._Connections[Callback] = nil

		task.spawn(CurrentThread, ...)
	end

	self._Connections[Callback] = true

	return coroutine.yield(CurrentThread)
end

function Signal:Fire(...)
	for Callback in self._Connections do
		task.spawn(Callback, ...)
	end
end

function Signal:FireAsync(...)
	for Callback in self._Connections do
		local Status, Message = pcall(Callback, ...)
		
		if Status == false then
			warn(`[SignalClass] {Message}`)
		end
	end
end

return Signal