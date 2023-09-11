AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Field Particle"
ENT.Author = "NaN"
ENT.Information = "Not happy"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.NonExistant = false

ENT.Category	= "Tunneling"

ENT.AnnihilationEffect = {"h_nuke_airburst","h_nuke2_airburst","h_nuke3_airburst"}
ENT.RunOffEffect = "h_grenade_main"

game.AddParticles( "particles/h_grenade.pcf")

game.AddParticles( "particles/h-nuke.pcf")
game.AddParticles( "particles/h-nuke2.pcf")
game.AddParticles( "particles/h-nuke3.pcf")

game.AddParticles( "particles/hnuke3.pcf")
game.AddParticles( "particles/hnuke2.pcf")
game.AddParticles( "particles/hnuke1.pcf")

local Whole = Material( "effects/energy_swave_warp2" )
local Singularity = Material( "effects/fas_glow_debris" )

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "Generation_Flux" )
	self:NetworkVar( "Float", 1, "Persistence" )
	self:NetworkVar( "Float", 2, "Frequency" )
	self:NetworkVar( "Float", 3, "Capacity" )
	self:NetworkVar( "Float", 4, "Charge" )
	self:NetworkVar( "Float", 5, "Velocity" )
	self:NetworkVar( "Float", 6, "Displacement" )
	self:NetworkVar( "Float", 7, "Saturation" )
	
	self:NetworkVar( "String", 0, "Type" )
	
	self:NetworkVar( "Int", 1, "Formation" )
	
end

function Diffusion( ent )
	local self = ent or nil
	local Position = self:WorldSpaceCenter()
	if ( self.NonExistant ) then return end
	if ( !IsValid( self ) ) then return end
	
	self.NonExistant = true
	
	if SERVER then
		local DetonationWaveRadius = (math.random(2,5) * 52.4934)
		local FractionalCharge = math.random( 12 , 190 )
		
		if IsValid( self ) then
			for k, Obj in pairs( ents.FindInSphere( self:WorldSpaceCenter() , DetonationWaveRadius ) ) do
				if ( Obj ~= self ) and IsValid( Obj ) then
					local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( self:WorldSpaceCenter() ) / DetonationWaveRadius ) )
					local DMG = DamageInfo()
					
					DMG:SetInflictor( self )
					DMG:GetAttacker( self )
					DMG:SetDamage( FractionalCharge )
					DMG:SetDamageType( DMG_BLAST )
					
					Obj:TakeDamage( FractionalCharge * Dist , self , self )
					Obj:SetVelocity( ( ( Obj:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * Dist ) * math.random(-10,-2) )
				end
			end
		end
		
		for i = 1, 5 do
			ParticleEffect( "Flashed", self:GetPos() , Angle(0,0,0) )
		end
		
		ParticleEffect( "ShockWave", self:GetPos() , Angle(0,0,0))
		self:Remove()
		
	elseif CLIENT then
		sound.Play( "main/bouncehit.wav", self:WorldSpaceCenter() , 130, math.random(135,140), 1 )
		
		sound.Play( "tunneling_physics/conjunction_organic.mp3", self:WorldSpaceCenter() , 0, math.random(90,100), 1 ) 
		
	end
	
end

function ENT:RunOff()
	local Position = self:WorldSpaceCenter()
	if ( self.NonExistant ) then return end
	if ( !IsValid( self ) ) then return end
	
	self.NonExistant = true
	
	if SERVER then
		
		ParticleEffect( "ShockWave", self:GetPos() , Angle(0,0,0))
		util.ScreenShake( self:GetPos(), 11, 0.1, 0.1, 1000 )
		
	elseif CLIENT then
		if IsValid(self.Emitter) then
			self.Emitter:Finish()
		end
		
		self:StopParticles()
		sound.Play( "main/caplier_faucation.wav", LocalPlayer():GetPos() , 90, math.random(30,45), 1 )
		
		self.Burning:Stop()
		self.HighBurn:Stop()
		
	end
end

function ENT:Initialize()
	
	if SERVER then
		self:SetModel("models/dav0r/hoverball.mdl")
		self:SetMaterial("models/debug/debugwhite")
		self:SetColor( Color( 0 , 0 , 0 ) )
		self:SetModelScale( 1 , 0.1 )
		self:SetMoveType( MOVETYPE_CUSTOM )	
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetSolid( SOLID_NONE )
		self:DrawShadow(false)
		
		self:SetCollisionGroup( COLLISION_GROUP_WORLD )
		self:SetMoveCollide( MOVECOLLIDE_FLY_SLIDE )
		
		spd = physenv.GetPerformanceSettings()
		spd.MaxVelocity = math.huge
		
		physenv.SetPerformanceSettings(spd)
		
		self:PhysWake()
		self:GetPhysicsObject():EnableGravity( false )
	elseif CLIENT then
		
		if IsValid(self) then
			self.Emitter = ParticleEmitter(self:GetPos())
			self.ParticleDelay = 0
		end
		
		self.Burning = CreateSound( self, "tunneling_physics/radeonic_flow.wav" )
		self.Burning:SetSoundLevel( 120 )
		self.HighBurn = CreateSound( self, "tunneling_physics/bakronic_formatic_exhale.mp3" )
		self.HighBurn:SetSoundLevel( 120 )
		
	end
	
	PrecacheParticleSystem( "Flashed" )
	PrecacheParticleSystem( "ShockWave" )
	
	local SetSatur = math.random( 500 , 1800 )
	
	self.FieldParticle = self
	
	self:SetFormation( 7 )
	
	self:SetType( "Typical" )
	self:SetCharge( math.huge )
	self:SetFrequency( math.huge )
	self:SetPersistence( 100 )
	
	self:SetSaturation( SetSatur )
	
	self:SetCapacity( math.huge )
	
end

function ENT:Draw()
	if ( self.NonExistant ) then return end
	local Pos , ViewPos, Persistence = self:LocalToWorld(self:OBBCenter()) , EyePos(), self:GetPersistence()
	
	local ExploseSize = ((1-(Persistence/100))^12) * 60
	render.SetMaterial(Singularity)
	render.DrawSprite( Pos , ExploseSize , ExploseSize , Color( 255 , 190 , 255 ) )
	
	render.SetMaterial(Singularity)
	render.DrawSprite( Pos , Persistence/30 , Persistence/30 , Color( 255 , 0 , 0 ) )
	
end


--lua_run for i=1, 10 do RunConsoleCommand( "ent_create" , "tunneling_physics_fieldparticle" ) end
--ent_create tunneling_physics_fieldparticle

function ENT:Think()
	if ( self.NonExistant ) then return end
	local SelfPhys = self:GetPhysicsObject()
	
	if SERVER then
		
		SelfPhys:AddVelocity( -(SelfPhys:GetVelocity()*0.001) + (VectorRand() * math.random(-1,1)) )
		
		for k, Obj in pairs( ents.FindInSphere( self:WorldSpaceCenter() , (160 * 52.4934) ) ) do
			if ( Obj ~= self ) and ( IsValid(Obj) and IsValid(self) ) then
				local Phys = Obj:GetPhysicsObject()
				local RealDist = Obj:WorldSpaceCenter():Distance( self:WorldSpaceCenter() )
				local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( self:WorldSpaceCenter() ) / (160 * 52.4934) ) )
				if Obj.FieldParticle then 
					if IsValid(Phys) then Phys:AddVelocity( ( ( Obj:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * (Dist^1.5) ) * -self:GetPersistence() ) end
					self:SetPersistence( self:GetPersistence() + math.Clamp( (Obj:GetPersistence()/self:GetSaturation()) , 0 , 15 ) )
					if RealDist <= 1 then 
						if IsValid(self) then 
							local Pos = self:GetPos()
							
							local Particled = ents.Create( "tunneling_physics_fieldparticle" )
							if ( not Particled:IsValid() ) then return end
							
							Particled:SetPersistence( self:GetPersistence() - Obj:GetPersistence() )
							Particled:SetSaturation( self:GetSaturation() + Obj:GetSaturation() )
							Particled:SetPos( Pos )
							
							SafeRemoveEntity( Obj )
							SafeRemoveEntity( self )
														
							Particled:Spawn()
						end
					end
				else
					Obj:SetVelocity( ( ( self:GetVelocity() ):GetNormalized() * (Dist^66) ) * -math.random(1,30) )
					if IsValid(Phys) then Phys:AddVelocity( ( ( self:GetVelocity() ):GetNormalized() * (Dist^66) ) * -math.random(1,30) ) end
				end
			end
		end
		
		if self:GetPersistence() > self:GetSaturation() then self:Remove() return end
		
		self:SetPersistence( self:GetPersistence() - 2 )
		self:SetSaturation( math.Clamp( self:GetSaturation() + 5 , 0 , self:GetPersistence()^2 ) )
		
	elseif CLIENT then
		
		if IsValid(self) then
			self.Burning:Play()
			self.HighBurn:Play()
			
			local Pitch = ( 55 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934) * 20 ) + 10
			self.Burning:ChangePitch( Pitch )
			self.Burning:ChangeVolume( (15 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			
			self.HighBurn:ChangePitch( 100 )
			self.HighBurn:ChangeVolume( (55 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
		else
			self.Burning:Stop()
			self.HighBurn:Stop()
			
		end
		
		if IsValid( self.Emitter ) and IsValid( self ) then
			local SpawnPos = self:GetPos() + (VectorRand() * math.random(5,35))
			local part = self.Emitter:Add( Singularity , SpawnPos )
			part:SetStartSize( math.random(5,math.random(6,180)) / self:GetPersistence() )
			part:SetEndSize(0)
			part:SetStartAlpha(255)
			part:SetEndAlpha(0)
			part:SetDieTime(math.random(0, 0.1))
			part:SetRoll( math.random(0, 360) )
			part:SetRollDelta(0.01)
			part:SetColor( 255 , 0 , 0 )
			part:SetLighting(false)
			part:SetVelocity( (SpawnPos - self:GetPos()):GetNormalized() * math.random(5,50) * (self:GetPersistence()/100) )
			
			part:SetNextThink( CurTime() ) -- Makes sure the think hook is used on all particles of the particle emitter
			part:SetThinkFunction( function( Particle )
				if IsValid(self) then
					Particle:SetVelocity( Particle:GetVelocity() + ( self:GetPos() - Particle:GetPos() ) * 0.1 )	
					Particle:SetColor( 255 , 240 , math.random(10,255) ) -- Randomize it
					Particle:SetNextThink( CurTime() ) -- Makes sure the think hook is actually ran.
				end
			end )
			
		end
		
	end
	
	if self:GetPersistence() < self:GetSaturation() then
		
		
		
	end
	
	if self:GetPersistence() <= 0 then
		if SERVER then self:StopParticles() end
		Diffusion( self )
		return
	end
	
	self:NextThink( CurTime() + 0.1 )
	return true
end 


function ENT:OnRemove()
	self:RunOff()
end
