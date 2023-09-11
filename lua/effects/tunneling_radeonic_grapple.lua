
function EFFECT:Init( data )
	self.Life = CurTime() + 0.01
	
	PositionAttach = data:GetOrigin()
	Origin = data:GetStart()
	Owner = data:GetEntity()
	TargetIndex = data:GetMaterialIndex() or -1
	Target = ents.GetByIndex( TargetIndex ) or nil
	
	Charge = data:GetMagnitude() or 1
	Range = data:GetRadius() or 50
	Stability = data:GetScale() or 0
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

net.Receive( "Radeonic_Grapple_Effect_Extra", function( len )
	Stability = net.ReadFloat() --Read first is Stability from grapple
end)

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
	
	if PullDifference > 0.1 then
		BurnParticles = math.Round(math.random(1*PullDifference*5,3*PullDifference*5))
		BurnEnergy = 2*PullDifference*5
		if PullDifference > 0.4 then 
			sound.Play( Sound("ahee_suit/radeonicgrapple/high_heat_burn_pulse.mp3"), Owner.RadeonHookHitPos , 90, math.random(70,90), PullDifference ) 
		end
	end
	
	
	local part = Emitter:Add( "sprites/heatwave" , Owner.RadeonHookHitPos + (VectorRand() * math.random(5, 10)) ) -- Create a new particle at pos
	if ( part ) then
		part:SetDieTime( ( math.random(10,50) / 200 ) )
		
		part:SetStartAlpha( 50 )
		part:SetEndAlpha( 0 )
		
		part:SetStartSize( (math.random(3,20) * BurnEnergy) )
		part:SetEndSize( 2 * BurnEnergy )
		
		part:SetColor( 255, 255, 255 )
		
		part:SetGravity( Vector( 0 , 0 , 2000 ) )
		part:SetVelocity( (-PullVector * math.random(320, 600)) + (VectorRand() * math.random(15, 120) * BurnEnergy) )
	end
	
	
	for i=1, 5 do
		local part = Emitter:Add( "sprites/glow04_noz" , Owner.RadeonHookHitPos ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( (math.random(50,80)/200) / i )
			
			part:SetStartAlpha( 120 )
			part:SetEndAlpha( 0 )
			
			part:SetStartSize( ( 20 - (i*2) ) * BurnEnergy )
			part:SetEndSize( 0 )
			
			part:SetColor( 255, (i*75), (i*65) )
			
			part:SetGravity( Vector( 0 , 0 , 0 ) )
			part:SetVelocity( Vector( 0 , 0 , 0 ) )
		end
	end
	
	if IsValid(Target) then 
		for i=1, BurnParticles/math.random(2,6) do
			local part = Emitter:Add( "sprites/glow04_noz_gmod" , Owner.RadeonHookHitPos ) -- Create a new particle at pos
			if ( part ) then
				part:SetDieTime( ( math.random(10,100) / 90 ) )
				
				part:SetStartAlpha( 255 )
				part:SetEndAlpha( 100 )
				
				part:SetColor( 255, math.Rand(180,255), math.Rand(90,180) )
				
				part:SetGravity( Vector( 0 , 0 , -600 ) )
				part:SetVelocity( OwnerVeloSquared + (-PullVector * math.random(220, 400)) + (VectorRand() * math.random(30, 200) * BurnEnergy) )
				
				part:SetStartSize( (math.Rand(1,15)/5) * BurnEnergy )
				part:SetEndSize( 0 )
				
				part:SetAirResistance( math.random(135,250) / BurnEnergy )
				part:SetCollide( true )
			end
		end
	end
	
	local LenAmt = 35
	render.SetMaterial( elecmat )
	render.StartBeam( LenAmt )
	render.AddBeam( RealGunPos, 0, 0, Color( 255,0,0,255 ) )
	for s=1, LenAmt do
		local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		render.AddBeam( LerpPosition , math.random(0.05,2.0)*(Stability/100), s+math.cos(CurTime()*20), Color( 255,230*(Stability/100),200*(Stability/100),200*(Stability/100) ))
	end
	render.EndBeam()
	
	render.SetMaterial( elecmat )
	render.StartBeam( LenAmt )
	render.AddBeam( RealGunPos, 0, 0, Color( 255,0,0,255 ) )
	for s=1, LenAmt do
		local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		render.AddBeam( LerpPosition , 15+20*(Stability/100), s, Color( 255*(Stability/100),100*(1-(Stability/100)),500*(1-(Stability/100)),20+20*(Stability/100) ))
	end
	render.EndBeam()
	
	for s=1, LenAmt/math.random(5,12) do
		local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		local ForwardLerpPosition = LerpVector( (s+1)/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos )
		local LerpPositionVector = (ForwardLerpPosition-LerpPosition)
		local part = Emitter:Add( "effects/spark_noz" , LerpPosition + LerpPositionVector:GetNormalized() * (math.random(-1,1) * LerpPositionVector:Length()) ) -- Create a new particle at pos
		
		if ( part ) then
			part:SetDieTime( ( math.random(10,100) / 100 ) )
			
			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 100 )
			
			part:SetColor( 255, math.Clamp(BurnEnergy*math.Rand(50,125),0,255), math.Clamp(BurnEnergy*math.Rand(35,50),0,255) )
			
			part:SetGravity( Vector( 0 , 0 , -600 ) )
			part:SetVelocity( OwnerVeloSquared + (-PullVector * math.random(20, 40)) + (VectorRand() * math.random(13, 16) * BurnEnergy) )
			
			part:SetStartSize( (math.Rand(1,15)/25) * BurnEnergy )
			part:SetStartLength( (math.Rand(1,15)/25) * BurnEnergy )
			part:SetEndSize( 0 )
			part:SetEndLength( (math.Rand(1,15)/25) * BurnEnergy * 3 )
			
			part:SetBounce( math.Rand(0,1) )
			part:SetAirResistance( math.Rand(1,25) )
			part:SetCollide( true )
		end
	end
	
	local Amt_Of_Beams = 3
	for i=1, Amt_Of_Beams do
		local BeamAng_Num = (i/Amt_Of_Beams)*math.pi*2
		local RandomLissen = ( RadTrace.Normal:Angle():Up() * (math.sin(CurTime()+BeamAng_Num)) ) + ( RadTrace.Normal:Angle():Right() * (math.cos(CurTime()+BeamAng_Num)) )
		
		render.SetMaterial(elecmat)
		render.StartBeam( LenAmt )
		
		render.AddBeam(
			RealGunPos --startPos
			, 0 --width
			, 0 --textureEnd
			, Color( 255 , 0 , 0 , 255 ) --color
		)
		
		for s=1, LenAmt do
			local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)) , Owner.RadeonHookHitPos)
			render.AddBeam(
				LerpPosition + ( ((RandomLissen*math.random(2,5)) * math.sin(s) * Stability/100 ) + VectorRand()*1 ) --startPos
				, 2 --width 
				, s --textureEnd
				, Color( math.random(100,255) , math.random(5,10+Stability) , 0 , 200*(Stability/100) ) --color
			)
			
		end
		
		render.EndBeam()
	end
	
	if IsValid(Target) then 
		local ownerpullingtrace = {}
		ownerpullingtrace.start = RealGunPos
		ownerpullingtrace.endpos = ownerpullingtrace.start + Owner:EyeAngles():Forward() * Range
		ownerpullingtrace.filter = Owner
		local PulledTrace = util.TraceLine(ownerpullingtrace)
		
		local PullDist = Target:WorldSpaceCenter():Distance(PulledTrace.HitPos)
		if PullDifference > 0.5 then
			for w=1, 2 do
				render.SetMaterial( elecmat )
				render.StartBeam( LenAmt )
				render.AddBeam( RealGunPos, 0, 0, Color( 255,255,255,255 ) )
				for k=1, LenAmt do
					local LerpPosition = LerpVector( k/LenAmt , RealGunPos  + (OwnerVeloSquared*(k/3)), Owner.RadeonHookHitPos)
					render.AddBeam( LerpPosition + (VectorRand() * math.random(9,12) * (Stability/100)) , 10, k, Color( 255,255*(Stability/100),255*(Stability/100),255 ))
				end
				render.EndBeam()
			end
			
		end
		
		for i=1, 7 do
			local RandomLissen = ( RadTrace.Normal:Angle():Up() * (math.sin((CurTime()*5)+i/7)) ) + ( RadTrace.Normal:Angle():Right() * (math.cos((CurTime()*5)+i*2)) )
			render.SetMaterial( elecmat )
			render.StartBeam( LenAmt )
			render.AddBeam( RealGunPos, 0, 0, Color( 255,0,25,255 ) )
			for s=1, LenAmt do
				local PullApproach = math.sin((math.pi/LenAmt) * s)
				local NormalPull = ( (RandomLissen*(1-(Stability/100))*(20+math.cos((CurTime()*15)+s*25)*Stability/10) ) * math.sin(i) ) * (PullDifference*3) * (PullApproach*4)
				local LerpPosition = LerpVector( s/LenAmt , RealGunPos + (OwnerVeloSquared*(s/3)), Owner.RadeonHookHitPos)
				
				render.AddBeam( LerpPosition + NormalPull , (math.random(1,8)/3) * (PullApproach^2)*2, s, Color( 255,math.random(5,100)+200*(Stability/100),math.random(25,200)+50*(Stability/100),100 ))
			end
			render.EndBeam()
		end
		
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


