--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local mazeSlice = require(ReplicatedStorage.Shared.ui.features.maze.state.mazeSlice)

local MazeServiceClient = {}

function MazeServiceClient.init(self: MazeServiceClient): ()
	self.networker = Networker.client.new("MazeService", self)

	mazeSlice.signals.generate:Connect(function()
		local width = mazeSlice.states.currentWidth()
		local height = mazeSlice.states.currentHeight()

		self:generate(width, height)
	end)

	mazeSlice.signals.cleanup:Connect(function()
		self:cleanup()
	end)
end

function MazeServiceClient.generate(self: MazeServiceClient, width: number, height: number): ()
	print(width, height)

	self.networker:fire("generate", width, height)
end

function MazeServiceClient.cleanup(self: MazeServiceClient): ()
	self.networker:fire("cleanup")
end

export type MazeServiceClient = typeof(MazeServiceClient) & {
	networker: Networker.Client,
}

return MazeServiceClient :: MazeServiceClient
