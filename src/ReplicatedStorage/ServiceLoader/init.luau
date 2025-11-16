local CONFIG = require(script.Config)
local UTIL_FUNCTIONS = require(script.Util)

local Services = {}
local Classes = {}

local ThreadsWaitingOnLoaded : {[thread] : any} = {}

local function SortTableByLoadOrder(Table : {ModuleScript}) : {ModuleScript}
	table.sort(Table, function(a, b)
		return
			(a:GetAttribute(CONFIG.LOAD_ORDER_ATTRIBUTE_NAME) or CONFIG.DEFAULT_LOAD_ORDER) <
			(b:GetAttribute(CONFIG.LOAD_ORDER_ATTRIBUTE_NAME) or CONFIG.DEFAULT_LOAD_ORDER)
	end)
	
	return Table
end

local function ApplyStaticAttributes(Metadata)
	local Object = game

	for _, ChildName in Metadata.Path do
		Object = Object:FindFirstChild(ChildName)

		if Object == nil then
			return
		end
	end

	for Name, Value in Metadata.Attributes do
		Object:SetAttribute(Name, Value)
	end
end

for _, v in CONFIG.STATIC_INSTANCE_ATTRIBUTES do
	ApplyStaticAttributes(v)
end

local Framework = {}
Framework.Util = UTIL_FUNCTIONS
Framework.Debug = {
	IsVerbose = game:GetService("RunService"):IsStudio(),
	DebugLoadDepth = {},

	ServicesToLoad = 0,
	ServicesLoaded = 0,
	ServiceCurrentlyLoading = "",
}

function Framework.InitializeService(Module : ModuleScript)
	if Module:GetAttribute(CONFIG.IGNORE_ATTRIBUTE_NAME) then
		return
	elseif Services[Module.Name] then
		warn(`service with name '{Module.Name}' is already initialized\n\n{debug.traceback()}`)

		return 
	end
	
	local str = ""
	local loadTime = os.clock()
	
	if Framework.Debug.IsVerbose then
		DebugLoadDepth[Module.Name] = (Framework.Debug.DebugLoadDepth[Module.Parent.Name] or 0) + 1
		
		for _ = 1, Framework.Debug.DebugLoadDepth[Module.Name] - 1 do
			str ..= "	-"
		end
		
		local loadOrder = Module:GetAttribute(CONFIG.LOAD_ORDER_ATTRIBUTE_NAME) or CONFIG.DEFAULT_LOAD_ORDER
		
		str ..= `	[{loadOrder}] > {Module.Name}`
	end

	Framework.Debug.ServiceCurrentlyLoading = Module.Name
	
	Services[Module.Name] = require(Module)
	
	if Services[Module.Name][CONFIG.INITIALIZE_FUNCTION_NAME] ~= nil then
		local Status, Returned = pcall(Services[Module.Name][CONFIG.INITIALIZE_FUNCTION_NAME])

		if Status == false then
			warn(`service with name '{Module.Name}' errored while initializing\n\n{Returned}\n\n`)
		end
	end
	
	Framework.Debug.ServicesLoaded += 1
	
	if Framework.Debug.IsVerbose then
		local passed = (os.clock() - loadTime) * 1000
		
		str = string.format("%.3fms ", passed) .. str
		
		if passed > 16 then
			warn(str)
		else
			print(str)
		end
	end
end

function Framework.InitializeServices(Root : Instance) : typeof(Framework)
	local ToRecurse = {}
	
	for _, Object in Root:GetChildren() do
		if Object:IsA("ModuleScript") then
			table.insert(ToRecurse, Object)
		end
	end
	
	Framework.Debug.ServicesToLoad += #ToRecurse
	
	SortTableByLoadOrder(ToRecurse)
	
	for _, Module in ToRecurse do
		Framework.InitializeService(Module)
		
		if Module:GetAttribute(CONFIG.IGNORE_DESCENDANTS_ATTRIBUTE_NAME) == true then
			continue
		end

		Framework.InitializeServices(Module)
	end
	
	return Framework
end

function Framework.GetService(Name : string)
	return Services[Name] or warn(`service with name '{Name}' does not exist\n\n{debug.traceback()}`)
end

function Framework.InitializeClass(Module : ModuleScript)
	if Module:GetAttribute(CONFIG.IGNORE_ATTRIBUTE_NAME) then
		return
	elseif Classes[Module.Name] then
		warn(`class with name '{Module.Name}' is already exists`)

		return
	end
	
	Classes[Module.Name] = require(Module)
end

function Framework.InitializeClasses(Root : Instance, Recursive : boolean?) : typeof(Framework)
	local ToLoop = Recursive == true and Root:GetDescendants() or Root:GetChildren()
	local ToInitialize = {}
	
	for _, Object in ToLoop do
		if Object:IsA("ModuleScript") then
			table.insert(ToInitialize, Object)
		end
	end
	
	for _, Module in SortTableByLoadOrder(ToInitialize) do
		Framework.InitializeClass(Module)
	end
	
	return Framework
end

function Framework.GetClass(Name : string)
	return Classes[Name] or warn(`class with name '{Name}' does not exist`)
end

function Framework.new(ClassName : string, ... : any)
	local Class = Framework.GetClass(ClassName)
	
	if Class == nil then
		return
	elseif Class.new == nil or typeof(Class.new) ~= "function" then
		return warn(`class with name '{ClassName}' does not have a valid constructor`)
	end

	return Class.new(...)
end

function Framework.MarkAsLoaded()
	IsLoaded = true
	
	local CurrentIndex : thread? = next(ThreadsWaitingOnLoaded)

	while CurrentIndex ~= nil do
		if coroutine.status(CurrentIndex) ~= "dead" then
			task.spawn(CurrentIndex)
		end

		ThreadsWaitingOnLoaded[CurrentIndex] = nil

		CurrentIndex = next(ThreadsWaitingOnLoaded)
	end
end

function Framework.WaitUntilLoaded() : typeof(Framework)
	if IsLoaded then
		return Framework
	end
	
	local CurrentThread = coroutine.running()

	ThreadsWaitingOnLoaded[CurrentThread] = true

	coroutine.yield(CurrentThread)

	return Framework
end

return Framework