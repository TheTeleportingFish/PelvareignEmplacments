

function EFFECT:Init( data )
	self.Life = CurTime() + 0.01
	
	selfPos = data:GetStart()
	TargetDirection = data:GetStart() + data:GetOrigin()
	Target = data:GetEntity()
	MegaAmp = data:GetMagnitude() or 1
	ChaoticArc = data:GetScale() or 0
	
	self:SetPos(selfPos)
	
	HitPos = TargetDirection
	
	if Target:IsWorld() then 
		Target = nil  
	else
		if IsValid(Target) then
			HitPos = Target:WorldSpaceCenter()
		end
	end
	
	MegaAmp = math.Clamp( MegaAmp , 0 , 120 )
	HitPos = HitPos + ( VectorRand() * 2 )
	
	HitDistance = selfPos:Distance(TargetDirection)
	HitDirection = (TargetDirection-selfPos):GetNormalized()
	
	CheckHitArc = util.TraceLine( {
		start = selfPos,
		endpos = TargetDirection,
		collisiongroup = COLLISION_GROUP_DEBRIS
	} )
	
	RememberStartPos = HitPos
	RememberPos = CheckHitArc.HitPos
	RememberBeamQuality = math.random(1,1+math.Round(MegaAmp/30))
	
	StrikeWidth = 0.05 + (MegaAmp^0.9)
	Branches = math.random(1,3)
	BeamDepth = 20
	
	if MegaAmp < 25 then
		util.Decal( "FadingScorch", CheckHitArc.StartPos, CheckHitArc.StartPos + (HitDirection * HitDistance) )
		util.Decal( "RedGlowFade", CheckHitArc.StartPos, CheckHitArc.StartPos + (HitDirection * HitDistance) )
	 else
		util.Decal( "Scorch", CheckHitArc.StartPos, CheckHitArc.StartPos + (HitDirection * HitDistance) )
		util.Decal( "RedGlowFade", CheckHitArc.StartPos, CheckHitArc.StartPos + (HitDirection * HitDistance) )
	 end
	 
	 if ChaoticArc == 1 then
		RandomLeanSuggestion = math.random(-3,3)/10
		RandomPullSuggestion = math.random(45,75)*(MegaAmp/120)
	else
		RandomLeanSuggestion = math.random(-10,10)/(10 + (MegaAmp/10))
		RandomPullSuggestion = math.random(5,35)/(10 + (MegaAmp/10))
	end
	
end

function EFFECT:Think()
	if CurTime() > self.Life then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	B_P_Table = {}
	
	for w=1, RememberBeamQuality do
		local RandomLean = (VectorRand() * RandomLeanSuggestion) * StrikeWidth
		local BEAM_DIR = (RememberPos - selfPos):GetNormalized()
		for k=1, BeamDepth do
			BEAM_DIR = ( (BEAM_DIR + RandomLean) + (VectorRand() * RandomPullSuggestion) )
			local BeamPlacement = LerpVector( k/BeamDepth , selfPos + BEAM_DIR, RememberPos )
			table.insert(B_P_Table,k,BeamPlacement)
		end
	end
	
	local DieTime = 0.05 + ((MegaAmp/120)*0.425)
	if ChaoticArc != 1 then
		local dlight = DynamicLight( LocalPlayer():EntIndex() )
		if ( dlight ) then
			dlight.pos = selfPos + (HitDirection * HitDistance/2)
			dlight.r = ((MegaAmp/120)*90) + 10
			dlight.g = ((MegaAmp/120)*110) + 10
			dlight.b = 255
			dlight.brightness = ((MegaAmp/120)*5) + 2
			dlight.Decay = 500 / DieTime
			dlight.Size = ((MegaAmp/120)*900) + 500
			dlight.DieTime = CurTime() + DieTime
		end
	end
	
	if CheckHitArc.Hit and CheckHitArc.Entity != Target then
		local pos = CheckHitArc.HitPos
		local Emitter = ParticleEmitter( pos )
		
		local effectdata = EffectData()
		effectdata:SetOrigin( CheckHitArc.HitPos - CheckHitArc.HitNormal )
		effectdata:SetNormal( CheckHitArc.HitNormal )
		effectdata:SetMagnitude( (MegaAmp/130) * 25 )
		effectdata:SetScale( 1 )
		effectdata:SetRadius( (MegaAmp/130) * 10 )
		util.Effect( "Sparks", effectdata )
		
		sound.Play( Sound("main/explodeair0_1.wav"), CheckHitArc.HitPos , 90, math.random(130,150), (MegaAmp/130) ^ 2 ) 
		
		for i=1, 5 do
			local part = Emitter:Add( "sprites/physg_glow1" , pos ) -- Create a new particle at pos
			if ( part ) then
				part:SetDieTime( (math.random(50,80)/10) / i )
				
				part:SetStartAlpha( 120 )
				part:SetEndAlpha( 0 )
				
				part:SetStartSize( ( 50 - (i*5) ) * (MegaAmp/20) )
				part:SetEndSize( 0 )
				
				part:SetColor( 255, (i*50), (i*35) )
				
				part:SetGravity( Vector( 0 , 0 , 0 ) )
				part:SetVelocity( Vector( 0 , 0 , 0 ) )
			end
		end
		
		for i=1, math.random(3,8) + (MegaAmp/10) do
			local part = Emitter:Add( "sprites/physg_glow1" , pos ) -- Create a new particle at pos
			if ( part ) then
				part:SetDieTime( ( math.random(30,250) / 100 ) )
				
				part:SetStartAlpha( 255 )
				part:SetEndAlpha( 0 )
				
				part:SetStartSize( (math.random(25,250)/100) + (MegaAmp/5) )
				part:SetEndSize( 0 )
				
				part:SetColor( 255, math.random(50,150), 0 )
				
				part:SetGravity( Vector( 0 , 0 , -600 ) )
				part:SetVelocity( (CheckHitArc.HitNormal * math.random(20, 1220)) + (VectorRand() * math.random(50, 120)) )
			end
		end
		
		Emitter:Finish()
	end
	
	local BeamedMat = Material( "effects/beam_generic01" )
	render.SetMaterial( BeamedMat )
	
	for w=1, RememberBeamQuality do
		
		render.SetMaterial( BeamedMat )
		render.StartBeam( BeamDepth )
		render.AddBeam( selfPos , StrikeWidth, 0, Color( 80,100,255,250 ) )
		for Key, Value in ipairs(B_P_Table) do
			local k = Key
			local BeamPlacement = Value
			render.AddBeam( BeamPlacement , StrikeWidth-(k/BeamDepth)*(StrikeWidth/1.25), k, Color( 80,100,255,250 ))
		end
		render.EndBeam()
		
		-- for i=1, Branches do
			-- local AttachPos = B_P_Table[ math.random( #B_P_Table * 0.8 ) ]
			-- local EndPos = ( VectorRand() * math.random(-StrikeWidth*2,StrikeWidth*2) )
			-- local RandomLean = (VectorRand() * 0.15) * StrikeWidth
			-- local BranchDepth = 22+math.Round(MegaAmp/30)
			-- local BEAM_DIR = VectorRand()
			
			-- render.SetMaterial( BeamedMat )
			-- render.StartBeam( BeamDepth )
			-- render.AddBeam( AttachPos, StrikeWidth, 0, Color( 255,255,255,20 ) )
			-- for s=1, BranchDepth do
				-- BEAM_DIR = ( (BEAM_DIR + RandomLean) + ( VectorRand() * math.random(0.1,0.4) * StrikeWidth ) )
				-- render.AddBeam( LerpVector( s/BranchDepth , AttachPos  , AttachPos + BEAM_DIR )  , StrikeWidth-(s/BranchDepth)*StrikeWidth, s, Color( 255,255,255,120 ))
			-- end
			-- render.EndBeam()
		-- end
		
	end
	
	for w=1, RememberBeamQuality do
		
		render.SetMaterial( BeamedMat )
		render.StartBeam( BeamDepth )
		render.AddBeam( selfPos , StrikeWidth/2, 0, Color( 255,255,255,255 ) )
		for Key, Value in ipairs(B_P_Table) do
			local k = Key
			local BeamPlacement = Value
			render.AddBeam( BeamPlacement , (StrikeWidth-(k/BeamDepth)*(StrikeWidth/1.25))/3, k, Color( 255,255,255,255 ))
		end
		render.EndBeam()
		
	end
	
end