local INITIALIZE_FUNCTION_NAME = "OnInitialized"
local IGNORE_ATTRIBUTE_NAME = "Ignore"
local IGNORE_DESCENDANTS_ATTRIBUTE_NAME = "IgnoreDescendants"
local LOAD_ORDER_ATTRIBUTE_NAME = "LoadOrder"
local DEFAULT_LOAD_ORDER = 1
local STATIC_INSTANCE_ATTRIBUTES = {
	{
		Path = {"ReplicatedStorage", "Client", "Services", "DataService"},
		Attributes = {
			[LOAD_ORDER_ATTRIBUTE_NAME] = -100
		}
	},
	{
		Path = {"ReplicatedStorage", "Shared", "Services", "NetworkService"},
		Attributes = {
			[IGNORE_DESCENDANTS_ATTRIBUTE_NAME] = true
		}
	},
	{
		Path = {"ServerScriptService", "Server", "Services", "DataService"},
		Attributes = {
			[IGNORE_DESCENDANTS_ATTRIBUTE_NAME] = true,
			[LOAD_ORDER_ATTRIBUTE_NAME] = -100
		}
	},
}
local UTIL_FUNCTIONS = {
	GetDictionaryLength = function(Dictionary : {[any] : any?}) : number
		local Amount = 0
		
		for _ in Dictionary do
			Amount += 1
		end
		
		return Amount
	end,
	DeepCopy = function<T>(Table : {[any] : any?} & T) : T
		-- stupid workaround because this scope doesnt have access to itself
		local function RecurseCopy<T>(v : {[any] : any?} & T) : T
			local Clone = table.clone(v)
		
			for Index, Value in Clone do
				if typeof(Value) == "table" then
					Clone[Index] = RecurseCopy(Value)
				end
			end
			
			return Clone
		end

		return RecurseCopy(Table)
	end,
}

local Services = {}
local Classes = {}

local ThreadsWaitingOnLoaded : {[thread] : any} = {}

local function SortTableByLoadOrder(Table : {ModuleScript}) : {ModuleScript}
	table.sort(Table, function(a, b)
		return
			(a:GetAttribute(LOAD_ORDER_ATTRIBUTE_NAME) or DEFAULT_LOAD_ORDER) <
			(b:GetAttribute(LOAD_ORDER_ATTRIBUTE_NAME) or DEFAULT_LOAD_ORDER)
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

for _, v in STATIC_INSTANCE_ATTRIBUTES do
	ApplyStaticAttributes(v)
end

local Framework = {}
Framework.Util = UTIL_FUNCTIONS

function Framework.InitializeService(Module : ModuleScript)
	if Module:GetAttribute(IGNORE_ATTRIBUTE_NAME) then
		return
	elseif Services[Module.Name] then
		return warn(`service with name '{Module.Name}' is already initialized`)
	end
	
	Services[Module.Name] = require(Module)
	
	if Services[Module.Name][INITIALIZE_FUNCTION_NAME] ~= nil then
		local Status, Returned = pcall(Services[Module.Name][INITIALIZE_FUNCTION_NAME], Framework)

		if Status == false then
			warn(`service with name '{Module.Name}' errored while initializing\n\n{Returned}\n\n`)
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
	
	SortTableByLoadOrder(ToRecurse)
	
	for _, Module in ToRecurse do
		Framework.InitializeService(Module)
	end
	
	for _, Object in ToRecurse do
		if Object:GetAttribute(IGNORE_DESCENDANTS_ATTRIBUTE_NAME) == true then
			continue
		end
		
		Framework.InitializeServices(Object)
	end
	
	return Framework
end

function Framework.GetService(Name : string)
	return Services[Name] or warn(`service with name '{Name}' does not exist`)
end

function Framework.InitializeClass(Module : ModuleScript)
	if Module:GetAttribute(IGNORE_ATTRIBUTE_NAME) then
		return
	elseif Classes[Module.Name] then
		return warn(`class with name '{Module.Name}' is already exists`)
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
	local CurrentThread = coroutine.running()

	ThreadsWaitingOnLoaded[CurrentThread] = true

	coroutine.yield(CurrentThread)

	return Framework
end

return Framework