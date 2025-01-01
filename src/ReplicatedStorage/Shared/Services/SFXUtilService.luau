
local Service = {}

function Service.GetRandomSound(Root : Instance, IncludesDescendants : boolean?) : Sound
	local Pool = IncludesDescendants == true and Root:GetDescendants() or Root:GetChildren()
	local Filtered = {}
	
	for _, Object in Pool do
		if Object:IsA("Sound") then
			table.insert(Filtered, Object)
		end
	end
	
	return Filtered[math.random(1, #Filtered)]
end

function Service.PlaySound(Sound : Sound, Properties : {[string] : any}?)
	local Clone = Sound:Clone()
	
	if Properties ~= nil then
		for PropertyName, PropertyValue in Properties do
			Clone[PropertyName] = PropertyValue
		end
	end
	
	Clone.Ended:Once(function()
		Clone:Destroy()
	end)
	
	Clone:Play()
end

function Service.PlaySoundAtPosition(Sound : Sound, Position : Vector3, Properties : {[string] : any}?)
	local Clone = Sound:Clone()

	if Properties ~= nil then
		for PropertyName, PropertyValue in Properties do
			Clone[PropertyName] = PropertyValue
		end
	end
	
	local Attachment = Instance.new("Attachment")
	Attachment.Parent = workspace.Terrain
	Attachment.WorldPosition = Position
	
	Clone.Parent = Attachment
	
	Clone.Ended:Once(function()
		Attachment:Destroy()
	end)

	Clone:Play()
end

return Service