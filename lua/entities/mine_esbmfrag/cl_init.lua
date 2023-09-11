include("shared.lua")

	local cablemat = Material( "cable/physbeam" )
	local elecmat = Material( "cable/blue_elec" )
	local redmat = Material( "cable/redlaser" )

function ENT:Draw()
	
	cam.Start3D()
	
	local DistFromEntToMeters = ( LocalPlayer():WorldSpaceCenter():Distance(self:WorldSpaceCenter()) / 52.4934 )
	local TraceHit = self.Tracing.Hit or false
	local TraceBoolConv = ((TraceHit) and 0) or 1
	
	if DistFromEntToMeters < 20 and DistFromEntToMeters > 2.5 then
	
		local Pos = LocalPlayer():GetEyeTrace().HitPos
		local LookDist = ( self:WorldSpaceCenter():Distance(Pos) / 52.4934 )
		if LookDist < 1 then
			render.SetColorMaterial()
			render.DrawSphere( self:WorldSpaceCenter(), (10 * 52.4934) , 20, 20, Color( 255, 255, 0, 50 ) )
			render.DrawSphere( self:WorldSpaceCenter(), (4 * 52.4934) , 20, 20, Color( 255, 150, 0, 50 ) )
			render.DrawSphere( self:WorldSpaceCenter(), (1 * 52.4934) , 20, 20, Color( 255, 0, 0, 50 ) )
			
			local Angle = Angle( 0, EyeAngles().y, 0 )
			local Pos = self:WorldSpaceCenter() + Vector( 0, 0, math.cos( CurTime() / 2 ) + (10 * 52.4934) )
			
			Angle:RotateAroundAxis( Angle:Up(), -90 )
			Angle:RotateAroundAxis( Angle:Forward(), 90 )
			
			cam.Start3D2D( Pos , Angle, 1.5 )
				local text = "1 - 10 Meters = 5,000 - 1 DMG"
				surface.SetFont( "Default" )
				local tW, tH = surface.GetTextSize( text )

				local pad = 10

				surface.SetDrawColor( 100, 0, 0, 200 )
				surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )

				draw.SimpleText( text, "Default", -tW / 2, 0, color_white )
			cam.End3D2D()
			
		end
	
	end
	
	if DistFromEntToMeters < 2.5 then
	
		local StartPos = self.Tracing.StartPos
		render.SetColorMaterial()
		render.DrawLine( StartPos, StartPos - self:GetUp()*20, Color( 255, 255*self.Tracing.Fraction^2, 255*TraceBoolConv ), true )
		
		if not self.PinsOn then
			render.DrawBox( self.Tracing.HitPos, self.Tracing.HitNormal:Angle(), Vector(0,-25,-25)*(1-self.Tracing.Fraction)^0.25, Vector(0,25,25)*(1-self.Tracing.Fraction)^0.25, Color( 255, 255, 255, 200 ) )
			render.DrawSphere( self.Tracing.HitPos, 10*(1-self.Tracing.Fraction)^0.5, 8, 8, Color( 255*(self.Tracing.Fraction)^0.5, 255*(1-self.Tracing.Fraction)^0.5, 0, 255*(1-self.Tracing.Fraction)^0.5 ) )
		end
	
	end
	
	cam.End3D()
	
	self:DrawModel()
	
end

function ENT:Initialize()
	self:SetModel(self.Model) 
	
	hook.Add( "PostDrawTranslucentRenderables", self, function( bDrawingDepth, bDrawingSkybox )
	
		if bDrawingSkybox then return end
		
		local Angle = EyeAngles()
		local Pos = self:WorldSpaceCenter() + self:GetUp()*20
			
		Angle:RotateAroundAxis( Angle:Up(), -90 )
		Angle:RotateAroundAxis( Angle:Forward(), 90 )
			
		cam.Start3D2D( Pos , Angle, 1 )
		
		if self.PinsOn then
			
			if math.abs(math.sin(CurTime()*20)) > 0.5 then
				local pos,material = Vector(), Material( "sprites/light_ignorez" )
				render.SetMaterial( material )
				render.DrawSprite( pos, 20, 20, Color( 255, 255*math.abs(math.sin(CurTime())), 0 ) )
				render.DrawSprite( pos, 6, 6, Color( 255, 255, 255 ) )
			end
			
		end
		
		cam.End3D2D()
		
	end)
	
	net.Receive( "ShockwaveFunction", function( len )
		local Dist = net.ReadFloat()
		--print(Dist,Dist^2)
		EmitSound( "main/explodeair0_"..math.random(1,4).."far.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^0.25, 120, 0, 100)
		EmitSound( "main/airshockwave.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^0.5, 120, 0, 100)
		EmitSound( "main/antispatialknock_highsavor.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist, 120, 0, math.random(190,200))
		EmitSound( "ambient/explosions/explode_4.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist/3, 120, 0, math.random(200,230))
	end )
	
end

