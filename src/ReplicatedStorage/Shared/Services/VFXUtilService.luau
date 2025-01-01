local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Service = {}

function Service.GetMaxLifetime(Particle : ParticleEmitter) : number
	return (Particle:GetAttribute("EmitDelay") or 0) + Particle.Lifetime.Max
end

function Service.Emit(Particle : ParticleEmitter)
	local EmitDelay = Particle:GetAttribute("EmitDelay")
	local EmitCount = Particle:GetAttribute("EmitCount") or 1
	
	if EmitDelay ~= nil then
		task.delay(EmitDelay, Particle.Emit, Particle, EmitCount)
	else
		Particle:Emit(EmitCount)
	end
end

function Service.EmitTable(Table : {Instance}, DestroyAfter : boolean?, DestroyParent : boolean?) : number
	local MaxLifetime = 0
	
	for _, Particle in Table do
		if Particle:IsA("ParticleEmitter") then
			MaxLifetime = math.max(MaxLifetime, Service.GetMaxLifetime(Particle))

			Service.Emit(Particle)
		end
		
		for _, Descendant in Particle:GetDescendants() do
			if not Descendant:IsA("ParticleEmitter") then
				continue
			end
			
			MaxLifetime = math.max(MaxLifetime, Service.GetMaxLifetime(Descendant))

			Service.Emit(Descendant)
		end
	end
	
	if DestroyAfter == true then
		task.delay(MaxLifetime, function()
			for _, Particle in Table do
				if DestroyParent == true and Particle.Parent ~= nil and Particle.Parent.Parent ~= nil then
					Particle.Parent:Destroy()
				else
					Particle:Destroy()
				end
			end
		end)
	end
	
	return MaxLifetime
end

function Service.CloneChildren(Root : Instance, NewParent : Instance?) : {Instance}
	local Clones = {}
	
	for _, Child in Root:GetChildren() do
		local Clone = Child:Clone()
		Clone.Parent = NewParent or nil
		
		table.insert(Clones, Clone)
	end
	
	return Clones
end

function Service.PlaceAttachment(Origin : Vector3 | CFrame) : Attachment
	local Attachment = Instance.new("Attachment")
	Attachment.Parent = workspace.Terrain
	
	if typeof(Origin) == "Vector3" then
		Attachment.WorldPosition = Origin
	else
		Attachment.WorldCFrame = Origin
	end
	
	return Attachment
end

return Service