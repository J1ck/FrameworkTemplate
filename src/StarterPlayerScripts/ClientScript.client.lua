local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ServiceLoader = require(ReplicatedStorage:WaitForChild("ServiceLoader"))
	.InitializeClasses(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Classes"))
	.InitializeServices(ReplicatedStorage.Shared:WaitForChild("Services"))
	.InitializeClasses(ReplicatedStorage:WaitForChild("Client"):WaitForChild("Classes"))
	.InitializeServices(ReplicatedStorage.Client:WaitForChild("Services"))