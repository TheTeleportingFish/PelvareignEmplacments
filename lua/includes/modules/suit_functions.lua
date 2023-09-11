AddCSLuaFile()

if SERVER then
	
	util.AddNetworkString( "Radeonic_Grapple_Effect_Extra" )
	util.AddNetworkString( "Weapon_Change_RoundType" )
	
	util.AddNetworkString( "Radeonic_Grapple_Effect_Far" )
	
	util.AddNetworkString( "Radeonic_Range_Blip" )
	
	util.AddNetworkString( "Suit_AddTo_PseudoTeam" )
	util.AddNetworkString( "Suit_Alert_PseudoTeam" )
	
	util.AddNetworkString( "Suit_PseudoTeam_Recieve_UnitVars" )
	
	util.AddNetworkString( "AHEE_System_Alert_Receive" )
	
end

net.Receive( "Radeonic_Range_Blip", function( len, ply )
	if CLIENT then
		local plr =  LocalPlayer()
		local ContinationWave = net.ReadFloat()
		local Sound_String = net.ReadString()
		local Dist = ( 1 - net.ReadFloat() ) or 0
		if ContinationWave == nil then return end
		
		local Sys_Tack = plr.System_Tacks 
		if Sys_Tack == nil then return end 
		local Radeonic_Tack = Sys_Tack.Radeonic_Tack
		
		if Radeonic_Tack.System_Internal_Switch then
			timer.Simple( ContinationWave , function() 
				EmitSound(Sound_String , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 0 , 0 , math.random(90,110) )
			end)
			
		end
		
	end
end)

net.Receive( "Radeonic_Grapple_Effect_Far", function( len, ply )
	
	local plr =  LocalPlayer() or ply
	local ContinationWave = net.ReadFloat()
	local Dist = ( 1 - net.ReadFloat() ) or 0
	if ContinationWave == nil then return end
	
	timer.Simple( ContinationWave , function() 
		EmitSound("ahee_suit/radeonicgrapple/radeonicgrapple_beam_launch_far.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist^3,0,1) , 60 , 0 , math.random(85,105) )
	end)
	
	EmitSound("ahee_suit/radeonicgrapple/radeonicgrapple_pull_blip_far.mp3" , Vector() , -1 , CHAN_AUTO , math.Clamp(Dist,0,1) , 60 , 0 , math.random(90,105) )
	
end)

function FindRealGunPos( self )
	local PlayerBounds_Min, PlayerBounds_Max = self:GetHitBoxBounds(0,0)
	PlayerBounds_Min = PlayerBounds_Min or Vector()
	PlayerBounds_Max = PlayerBounds_Max or Vector()
	
	return self:WorldSpaceCenter() + (PlayerBounds_Max * Vector(0,0,4))
end

function SetRadeonicGrappleHook( self , Boolean )
	if not IsValid( self ) then return end
	if not self.RadeonicGrapplePack then return end
	local Boolean = Boolean or false
	
	if not Boolean then
		self.RadeonHookHitTarget = nil
		self.RadeonHookHitPos = nil
		AnglePulling = false
	end
	
	GrappleStabilityKnock( self , Boolean )
	
	self.RadeonicGrapplePack.Hooking = Boolean
end

function SetRadeonicGrappleDistance( self , Distance )
	if not IsValid( self ) then return end
	if self.RadeonicGrapplePack == nil then return end
	
	local Distance = Distance or 50
	
	self.RadeonicGrapplePack.RangeOrder = Distance
end

function Create_Grapple_Pos( self )
	if not IsValid( self ) then return end
	
	local GrapplePack = self.RadeonicGrapplePack
	local RadeonicHooking = GrapplePack.Hooking
	local RadeonicDistance = GrapplePack.RangeOrder * 52.4934
	
	local RealGunPos = FindRealGunPos( self )
	local PositionTrace = {}
	PositionTrace.start = RealGunPos
	PositionTrace.endpos = PositionTrace.start + self:EyeAngles():Forward() * RadeonicDistance
	PositionTrace.filter = self
	
	local CorrectTrace = util.TraceLine(PositionTrace)
	self.RadeonHookHitTarget = CorrectTrace.Entity
	
	if IsValid(self.RadeonHookHitTarget) then
		self.RadeonHookHitPos = self.RadeonHookHitTarget:WorldSpaceCenter()
	else
		self.RadeonHookHitPos = CorrectTrace.HitPos or self:WorldSpaceCenter()
	end
	
	Orig_PullDist = self.RadeonHookHitPos:Distance(self:GetPos())
	
end

function Interest_Pos_Change( self )
	if not IsValid( self ) then return end
	
	local Trace = util.TraceLine( {
		start = self:EyePos(),
		endpos = self:EyePos() + self:GetAimVector() * 1000000,
		filter = self
	} )
	
	self.InternalInterest_Pos = Trace.HitPos
	
end

function Target_PowerMains_Change( self )
	if not IsValid( self ) then return end
	local Target_Mains = self.Targeting_Mains
	
	self.Targeting_Mains.Target_PowerMains = !Target_Mains.Target_PowerMains
	
end

function GetArmAngle( self )
	if not IsValid( self ) then return end
	if self.RadeonHookHitPos==nil then
		return 0 
	end
	
	local RealGunPos = FindRealGunPos( self )
	local ArmVector = (self.RadeonHookHitPos - RealGunPos):GetNormalized() 
	local AngleBetween = math.deg(math.acos(self:GetAimVector():Dot(ArmVector) / (self:GetAimVector():Length() * ArmVector:Length())))
	
	return AngleBetween
end

function CheckArmAngleValid( self )
	
	if not IsValid( self ) then return end
	if not self.RadeonHookHitPos then return false end
	
	local RealGunPos = FindRealGunPos( self )
	local ArmVector = (self.RadeonHookHitPos - RealGunPos):GetNormalized() 
	
	local GrapplePack = self.RadeonicGrapplePack
	local RadeonicHooking = GrapplePack.Hooking
	local RadeonicDistance = GrapplePack.RangeOrder * 52.4934
	
	local DegreeLimit = 90
	local RadeonicGrappleTrace = {}
	RadeonicGrappleTrace.start = RealGunPos
	RadeonicGrappleTrace.endpos = RadeonicGrappleTrace.start + (ArmVector * math.Clamp( RealGunPos:Distance(self.RadeonHookHitPos) , 0 , RadeonicDistance ))
	RadeonicGrappleTrace.filter = self
	local RadeonicGrappleTraceLine= util.TraceLine(RadeonicGrappleTrace)
	
	local AngleBetween = GetArmAngle( self )
	local AngledTooMuched = AngleBetween > DegreeLimit
	
	local Reachable = not RadeonicGrappleTraceLine.HitWorld or (RadeonicGrappleTraceLine.HitPos:Distance(self.RadeonHookHitPos) < 500)
	local TooFar = self.RadeonHookHitPos:Distance(RealGunPos) > RadeonicDistance
	
	return (Reachable and not AngledTooMuched)
end

function CanAttachRadeonicGrapple( self )
	if not IsValid( self ) then return end
	
	local GrapplePack = self.RadeonicGrapplePack
	local RadeonicHooking = GrapplePack.Hooking
	
	if GrapplePack.BufferEnergy <= 0 or GrapplePack.Stability <= 30 then
		SetRadeonicGrappleHook( self , false )
		return false
	end
	
	if RadeonicHooking and not CheckArmAngleValid( self ) then
		SetRadeonicGrappleHook( self , false )
		return false
	end
	
	return true
end

function LaunchGrapple( self )
	
	local GrapplePack = self.RadeonicGrapplePack
	if GrapplePack.BufferEnergy <= 0 or GrapplePack.Stability <= 35 then
		return
	end
	
	local TargetID = IsValid( self.RadeonHookHitTarget ) and ( self.RadeonHookHitTarget ):EntIndex() or -1
	local effectdata = EffectData()
	effectdata:SetOrigin( self.RadeonHookHitPos )
	effectdata:SetStart( self.RadeonHookHitPos )
	effectdata:SetEntity( self )
	effectdata:SetMaterialIndex( TargetID )
	effectdata:SetMagnitude( 32 )
	effectdata:SetScale( GrapplePack.Stability*2 )
	effectdata:SetRadius( Orig_PullDist )
	util.Effect( "tunneling_radeonic_grapple_splash", effectdata)
	
	local SoundDistanceMax = 8000 * 52.4934
	for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
		if IsValid(v) and v:IsPlayer() then
			local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
			local Meter_Dist = Dist * SoundDistanceMax
			local Blip_String = ""
			
			local SpatialWaveFormat = (343*20) + math.random(-10,150)
			local ContinationWave = ( Meter_Dist ) / ( SpatialWaveFormat * 52.4934 )
			
			Blip_String = (Meter_Dist < 230) and "ahee_suit/radeonicgrapple/radeonicgrapple_pull_blip_close_explose.mp3" or "ahee_suit/radeonicgrapple/radeonicgrapple_pull_blip_form.mp3"
			
			net.Start("Radeonic_Range_Blip")
				net.WriteFloat(ContinationWave)
				net.WriteString(Blip_String)
				net.WriteFloat(Dist)
			net.Send(v)
			
		end
	end
	
	local Meters = 400
	local traceData = {}
	traceData.mask = bit.bor(CONTENTS_SOLID, CONTENTS_MOVEABLE, CONTENTS_DEBRIS, CONTENTS_MONSTER, CONTENTS_HITBOX, CONTENTS_WATER)
	
	local SoundDistanceMax = Meters * 52.4934
		for k, v in pairs(ents.FindInSphere(self:WorldSpaceCenter(),SoundDistanceMax)) do
			if IsValid(v) and v:IsPlayer() and v != self then
				local Dist = v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/SoundDistanceMax
				
				obj = v
				
				local positedplayer = v:WorldSpaceCenter()
				
				direction = ( positedplayer - self:WorldSpaceCenter() )
				
				traceData.filter = {Bouncer,self}
				traceData.start = self:WorldSpaceCenter() 
				traceData.endpos = traceData.start + direction * SoundDistanceMax
				
				local trace = util.TraceLine(traceData)
				
				local ent = trace.Entity
				local fract = trace.Fraction
				
				local isplayer = ent:IsPlayer()
				local isnpc = ent:IsNPC()
				local equal = ent == v
				
				local SpatialWaveFormat = (343*2) + math.random(-10,150)
				
				if not equal then 
					SpatialWaveFormat = SpatialWaveFormat / ( math.random( 110 , 150 ) / 100 )
					Dist = (Dist ^ math.random( 0.45 , 0.75 ) )
				end
				
				local ContinationWave = ( Dist * SoundDistanceMax ) / ( SpatialWaveFormat * 52.4934 )
				
				net.Start("Radeonic_Grapple_Effect_Far")
					net.WriteFloat(ContinationWave)
					net.WriteFloat(Dist)
				net.Send(v)
				
			end
		end
	
	self:EmitSound("ahee_suit/radeonicgrapple/radeonicgrapple_beam_launch_"..math.random(1,4)..".mp3", 100, 100,0.7)
	self:EmitSound("ahee_suit/radeonicgrapple/radeonicgrapple_pull_blip_close.mp3", 120, 100,0.7)
	
end

function GrappleStabilityCalculate( self )
	
	local GrapplePack = self.RadeonicGrapplePack
	
	local RadeonicFrequency = 280000 --Hertz
	local TychronicCharge = 1200 --Watts
	local Stability_Calc = (GrapplePack.Charge/TychronicCharge) + (GrapplePack.Frequency/RadeonicFrequency)
	local SquaredBuffer = math.Clamp( GrapplePack.BufferLoad ^ 0.5 , 1 , math.huge )
	
	return Stability_Calc / SquaredBuffer
end

function GrappleStabilityKnock( self , Associate )
	local GrapplePack = self.RadeonicGrapplePack
	if GrapplePack.BufferEnergy <= 0 or GrapplePack.Stability <= 35 then
		return
	end
	
	local Associate = Associate or false
	
	if Associate then GrapplePack.BufferLoad = GrapplePack.BufferLoad - (60 * GrapplePack.EnergyYield) end
	local PowerField = GrapplePack.Charge * GrapplePack.EnergyYield
	local SquaredBuffer = math.Clamp( math.abs(GrapplePack.BufferLoad) , 1 , GrapplePack.MaxBufferEnergy )
	
	GrapplePack.Stability = GrapplePack.Stability - (SquaredBuffer / PowerField)
end

function RadeonicGrapple_Handling( self )
	if not IsValid( self ) then return end
	
	local RealGunPos = FindRealGunPos( self )
	
	local GrapplePack = self.RadeonicGrapplePack
	local RadeonicHooking = GrapplePack.Hooking
	local RadeonicDistance = GrapplePack.RangeOrder * 52.4934
	
	local Beam_Attachable = CanAttachRadeonicGrapple( self )
	local BufferEnergyTotal = math.Clamp( GrapplePack.BufferEnergy / GrapplePack.MaxBufferEnergy , 0 , 1 )
	local StabilityTotal = math.Clamp( GrapplePack.Stability / 100 , 0 , 1 )
	
	GrapplePack.Stability = math.Clamp( GrapplePack.Stability + GrappleStabilityCalculate( self ) , 0 , 100 )
	GrapplePack.BufferLoad = math.Clamp( GrapplePack.MaxBufferEnergy - GrapplePack.BufferEnergy , 0 , GrapplePack.Charge )
	GrapplePack.BufferEnergy = math.Clamp( GrapplePack.BufferEnergy , 0 , GrapplePack.MaxBufferEnergy )
	
	if CLIENT then
		if ( not RadeonicHooking and input.IsButtonDown( KEY_T ) ) and Beam_Attachable then
			
			net.Start("RadeonicGrapple_Server")
				net.WriteEntity(self)
				net.WriteBool(true)
			net.SendToServer()
			
			Create_Grapple_Pos( self )
			SetRadeonicGrappleHook( self , true )
		elseif ( RadeonicHooking and not input.IsButtonDown( KEY_T ) ) then
			
			net.Start("RadeonicGrapple_Server")
				net.WriteEntity(self)
				net.WriteBool(false)
			net.SendToServer()
			
			SetRadeonicGrappleHook( self , false )
		end
		
	end
	
	if RadeonicHooking and Beam_Attachable and self.RadeonHookHitPos then
		local AngleBetween = GetArmAngle( self )
		local PullEnergy = self.RadeonHookHitPos:Distance(self:GetPos())
		
		GrapplePack.PullAxis = math.Clamp( AngleBetween , 0 , 90 )
		GrapplePack.BufferLoad = GrapplePack.BufferLoad + (GrapplePack.Charge + (GrapplePack.PullAxis * 25) + ((PullEnergy/RadeonicDistance)*1300)) * GrapplePack.EnergyYield
		GrapplePack.BufferEnergy = GrapplePack.BufferEnergy - GrapplePack.BufferLoad
		
		local ownerpullingtrace = {}
		ownerpullingtrace.start = RealGunPos
		ownerpullingtrace.endpos = ownerpullingtrace.start + self:EyeAngles():Forward() * Orig_PullDist
		ownerpullingtrace.filter = {self,self.RadeonHookHitTarget}
		
		local PulledTrace = util.TraceLine(ownerpullingtrace)
		local PullDist = self.RadeonHookHitPos:Distance(PulledTrace.HitPos)
		local PullVector = -(self.RadeonHookHitPos - PulledTrace.HitPos):GetNormalized()
		local PullDifference = PullDist / Orig_PullDist
		
		if PullDifference > 1.3 then
			RadeonicGrappleLoop = CreateSound( self,"ahee_suit/radeonicgrapple/radeonicgrapple_beam_maximum_force.mp3")
			RadeonicGrappleLoop:PlayEx( 0.5 , 100 )
		elseif PullDifference > 0.7 then
			RadeonicGrappleLoop = CreateSound( self,"ahee_suit/radeonicgrapple/radeonicgrapple_beam_moderate_force.mp3")
			RadeonicGrappleLoop:PlayEx( 0.5 , 100 )
		else
			RadeonicGrappleLoop = CreateSound( self,"ahee_suit/radeonicgrapple/radeonicgrapple_beam_minimum_force.mp3")
			RadeonicGrappleLoop:PlayEx( 0.5 , 100 )
		end
		
		if SERVER then
			local Stability_Affect = (100-GrapplePack.Stability)
			local Affect_Size = 52.4934 * (1.5 + math.Clamp( PullDifference^0.5 , 0 , 5 )) + Stability_Affect * 3
			for k, v in pairs(ents.FindInSphere( self.RadeonHookHitPos , Affect_Size )) do
				if ( v ~= self ) and v != self.RadeonHookHitTarget then
					local Dist = ( 1.05 - math.Clamp(v:GetPos():Distance(self.RadeonHookHitPos)/Affect_Size,0,1)^2 )
					local Velo = -((v:GetPos() - self.RadeonHookHitPos):GetNormalized() * Dist) * math.Rand(1,8) * ((Stability_Affect / 3) + 1)
					local PhysObj = v:GetPhysicsObject()
					
					local d = DamageInfo()
					
					if IsValid(v) and IsValid(self) then
						if IsValid( PhysObj ) then PhysObj:AddVelocity(  (-v:GetVelocity()*(0.999-(Stability_Affect/85))) + (Velo * PhysObj:GetMass()^0.25) ) else v:SetVelocity( (-v:GetVelocity()*(0.999-(Stability_Affect/85))) + Velo ) end
						
						d:SetDamage( math.random(3800,4500)*Dist )
						d:SetDamageType( DMG_RADIATION )
						d:SetAttacker( self )
						d:SetInflictor( self )
						v:TakeDamageInfo( d )
						
						d:SetDamage( math.random(750,800)*Dist )
						d:SetDamageType( DMG_GENERIC )
						d:SetAttacker( self )
						d:SetInflictor( self )
						v:TakeDamageInfo( d )
						
					end
				end
			end
		end
		
		if IsValid(self.RadeonHookHitTarget) and (self.RadeonHookHitTarget:IsNPC() or self.RadeonHookHitTarget:IsPlayer() or self.RadeonHookHitTarget:GetMoveType(MOVETYPE_VPHYSICS)) then
			self.RadeonHookHitPos = self.RadeonHookHitTarget:WorldSpaceCenter()
			
			if self.RadeonHookHitTarget:GetMoveType(MOVETYPE_VPHYSICS) and not self.RadeonHookHitTarget:IsNPC() then 
				if SERVER then
					local physobjter = self.RadeonHookHitTarget:GetPhysicsObject() != nil and self.RadeonHookHitTarget:GetPhysicsObject() or self.RadeonHookHitTarget
					if physobjter:IsValid() then 
					physobjter:SetVelocity( ((PullVector * 52.4934 ) * (PullDist * 0.254)) - physobjter:GetVelocity()/5 ) 
					end
				end
			else
				self.RadeonHookHitTarget:SetVelocity( ((PullVector * 52.4934 ) * (PullDist * 0.0254)) - self.RadeonHookHitTarget:GetVelocity()/10 )
			end
			
			
			
			if not IsValid(self.RadeonHookTargetBurn) or not self.RadeonHookTargetBurn:IsPlaying() then
				self.RadeonHookTargetBurn = nil
				self.RadeonHookTargetBurn = CreateSound( self.RadeonHookHitTarget,"ahee_suit/radeonicgrapple/high_heat_burn_loop.mp3" )
				self.RadeonHookTargetBurn:PlayEx( 1 , 100 )
			end
			
			if SERVER then
				local dmginfo = DamageInfo()
				local dmg_random = math.random(1000,1200) 
				dmginfo:SetDamage( dmg_random )
				dmginfo:SetAttacker( self )
				dmginfo:SetInflictor( self )
				dmginfo:SetDamageType( DMG_SHOCK ) 
				dmginfo:SetDamagePosition( self.RadeonHookHitTarget:WorldSpaceCenter() )
				self.RadeonHookHitTarget:TakeDamageInfo( dmginfo )
			end
			
			if PullDifference > 0.5 then
				GrapplePack.BufferEnergy = GrapplePack.BufferEnergy - 3250
				GrapplePack.Stability = GrapplePack.Stability * 0.99
				self.RadeonHookHitTarget:EmitSound("ahee_suit/fraise/fraise_passive_plasmaticdetonation_far_heavy_"..math.random(1,3)..".mp3", 140, math.random(90,130),1)	
				
				if SERVER then
					local dmginfo = DamageInfo()
					local dmg_random = math.random(2,5) 
					dmginfo:SetDamage( dmg_random * (self.RadeonHookHitTarget:GetVelocity():Length() * 0.0254) ^ 2 )
					dmginfo:SetAttacker( self )
					dmginfo:SetInflictor( self )
					self.RadeonHookHitTarget:TakeDamageInfo( dmginfo )
				end
				
			elseif PullDifference > 0.1 then 
				GrapplePack.BufferEnergy = GrapplePack.BufferEnergy - 150
				GrapplePack.Stability = GrapplePack.Stability * 0.999
				
			end
			
		else
			
			local PullDist = self.RadeonHookHitPos:Distance(self:WorldSpaceCenter())
			local PullVector = (self.RadeonHookHitPos - self:WorldSpaceCenter()):GetNormalized()
			
			local OwnerVelo = self:GetVelocity()
			local OwnerVeloSquared = Vector( (math.abs(OwnerVelo.x) ^ 0.5) * OwnerVelo:GetNormalized().x , (math.abs(OwnerVelo.y) ^ 0.5) * OwnerVelo:GetNormalized().y , (math.abs(OwnerVelo.z) ^ 0.5) * OwnerVelo:GetNormalized().z )
			
			local PullSpeed = (( PullVector * 52.4934 ) * (PullDist/(PullDist^self.GrapplePull)))
			local PullSpeedSquared = Vector( (math.abs(PullSpeed.x) ^ 0.5) * PullSpeed:GetNormalized().x , (math.abs(PullSpeed.y) ^ 0.5) * PullSpeed:GetNormalized().y , (math.abs(PullSpeed.z) ^ 0.5) * PullSpeed:GetNormalized().z )
			
			self:SetEyeAngles( LerpAngle( 0.015 , self:EyeAngles() , self:GetVelocity():GetNormalized():Angle() ):Forward():Angle() )
			self:SetVelocity( PullSpeed )
			self:SetPos( self:GetPos() + PullSpeedSquared )
			
		end
		
		if AngleBetween > 50 then
			if not AnglePulling then
				self:EmitSound("ahee_suit/radeonicgrapple/radeonic_powerplate_open.mp3", 75, math.random(90,100),0.3)
				AnglePulling = true
			end
			
		elseif AngleBetween < 25 then
			if AnglePulling then
				self:EmitSound("ahee_suit/radeonicgrapple/radeonic_powerplate_close.mp3", 75, math.random(90,100),0.3)
			end
			AnglePulling = false
		end
		
	else
		
		if RadeonicHooking then
			self:EmitSound("ahee_suit/radeonicgrapple/radeonicgrapple_beam_powercut.wav", 70, 100,0.3)
			self:EmitSound("ahee_suit/radeonicgrapple/radeonic_grappleunit_port_close.mp3", 70, math.random(90,130),0.3)
		end
		
		GrapplePack.PullAxis = 0
		
		if self.RadeonHookTargetBurn then 
			self.RadeonHookTargetBurn = nil
		end
		
		if RadeonicGrappleLoop and self.GForceBreathing and self.PullingGForce then
			RadeonicGrappleLoop:Stop()
			self.GForceBreathing:FadeOut(3)
			self.PullingGForce:FadeOut(1)
		end
		
	end
	
	if (self.MainCapacitorMJ*1000000) > GrapplePack.BufferLoad and GrapplePack.BufferEnergy < GrapplePack.MaxBufferEnergy then
		GrapplePack.BufferEnergy = GrapplePack.BufferEnergy + GrapplePack.BufferLoad * 0.99
		self.MainCapacitorMJ = self.MainCapacitorMJ - math.Clamp( GrapplePack.BufferLoad / 1000000 , 0 , GrapplePack.MaxBufferEnergy )
		
		self.RadeonicGrapplePowerLoop = CreateSound( self,"ahee_suit/radeonicgrapple/radeonic_grappleunit_powernoise.mp3")
		if not self.RadeonicGrapplePowerLoop:IsPlaying() then
			local EnergyToEmpty = (1-BufferEnergyTotal)
			self.RadeonicGrapplePowerLoop:PlayEx( 0.1 + (EnergyToEmpty*0.40) , 50 + math.Round(BufferEnergyTotal*50) )
		end
	else
		if self.RadeonicGrapplePowerLoop then
			self.RadeonicGrapplePowerLoop:Stop()
		end
	end
	
	if GrapplePack.Stability < 100 then
		
		self.RadeonicGrappleStabilityLoop = CreateSound( self,"ahee_suit/small_highload_inverter_highenergybuild.mp3")
		if not self.RadeonicGrappleStabilityLoop:IsPlaying() then
			local StabilityToEmpty = (1-StabilityTotal)
			self.RadeonicGrappleStabilityLoop:PlayEx( 0.3 + (StabilityToEmpty*0.30) , 90 + math.Round(StabilityTotal*20) )
		end
		
	else
		if self.RadeonicGrappleStabilityLoop then
			self.RadeonicGrappleStabilityLoop:Stop()
		end
	end
	
	if RadeonicHooking then
		if SERVER then
			--net.Start("Radeonic_Grapple_Effect_Extra")
				--net.WriteFloat( GrapplePack.Stability )
			--net.Broadcast()
		end
		
		if self.RadeonHookHitPos != nil and IsValid( self.RadeonHookHitTarget ) then
			local effectdata = EffectData()
			local TargetID = IsValid( self.RadeonHookHitTarget ) and ( self.RadeonHookHitTarget ):EntIndex() or -1
			effectdata:SetOrigin( self.RadeonHookHitPos )
			effectdata:SetStart( self.RadeonHookHitPos )
			effectdata:SetEntity( self )
			effectdata:SetMaterialIndex( TargetID )
			effectdata:SetMagnitude( 1 )
			effectdata:SetScale( GrapplePack.Stability )
			effectdata:SetRadius( Orig_PullDist )
			util.Effect( "tunneling_radeonic_grapple", effectdata)
		elseif self.RadeonHookHitPos != nil then
			local effectdata = EffectData()
			local TargetID = IsValid( self.RadeonHookHitTarget ) and ( self.RadeonHookHitTarget ):EntIndex() or -1
			effectdata:SetOrigin( self.RadeonHookHitPos )
			effectdata:SetStart( self.RadeonHookHitPos )
			effectdata:SetEntity( self )
			effectdata:SetMaterialIndex( TargetID )
			effectdata:SetMagnitude( 1 )
			effectdata:SetScale( GrapplePack.Stability )
			effectdata:SetRadius( Orig_PullDist )
			util.Effect( "tunneling_radeonic_grapple", effectdata)
		end
	end
	
end

function AHEE_System_AddTo_PseudoTeam( self , Ent )
	local LocalTeam = self.A9_Team_List
	if not LocalTeam then return end
	
	local Is_In_Team = IsValid(LocalTeam[ table.KeyFromValue( LocalTeam, Ent ) ])
	if Is_In_Team then return end
	
	local function Entity_Add()
		if CLIENT then
			local Name = Ent:IsPlayer() and Ent:GetName() or tostring(Ent)
			EmitSound( "ahee_suit/ahee_system_full_send_cycle_start.mp3", Vector(), -1, CHAN_STATIC, 0.6, 0, 0, 100 )
			Hint_Setup( "Link Established ; " .. Name , false , 6 )
		end
		
		table.insert( LocalTeam, #LocalTeam+1, Ent )
	end
	
	if Ent:GetNWBool("AHEE_EQUIPED") or Ent:GetClass() == "pelvareign_nextbot" then
		Entity_Add()
	end
	
	if Ent:IsPlayer() and not Is_In_Team then
		AHEE_System_AddTo_PseudoTeam( Ent , self ) 
	end
	
end

net.Receive( "Suit_PseudoTeam_Recieve_UnitVars", function( len, ply )

	local plr =  net.ReadEntity()
	plr.Fraise_Stability = net.ReadFloat()
	
	plr.ShieldingBufferEnergy = net.ReadFloat()
	plr.ShieldingBufferEnergyLimit = net.ReadFloat()
	
	plr.MainCapacitorMJ = net.ReadFloat()
	plr.MainCapacitorMJLimit = net.ReadFloat()
	
	local Binary_Table_Number = net.ReadUInt( 32 )
	local Table_Data = net.ReadData( Binary_Table_Number )
	
	local Decompressed_Str = util.Decompress( Table_Data )
	local Table_String = util.JSONToTable( Decompressed_Str )
	
	plr.ShieldingList = Table_String
	
end)

function AHEE_System_GoThrough_PseudoTeam( self )
	local LocalTeam = self.A9_Team_List
	if not LocalTeam then return end
	
	for Index, Entity in pairs( LocalTeam ) do
		if not IsValid( Entity ) or (Entity:IsPlayer() and not Entity:GetNWBool("AHEE_EQUIPED")) then
			table.remove( LocalTeam, Index )
		end
		
		if Entity:IsPlayer() and SERVER then
			net.Start("Suit_PseudoTeam_Recieve_UnitVars")
				net.WriteEntity( self )
				net.WriteFloat( self.Fraise_Stability )
				
				net.WriteFloat( self.ShieldingBufferEnergy )
				net.WriteFloat( self.ShieldingBufferEnergyLimit )
				
				net.WriteFloat( self.MainCapacitorMJ )
				net.WriteFloat( self.MainCapacitorMJLimit )
				
				local Table_String = util.TableToJSON( self.ShieldingList )
				local Compressed_Str = util.Compress( Table_String )
				local Binary_Table_Number = #Compressed_Str
				net.WriteUInt( Binary_Table_Number, 32 )
				net.WriteData( Compressed_Str, Binary_Table_Number )
				
			net.Send(Entity)
		end
		
	end
	
end

function AHEE_System_Alert_PseudoTeam( self )
	local LocalTeam = self.A9_Team_List
	local Target = self:GetNWEntity( "TargetSelected" ) or nil
	
	if not LocalTeam then return end
	
	net.Start("AHEE_System_Alert_Receive")
		net.WriteEntity( self )
		net.WriteEntity( Target )
		net.WriteVector( self.InternalInterest_Pos )
	net.Send(self)
	
	for Index, Entity in pairs( LocalTeam ) do
		if IsValid(Entity) then
			if ( Entity:IsPlayer() and Entity:GetNWBool("AHEE_EQUIPED") ) then
			
				net.Start("AHEE_System_Alert_Receive")
					net.WriteEntity( self )
					net.WriteEntity( Target )
					net.WriteVector( self.InternalInterest_Pos )
				net.Send(Entity)
				
			elseif ( Entity:GetClass() == "pelvareign_nextbot" ) then
				if Target then Entity:AddThreat( Target ) end
				
				local Position = self.InternalInterest_Pos + ( VectorRand(5,40) * VectorRand() * Vector(1,1,0) )
				local options = {}
				options.Run = true
				options.range = 2500
				options.dist = 150
				
				Entity:GotoPosition( Position , options )
				
			end
			
		end
	end
	
	
end

function Target_To_Team_Transfer( Ply )
	local Target = Ply:GetNWEntity( "TargetSelected" )
	if IsValid( Target ) then AHEE_System_AddTo_PseudoTeam( Ply , Target ) end
end

function AHEE_LookFor_Striker( self )
	if not self.ShieldingActiveShot then return end
	
	local InFieldCondition = 100*52.4934
	for TargetInfo, Object in pairs( ents.FindInSphere( self:WorldSpaceCenter(), InFieldCondition / 2 ) ) do
		ObjectVelocityMetered = nil
		
		if IsValid(Object) and not Object.ObjectIsNotAllowedToZap and Object != self.HeldItem then
		if (Object != self) and (Object:GetOwner() != self) and Object != self.PlayerBody then
		if (not (Object:IsNPC() or Object:IsNextBot() or Object:IsPlayer())) and Object:GetMoveType() != 0 then 
		
		local ObjectPhysics = Object:GetPhysicsObject() or nil
		local ObjectVelocity = IsValid(ObjectPhysics) and ObjectPhysics:GetVelocity() or Object:GetVelocity()
		if ObjectVelocity then
		ObjectVelocityMetered = ObjectVelocity and (ObjectVelocity:Length()/52.4934) or 0
		
		local ObjectMin, ObjectMax = Object:GetCollisionBounds()
		local ObjectVolume = ((math.abs(ObjectMin:Length()/52.4934)*100) * (math.abs(ObjectMax:Length()/52.4934)*100)) -- In CM
		local ObjectDistance = Object:WorldSpaceCenter():Distance( self:WorldSpaceCenter() )
		local ObjectVelocityRooted = Vector( (math.abs(ObjectVelocity.x)^0.5) , (math.abs(ObjectVelocity.y)^0.5) , (math.abs(ObjectVelocity.z)^0.5) ):Length()
		
		local GravityConst = physenv.GetGravity()
		local ObjectGravityRooted = Vector( math.abs(GravityConst.x)^0.5 , math.abs(GravityConst.y)^0.5 , math.abs(GravityConst.z)^0.5 ):Length()
		
		local mins = Object:OBBMins()
		local maxs = Object:OBBMaxs()
		local startpos = Object:GetPos()
		local dir = ObjectVelocity:GetNormalized()
		local Gravdir = GravityConst:GetNormalized()
		local GravForce = Gravdir * math.abs(ObjectGravityRooted)
		local DistanceConcern = math.abs(ObjectVelocityRooted)
		local VelocityForce = dir * DistanceConcern
		
		local DegreesToConsider = 60
		local linetotargeted = (self:WorldSpaceCenter() - Object:WorldSpaceCenter()):GetNormalized()
		local AngleBetweened = math.deg( math.acos( dir:Dot(linetotargeted) / (dir:Length() * linetotargeted:Length()) ) )
		local AngledTooMuched = AngleBetweened > DegreesToConsider
		local WarningTraceHit = nil
		
		local ConcernSpeed = (Object:GetOwner() == self) and 10 or 0.1
		
		if ObjectVelocityMetered > ConcernSpeed and not AngledTooMuched then
			for i = 1, math.Clamp(math.Round(ObjectVelocityRooted/5),1,10) do
				WarningTraceHit = nil
				VeloPos = VeloPos or startpos
				WarningTrace = util.TraceHull( {
					start = VeloPos,
					endpos = VeloPos + (ObjectVelocity*engine.TickInterval()*i), -- (GravForce*engine.TickInterval()*(i^2))
					maxs = maxs,
					mins = mins,
					filter = Object
				} )
				--debugoverlay.Box( WarningTrace.HitPos, mins, maxs, 0.05, Color( 255, 180, 180, 25 ) )
				VeloPos = VeloPos + (WarningTrace.HitPos-VeloPos)
				WarningTraceHit = WarningTrace.Entity
			end
		end
		VeloPos = nil
		
		if (IsValid(WarningTraceHit) and WarningTraceHit == self) and ObjectDistance < (52.4934*5) then
		local Attacker = Object
		
		if ( not CheckShieldingDown(self) ) and CheckShieldingStability(self) then 
			
			local Low, High = self:WorldSpaceAABB()
			local vPos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
			
			local MassEnergyConsumation = ObjectVolume * (ObjectVelocityMetered^2)
			local MassEnergyAmperage =  math.Clamp( (MassEnergyConsumation / 1000000) + 5 , 1 , 120 )
			
			ChangeShielding( self , MassEnergyConsumation / 1000000 , false )
			
			local Hit_Table = {}
			Hit_Table.Owner = self
			Hit_Table.Vector = vPos + self:WorldSpaceCenter()
			Hit_Table.Damage = math.Clamp( MassEnergyConsumation / 1000 , 0.1 , 4 )
			
			ShieldHit_Shared( Hit_Table )
			
			net.Start( "ShieldStats_Affected_Client" )
			net.WriteEntity( self )
			net.WriteFloat( MassEnergyConsumation / 1000000 )
			net.WriteBool(false)
			net.Send( self )
			
			local AttackerDirectionized = (IsValid(Attacker) and (Attacker:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized()) or self:EyeAngles():Forward()
			local randomiz = math.random(1,5)
			AttackerDirectionized = AttackerDirectionized * ((52.4934*randomiz)*math.random(90,100)/100)

			if IsValid(Attacker) then
				local effectdata = EffectData()
				effectdata:SetStart( vPos )
				effectdata:SetOrigin( AttackerDirectionized )
				effectdata:SetNormal( AngleRand():Forward() )
				if IsValid(Attacker) and Attacker != self and ObjectDistance < (52.4934*5) then
					effectdata:SetEntity( Attacker )
				end
				effectdata:SetMagnitude( MassEnergyAmperage )
				util.Effect( "tunneling_fraise_arc", effectdata, true, true)
			end
			
		
			if IsValid(Attacker) and Attacker != self and ObjectDistance < (52.4934*5) then
				local daginfo = DamageInfo()
				local dmg_random = math.random(50000,108000) 
				local PowerMultiplier = 1
				for Shield, Value in pairs(self.ShieldingList) do
					local TurnedOut = Value[2]
					local Power = Value[3]
					if TurnedOut == false then
						PowerMultiplier = Value[6]
						break
					end
				end
				
				local VoltageMult = ( (MassEnergyAmperage^3) * PowerMultiplier )
				local VoltToMeter = ( 52.4934 * VoltageMult )
				local ObjectsInVoltRange = ents.FindInSphere( Object:WorldSpaceCenter() , VoltToMeter )
				
				for k, v in pairs( ObjectsInVoltRange ) do
					local VoltDistance = Object:WorldSpaceCenter():Distance( v:WorldSpaceCenter() )
					if IsValid(v) and (v != self) and (Object != self) and (type(v) == "Entity") and not string.match( tostring( v ) , "physgun_beam" ) and not string.match( tostring( v ) , "viewmodel" ) and not string.match( tostring( v ) , "flame" ) then
						local Dist = ( 1 - ( VoltDistance / (5 * 52.4934) ) )
						local Energy = ( ( MassEnergyAmperage ) * Dist ) ^ 0.75
						local BoltAmount =  math.Round(math.Clamp( (Energy*2) , 3 , 14 ))
						if Dist>0 and Dist<=1 and Energy then
						
						sound.Play( Sound("ahee_suit/fraise/active_protection_discharge_"..math.random(1,3)..".mp3"), Object:WorldSpaceCenter(), 110, math.random(150,160), 0.5 )
						
						if IsValid(ObjectPhysics) then
							ObjectPhysics:SetVelocity( ObjectVelocity + ( (Object:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * (ObjectVelocity/3) ) * Dist )
						else
							Object:SetVelocity( ObjectVelocity + ( (Object:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * (ObjectVelocity/3) ) * Dist )
						end
						
							for i=1, BoltAmount do
								
								local Low, High = Object:WorldSpaceAABB()
								local vPos = Vector( math.Rand( Low.x, High.x ), math.Rand( Low.y, High.y ), math.Rand( Low.z, High.z ) )
								local PositiveCharge = ( vPos - Object:WorldSpaceCenter() ):GetNormalized()
								local NegativeCharge = ( PositiveCharge + (AngleRand():Forward()/5) ):GetNormalized() * ( (VoltToMeter^0.5) * Dist )
								local HitPosition = NegativeCharge
								
								local effectdata = EffectData()
								effectdata:SetStart( vPos )
								effectdata:SetOrigin( HitPosition )
								effectdata:SetNormal( AngleRand():Forward() )
								effectdata:SetMagnitude( Energy * (math.random(40,160)/100) )
								if BoltAmount > 2 and IsValid(v) and (v!= Object) then
									effectdata:SetEntity( v )
								end
								effectdata:SetScale( 1 )
								util.Effect( "tunneling_fraise_arc", effectdata, true, true)
								
							end
							
							if IsValid(v) and (v != Object) and (v != self) then
								local EnergyReceived = ((dmg_random*PowerMultiplier) + ((MassEnergyConsumation)*PowerMultiplier)) * Dist
								local VMin, VMax = v:GetCollisionBounds()
								local VVolume = ((math.abs(VMin:Length()/52.4934)*100) * (math.abs(VMax:Length()/52.4934)*100))
								local VolumeRatio = (ObjectVolume/VVolume)
								
								daginfo:SetDamage( EnergyReceived )
								daginfo:SetAttacker( self )
								daginfo:SetInflictor( self )
								daginfo:SetDamageType( DMG_GENERIC ) 
								daginfo:SetDamagePosition( Object:WorldSpaceCenter() )
								if Dist > 0.25 and v:GetOwner() != self then
									v:Ignite(5)
									v:EmitSound("main/explodeair0_"..math.random(1,4)..".wav", 110, math.random(210,230),1)
								end
								
								local VPhysics = v:GetPhysicsObject() or nil
								local VVelocity = IsValid(VPhysics) and VPhysics:GetVelocity() or v:GetVelocity()
								
								v:TakeDamageInfo( daginfo )
								if IsValid(v) and VVelocity then
									if IsValid(VPhysics) then
										VPhysics:SetVelocity( VVelocity + ((v:WorldSpaceCenter() - Object:WorldSpaceCenter()):GetNormalized() * Dist) * VolumeRatio * 100 )
									elseif not IsValid(VPhysics) then
										v:SetVelocity( VVelocity + ((v:WorldSpaceCenter() - Object:WorldSpaceCenter()):GetNormalized() * Dist) * VolumeRatio * 100 )
									end
								end
							end
							
						end
					end
				end
				
				Object:SetMaterial( "models/props_combine/portalball001_sheet" )
				Object:SetColor( Color(100,100,255,255) )
				Object.ObjectIsNotAllowedToZap = true
				timer.Simple( 0.05, function() 
					if IsValid(Object) then
						Object:Remove()
						if ObjectVolume > 100000 then 
							for i=1, 6 do ParticleEffect( "HugeFire", Object:WorldSpaceCenter() , AngleRand() ) end
							sound.Play( "main/railexplode.wav", Object:WorldSpaceCenter(), 140, math.random(40,60), 1 )
							sound.Play( "high_energy_systems/antispatialknock_highsavor.wav", Object:WorldSpaceCenter(), 140, math.random(100,120), 1 )
						elseif ObjectVolume < 100000 and ObjectVolume > 10000 then 
							for i=1, 6 do ParticleEffect( "SUPEREMBERHIT", Object:WorldSpaceCenter() , AngleRand() ) end
							sound.Play( "main/fragexplose"..math.random(1,3)..".mp3", Object:WorldSpaceCenter(), 120, math.random(60,70), 1 )
						else
							for i=1, 6 do ParticleEffect( "DirtFireball", Object:WorldSpaceCenter() , AngleRand() ) end
							sound.Play( "main/tanks_explosion_01.wav", Object:WorldSpaceCenter(), 110, math.random(95,100), 1 )
						end
					end 
				end)
				
				
				local DetonationWaveRadius = (math.random(5,7) * 52.4934) * (MassEnergyAmperage/80)
				
				for k, v in pairs(ents.FindInSphere( self:WorldSpaceCenter() ,DetonationWaveRadius)) do
					if IsValid(v) and v!=self then
						local Dist = ( 1 - (v:WorldSpaceCenter():Distance(self:WorldSpaceCenter())/DetonationWaveRadius) )
						
						local VMin, VMax = v:GetCollisionBounds()
						local VVolume = (math.abs(VMin:Length()/52.4934) * math.abs(VMax:Length()/52.4934))
						local Force = math.random(600,2900) / VVolume
						
						local VPhysics = v:GetPhysicsObject() or nil
						local VVelocity = IsValid(VPhysics) and VPhysics:GetVelocity() or v:GetVelocity()
						
						if IsValid(v) and VVelocity then
							if IsValid(VPhysics) then
								VPhysics:SetVelocity( ((v:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * Dist) * Force )
							elseif not IsValid(VPhysics) then
								v:SetVelocity( ((v:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized() * Dist) * Force )
							end
						end
						v:EmitSound("main/explodeair0_"..math.random(1,4)..".wav", 90, math.random(140,160),0.6)
						
					end
				end
			
			end
			
			self:EmitSound("ahee_suit/suit_particleheat_malformation.wav", 110, math.random(90,100),0.1)
			self:EmitSound("ahee_suit/fraise/active_protection_discharge_"..math.random(1,3)..".mp3", 100, math.random(170,175)-((MassEnergyAmperage/120)*100),0.9)
			
			local d = DamageInfo()
			d:SetDamage( math.random(12,85) )
			d:SetAttacker( self )
			d:SetInflictor( self )
			d:SetDamageType( DMG_RADIATION )
			util.BlastDamageInfo(d, self:WorldSpaceCenter(), (math.random(1,3) * 52.4934))
			
			if MassEnergyConsumation > 10 then
			
				for i=1,25 do
					timer.Simple( i/50, function()
						if not IsValid(self) or not IsValid(self) then return end
						self:SetViewPunchAngles(Angle(math.random(-10-i,10+i)/200, math.random(-10-i,10+i)/200, math.random(-10-i,10+i)/200)+self:GetViewPunchAngles())
					end)
				end
				
				local d = DamageInfo()
				d:SetDamage( math.random(29890,91300) )
				d:SetAttacker( self )
				d:SetInflictor( self )
				d:SetDamageType( DMG_RADIATION )
				util.BlastDamageInfo(d, self:WorldSpaceCenter(), (math.random(4,6) * 52.4934))
			
				net.Start( "MalPlhasealSuit_Squeeze" )
					net.WriteBool( true )
				net.Send( self )
				
			end
			
		end
	
	end end end end end
	
	end
end

function AHEE_DragCollide( self , collision_data )
	local FullDragBar = self.DragShielding / self.DragShieldingLimit
	local DragShieldingOn = (FullDragBar >= 0.1 and self.DragShieldingSetting)
	local OldVelo = self:GetVelocity() + self:GetGroundSpeedVelocity()
	local HitEnt = collision_data.HitEntity
	local HitPhys = collision_data.PhysObject
	
	if DragShieldingOn then
		timer.Simple( 0 , function()
			self:SetVelocity( (OldVelo-self:GetVelocity()) )
			if HitEnt and HitPhys then
				HitEnt:SetVelocity( HitEnt:GetVelocity():Length() * -(HitEnt:GetPos() - self:GetPos()):GetNormalized() )
				HitPhys:SetVelocity( HitEnt:GetVelocity():Length() * -(HitEnt:GetPos() - self:GetPos()):GetNormalized() )
			end
			
		end)
	end
end


net.Receive( "Weapon_Change_RoundType", function( len, ply )
	local ply = ply or LocalPlayer()
	local Str = net.ReadString()
	
	ply:EmitSound("main/interact_foley_short_"..math.random(1,3)..".wav", 90, math.random(115,120), 0.8 )
	
	local ActiveWeapon = ply:GetActiveWeapon()
	local Rounds = ActiveWeapon["RoundTypes"]
	local RoundTypes = table.GetKeys(Rounds)
	local CurrentAmmoType = ActiveWeapon["AmmunitionType"]
	
	if IsValid(ActiveWeapon) then
		if Rounds and type(Rounds) == "table" then
			ActiveWeapon.AmmunitionType = Rounds[Str]
		end
	end
	
end)

net.Receive( "RadeonicGrapple_Server", function( len, ply )
	local Ent = net.ReadEntity()
	local Bool = net.ReadBool()
	
	if Bool then 
		Create_Grapple_Pos( Ent )
		LaunchGrapple(Ent)
	end
	SetRadeonicGrappleHook( Ent , Bool )
	
end)

net.Receive( "Target_To_Team_Transfer_Server", function( len, ply )
	Target_To_Team_Transfer( ply )
end)

net.Receive( "Suit_Alert_PseudoTeam", function( len, ply )
	AHEE_System_Alert_PseudoTeam( ply )
end)

net.Receive( "Suit_AddTo_PseudoTeam", function( len, ply )
	local Player = LocalPlayer() or ply
	local Ent = net.ReadEntity() or nil
	if Ent == nil then return end
	
	AHEE_System_AddTo_PseudoTeam( Player , Ent )
	
end)

net.Receive( "Targeting_Ping_Server", function( len, ply )
	local Ent = net.ReadEntity()
	Interest_Pos_Change( Ent )
	
end)

net.Receive( "Targeting_Mains_Change_Ping_Server", function( len, ply )
	local Ent = net.ReadEntity()
	Target_PowerMains_Change( Ent )
	
end)
