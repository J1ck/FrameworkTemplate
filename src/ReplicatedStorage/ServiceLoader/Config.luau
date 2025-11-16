local LOAD_ORDER_ATTRIBUTE_NAME = "LoadOrder"
local IGNORE_DESCENDANTS_ATTRIBUTE_NAME = "IgnoreDescendants"

return {
	INITIALIZE_FUNCTION_NAME = "OnInitialized",
	IGNORE_ATTRIBUTE_NAME = "Ignore",
	IGNORE_DESCENDANTS_ATTRIBUTE_NAME = IGNORE_DESCENDANTS_ATTRIBUTE_NAME,
	LOAD_ORDER_ATTRIBUTE_NAME = LOAD_ORDER_ATTRIBUTE_NAME,
	DEFAULT_LOAD_ORDER = 1,
	STATIC_INSTANCE_ATTRIBUTES = {
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
}