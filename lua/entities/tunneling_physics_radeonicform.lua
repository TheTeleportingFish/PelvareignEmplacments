AddCSLuaFile()
ENT.Type = "anim"
ENT.PrintName = "Radeonic Form Mass"
ENT.Author = "NaN"
ENT.Information = "Not happy"
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.NonExistant = false

ENT.Category	= "Tunneling"
ENT.RunOffEffect = "fraise_explosion"

local Whole = Material( "effects/energy_swave_warp2" )
local Singularity = Material( "effects/fas_glow_debris" )

function ENT:SetupDataTables()
	self:NetworkVar( "Float", 0, "Charge" )
	self:NetworkVar( "Float", 1, "Radiation" )
	self:NetworkVar( "Float", 2, "Frequency" )
	self:NetworkVar( "Float", 3, "EnergyDensity" )
	self:NetworkVar( "Float", 4, "Pressure" )
	self:NetworkVar( "Float", 5, "Temperature" )
	self:NetworkVar( "Float", 6, "Capacity" )
	self:NetworkVar( "Float", 7, "Saturation" )
	
	self:NetworkVar( "String", 0, "Type" )
	
	self:NetworkVar( "Int", 0, "Particles" )
	self:NetworkVar( "Int", 1, "Formation" )
	
end

function ENT:Special_Ent_Dmg( Ent , FractionalCharge )
	if not Ent:IsValid() then return end
	local Velocity = self:GetVelocity()
	local Position = self:GetPos()
	local Ent_Class = Ent:GetClass()
	
	if Ent_Class == "npc_turret_floor" then
		Ent:Fire("SelfDestruct")
		ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, Ent, -1 )
		ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Ent, -1 )
		
	elseif Ent_Class == "npc_strider" then
		
		Ent:SetSaveValue( "m_bExploding", true )
		local d = DamageInfo()
		d:SetDamage( Ent:Health() )
		d:SetAttacker( Ent )
		d:SetInflictor( Ent )
		d:SetDamageType( DMG_GENERIC )
		Ent:TakeDamageInfo( d )
		
		ParticleEffect( "small_caliber_heat_shrapnel", Ent:GetPos(), (Velocity:GetNormalized()-VectorRand()/math.random(2,5)):Angle() )
		ParticleEffect( "small_caliber_fragmentation_shrapnel", Ent:GetPos(), VectorRand():Angle() )
		ParticleEffect( "object_vaporize_shrapnel_large", Ent:GetPos(), Angle() )
		return true
		
	elseif Ent_Class == "npc_helicopter" then
		local Size = 12*52.4934
		local effectdata = EffectData()
		local d = DamageInfo()
		d:SetDamage( FractionalCharge )
		d:SetAttacker( self )
		d:SetInflictor( self )
		d:SetDamageType( DMG_AIRBOAT )
		Ent:TakeDamageInfo( d )
		
		util.BlastDamage( self, self, Position, Size, Velocity:Length()^0.5 )
		
		ParticleEffect( "small_caliber_fragmentation_smoke", Ent:WorldSpaceCenter(), (Velocity:GetNormalized()-VectorRand()/math.random(2,5)):Angle() )
		ParticleEffect( "object_vaporize_shrapnel_large", Ent:WorldSpaceCenter(), Angle() )
		
	end
	
	return false --Return true to indicate special damage effects only, false for normal
	
end

function Annhilation( ent )
	local self = ent
	local Position = self:WorldSpaceCenter()
	if ( self.NonExistant ) then return end
	
	self.NonExistant = true
	
	if SERVER then
		local DetonationWaveRadius = (math.random(121,230) * 52.4934)
		local FractionalCharge = math.random( 8.8953e+6 , 9.35e+19 )
		
		if IsValid( self ) then
			for k, Obj in pairs( ents.FindInSphere( Position , DetonationWaveRadius/6 ) ) do
				if ( Obj ~= self ) and IsValid( Obj ) then
					local Obj_Phys = Obj:GetPhysicsObject()
					local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( Position ) / DetonationWaveRadius ) )
					local Obj_Force_Velocity = ( ( Obj:WorldSpaceCenter() - Position ):GetNormalized() * (math.random(47,50) * 52.4934) ) * Dist
					local DMGInfor = DamageInfo()
					
					self:Special_Ent_Dmg( Obj , FractionalCharge )
					
					DMGInfor:SetInflictor( self )
					DMGInfor:GetAttacker( self )
					DMGInfor:SetDamage( FractionalCharge )
					DMGInfor:SetDamageType( DMG_RADIATION )
					Obj:TakeDamage( FractionalCharge , self , self )
					
					DMGInfor:SetInflictor( self )
					DMGInfor:GetAttacker( self )
					DMGInfor:SetDamage( FractionalCharge )
					DMGInfor:SetDamageType( DMG_DISSOLVE )
					Obj:TakeDamage( FractionalCharge/3 , self , self )
					
					Obj:Ignite( 30, 50 )
					ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Obj, -1 )
					
					if IsValid(Obj_Phys) then Obj_Phys:AddVelocity( Obj_Force_Velocity ) else Obj:SetVelocity( Obj_Force_Velocity ) end
				end
			end
			
			
			
			timer.Simple( 0 , function()
				if IsValid(self) then
					
					ParticleEffect( "condensed_kiloton_nuclear_detonation" ,self:GetPos() + VectorRand() * (6 * 52.4934),Angle(0,0,0),nil)
					
					for k, Obj in pairs( ents.FindInSphere( self:WorldSpaceCenter() , DetonationWaveRadius ) ) do
						if ( Obj ~= self ) and IsValid( Obj ) then
							local Obj_Phys = Obj:GetPhysicsObject()
							local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( self:WorldSpaceCenter() ) / DetonationWaveRadius ) )
							local Obj_Force_Velocity = ( ( Obj:WorldSpaceCenter() - Position ):GetNormalized() * (math.random(190,200) * 52.4934) ) * Dist
							local DMG = DamageInfo()
							
							self:Special_Ent_Dmg( Obj , FractionalCharge )
							
							DMG:SetInflictor( self )
							DMG:GetAttacker( self )
							DMG:SetDamage( FractionalCharge/50 )
							DMG:SetDamageType( DMG_BLAST )
							
							constraint.RemoveAll( Obj )
							Obj:Fire("EnableMotion")
							
							ParticleEffectAttach( "object_vaporize_shrapnel", PATTACH_ABSORIGIN_FOLLOW, Ent, -1 )
							ParticleEffectAttach( "object_vaporize_vapor", PATTACH_ABSORIGIN_FOLLOW, Obj, -1 )
							
							Obj:TakeDamage( FractionalCharge * Dist , self , self )
							if IsValid(Obj_Phys) then Obj_Phys:AddVelocity( Obj_Force_Velocity ) else Obj:SetVelocity( Obj_Force_Velocity ) end
						end
					end
					
					self:Remove()
				end
			end)
			
		end
		
	elseif CLIENT then
		sound.Play( "high_energy_systems/2megaton_nuclear_detonation_"..math.random(1,3)..".mp3", self:WorldSpaceCenter() , 0, math.random(70,80), 1 )
		
		sound.Play( "tunneling_physics/conjunction_organic.mp3", self:WorldSpaceCenter() , 0, math.random(90,100), 1 ) 
		sound.Play( "central_base_material/cbmarmor_explosivedeform_"..math.random(1,3)..".mp3", self:WorldSpaceCenter() , 140, math.random(180,190), 0.2 ) 
		sound.Play( "tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3", self:WorldSpaceCenter() , 0, math.random(20,30), 1 )
		sound.Play( "tunneling_physics/radeonic_distresipution_wave_"..math.random(1,7)..".mp3", self:WorldSpaceCenter() , 0, math.random(230,255), 0.7 )
		
	end
	
end

function RunOff( ent )
	local self = ent or nil
	local Position = self:WorldSpaceCenter()
	if ( self.NonExistant ) then return end
	
	self.NonExistant = true
	
	if CLIENT then
		if IsValid(self.Emitter) then
			self.Emitter:Finish()
		end
		
		self:StopParticles()
		ParticleEffect(self.RunOffEffect,Position,Angle(0,0,0),nil) 
		sound.Play( "main/closeradeonicwave.wav", Position , 130, math.random(25,90), 1 ) 
		sound.Play( "tunneling_physics/caplier_faucation.wav", LocalPlayer():GetPos() , 90, math.random(70,130), 1 )
		util.ScreenShake( self:GetPos(), 11, 0.1, 1, 1000 )
		
		self.Burning = nil
		self.HighBurn = nil
		
	elseif SERVER then
		
		local Max = math.Clamp( self:GetSaturation()/self:GetPressure() , 0.5, 3 )
		local DetonationWaveRadius = (math.random(10,38) * 52.4934) * Max
		local FractionalCharge = math.random( 6000 , 3905000 ) * Max
		
		for k, Obj in pairs( ents.FindInSphere( Position , DetonationWaveRadius ) ) do
			if ( Obj ~= self ) and ( Obj:Health() != nil ) then
				if ( IsValid( Obj ) ) then 
					local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( Position ) / DetonationWaveRadius ) )
					local DMGInfor = DamageInfo()
			
					DMGInfor:SetInflictor( self )
					DMGInfor:GetAttacker( self )
					DMGInfor:SetDamage( FractionalCharge )
					DMGInfor:SetDamageType( DMG_RADIATION )
					
					Obj:TakeDamage( FractionalCharge , self , self )
					Obj:SetVelocity( ( ( Obj:WorldSpaceCenter() - Position ):GetNormalized() * Dist ) * math.random(-self:GetPressure(),-self:GetPressure()/20) )
				end
			end
		end
		if Max > 2.5 then
			for i=1, math.random( 1,10 ) do
				
				local ent = ents.Create("tunneling_physics_fieldparticle")
				
				ent:SetPos( self:GetPos() + VectorRand() * 25  ) 
				ent:Spawn()
				ent:Activate()
				
				local Phys = ent:GetPhysicsObject()
				if IsValid( Phys ) then
					Phys:SetVelocity( VectorRand() * math.random(-self:GetPressure(),-self:GetPressure()/20) )
				end
				
			end
		end
		
	end
end

function ENT:Initialize()
	
	if SERVER then
		self:SetModel("models/dav0r/hoverball.mdl")
		self:SetMaterial("models/debug/debugwhite")
		self:SetColor( Color( 0 , 0 , 0 ) )
		self:SetModelScale( 2 , 0.1 )
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
		self.Burning:SetSoundLevel( 0 )
		self.HighBurn = CreateSound( self, "main/electromagneticradeonicpropulsion.wav" )
		self.HighBurn:SetSoundLevel( 0 )
		
	end
	
	local SetSatur = math.random( 500 , 1800 )
	local SetTemp = math.random( SetSatur , 29000 )
	
	self.Radeonic = self
	
	self:SetParticles( 1 )
	self:SetFormation( 0 )
	
	self:SetType( "Typical" )
	self:SetCharge( math.huge )
	self:SetRadiation( 9 )
	self:SetFrequency( 1e+9 )
	self:SetPressure( 1000 )
	
	self:SetSaturation( SetSatur )
	self:SetTemperature( SetTemp )
	
	self:SetCapacity( 1e+12 )
	
	self:SetEnergyDensity( (self:GetPressure() * self:GetFrequency()) / self:GetTemperature() )
	
	Annhilation(self)
	
end

function ENT:Draw()
	if ( self.NonExistant ) then return end
	local Pos , ViewPos, Pressure = self:LocalToWorld(self:OBBCenter()) , EyePos(), self:GetPressure()
	
	for i=1, 6 do
		render.SetMaterial(Whole)
		render.DrawSprite( Pos , (Pressure/10) , (Pressure/10) , color_white )
		render.SetMaterial(Singularity)
		render.DrawSprite( Pos , (Pressure/500)*i , (Pressure/500)*i , Color( 255 , math.random(0,60) , math.random(0,190) ) )
	end
	
	render.SetMaterial(Whole)
	render.DrawSprite( Pos , Pressure/150 , Pressure/150 , color_white )
	render.SetMaterial(Singularity)
	render.DrawSprite( Pos , Pressure/10 , Pressure/10 , Color( 255 , math.random(0,60) , math.random(0,190) ) )
	render.SetMaterial(Singularity)
	render.DrawSprite( Pos , Pressure/300 , Pressure/300 , Color( 255 , 195 , 195 ) )
	
	local ExploseSize = ((1-(Pressure/1000))^120) * 2500
	render.SetMaterial(Whole)
	render.DrawSprite( Pos , ExploseSize , ExploseSize , Color( 255 , 255 , 255 ) )
	render.SetMaterial(Singularity)
	render.DrawSprite( Pos , ExploseSize*5 , ExploseSize*5 , Color( 0 , 0 , 0 ) )
	
end


--lua_run for i=1, 10 do RunConsoleCommand( "ent_create" , "tunneling_physics_radeonicform" ) end
--ent_create tunneling_physics_radeonicform

function ENT:Think()
	if ( self.NonExistant ) then return end
	local SelfPhys = self:GetPhysicsObject()
	
	if SERVER then
		
		SelfPhys:AddVelocity( -(SelfPhys:GetVelocity()*0.025) + (VectorRand() * math.random(0.1,math.random(0.5,60))) )
		
		for k, Obj in pairs( ents.FindInSphere( self:WorldSpaceCenter() , (160 * 52.4934) ) ) do
			if ( Obj ~= self ) and ( IsValid(Obj) and IsValid(self) ) then
				local Phys = Obj:GetPhysicsObject()
				local Dist = ( 1 - ( Obj:WorldSpaceCenter():Distance( self:WorldSpaceCenter() ) / (160 * 52.4934) ) )
				if Obj.Radeonic then
					if IsValid(Phys) then Phys:AddVelocity( ( ( Obj:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * (Dist^2) ) * -self:GetSaturation() / self:GetPressure() ) end
					self:SetPressure( self:GetPressure() + math.Clamp( (Obj:GetNWFloat( "Pressure" )/self:GetTemperature()) , 0 , 15 )  )
				else
					Obj:SetVelocity( ( ( Obj:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * (Dist^220) ) * -math.random(3,12200) )
					if IsValid(Phys) then Phys:AddVelocity( ( ( Obj:WorldSpaceCenter() - self:WorldSpaceCenter() ):GetNormalized() * (Dist^33) ) * -math.random(35,100) ) end
				end
			end
		end
		
		if self:GetPressure() > self:GetTemperature() then self:Remove() return end
		
		self:SetPressure( self:GetPressure() - 2 )
		self:SetRadiation( self:GetPressure() / 100 )
		
		self:SetEnergyDensity( (self:GetPressure() * self:GetFrequency()) / self:GetTemperature() )
		
	elseif CLIENT then
		
		if IsValid(self) then
			self.Burning:Play()
			self.HighBurn:Play()
			
			local Pitch = ( 2 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934) * 200 ) + 10
			self.Burning:ChangePitch( Pitch )
			self.Burning:ChangeVolume( (50 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
			
			self.HighBurn:ChangePitch( (Pitch/3) + 25 )
			self.HighBurn:ChangeVolume( (100 / (self:GetPos():Distance(LocalPlayer():GetPos()) / 52.4934)) )
		else
			if self.Burning:IsPlaying() then self.Burning:Stop() end
			if self.HighBurn:IsPlaying() then self.HighBurn:Stop() end
			
		end
		
		if IsValid( self.Emitter ) and IsValid( self ) then
			local SpawnPos = self:GetPos() + (VectorRand() * math.random(5,15))
			local part = self.Emitter:Add( Singularity , SpawnPos )
			part:SetStartSize( math.random(0.5,6) )
			part:SetEndSize(0)
			part:SetStartAlpha(255)
			part:SetEndAlpha(0)
			part:SetDieTime(math.random(0, 12))
			part:SetRoll( math.random(0, 360) )
			part:SetRollDelta(0.01)
			part:SetColor( math.random(0,390) , math.random(30,160) , math.random(0,290) )
			part:SetLighting(false)
			part:SetVelocity( (SpawnPos - self:GetPos()):GetNormalized() * math.random(5,50) * (self:GetPressure()/100) )
			
			part:SetNextThink( CurTime() ) -- Makes sure the think hook is used on all particles of the particle emitter
			part:SetThinkFunction( function( Particle )
				if IsValid(self) then
					Particle:SetVelocity( Particle:GetVelocity() + ( self:GetPos() - Particle:GetPos() ) * 0.1 )	
					Particle:SetColor( math.random(0,390) , math.random(30,160) , math.random(0,290) ) -- Randomize it
					Particle:SetNextThink( CurTime() ) -- Makes sure the think hook is actually ran.
				end
			end )
			
		end
		
	end
	
	if self:GetPressure() < self:GetSaturation() then
		local Max = math.Clamp( self:GetSaturation()/self:GetPressure() , 1, 5 )
		for i=1, math.random( 1 , Max ) do
			local tr = util.TraceLine( {
				start = self:GetPos(),
				endpos = self:GetPos() + (VectorRand() * 500000),
				filter = self
			} )
			
			local HitEnt = tr.Entity
			
			if SERVER then
				
				if IsValid(HitEnt) then
					local RadiationInfo = DamageInfo()
					local FractionalCharge = math.random( 8.8953e+6 , 9.35e+11 ) / self:GetPos():DistToSqr( HitEnt:GetPos() )
					RadiationInfo:SetInflictor( self )
					RadiationInfo:GetAttacker( self )
					RadiationInfo:SetDamage( FractionalCharge )
					RadiationInfo:SetDamageType( DMG_RADIATION )
					--print( FractionalCharge, HitEnt)
					HitEnt:TakeDamage( FractionalCharge , self , self )
				end
				
			elseif CLIENT then
				local Pos = self:GetPos()
				local Radiation = math.Clamp( self:GetRadiation() , 0 , 25 )
				local Emitter = ParticleEmitter( Pos )
				local Length = (math.random(0.1,0.5) * 52.49)
				local Amt = Length / Radiation
				if IsValid(Emitter) then
					
					for i = 1, math.Round(Amt) do
						local part = Emitter:Add( "particle/smokesprites_0003" , Pos + ( tr.Normal * Length ) + ( tr.Normal * (( i/Amt ) * Length) ) )
						local LocalizedColor = math.random(220, 250)
						part:SetStartSize( 10 / ( i ^ 0.5 ) )
						part:SetEndSize( 0 )
						part:SetStartAlpha( 45 )
						part:SetEndAlpha( 0 )
						part:SetDieTime( 0.3 )
						part:SetRoll( math.random(-360, 360) )
						part:SetRollDelta( 0.1 )
						part:SetColor(LocalizedColor,LocalizedColor,LocalizedColor)
						part:SetLighting(false)
						part:SetVelocity( ( tr.Normal + (VectorRand()/5) ) * 52.49 * math.random( 1 , 3 ) )
						if i == Amt then Emitter:Finish() end
					end
				end
				
			end
		end
	end
	
	if self:GetPressure() <= 0 then
		if SERVER then self:StopParticles() end
		Annhilation( self )
		return
	end
	
	self:NextThink( CurTime() + 0.1 )
	return true
end 


function ENT:OnRemove()
	RunOff( self )
end
