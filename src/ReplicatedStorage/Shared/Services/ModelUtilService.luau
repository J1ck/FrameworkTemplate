local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local function Lerp(a, b, t)
	return a + (b - a) * t
end

local Service = {}

function Service.TweenModelScale(Model : Model, Info : TweenInfo, Scale : number) : RBXScriptConnection
	local Elapsed = 0
	local OriginalValue = Model:GetScale()
	local Connection = nil

	Connection = RunService.Heartbeat:Connect(function(DeltaTime)
		Elapsed = math.clamp(Elapsed + DeltaTime, 0, Info.Time)

		if Elapsed == Info.Time then
			Connection:Disconnect()
		end

		local Alpha = Elapsed / Info.Time
		local Value = TweenService:GetValue(Alpha, Info.EasingStyle, Info.EasingDirection)
		local NewScale = Lerp(OriginalValue, math.max(Value, 0.001), Value)
		
		Model:ScaleTo(NewScale)
	end)
	
	return Connection
end

function Service.SetDescendantsProperties(Model : Model, Class : string, Properties : {[string] : any})
	for _, Descendant in Model:GetDescendants() do
		if Descendant:IsA(Class) then
			for Property, Value in Properties do
				Descendant[Property] = Value
			end
		end
	end
end

return Service