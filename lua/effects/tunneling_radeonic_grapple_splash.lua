
function EFFECT:Init( data )
	self.LifeTime = math.Rand(0.11,0.4)
	self.Life = CurTime() + self.LifeTime
	
	PositionAttach = data:GetOrigin()
	Origin = data:GetStart()
	Owner = data:GetEntity()
	TargetIndex = data:GetMaterialIndex() or -1
	Target = ents.GetByIndex( TargetIndex ) or nil
	
	TimedCharge = data:GetMagnitude() or 1
	Range = data:GetRadius() or 50
	TimedStability = data:GetScale() or 0
	--Stability = Stability or 0
	
	OwnerPosition = Owner:GetPos()
	
	if Owner:IsWorld() then 
		Owner = nil
	end
	
	Charge = math.Clamp( Charge , 0 , 10 )
	
	HitDistance = OwnerPosition:Distance(PositionAttach)
	HitDirection = (PositionAttach-OwnerPosition):GetNormalized()
	
	StrikeWidth = 0.05 + (Charge^0.9)
	Branches = math.random(1,3)
	BeamDepth = 20
	
end

function EFFECT:Think()
	if CurTime() > self.Life then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	local cablemat = Material( "cable/physbeam" )
	local elecmat = Material( "effects/beam_generic01" )
	local redmat = Material( "cable/redlaser" )
	
	if not IsValid(Owner) then return end
	if not Owner.RadeonHookHitPos then
		Owner.RadeonHookHitPos = Origin
	end
	-- if self ~= LocalPlayer() and (self.RadeonHookHitPos and self.WeaponHooking and self.MaxPullDist) then 
		-- self.WeaponHooking = newder or false
		-- self.RadeonHookHitPos = newdered + self:GetPos()
		-- self.MaxPullDist = BeamLength
	-- end
	
	local Emitter = ParticleEmitter( Owner.RadeonHookHitPos )
	
	local EnergyTime = (self.Life - CurTime()) / self.LifeTime
	
	Stability = TimedStability * ((1-EnergyTime)*0.9) + 0.05
	Charge = TimedCharge * ((1-EnergyTime)*0.9) + 0.05
	
	Anti_Stability = (100-Stability)
	
	local radeontrace = {}
	local forwardtrace = {}
	local PullDist
	local PlayerBounds_Min, PlayerBounds_Max = Owner:GetHitBoxBounds(0,0)
	PlayerBounds_Min = PlayerBounds_Min or Vector()
	PlayerBounds_Max = PlayerBounds_Max or Vector()
	local RealGunPos = Owner:WorldSpaceCenter() + (PlayerBounds_Max * Vector(0,0,2))
	
	radeontrace.start = RealGunPos
	radeontrace.endpos = PositionAttach
	radeontrace.filter = Owner
	local RadTrace = util.TraceLine(radeontrace)
	
	local PullDist = (Owner.RadeonHookHitPos:Distance(Owner:GetPos()))
	
	forwardtrace.start = RealGunPos
	forwardtrace.endpos = forwardtrace.start + Owner:EyeAngles():Forward() * PullDist
	forwardtrace.filter = Owner
	local ForTrace = util.TraceLine(forwardtrace)
	
	local PulledTraceDist = Owner.RadeonHookHitPos:Distance(ForTrace.HitPos)
	local PullVector = (Owner.RadeonHookHitPos - ForTrace.HitPos):GetNormalized()
	local PullDifference = PulledTraceDist / Range
	
	if IsValid(Target) then 
		OwnerVelo = Target:GetVelocity() + (ForTrace.HitPos-RealGunPos)
		Owner.RadeonHookHitPos = Target:WorldSpaceCenter()
	else
		OwnerVelo = Owner:GetVelocity() + (ForTrace.HitPos-RealGunPos)
		Owner.RadeonHookHitPos = RadTrace.HitPos
	end
	
	local OwnerVeloSquared = Vector( (math.abs(OwnerVelo.x) ^ 0.5) * OwnerVelo:GetNormalized().x , (math.abs(OwnerVelo.y) ^ 0.5) * OwnerVelo:GetNormalized().y , (math.abs(OwnerVelo.z) ^ 0.5) * OwnerVelo:GetNormalized().z )
	
	local BurnParticles = math.random(1,3)
	local BurnEnergy = 2.5
	
	if PullDifference > 0.01 then
		BurnParticles = math.Round(math.random(1*PullDifference*5,3*PullDifference*5))
		BurnEnergy = 0.05+(PullDifference*6)
		if PullDifference > 0.4 then 
			sound.Play( Sound("ahee_suit/radeonicgrapple/radeonicgrapple_pull_blip_form.mp3"), Owner.RadeonHookHitPos , 90, math.random(70,90), PullDifference ) 
		end
	end
	
	for i=1, math.random(3,5) do
		local part = Emitter:Add( "sprites/glow04_noz_gmod" , Owner.RadeonHookHitPos ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(10,100) / 50 ) )
			
			part:SetStartAlpha( 200 )
			part:SetEndAlpha( 150 )
			
			part:SetColor( 255, math.Rand(200,255), math.Rand(90,200) )
			
			part:SetGravity( Vector( 0 , 0 , -1600 ) )
			part:SetVelocity( OwnerVeloSquared + (-PullVector * math.random(22, 40)) + (VectorRand() * math.random(30, 230) * BurnEnergy) )
			
			part:SetStartSize( (math.Rand(13,35)/25) * BurnEnergy )
			part:SetEndSize( 0 )
			
			part:SetAirResistance( math.random(135,250) / BurnEnergy )
			part:SetCollide( true )
		end
	end
	
	local LenAmt = 35
	render.SetMaterial( elecmat )
	render.StartBeam( LenAmt )
	render.AddBeam( RealGunPos, 4, 0, Color( 255,0,0,255 ) )
	for s=1, LenAmt do
		local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		render.AddBeam( LerpPosition , math.Rand(0.05,2.0)*(Stability/100), s+math.cos(CurTime()*20), Color( 255,230*(Stability/100),200*(Stability/100),200*(Stability/100) ))
		
		local part = Emitter:Add( "sprites/glow04_noz_gmod" , LerpPosition + (VectorRand() * math.random(5, 10)) ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(10,50) / 400 ) )
			
			part:SetStartAlpha( 20 )
			part:SetEndAlpha( 0 )
			
			part:SetStartSize( (math.random(6,25) * BurnEnergy) )
			part:SetEndSize( 6 * BurnEnergy )
			
			part:SetColor( 255, 255, 255 )
			part:SetGravity( Vector( 0 , 0 , 600 ) )
			
			part:SetAirResistance( math.random(1350,2500) )

		end
		
	end
	render.EndBeam()
	
	render.SetMaterial( elecmat )
	render.StartBeam( LenAmt )
	render.AddBeam( RealGunPos, 0, 0, Color( 255,0,0,255 ) )
	for s=1, LenAmt do
		local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		local PullApproach = math.sin((math.pi/LenAmt) * s)
		render.AddBeam( LerpPosition , (15+50*(Stability/100))*PullApproach, s, Color( 255*(Stability/100),100*(1-(Stability/100)),500*(1-(Stability/100)),20+20*(Stability/100) ))
	end
	render.EndBeam()
	
	local ownerpullingtrace = {}
	ownerpullingtrace.start = RealGunPos
	ownerpullingtrace.endpos = ownerpullingtrace.start + Owner:EyeAngles():Forward() * Range
	ownerpullingtrace.filter = Owner
	local PulledTrace = util.TraceLine(ownerpullingtrace)
	
	local PullDist = Owner.RadeonHookHitPos:Distance(PulledTrace.HitPos)
	
	for i=1, math.random(3,7) do
		local RandomLissen = ( RadTrace.Normal:Angle():Up() * (math.sin((CurTime()*25)+i/7)) ) + ( RadTrace.Normal:Angle():Right() * (math.cos((CurTime()*25)+i*2)) )
		render.SetMaterial( elecmat )
		render.StartBeam( LenAmt )
		render.AddBeam( RealGunPos, 0, 0, Color( 255,0,25,255 ) )
		for s=1, LenAmt do
			local PullApproach = math.sin((math.pi/LenAmt) * s)
			local NormalPull = ( (RandomLissen*(1-(Anti_Stability/100))*(20+math.cos((CurTime()*35)+s*25)*Stability/10) ) * math.sin(i) ) * ((5+Anti_Stability)/100) * (PullApproach*3)
			local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos)
			
			render.AddBeam( LerpPosition + NormalPull , (math.random(1,8)/1) * (PullApproach^2)*2, s, Color( 255,math.random(5,100)+200*(Anti_Stability/100),math.random(25,200)+50*(Anti_Stability/100),100 ))
		end
		render.EndBeam()
		end
	
	-- if Owner == LocalPlayer() and (NewEntity.MaxPullDist and NewEntity.WeaponHooking) then 
		-- net.Start( "newsoldier_radeon_grapple_shared" )
			-- net.WriteEntity( ply )
			-- net.WriteBool( ply.WeaponHooking )
			-- net.WriteVector( ply.RadeonHookHitPos )
			-- net.WriteFloat( ply.MaxPullDist )
		-- net.SendToServer()
	-- end
	
end


