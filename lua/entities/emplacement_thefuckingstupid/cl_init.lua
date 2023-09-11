include("shared.lua")

function ENT:Initialize()
	
	net.Receive( "DeathNotification" , function(len)
		if self:IsValid() then
		gmod.GetGamemode():AddDeathNotice( self:GetClass(), 0, nil, self:GetClass(), 0 )
		end
	end)
	
	net.Receive( "ShockwaveFunction", function( len )
		local Dist = net.ReadFloat()
			EmitSound( "main/explodeair0_"..math.random(1,4).."far.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist, 50, 0, 70)
			EmitSound( "main/explodeair0_"..math.random(1,4)..".wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^3, 50, 0, 70)
	end )

	self.Entity.Emitter = ParticleEmitter(self.Entity:GetPos())
	self.Entity.ParticleDelay = 0
end

function ENT:Draw()
	self.Entity:DrawModel()
end