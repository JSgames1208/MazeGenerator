--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Networker = require(ReplicatedStorage.Packages.Networker)
local MazeGenerator = require(ReplicatedStorage.Shared.modules.MazeGenerator)

local MazeServiceServer = {}

function MazeServiceServer.init(self: MazeServiceServer): ()
	self.networker = Networker.server.new("MazeService", self, {
		self.generate :: any,
		self.cleanup :: any,
	})
end

function MazeServiceServer.generate(self: MazeServiceServer, player: Player, width: number, height: number): ()
	MazeGenerator.generate(width, height)
end

function MazeServiceServer.cleanup(self: MazeServiceServer): ()
	MazeGenerator.cleanup()
end

export type MazeServiceServer = typeof(MazeServiceServer) & {
	networker: Networker.Server,
}

return MazeServiceServer :: MazeServiceServer
