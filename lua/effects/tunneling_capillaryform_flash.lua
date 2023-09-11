function EFFECT:Init( data )
	
	local vOffset = data:GetOrigin()
	local vMagnitude = data:GetMagnitude()
	local vAmount = data:GetRadius()
	local vDirection = data:GetNormal()
	
	vAmount = math.Clamp( vAmount, 0.1, 3 )
	Emitter = ParticleEmitter( vOffset )
	
	local RandPos = vOffset + (VectorRand() * 3) * vAmount
	
	for i=1, math.Round(math.random( 3 , 8 ) * vAmount) do
		local particle = Emitter:Add( "sprites/physg_glow1" , vOffset + (VectorRand() * 6) * vAmount ) -- Create a new particle at pos
		if ( particle ) then
			particle:SetDieTime( math.random( 12 , 50 ) / 200 )
			
			particle:SetStartAlpha( 220 )
			particle:SetEndAlpha( 0 )
			
			particle:SetStartSize( math.random( 30 , 90 ) * (vMagnitude ^ 0.5) )
			particle:SetEndSize( 0 )
			
			particle:SetColor( math.random( 10 , 60 ) * vMagnitude, math.random( 70 , 255 ), math.random( 50 , 190 ) )
			
			particle:SetGravity( Vector( 0 , 0 , 0 ) )
			particle:SetVelocity( Vector( 0 , 0 , 0 ) )
		end
	end
	
	local energy_points = math.random(6,10)+math.Round(vAmount)
	local point_type = "sprites/light_ignorez"
	
	for i=1, energy_points do
		
		if i > (energy_points/2) then
			point_type = "effects/spark_noz"
			point_size = 4
		else
			point_type = "sprites/glow04_noz"
			point_size = 30
		end
		
		local part = Emitter:Add( point_type , RandPos + (VectorRand() * (vMagnitude ^ 0.5) * math.random(10,15)) ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(10,100) / 100 ) )
			
			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 0 )
			
			part:SetColor( math.Clamp(vAmount*math.random(10,60),0,255), math.Clamp(vAmount*math.random(70,255),0,255), math.Clamp(vAmount*math.random(50,190),0,255) )
			
			part:SetGravity( Vector( 0 , 0 , math.random(-800,-50) ) )
			part:SetVelocity( ((vDirection * math.Rand(150, 200)) * vAmount) + (VectorRand() * vAmount * math.Rand(40, 50)) )
			
			part.amt = i
			
			if i > (energy_points/2) then
				part:SetStartSize( math.Rand(1,2) * vAmount * point_size )
				part:SetEndSize( 0 )
				part:SetStartLength( math.Rand(1,3) * vAmount * point_size )
				part:SetEndLength( 0 )
			else
				part:SetStartSize( math.Rand(2,3) * vAmount * point_size )
				part:SetEndSize( 0 )
			end
			
			part:SetBounce( math.Rand(0.1,0.5) )
			part:SetAirResistance( math.Rand(0.1,0.5) / vAmount )
			part:SetCollide( true )
			
			part:SetNextThink( CurTime() )
			part:SetThinkFunction( function()
				
				part:SetVelocity( (part:GetVelocity()*math.Rand(0.9,1.1)) + (VectorRand() * math.random(5,110) * vAmount) )
				
				if part.amt > (energy_points/2) then
					part:SetStartSize( math.Rand(1,2) * vAmount * point_size )
				else
					part:SetStartSize( math.Rand(1,3) * vAmount * point_size )
				end
				
				part:SetNextThink( CurTime()+0.05 )
			end)
			
		end
	end
	
	Emitter:Finish()
	
end

function EFFECT:Think()
	return false
end

function EFFECT:Render()
end