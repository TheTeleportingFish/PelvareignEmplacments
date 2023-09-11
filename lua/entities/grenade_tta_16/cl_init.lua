include("shared.lua")

	local cablemat = Material( "cable/physbeam" )
	local elecmat = Material( "cable/blue_elec" )
	local redmat = Material( "cable/redlaser" )

function ENT:Draw()
	
	cam.Start3D()
	
	local DistFromEntToMeters = ( LocalPlayer():WorldSpaceCenter():Distance(self:WorldSpaceCenter()) / 52.4934 )
	
	if DistFromEntToMeters < 20 and DistFromEntToMeters > 1.5 then
	
		local Pos = LocalPlayer():GetEyeTrace().HitPos
		local LookDist = ( self:WorldSpaceCenter():Distance(Pos) / 52.4934 )
		if LookDist < 2 then
			render.SetColorMaterial()
			for i=1,10 do
				render.DrawSphere( self:WorldSpaceCenter(), ((math.cos( CurTime() * 2 ) * 0.25) + 1) * ((i * 52.4934)/15) , 20, 20, Color( 255-(i^2.5), 255, 255-(i^2.5), 20 ) )
			end
			
			local Angle = Angle( 0, EyeAngles().y, 0 )
			local Pos = self:WorldSpaceCenter() + Vector( 0, 0, (math.cos( CurTime() * 2 ) * (0.125 * 52.4934)) + (0.85 * 52.4934) )
			
			Angle:RotateAroundAxis( Angle:Up(), -90 )
			Angle:RotateAroundAxis( Angle:Forward(), 90 - (30 * math.cos( CurTime() * 4 )) )
			
			cam.Start3D2D( Pos , Angle, 0.25 )
				local text = "1 - 25 Meter Kill Zone"
				surface.SetFont( "Default" )
				local tW, tH = surface.GetTextSize( text )

				local pad = 10

				surface.SetDrawColor( 0, 0, 0, 200 )
				surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )
				surface.SetDrawColor( 0, 150, 255, 50 )
				pad = pad - 2
				surface.DrawRect( -tW / 2 - pad, -pad, tW + pad * 2, tH + pad * 2 )

				draw.SimpleText( text, "Default", -tW / 2, 0, Color( 200, 150, 255, 200 ) )
				draw.SimpleText( text, "Default", -tW / 2, -2, Color( 255, 255, 255, 255 ) )
			cam.End3D2D()
			
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
		local Pos = self:WorldSpaceCenter() + self:GetUp()*5
			
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
		EmitSound( "main/airshockwave.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^0.7, 120, 0, 300)
		EmitSound( "ambient/explosions/explode_4.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist/3, 120, 0, math.random(200,230))
	end )
	
end

