
function EFFECT:Init( data )
	self.Life = CurTime()
	
	local Rand_Energy_Transfer = math.Rand(0.9,1.7)
	
	Position = data:GetOrigin()
	Power = math.Clamp( data:GetRadius() * Rand_Energy_Transfer , 1 , 10 )
	Magnitude = math.Clamp( (data:GetMagnitude() ^ 0.5) * Rand_Energy_Transfer , 1 , 1000 )
	Direction = data:GetNormal()
	
	Direction_Vector = Direction * Magnitude
	FragmentSize = (Magnitude * Power) ^ 0.5
	
	util.Decal( "FadingScorch", Position, Position - Direction_Vector )
	util.Decal( "RedGlowFade", Position, Position - Direction_Vector )
end

function EFFECT:Think()
	if CurTime() > self.Life then
		return false
	else
		return true
	end
end

function EFFECT:Render()
	local Emitter = ParticleEmitter( Position )
	
	for i=1, 5 do
		local part = Emitter:Add( "sprites/glow04_noz_gmod" , Position ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( (math.random(50,80)/50) / i )
			
			part:SetStartAlpha( 120 )
			part:SetEndAlpha( 0 )
			
			part:SetStartSize( ( 50 - (i*5) ) * (Power/5) )
			part:SetEndSize( 0 )
			
			part:SetColor( 255, (i*75), (i*35) )
			
			part:SetGravity( Vector( 0 , 0 , 0 ) )
			part:SetVelocity( Vector( 0 , 0 , 0 ) )
		end
	end
	
	for i=1, math.random(2,6) do
		local part = Emitter:Add( "sprites/heatwave" , Position + (VectorRand() * math.Rand(4, 5) * FragmentSize) ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(35,50) / 200 ) )
			
			part:SetStartAlpha( 1 )
			part:SetEndAlpha( 0 )
			
			part:SetStartSize( (math.Rand(10,15) * FragmentSize) )
			part:SetEndSize( FragmentSize )
			
			part:SetColor( 255, 255, 255 )
			
			part:SetGravity( Vector( 0 , 0 , 200*FragmentSize ) )
			part:SetVelocity( Direction_Vector + (VectorRand() * math.Rand(1, 5)) * FragmentSize )
		end
	end
	
	for i=1, math.random(1,5)+math.Round(Power) do
		local part = Emitter:Add( "sprites/glow04_noz_gmod" , Position ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(5,100) / 150 ) )
			
			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 100 )
			
			part:SetColor( 255, math.Clamp(Power*math.random(90,150),0,255), math.Clamp(Power*math.random(50,90),0,255) )
			
			part:SetGravity( Vector( 0 , 0 , -600 ) )
			part:SetVelocity( ((Direction_Vector * math.Rand(1, 25)) * Power) + (VectorRand() * Magnitude * math.Rand(1, 5)) )
			
			part:SetStartSize( math.Rand(1,3) * FragmentSize )
			part:SetEndSize( 0 )
			
			part:SetBounce( math.Rand(0.25,1) )
			part:SetAirResistance( math.random(200,400) / FragmentSize )
			part:SetCollide( true )
		end
	end

	for s=1, math.random(5,10)+math.Round(Power) do
		local part = Emitter:Add( "effects/spark_noz" , Position ) -- Create a new particle at pos
		if ( part ) then
			part:SetDieTime( ( math.random(5,100) / 100 ) )
			
			part:SetStartAlpha( 255 )
			part:SetEndAlpha( 100 )
			
			part:SetColor( 255, math.Clamp(Power*math.random(75,125),0,255), math.Clamp(Power*math.random(15,75),0,255) )
			
			part:SetGravity( Vector( 0 , 0 , -600 ) )
			part:SetVelocity( ((Direction_Vector * math.Rand(1, 25)) * Power) + (VectorRand() * Magnitude * math.Rand(1, 5)) )
			
			part:SetStartSize( math.Rand(0.75,1.30) * FragmentSize )
			part:SetStartLength( FragmentSize * 2 )
			part:SetEndSize( 0 )
			part:SetEndLength( FragmentSize )
			
			part:SetBounce( math.Rand(0.25,1) )
			part:SetAirResistance( math.random(150,300) / FragmentSize )
			part:SetCollide( true )
		end
	end
	
end


