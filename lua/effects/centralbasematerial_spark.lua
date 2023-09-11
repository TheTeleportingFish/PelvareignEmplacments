EFFECT.Blunt = 0

function EFFECT:Init( data )
	vOffset = data:GetOrigin()
	vMagnitude = data:GetMagnitude()
	vDirection = data:GetNormal()
	self.Blunt = data:GetScale() 
	
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
	
	self.Emitter = ParticleEmitter( vOffset )
	if self.Blunt == 1 then
		if ( self.Emitter ) then
			local particle = self.Emitter:Add( "particle/smokesprites_0003" , vOffset + (VectorRand() * 20) ) -- Create a new particle at pos
			local SmokeCol = math.random( 100 , 155 )
			if ( particle ) then
				particle:SetDieTime( math.random( 22 , 150 ) / 100 )
				
				particle:SetStartAlpha( 220 )
				particle:SetEndAlpha( 0 )
				
				particle:SetStartSize( math.random( 1 , 3 ) + (vMagnitude*5) )
				particle:SetEndSize( math.random( 9 , 10 ) + (vMagnitude*5) )
				
				particle:SetColor( SmokeCol , SmokeCol , SmokeCol )
				
				particle:SetGravity( Vector( 0 , -8.3 , 0 ) )
				particle:SetVelocity( Vector( 0 , 0 , 0 ) )
			end
			
		end
		
		sound.Play( "physics/metal/metal_box_impact_hard"..math.random(1,3)..".wav", vOffset , 80, math.random(30,90), 0.9 )
		sound.Play( "central_base_material/cbmarmor_shed_"..math.random(1,3)..".mp3", vOffset , 90, math.random(60,80), 0.5 ) 
	
	elseif self.Blunt == 0 then
		
		sound.Play( "central_base_material/cbmarmor_hitnone_"..math.random(1,3)..".mp3", vOffset , 90, math.random(130,240), 0.6 ) 
		
		if vMagnitude > 0.06 then
			sound.Play( "central_base_material/infantryarmor_hit"..math.random(2,3)..".mp3", vOffset , 60, math.random(130,240), vMagnitude * 0.2 ) 
		end
		
		local effectdata = EffectData()
		effectdata:SetOrigin( vOffset + (VectorRand() * math.random(-0.8,0.8)) )
		effectdata:SetNormal( AngleRand():Forward() )
		effectdata:SetMagnitude( (math.random( 50 , 170 ) / 100) * vMagnitude )
		effectdata:SetRadius( (math.random( 10 , 20 ) / 10) )
		util.Effect( "regular_material_spark", effectdata, true, true)
		
		if ( self.Emitter ) then
			if vMagnitude > 0.1 then
				for i=1, math.random( 2 , 4 ) do
					local smoke = self.Emitter:Add( "particle/smokesprites_0003" , vOffset + (VectorRand() * 8) )
					local SmokeCol = math.random( 100 , 200 )
					if ( smoke ) then
						smoke:SetDieTime( math.Rand( 0.22 , 1.5 ) )
						
						smoke:SetStartAlpha( 130 )
						smoke:SetEndAlpha( 0 )
						
						smoke:SetStartSize( math.random( 1 , 3 ) + (vMagnitude*5) )
						smoke:SetEndSize( math.random( 9 , 10 ) + (vMagnitude*5) )
						
						smoke:SetColor( SmokeCol , SmokeCol , SmokeCol )
						
						smoke:SetGravity( Vector( 0 , -8.3 , 0 ) )
						smoke:SetVelocity( VectorRand() * 40 )
					end
				end
			end
			local particle = self.Emitter:Add( "sprites/physg_glow1" , vOffset ) -- Create a new particle at pos
			if ( particle ) then
				particle:SetDieTime( math.Rand( 0.2 , 0.8 ) )
				
				particle:SetStartAlpha( 220 )
				particle:SetEndAlpha( 0 )
				
				particle:SetStartSize( math.Rand( 9.8 , 15 ) )
				particle:SetEndSize( 0 )
				
				particle:SetColor( math.random( 190 , 230 ) , math.random( 60 , 200 ) , 60 )
				
				particle:SetGravity( Vector( 0 , 0 , 0 ) )
				particle:SetVelocity( Vector( 0 , 0 , 0 ) )
			end
		end
	end
	self.Emitter:Finish()
	
end