local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.React)
local ReactRoblox = require(ReplicatedStorage.Packages.ReactRoblox)
local MazeServiceClient = require(ReplicatedStorage.Shared.services.MazeServiceClient)
local RootUI = require(ReplicatedStorage.Shared.ui.app.RootUI)
MazeServiceClient:init()

local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

local uiFolder = Instance.new("Folder")
uiFolder.Name = "ReactUI"
uiFolder.Parent = playerGui

local root = ReactRoblox.createRoot(uiFolder)
root:render(React.createElement(RootUI))
