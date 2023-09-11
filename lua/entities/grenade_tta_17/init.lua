AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")
include("cl_init.lua")

local phys, ef

function ENT:Initialize()

	game.AddParticles( "particles/heibullet_explosion.pcf" )
	PrecacheParticleSystem( "DirtFireballHit" )
	PrecacheParticleSystem( "Flashed" )
	PrecacheParticleSystem( "DirtDebrisShock" )
	
	self:CustomInitialize()
end
