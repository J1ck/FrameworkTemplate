local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage.ServiceLoader)

local GlobalSignals = {}

local Service = {}

function Service.GetSignal(SignalName : string)
	if not GlobalSignals[SignalName] then
		GlobalSignals[SignalName] = ServiceLoader.new("SignalClass")
	end

	return GlobalSignals[SignalName]
end

function Service.Fire(SignalName : string, ... : any?)
	Service.GetSignal(SignalName):Fire(...)
end

return Service