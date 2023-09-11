
include( "includes/modules/main_management_system_utility.lua" )
include( "includes/modules/main_management_system_graphics.lua" )
include( "includes/modules/main_management_system.lua" )
include( "includes/modules/ahee_front_hud_system.lua" )
include( "includes/modules/ahee_suit_hud_material_module.lua" )
include( "includes/modules/suit_functions.lua" )

System_Mains_Tabs = {}

local LocalWarningSystem = {}
local LocalHintSystem = {}
local LocalAlertSystem = {}

if CLIENT then
	
	surface.CreateFont( "SystemPowerFont", {
		font = "TargetID", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = false,
		size = 14,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont( "SystemWarningFont", {
		font = "TargetID", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = false,
		size = 30,
		weight = 1500,
		blursize = 0,
		scanlines = 2,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
	surface.CreateFont( "SystemBatteryFont", {
		font = "TargetID", --  Use the font-name which is shown to you by your operating system Font Viewer, not the file name
		extended = false,
		size = 20,
		weight = 500,
		blursize = 0,
		scanlines = 0,
		antialias = false,
		underline = false,
		italic = false,
		strikeout = false,
		symbol = false,
		rotary = false,
		shadow = false,
		additive = false,
		outline = false,
	} )
	
end

function comma_value(amount)
	local formatted = amount
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then
			break
		end
	end
	return formatted
end

function energy_seperation( amount , readout )
	local formatted = amount
	formatted = string.len( formatted )
	readout = readout or false
	
	if formatted < 3 then
		Given = readout and "Joules" or "J"
		Division = 1
	elseif formatted > 3 and formatted < 6 then
		Given = readout and "KiloJoules" or "KJ"
		Division = 1000
	elseif formatted > 6 and formatted < 9 then
		Given = readout and "MegaJoules" or "MJ"
		Division = 1000000
	elseif formatted > 9 and formatted < 12 then
		Given = readout and "GigaJoules" or "GJ"
		Division = 1000000000
	elseif formatted > 12 and formatted < 15 then
		Given = readout and "TeraJoules" or "TJ"
		Division = 1000000000000
	elseif formatted > 15 and formatted < 18 then
		Given = readout and "PetaJoules" or "PJ"
		Division = 1000000000000000
	elseif formatted > 18 and formatted < 21 then
		Given = readout and "ExaJoules" or "EJ"
		Division = 1000000000000000000
	elseif formatted > 21 and formatted < 24 then
		Given = readout and "ZettaJoules" or "ZJ"
		Division = 1000000000000000000000
	elseif formatted > 24 then
		Given = readout and "YottaJoules" or "YJ"
		Division = 1000000000000000000000000
	else
		Given = readout and "Joules" or "J"
		Division = 1
	end
	
	return Given , Division
end

function suffix_seperation( amount , readout )
	local formatted = amount
	formatted = string.len( formatted )
	readout = readout or false
	
	if formatted > 3 then
		Given = readout and "Kilo" or "K"
	elseif formatted > 6 and formatted < 9 then
		Given = readout and "Mega" or "M"
	elseif formatted > 9 and formatted < 12 then
		Given = readout and "Giga" or "G"
	elseif formatted > 12 and formatted < 15 then
		Given = readout and "Tera" or "T"
	elseif formatted > 15 and formatted < 18 then
		Given = readout and "Peta" or "P"
	elseif formatted > 18 and formatted < 21 then
		Given = readout and "Exa" or "E"
	elseif formatted > 21 and formatted < 24 then
		Given = readout and "Zetta" or "Z"
	elseif formatted > 24 then
		Given = readout and "Yotta" or "Y"
	end
	
	return Given
end

function ThreeD_HUD_System()
	local self = LocalPlayer()
	local GlobalTargetedNpc = self:GetNWEntity( "TargetSelected" )
	
	if EntArray then
	for key, Entity in pairs(EntArray) do
		if IsValid(Entity) and Entity.InternalTagged then
			local Type = Entity.Type or "Unknown"
			local IS_ON_PSEUDO_TEAM = IsValid( self.A9_Team_List[table.KeyFromValue( self.A9_Team_List, Entity )] )
			local Distance = LocalPlayer():WorldSpaceCenter():Distance(Entity:WorldSpaceCenter())
			local DistanceOffset = (Distance / 52.4934)
			local Pos = Entity:WorldSpaceCenter() + Vector( 0, 0, -5 )
			
			local LocalAngle = Angle( 0, (self:GetPos()-Pos):Angle().y, 0 )
				
				local RectSize = 52.4934
				local pad = 5
				
				LocalAngle:RotateAroundAxis( LocalAngle:Up(), 90 )
				LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 90 )
				
			cam.IgnoreZ( true )
			cam.Start3D2D( Pos , LocalAngle, 0.4 )
				if DistanceOffset < 25 then
					local text = "Tracing : "..math.Round(DistanceOffset,1).." Meters"
					surface.SetFont( "SystemBatteryFont" )
					local tW, tH = surface.GetTextSize( text )
					
					surface.SetDrawColor( 255, 110, 100, 20 )
					surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2), tW + pad * 2, tH + pad * 2 )
					draw.SimpleText( text, "SystemBatteryFont", -(tW / 2) - (tH*5), (-tH / 2) + pad , Color( 255, 255, 255, 255 ) )
					
					local text = "Type : "..Type
					surface.SetFont( "SystemBatteryFont" )
					local tW, tH = surface.GetTextSize( text )
					
					surface.SetDrawColor( 255, 255, 255, 20 )
					surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2) + (tH*2), (tW + pad * 2), tH + pad * 2 )
					draw.SimpleText( text, "SystemBatteryFont", -(tW / 2) - (tH*5), ((-tH / 2) + pad) + (tH*2) , Color( 255, 255, 255, 255 ) )
				end
				surface.SetDrawColor( 0, 0, 0, 100 )
				surface.DrawRect( RectSize, (-RectSize*2), RectSize, RectSize )
				surface.SetDrawColor( 255, 255, 255, 20 )
				surface.DrawRect( RectSize + pad/2, (-RectSize*2) + pad/2, RectSize - pad, RectSize - pad )
				
				pad = pad*2
				
				if IS_ON_PSEUDO_TEAM then
					surface.SetDrawColor( 255, 255, 255, 100 )
					surface.SetMaterial( id_icon ) -- Use our cached material
					surface.DrawTexturedRect( RectSize + pad/2, (-RectSize*2) + 2 + pad/2, RectSize - pad, RectSize - pad ) -- Actually draw the rectangle
					
					surface.SetDrawColor( 50, 140, 255, 230 )
				else
					surface.SetDrawColor( 255, 255, 255, 230 )
					surface.SetMaterial( question_icon ) -- Use our cached material
				end
				
				surface.DrawTexturedRect( RectSize + pad/2, (-RectSize*2) + pad/2, RectSize - pad, RectSize - pad ) -- Actually draw the rectangle
				
			cam.End3D2D()
			cam.IgnoreZ( false )
			
		end
		
	end
	end
	
	for key, Entity in pairs(ents.GetAll()) do
		if IsValid(Entity) and Entity.Interactable != nil and Entity.Interactable then
			local Type = Entity.Type or "Unknown"
			local Distance = LocalPlayer():WorldSpaceCenter():Distance(Entity:WorldSpaceCenter())
			local DistanceOffset = (Distance / 52.4934)
			local Pos = Entity:WorldSpaceCenter() + Vector( 0, 0, -5 )
			local Position = ( Entity:WorldSpaceCenter() ):ToScreen() 
			
			local LocalAngle = Angle( 0, (self:GetPos()-Pos):Angle().y, 0 )
			
			local RectSize = 52.4934
			local pad = 5
			
			LocalAngle:RotateAroundAxis( LocalAngle:Up(), 90 )
			LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 90 )
			
			if DistanceOffset < 10 and DistanceOffset > 0.5 then
			cam.IgnoreZ( true )
			cam.Start3D2D( Pos , LocalAngle, 0.4 )
				if DistanceOffset < 5 then
					local text = "Estimate : "..math.Round(DistanceOffset,1).." Meters"
					surface.SetFont( "Default" )
					local tW, tH = surface.GetTextSize( text )
					
					surface.SetDrawColor( 255, 110, 100, 20 )
					surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2), tW + pad * 2, tH + pad * 2 )
					draw.SimpleText( text, "Default", -(tW / 2) - (tH*5), (-tH / 2) + pad , Color( 255, 255, 255, 255 ) )
					
					local text = "Type : "..Type
					surface.SetFont( "Default" )
					local tW, tH = surface.GetTextSize( text )
					
					surface.SetDrawColor( 255, 255, 255, 20 )
					surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2) + (tH*2), (tW + pad * 2), tH + pad * 2 )
					draw.SimpleText( text, "Default", -(tW / 2) - (tH*5), ((-tH / 2) + pad) + (tH*2) , Color( 255, 255, 255, 255 ) )
					
				end
				surface.SetDrawColor( 0, 0, 0, 100 )
				surface.DrawRect( (-RectSize/2), (-RectSize*2), RectSize, RectSize )
				surface.SetDrawColor( 255, 255, 255, 20 )
				surface.DrawRect( (-RectSize/2) + pad/2, (-RectSize*2) + pad/2, RectSize - pad, RectSize - pad )
				
				pad = pad*2
				
				surface.SetDrawColor( 255, 255, 255, 230 )
				surface.SetMaterial( hand_grab ) -- Use our cached material
				surface.DrawTexturedRect( (-RectSize/2) + pad/2, (-RectSize*2) + pad/2, RectSize - pad, RectSize - pad ) -- Actually draw the rectangle
				
				draw.DrawText( "Interact" , "GModNotify", 0 , RectSize , Color( 255, 255, 255, 200 ), TEXT_ALIGN_CENTER )
				
			cam.End3D2D()
			cam.IgnoreZ( false )
			end
			
		end
	end
	
	if IsValid(GlobalTargetedNpc) then
	
		local DistanceVector = ( LocalPlayer():WorldSpaceCenter()-GlobalTargetedNpc:WorldSpaceCenter() )
		local DistanceXY = Vector( DistanceVector.x , DistanceVector.y , 0 ):Length() / 52.4934 
		local DistanceHeight = DistanceVector.z / 52.4934 
		
		local Angled = Angle( 0, (self:GetPos()-GlobalTargetedNpc:GetPos()):Angle().y, 0 )
		local Pos = (GlobalTargetedNpc:WorldSpaceCenter() - Vector(0,0,GlobalTargetedNpc:WorldSpaceCenter().z)) + Vector(0,0,self:WorldSpaceCenter().z) + Vector( 0, 0, -5 )
		local DistanceOffset = (DistanceXY * 52.4934)
		
		Angled:RotateAroundAxis( Angled:Up(), 90 )
			
			local RectSize = 52.4934
			local Padding = 5
			local FullRectSize = (RectSize+Padding)
			
			local AmountOfRects = (DistanceOffset / (FullRectSize))
			surface.SetDrawColor( 255, 255, 255, 50 )
			
		cam.Start3D2D( Pos , Angled, 0.5 )
			
			for i=0, math.floor(AmountOfRects) do
				surface.DrawRect( -RectSize/4 , ((i*FullRectSize) + DistanceOffset) - FullRectSize, RectSize/2 , RectSize )
			end
			
		cam.End3D2D()
		
			local pad = 5
			
			local LocalAngle = Angle( 0, (self:GetPos()-Pos):Angle().y, 0 )
			local SetPos = Pos + ( LocalAngle:Forward() * ((DistanceOffset)-RectSize*2) )
			
			LocalAngle:RotateAroundAxis( LocalAngle:Up(), 90 )
			LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 45 )
			
		cam.Start3D2D( SetPos , LocalAngle, 0.5 )
			
			local text = "Dist : "..math.Round(DistanceXY).." Meters"
			surface.SetFont( "SystemBatteryFont" )
			local tW, tH = surface.GetTextSize( text )
			
			surface.SetDrawColor( 0, 0, 0, 150 )
			surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2), tW + pad * 2, tH + pad * 2 )
			draw.SimpleText( text, "SystemBatteryFont", -(tW / 2) - (tH*5), (-tH / 2) + pad , Color( 255, 255, 255, 250 ) )
			
			local text = "Height : "..math.Round(-DistanceHeight).." Meters"
			surface.SetFont( "SystemBatteryFont" )
			local tW, tH = surface.GetTextSize( text )
			
			surface.SetDrawColor( 0, 0, 0, 150 )
			surface.DrawRect( (-(tW / 2)) - pad - (tH*5), (-tH / 2) + (tH*2), (tW + pad * 2), tH + pad * 2 )
			draw.SimpleText( text, "SystemBatteryFont", -(tW / 2) - (tH*5), ((-tH / 2) + pad) + (tH*2), Color( 255, 255, 255, 250 ) )
			
		cam.End3D2D()
		
		cam.Start3D()
		
			local Counts = 5
			
			for i=0, math.floor((DistanceXY*2)/Counts) do
				local text = math.Round(i*Counts).." M"
				local tW, tH = surface.GetTextSize( text )
				local LocalAngle = Angle( 0, (self:GetPos()-Pos):Angle().y, 0 )
				local SetPos = Pos + (( LocalAngle:Forward() * (i*RectSize) )*Counts)
				
				LocalAngle:RotateAroundAxis( LocalAngle:Up(), 90 )
				LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 45 )
				
				cam.Start3D2D( SetPos , LocalAngle, 0.5 )
					draw.SimpleText( text, "SystemBatteryFont", Padding + (tW / 2), (-tH / 2) , Color( 255, 255, 255, 250 ) )
				cam.End3D2D()
			end
		
		cam.End3D()
	end
	
end

local TychronicVisionThrottle = 0
ZoomKeyToggled = false
MWheel_Input = 0
MouseScrollAnimation_Num = 0
MouseScrollAnimation_Desired = 0

function Suit_Zoom_Function()
	local self = LocalPlayer()
	
	local Key_Up_Input = input.IsKeyDown( KEY_UP ) and 1 or 0
	local Key_Down_Input = input.IsKeyDown( KEY_DOWN ) and 1 or 0
	local Key_Input = ( Key_Up_Input - Key_Down_Input )
	
	MouseScrollAnimation_Num = MouseScrollAnimation_Num or 0
	MouseScrollAnimation_Desired = MouseScrollAnimation_Desired or 0
	ZoomKeyToggled = ZoomKeyToggled or false
	
	if input.IsKeyDown( KEY_LALT ) then
		MWheel_Input = math.Clamp( (MWheel_Input*0.95) + (Key_Input*1.5) * RealFrameTime() , -3 , 3 )
		
		if not ZoomKeyToggled then 
			ZoomKeyToggled = true
			EmitSound( "main/mechanism_borcheltick.wav", Vector(), -1, CHAN_STATIC, 0.5, 0, 0, 60 )
		end
	else
		MWheel_Input = 0
		
		if ZoomKeyToggled then 
			ZoomKeyToggled = false
			EmitSound( "main/mechanism_borcheltick.wav", Vector(), -1, CHAN_STATIC, 0.8, 0, 0, 60 )
		end
	end
	
	if math.Round(MouseScrollAnimation_Desired,1) != math.Round(MouseScrollAnimation_Num,1) then
		EmitSound( "main/target_tick.wav", Vector(), -1, CHAN_STATIC, 0.1, 0, 0, 90+(math.abs(MWheel_Input*20)) )
	end
	
end

function PelvareignSecondPersonCalc( ply, pos, angles, fov )
	MouseScrollAnimation_Num = MouseScrollAnimation_Num or 0
	MouseScrollAnimation_Desired = MouseScrollAnimation_Desired or 0
	
	local AimedNumber = (MouseScrollAnimation_Desired - MouseScrollAnimation_Num)
	
	MouseScrollAnimation_Desired = math.Clamp( MouseScrollAnimation_Desired + MWheel_Input / 5 , 0 , 10 )
	MouseScrollAnimation_Num = math.Clamp( MouseScrollAnimation_Num + (AimedNumber * 0.25)  , 0 , 10 )
	
	if ply.AHEEMENU_ISOPEN then
		Rotate = Rotate and (Rotate+RealFrameTime()) or 0
		local Angled = Angle( math.sin(Rotate/3)*25 , Rotate*25 , 0 )
		view = {
			angles = Angled,
			origin = pos - ( Angled:Forward() * 100 ) + ( Angled:Up() * math.sin(Rotate/3) * 15 ),
			fov = fov * math.Clamp( 1 - ( MouseScrollAnimation_Num * 0.09 ) , 0.1 , 1 ),
			drawviewer = true
		}
		
	else
		view = {
			origin = pos,
			angles = angles,
			fov = fov * math.Clamp( 1 - ( MouseScrollAnimation_Num * 0.09 ) , 0.1 , 1 ),
			drawviewer = false
		}
		
	end
	
	return view
end 

function AHEE_HUD_System()
	local self = LocalPlayer()
	
	if not self:GetNWBool("AHEE_EQUIPED") then return end
	
	local GlobalTargetedNpc = self:GetNWEntity( "TargetSelected" )
	
	local FrameSizeW = ScrW() / 5
	local FrameSizeH = ScrH() / 5
	
	local TychronicVisionBool = self.TycronicVision and 1 or -1
	TychronicVisionThrottle = math.Clamp( TychronicVisionThrottle + ((TychronicVisionBool - TychronicVisionThrottle) * 0.1) , 0 , 1 ) or 0
	local ThrottleAffect = (self.TychronicInverterThrottle / 2500)
	
	surface.SetMaterial( LinedVision )
	surface.SetDrawColor( 255, 255, 255, 50 + (150 * ThrottleAffect) )
	surface.DrawTexturedRect( 0, 0, ScrW() , ScrH()  )
	
	surface.SetMaterial( OutlinedVision )
	surface.SetDrawColor( 255, 255, 255, 225 )
	surface.DrawTexturedRect( 0, 0, ScrW() , ScrH()  )
	
	local blurMat = Material("pp/blurscreen")
	surface.SetDrawColor(255,255,255,255)
	surface.SetMaterial(blurMat)
	
	blurMat:SetFloat("$blur",0.5)
	blurMat:Recompute()
	render.UpdateScreenEffectTexture()
	surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
	
	local Sys_Tack = self.System_Tacks 
	local Radeonic_Tack = Sys_Tack.Radeonic_Tack
	
	if Radeonic_Tack.System_Internal_Switch then
		
		if self.Fraise_Stable then
			local Fraise_Stable_Val = self.Fraise_Stability / 100
			
			local colorAddMat = Material("pp/blurx")
			colorAddMat:SetFloat("$size", ((math.abs(math.sin(math.Rand(0.1,0.3)+SysTime()*2))^6)*1) * Fraise_Stable_Val )
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(colorAddMat)
			colorAddMat:Recompute()
			surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
			
			local colorBlur = Material("pp/colour")
			colorBlur:SetFloat("$pp_colour_brightness", (0.0001+math.Rand(0.01,0.3)*(1-Fraise_Stable_Val)) * Fraise_Stable_Val )
			colorBlur:SetFloat("$pp_colour_contrast", (3+math.abs(math.sin(math.Rand(0.08,0.1)+SysTime()*0.1))*0.5) * Fraise_Stable_Val )
			colorBlur:SetFloat("$pp_colour_mulr", (math.abs(math.cos(math.Rand(0.01,0.1)+SysTime()*0.3))*0.1) * Fraise_Stable_Val )
			colorBlur:SetFloat("$pp_colour_mulg", (math.abs(math.cos(math.Rand(0.01,0.1)+SysTime()*0.3))*0.1) * Fraise_Stable_Val )
			colorBlur:SetFloat("$pp_colour_mulb", (math.abs(math.sin(math.Rand(0.01,0.1)+SysTime()*0.3))*3) * Fraise_Stable_Val )
			colorBlur:SetFloat("$pp_colour_addg", (-0.2 * Fraise_Stable_Val) )
			colorBlur:SetFloat("$pp_colour_addr", (0.4 * (1-Fraise_Stable_Val)) + (-0.4 * Fraise_Stable_Val) )
			
			surface.SetDrawColor(255,255,255,255)
			surface.SetMaterial(colorBlur)
			colorBlur:Recompute()
			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
			
			self.Fraise_LastOrder_Self = CreateSound( self , "ahee_suit/fraise/fraise_lastorder_magnituderush.mp3" )
			self.Fraise_LastOrder_Self:SetSoundLevel( 0 )
			self.Fraise_LastOrder_Self:SetDSP( 1 )
			self.Fraise_LastOrder_Self:PlayEx( 0.9, 100 )
			
		end
		
		self.Radeonic_Tack_Noise = CreateSound( self , "ahee_suit/ahee_tack_system_radeonic_low.mp3" )
		self.Radeonic_Tack_Noise:SetSoundLevel( 0 )
		self.Radeonic_Tack_Noise:SetDSP( 0 )
		self.Radeonic_Tack_Noise:PlayEx( 0.6, 100 )
		
		local colorMat = Material("pp/bloom")
		colorMat:SetFloat("$levelg",0.3)
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(colorMat)
		colorMat:Recompute()
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
		
		for Key, Ent in ipairs(ents.GetAll()) do
			local SpecialCase = string.match( tostring(Ent) , "bone" ) or string.match( tostring(Ent) , "C_" ) or string.match( tostring(Ent) , "CLuaEffect" )
			if not Ent:IsWorld() and Ent:GetParent() != Ent and not SpecialCase then
			
			cam.Start2D()
				local Ent_Screen_Pos = Ent:GetPos():ToScreen()
				local material = Material( "sprites/glow04_noz_gmod" )
				
				surface.SetMaterial( material )
				surface.SetDrawColor(255,255,255,math.random(15,122))
				surface.DrawTexturedRectRotated( Ent_Screen_Pos.x, Ent_Screen_Pos.y, math.Rand(2,8)*ScrH()*0.008, math.Rand(1,5)*ScrH()*0.008, math.random(-360,360) )
				
				if Ent.Radeonic != nil then
					material = Material( "effects/energy_impact4_nocolor" )
					surface.SetMaterial( material )
					surface.SetDrawColor(255,0,0,math.random(50,85))
					surface.DrawTexturedRectRotated( Ent_Screen_Pos.x, Ent_Screen_Pos.y, math.Rand(2,8)*ScrH()*0.02, math.Rand(1,5)*ScrH()*0.02, math.random(-360,360) )
				end
			cam.End2D()
			
			cam.Start3D()
				
				render.SetColorMaterial()
				Ent:DrawModel()
				
			cam.End3D()
			
			end
		end
		
		render.UpdateScreenEffectTexture()
		
	else
		
		if self.Radeonic_Tack_Noise and self.Radeonic_Tack_Noise:IsPlaying() then 
			self.Radeonic_Tack_Noise:Stop()
		elseif self.Fraise_LastOrder_Self and self.Fraise_LastOrder_Self:IsPlaying() then 
			self.Fraise_LastOrder_Self:Stop() 
		end
		
	end
	
	if self.TycronicVision then
		
		self.TychronicVisionNoise = CreateSound( self , "ahee_suit/light_charge_radiation.mp3" )
		self.TychronicVisionNoise:SetSoundLevel( 0 )
		self.TychronicVisionNoise:SetDSP( 0 )
		self.TychronicVisionNoise:PlayEx( ThrottleAffect, 100 )
		
		local brightMat = Material("pp/colour")
		brightMat:SetFloat("$pp_colour_contrast",0.1+(ThrottleAffect*5.0))
		brightMat:SetFloat("$pp_colour_colour",1-(ThrottleAffect*1))
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(brightMat)
		brightMat:Recompute()
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
		
		local bloomMat = Material("pp/bloom")
		bloomMat:SetFloat("$colormul",0.5+(ThrottleAffect*2.0))
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(bloomMat)
		bloomMat:Recompute()
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
		
		local blurMat = Material("pp/blurscreen")
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(blurMat)
		
		blurMat:SetFloat("$blur",0.5+(ThrottleAffect*2))
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
		
		if IsValid( TychronicLightEntityFor ) then
			-- Set it all up
			TychronicLightEntityFor:SetTexture( "effects/flashlight001" )
			TychronicLightEntityFor:SetFarZ( 5000 ) -- How far the light should shine
			TychronicLightEntityFor:SetLinearAttenuation( (self.TychronicInverterThrottle * 5) )
			TychronicLightEntityFor:SetFOV( 179.7 )
			
			TychronicLightEntityFor:SetBrightness( 0.1 + (self.TychronicInverterThrottle / 500) )
			TychronicLightEntityFor:SetPos( LocalPlayer():WorldSpaceCenter() ) -- Initial position and angles
			TychronicLightEntityFor:SetAngles( Angle(0,math.sin(SysTime())*360*(self.TychronicInverterThrottle / 500),0)  )
			TychronicLightEntityFor:Update()
			
			TychronicLightEntityBack:SetTexture( "effects/flashlight001" )
			TychronicLightEntityBack:SetFarZ( 5000 ) -- How far the light should shine
			TychronicLightEntityBack:SetLinearAttenuation( (self.TychronicInverterThrottle * 5) )
			TychronicLightEntityBack:SetFOV( 179.7 )
			
			TychronicLightEntityBack:SetBrightness( 0.1 + (self.TychronicInverterThrottle / 500) )
			TychronicLightEntityBack:SetPos( LocalPlayer():WorldSpaceCenter() ) -- Initial position and angles
			TychronicLightEntityBack:SetAngles( Angle(0,(math.sin(SysTime())*360*(self.TychronicInverterThrottle / 500))-180,0)  )
			TychronicLightEntityBack:Update()
			
		else
			
			TychronicLightEntityFor = ProjectedTexture() -- Create a projected texture
			TychronicLightEntityBack = ProjectedTexture()
			
		end
		
		surface.SetMaterial( TunnelVision )
		surface.SetDrawColor(  255 - (255 * ThrottleAffect) , (250 * ThrottleAffect) , (110 * ThrottleAffect), (ThrottleAffect ^ 0.5)*130 ) -- Set the drawing color
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH()  )
		
	else
		if self.TychronicVisionNoise then self.TychronicVisionNoise:Stop() end
		
		if IsValid( TychronicLightEntityFor ) then
			TychronicLightEntityFor:Remove()
			TychronicLightEntityBack:Remove()
		end
	
	end
	
	local w, h = ScrW(), ScrH()
	local oldRT = GetRenderTarget( "currentcamera", w, h )
	
	local FullEnergy = (self.MainCapacitorMJ / self.MainCapacitorMJLimit)
	
	local PlayerBounds_Min, PlayerBounds_Max = self:GetHitBoxBounds(0,0)
	PlayerBounds_Min = PlayerBounds_Min or Vector()
	PlayerBounds_Max = PlayerBounds_Max or Vector()
	local RealGunPos = self:WorldSpaceCenter() + (PlayerBounds_Max * Vector(0,0,4))
	
	local linetotarget = IsValid(GlobalTargetedNpc) and (GlobalTargetedNpc:WorldSpaceCenter() - RealGunPos):GetNormalized() or Vector()
	
	local tcd = {}
	tcd.start = RealGunPos
	tcd.endpos = tcd.start + linetotarget * 100000
	tcd.filter = self
	
	local tcr = util.TraceLine(tcd)
	
	Floor_Check.start = self:GetPos()
	Floor_Check.endpos = Floor_Check.start - self:GetAngles():Up() * 200
	Floor_Check.filter = self
	
	local Floor_Response = util.TraceLine(Floor_Check)
	
	SlamNormal_x,SlamNormal_y,SlamNormal_z = self:GetVelocity():GetNormalized():Unpack()
	TouchingGround = Floor_Response.HitPos:Distance(self:GetPos()) < 50
	
	local GroundTrace = {}
	GroundTrace.start = RealGunPos
	GroundTrace.endpos = GroundTrace.start - (Vector(0,0,1) * 1000000)
	GroundTrace.filter = self
	local GrdTrace = util.TraceLine(GroundTrace)
	
	local Hudtrace = {}
	Hudtrace.start = RealGunPos
	Hudtrace.endpos = Hudtrace.start + self:EyeAngles():Forward() * 50000
	Hudtrace.filter = self
	local TestTrace = util.TraceLine(Hudtrace)
	
	local HITPOS = TestTrace.HitPos
	local OwnerVelo = self:GetVelocity()
	local OwnerVeloSquared = Vector( (math.abs(OwnerVelo.x) ^ 0.5) * OwnerVelo:GetNormalized().x , (math.abs(OwnerVelo.y) ^ 0.5) * OwnerVelo:GetNormalized().y , (math.abs(OwnerVelo.z) ^ 0.5) * OwnerVelo:GetNormalized().z )
	
	local DistanceInCm = ((HITPOS:Distance(self:GetPos())*0.75)*2.54)
	local DistanceToMeters = math.Round( DistanceInCm/100,2 )
	local MeterVelocity = math.Round(((OwnerVelo:Length()*0.75)*2.54)/100,2)
	
	local Clamp = math.Clamp(DistanceInCm^0.675,0,2500) -- Account for distance to height of lock
	local ClampedMeter = math.Clamp(DistanceToMeters/4,1,12.5)
	
	local GrapplePosition = ( HITPOS ):ToScreen() 
	local VelocityPosition = ( self:WorldSpaceCenter() + (OwnerVeloSquared) ):ToScreen() 
	
	cam.Start3D()
	
	--- Velocity Tracker
	render.SetColorMaterial()
	render.DrawLine( self:WorldSpaceCenter(), self:WorldSpaceCenter() + (OwnerVeloSquared), Color( 255, 255, 0, 200), true )
	render.DrawSphere( self:WorldSpaceCenter() + (OwnerVeloSquared), 5, 10, 10, Color( 255, 255, 255, 100 ) )
	render.DrawSphere( self:WorldSpaceCenter() + (OwnerVeloSquared), -4, 10, 10, Color( 0, 0, 0, 100 ) )
	
	AHEE_SUIT_SPEED_WARN = AHEE_SUIT_SPEED_WARN or false
	
	if IsValid(self) then
		cam.Start3D()
		
		local mins = self:OBBMins()
		local maxs = self:OBBMaxs()
		
		local ObjectVelocityMetered = OwnerVelo and (OwnerVelo:Length()/52.4934) or 0
		
		local ObjectVolume = ((math.abs(mins:Length()/52.4934)*100) * (math.abs(maxs:Length()/52.4934)*100)) -- In CM
		local ObjectVelocityRooted = Vector( (math.abs(OwnerVelo.x)^0.5) , (math.abs(OwnerVelo.y)^0.5) , (math.abs(OwnerVelo.z)^0.5) )
		
		local GravityConst = physenv.GetGravity()
		local ObjectGravityRooted = Vector( math.abs(GravityConst.x)^0.5 , math.abs(GravityConst.y)^0.5 , math.abs(GravityConst.z)^0.5 )
		local ConcernSpeed = 25 --MetersPerSecond
		
		local Calc_Portions = math.Clamp( math.Round(ObjectVelocityMetered)*2 , 400 , 500 )
		local DistanceMeasured = 0
		
		if ObjectVelocityMetered > ConcernSpeed and not self:IsOnGround() then
			local startpos = self:WorldSpaceCenter()
			
			if ObjectVelocityMetered > ConcernSpeed * 5 then
				AHEE_SUIT_SPEED_DANGER = true
			else
				AHEE_SUIT_SPEED_DANGER = false
			end
			
			local VeloPos = startpos
			local CurVelo = OwnerVelo
			
			local Local_Warn_Speed = math.sin( SysTime() * math.pi * 2 )
			
			render.SetColorMaterial() -- white material for easy coloring
			cam.IgnoreZ( true ) -- makes next draw calls ignore depth and draw on top
			
			for i = 1, Calc_Portions do
				VeloPos = VeloPos
				CurVelo = CurVelo
				WarningTraceHit = nil

				local Forces_Vector = (GravityConst) * engine.TickInterval()
				
				CurVelo = CurVelo + Forces_Vector
				
				DistanceMeasured = DistanceMeasured + 1
				
				WarningTrace = util.TraceHull( {
					start = VeloPos,
					endpos = VeloPos + ( CurVelo:GetNormalized() * 52.4934 ),
					maxs = maxs,
					mins = mins,
					filter = self
				} )
				
				VeloPos = WarningTrace.HitPos
				WarningTraceHit = WarningTrace.Entity
				
				if not WarningTrace.Hit then
					local Size_Anim = ((math.abs( math.sin( (SysTime() + i) * 3.3 ) ) * 0.9) + 0.1)^3
					
					render.DrawSphere( VeloPos, 3+(6*Size_Anim), 6, 6, Color(80,190,255,(90*Size_Anim)) )
					render.DrawSphere( VeloPos + VectorRand()*3*Size_Anim, 3, 6, 6, Color(255*(1-Size_Anim),255*(1-Size_Anim),255*(1-Size_Anim),200-(120*Size_Anim)) )
					
					if AHEE_SUIT_SPEED_WARN then
						AHEE_SUIT_SPEED_WARN = false
					end
					
				else
					local ImpactSize = math.Clamp( ObjectVelocityRooted:Length() , 25 , 125 ) / 125
					
					local LocalAngle = LocalPlayer():EyeAngles()
					
					LocalAngle:RotateAroundAxis( LocalAngle:Up(), -90 )
					LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 90 )
					
					local Distance = self:WorldSpaceCenter():Distance( WarningTrace.HitPos )
					local Distance_Size = math.Clamp( (Distance / 52.4934) / 50 , 0.6 , 10 )
					local velocity_3D_text = math.Round( ObjectVelocityMetered )
					
					cam.Start2D()
						
						local data2D = VeloPos:ToScreen()
						draw.SimpleText( " Impact ", "GModNotify", data2D.x, -(32*Distance_Size) + data2D.y, Color( 90, 180, 255 , 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						draw.SimpleText( " Impact ", "GModNotify", data2D.x, -(32*Distance_Size) + data2D.y-2, Color( 255, 255, 255 , 230 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						
					cam.End2D()
					
					local Hud_Mark_Size = (ImpactSize^0.5)*2
					local Mark_Size = 100
					
					local Mark_Dir = (VeloPos-self:WorldSpaceCenter()):GetNormalized()
					
					local EyeNormal = Angle( 0 ,  self:EyeAngles().y , 0 ):Forward()
					local Direction_Follow = math.Clamp( -math.deg(math.atan( Mark_Dir:Dot(EyeNormal:Angle():Right()) )) / 30 , -2 , 2 )
					
					local Mark_Pos = Vector( 0 , 0 , (512*Distance_Size)*Hud_Mark_Size ) + ((1024*Distance_Size) * Mark_Dir:Angle():Right() * Direction_Follow )
					cam.Start3D2D( VeloPos + Mark_Pos , LocalAngle, Distance_Size*5 ) -- 45 Angle
						
						draw.SimpleText( velocity_3D_text, "SystemBatteryFont", 0, 0, Color( 255, 255, 255 , 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
						
						draw.RoundedBox( (Mark_Size/2), -(Mark_Size/2), -(Mark_Size/2), Mark_Size, Mark_Size, Color( 0, 0, 0, 25 ) )
						draw.RoundedBox( (Mark_Size*0.9)/2, -(Mark_Size*0.9)/2, -(Mark_Size*0.9)/2, Mark_Size*0.9, Mark_Size*0.9, Color( 30, 130, 255, 40*Local_Warn_Speed ) )
						
						if Local_Warn_Speed > 0 then 
							surface.SetMaterial( interact_240_high ) 
							surface.SetDrawColor( Color(255,0,0,100) )
						else 
							surface.SetMaterial( interact_240_tamiral ) 
							surface.SetDrawColor( Color(255,255,0,100) )
						end
						
						surface.DrawTexturedRectRotated( 0, 0, Mark_Size, Mark_Size, 0 )
						
					cam.End3D2D()
					
					LocalAngle = (WarningTrace.HitNormal):Angle()
					
					LocalAngle:RotateAroundAxis( LocalAngle:Up(), 90 )
					LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 90 )
					
					cam.Start3D2D( VeloPos , LocalAngle, 1.0 ) -- Plane Angle
						
						draw.RoundedBox( (1024/2)*(ImpactSize^0.5), -(1024/2)*(ImpactSize^0.5), -(1024/2)*(ImpactSize^0.5), 1024*(ImpactSize^0.5), 1024*(ImpactSize^0.5), Color( 255, 0, 0, 25 ) )
						draw.RoundedBox( (1024/2)*(ImpactSize^0.75), -(1024/2)*(ImpactSize^0.75), -(1024/2)*(ImpactSize^0.75), 1024*(ImpactSize^0.75), 1024*(ImpactSize^0.75), Color( 255, 255, 0, 25 ) )
						draw.RoundedBox( (1024/2)*(ImpactSize^2.0), -(1024/2)*(ImpactSize^2.0), -(1024/2)*(ImpactSize^2.0), 1024*(ImpactSize^2.0), 1024*(ImpactSize^2.0), Color( 255, 255, 255, 25 ) )
						
						surface.SetMaterial( interact_240_low )
						
						surface.SetDrawColor( Color(255,0,0,100) )
						surface.DrawTexturedRectRotated( 0, 0, 1024*(ImpactSize^0.5), 1024*(ImpactSize^0.5), 0 )
						
						surface.SetDrawColor( Color(255,255,0,100) )
						surface.DrawTexturedRectRotated( 0, 0, 1024*(ImpactSize^0.75), 1024*(ImpactSize^0.75), 0 )
						
						surface.SetMaterial( interact_240_a5_low )
						
						surface.SetDrawColor( Color(255,255,255,100) )
						surface.DrawTexturedRectRotated( 0, 0, 1024*(ImpactSize^2.0), 1024*(ImpactSize^2.0), SysTime()*180 )
						
					cam.End3D2D()
					
					if not AHEE_SUIT_SPEED_WARN then
						AHEE_SUIT_SPEED_WARN = true
					end
					
					break
				end
				
			end
			
			cam.IgnoreZ( false ) -- disables previous call
			
		else
			AHEE_SUIT_SPEED_WARN = false
		end
		
		cam.End3D()
		
		if not AHEE_SUIT_SPEED_WARN then
			if AHEE_SUIT_SPEED_WARN_NOISE and AHEE_SUIT_SPEED_WARN_NOISE:IsPlaying() then
				AHEE_SUIT_SPEED_WARN_NOISE:Stop()
				
			elseif AHEE_SUIT_SPEED_DANGER_NOISE and AHEE_SUIT_SPEED_DANGER_NOISE:IsPlaying() then
				AHEE_SUIT_SPEED_DANGER_NOISE:Stop()
				
			end
		else
			
			cam.Start2D()
				
				local Seconds_Till_Impact = (self:WorldSpaceCenter():Distance( WarningTrace.HitPos ) / 52.4934) / ObjectVelocityMetered
				local Local_Text, Impact_Color
				local Local_Text_X, Local_Text_Y = (ScrW() * 0.5), (ScrH() * 0.2)
				
				if not AHEE_SUIT_SPEED_DANGER then
					if AHEE_SUIT_SPEED_DANGER_NOISE then AHEE_SUIT_SPEED_DANGER_NOISE:Stop() end
					AHEE_SUIT_SPEED_WARN_NOISE = CreateSound( self,"ahee_suit/ahee_system_high_energy_incoming.mp3" )
					AHEE_SUIT_SPEED_WARN_NOISE:PlayEx( 0.9 , 100 )
					Local_Text = "High Impact / Avoid : "..math.Round(ObjectVelocityMetered).." ; Sec : "..math.Round(Seconds_Till_Impact,2).." ; ^ "..DistanceMeasured.." M"
					Impact_Color = math.abs(math.sin(SysTime()*3.3))
					
				else
					if AHEE_SUIT_SPEED_WARN_NOISE then AHEE_SUIT_SPEED_WARN_NOISE:Stop() end
					AHEE_SUIT_SPEED_DANGER_NOISE = CreateSound( self,"ahee_suit/ahee_system_high_energyshift_detected.mp3" )
					AHEE_SUIT_SPEED_DANGER_NOISE:PlayEx( 0.9 , 100 )
					Local_Text = "Extreme Speed / Slow Down : "..math.Round(ObjectVelocityMetered).." ; Sec : "..math.Round(Seconds_Till_Impact,2).." ; ^ "..DistanceMeasured.." M"
					Impact_Color = math.abs(math.sin(SysTime()*1.1))
					
				end
				
				draw.DrawText( Local_Text, "SystemWarningFont", Local_Text_X, Local_Text_Y , Color( 255, 155*Impact_Color, 50, 160 ), 1 )
				draw.DrawText( Local_Text, "SystemWarningFont", Local_Text_X, Local_Text_Y - 2 , Color( 255, 255, 255, 90 ), 1 )
				
				surface.SetFont( "SystemWarningFont" )
				local text_width, text_height = surface.GetTextSize( Local_Text )
				local text_padding = ScrH() * 0.01
				
				local timeframe_bar = math.Clamp( Seconds_Till_Impact / 5 , 0 , 1 )
				
				surface.SetDrawColor(255,100*Impact_Color,0,50)
				surface.DrawRect( Local_Text_X - (text_width/2) - (text_padding/2), Local_Text_Y - (text_padding/2), text_width + text_padding, text_height + text_padding)
				
				surface.SetDrawColor(255,255,255,20)
				surface.DrawRect( Local_Text_X - ((text_width*timeframe_bar)/2) - (text_padding/2) , Local_Text_Y - (text_padding/2), (text_width * timeframe_bar) + text_padding , text_height + text_padding )
				
				text_padding = text_padding + (ScrH() * 0.005)
				surface.SetDrawColor(0,0,0,50)
				surface.DrawRect( Local_Text_X - (text_width/2) - (text_padding/2), Local_Text_Y - (text_padding/2), text_width + text_padding, text_height + text_padding)
				
			cam.End2D()
		end
		
	end
	
	if not (IsValid(Interaction_MainFrame) or IsValid(MainFrame) or IsValid(LockSite_MainFrame)) and self:KeyDown(IN_USE) then
		if not PING_TOGGLE then
			
			if not self:KeyDown(IN_SPEED) then
				net.Start("Targeting_Ping_Server")
					net.WriteEntity(self)
				net.SendToServer()
				
				Interest_Pos_Change( self )
				
				EmitSound( "ahee_suit/ahee_system_map_short.mp3" , Vector() , -1 , CHAN_AUTO , 1 , 80 , 0 , 100 )
			else
				
				if self.Targeting_Mains.Target_PowerMains then
					
					EmitSound( "ahee_suit/ahee_system_manage_fail.mp3" , Vector() , -1 , CHAN_AUTO , 1 , 90 , 0 , 100 )
				else
					
					EmitSound( "ahee_suit/ahee_system_revital_master.mp3" , Vector() , -1 , CHAN_AUTO , 1 , 90 , 0 , 100 )
					EmitSound( "ahee_suit/ahee_system_manage_liss.mp3" , Vector() , -1 , CHAN_AUTO , 1 , 90 , 0 , 100 )
				end
				
				net.Start("Targeting_Mains_Change_Ping_Server")
					net.WriteEntity(self)
				net.SendToServer()
				
				Target_PowerMains_Change( self )
				
			end
			
			PING_TOGGLE = true
			timer.Simple( 0.3, function() 
				PING_TOGGLE = false 
				EmitSound( "ahee_suit/ahee_system_reload.mp3" , Vector() , -1 , CHAN_AUTO , 1 , 90 , 0 , 100 )
			end)
		end
		
	end
	
	if self.Targeting_Mains then
		
		local Size_Point = ScrH() * 0.05
		local Ping_Col = PING_TOGGLE and 0 or 1
		local Focusing = self.Targeting_Mains.Target_PowerMains and 1 or 0
		
		local Point_Pos = self.InternalInterest_Pos
		local Calc_Pos = self.Targeting_Mains.Interest_Focus
		
		cam.Start2D()
			
			if self.Targeting_Mains.Interest_Focus then
				
				local data2D = Point_Pos:ToScreen()
				Size_Point = ScrH() * 0.05
				
				draw.SimpleText( " L ", "GModNotify", data2D.x, (-Size_Point/2)+data2D.y, Color( 90, 180, 255 , 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				draw.SimpleText( " L ", "GModNotify", data2D.x, (-Size_Point/2)+data2D.y-2, Color( 255, 255*Ping_Col, 255*Ping_Col , 230 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				
				surface.SetMaterial( interact_240_mark_low )
				
				surface.SetDrawColor( Color(255,255*Ping_Col,255*Ping_Col,150) )
				surface.DrawTexturedRectRotated( data2D.x, data2D.y, Size_Point, Size_Point, SysTime()*180 )
			end
			
			local mark_1 = Calc_Pos:ToScreen()
			Size_Point = ScrH() * 0.04
			
			draw.SimpleText( " Hot ", "GModNotify", mark_1.x, (-Size_Point/2)+mark_1.y, Color( 90, 180, 255 , 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( " Hot ", "GModNotify", mark_1.x, (-Size_Point/2)+mark_1.y-2, Color( 255, 255, 255 , 230 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			surface.SetMaterial( interact_240_tamiral )
			
			surface.SetDrawColor( Color(255, math.abs(math.sin(SysTime()*math.pi)) * 255 ,0,200) )
			surface.DrawTexturedRectRotated( mark_1.x, mark_1.y, Size_Point, Size_Point, 0 )
			
			for Key, Point in pairs(self.Targeting_Mains.Focus_Points) do
				local Sys_Change = math.sin( (5*SysTime()+(Key*(math.pi/#self.Targeting_Mains.Focus_Points)) ) )
				local Sys_Ch_Abs = math.abs(Sys_Change)
				local point_local = Point:ToScreen()
				local Size_Point = ScrH() * (0.075 + (Sys_Ch_Abs*0.0125))
				
				draw.SimpleText( Key, "GModNotify", point_local.x, (-Size_Point/1.5)+point_local.y, Color( 30, 200, 255 , 150 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				
				surface.SetMaterial( interact_240_mark_high )
				
				surface.SetDrawColor( Color(255, Sys_Ch_Abs * 255 ,0,200) )
				surface.DrawTexturedRectRotated( point_local.x, point_local.y, Size_Point, Size_Point, Sys_Change*90 )
				
				surface.SetDrawColor( Color( 255, 255*Sys_Ch_Abs, 255*Sys_Ch_Abs , 200 )  )
				surface.DrawLine( mark_1.x, mark_1.y, point_local.x, point_local.y )
			end
			
			if self.Targeting_Mains.Target_PowerMains then
				local Warn_Col = math.abs(math.sin(SysTime()*math.pi))
				
				surface.SetMaterial( selfidentify_radiationwarning )
				
				surface.SetDrawColor( Color(255*Warn_Col,255*Warn_Col,255*Warn_Col,150) )
				surface.DrawTexturedRectRotated( mark_1.x+Size_Point, mark_1.y+Size_Point, Size_Point, Size_Point, 0 )
				
				surface.SetMaterial( interact_240_a3_high )
				
				surface.SetDrawColor( Color(255,255*Ping_Col,255*Ping_Col,150) )
				surface.DrawTexturedRectRotated( mark_1.x, mark_1.y, Size_Point*2, Size_Point*2, math.sin(SysTime()*math.pi)*90 )
			end
			
			cam.Start3D()
				local Line_Vector = Point_Pos - Calc_Pos
				render.DrawLine( Calc_Pos, Calc_Pos+Line_Vector/2, Color( 255, 255*Ping_Col, 255*Ping_Col , 200 ) )
			cam.End3D()
			
		cam.End2D()
		
		local LocalAngle = Angle( 0 ,  (Calc_Pos-self:WorldSpaceCenter()):Angle().y , 0 )
		
		LocalAngle:RotateAroundAxis( LocalAngle:Up(), -90 )
		LocalAngle:RotateAroundAxis( LocalAngle:Forward(), 0 )
		
		local Distance = self:WorldSpaceCenter():Distance( Calc_Pos )
		local text_3D = math.Round( (Distance / 52.4934) ) .. " Meter"
		
		local Hud_Mark_Size = 2
		local Mark_Size = 52.4934 * 5
		
		local Mark_Dir = (Calc_Pos-self:WorldSpaceCenter()):GetNormalized()
		
		local Effect_Amt = 10
		for Num=1, Effect_Amt do
			local EffectedSize = 30
			local Change_Local = (Num*EffectedSize) - (math.floor( SysTime() ) - SysTime()) * EffectedSize
			local Spatial_Pos = Calc_Pos + Vector( 0 , 0 , Change_Local-(EffectedSize*Effect_Amt/2) )
			local Change_Col = math.abs(math.sin( (Num/Effect_Amt) * math.pi ))
			
			local Effect_Quality = 0.01
			local Effect_Size = (52.4934 * 4) * Effect_Quality
			cam.Start3D2D( Spatial_Pos , LocalAngle, Hud_Mark_Size * 1 / Effect_Quality )
				
				surface.SetDrawColor( Color( 255*Change_Col ^ 2, 255*Change_Col ^ 1.5, 255*Change_Col ^ 1.2, 50*Change_Col ^ 1.25 ) )
				surface.SetMaterial( interact_240_low )
				surface.DrawTexturedRectRotated( 0, 0, Effect_Size, Effect_Size, 0 )
				
			cam.End3D2D()
			
		end
		
		cam.Start3D2D( Calc_Pos , LocalAngle, Hud_Mark_Size * 1 ) -- 45 Angle
			
			draw.SimpleText( text_3D, "GModNotify", 0, 0, Color( 255, 255, 255 , 100 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			draw.RoundedBox( (Mark_Size/2), -(Mark_Size/2), -(Mark_Size/2), Mark_Size, Mark_Size, Color( 0, 0, 0, 50*Focusing ) )
			
			surface.SetDrawColor( Color(255,255,255,50) )
			surface.SetMaterial( interact_240_a1_low )
			surface.DrawTexturedRectRotated( 0, 0, Mark_Size, Mark_Size, 0 )
			
		cam.End3D2D()
		
		if self.Targeting_Mains.Target_PowerMains then
			self.Signature_Noise = CreateSound( self , "ahee_suit/ahee_system_signature_idle.mp3")
			self.Signature_Noise:PlayEx( 0.7 , 100 )
		else
			
			if self.Signature_Noise and self.Signature_Noise:IsPlaying() then 
				self.Signature_Noise:Stop() 
			end
			
		end
		
	end
	
	if self:KeyDown(IN_ZOOM) then
		render.SetColorMaterial()
		render.DrawSphere( HITPOS, 25, 30, 30, Color( 0, 175, 175, 100 ) )
		render.SetColorMaterial()
		render.DrawSphere( HITPOS, 2, 30, 30, Color( 244, 90, 90, 100 ) )
	end
	
	cam.End3D()
	
	if IsValid(GlobalTargetedNpc) then
		
		local eyeAng = EyeAngles()
		eyeAng.p = 0
		eyeAng.y = eyeAng.y + 90
		eyeAng.r = 90
		eyeAng:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
		
		if IsValid(self) then
			
			local mins, maxs = GlobalTargetedNpc:GetModelBounds()
			local DistanceInCm = ((LocalPlayer():GetPos():Distance(GlobalTargetedNpc:GetPos())*0.75)*2.54)
			local DistanceToMeters = math.Round( DistanceInCm/100,3 )
			local MeterVelocity = math.Round(((GlobalTargetedNpc:GetVelocity():Length()*0.75)*2.54)/100,2)
			local Width = 50
			local Height = 7
			local Name = tostring(GlobalTargetedNpc)

			
			cam.Start3D2D(GlobalTargetedNpc:WorldSpaceCenter() + Vector( 0,0,50 ), eyeAng, 1)
				--draw.RoundedBox( 0.1, -Width/2, 0, Width, Height, Color(0, 0, 0, 200) )
			cam.End3D2D()
			
			cam.Start3D()
				if GlobalTargetedNpcFocusPos then
					local PlayerBounds_Min, PlayerBounds_Max = self:GetModelBounds()
					render.SetColorMaterial()
					render.DrawSphere( GlobalTargetedNpcFocusPos, 12, 30, 30, Color( 244, 90, 90, 100 ) )
					render.DrawBox( GlobalTargetedNpcFocusPos, Angle(), PlayerBounds_Min, PlayerBounds_Max, Color( 255, 255, 255, 100 ) )
				end
			cam.End3D()
			
			cam.Start2D()
			
			if GlobalTargetedNpcFocusPos then
				local PlayerBounds_Min, PlayerBounds_Max = self:GetModelBounds()
				local Position = ( GlobalTargetedNpcFocusPos + Vector( 0 , 0 , PlayerBounds_Max.Z ) ):ToScreen() 
				draw.DrawText( "Last Position Known", "SystemBatteryFont", Position.x, Position.y, Color( 100, 100, 255, 255 ), 1 )
				draw.DrawText( "Last Position Known", "SystemBatteryFont", Position.x, Position.y-2, Color( 255, 255, 255, 255 ), 1 )
			end
			
			local Clamp = math.Clamp(DistanceInCm^0.675,0,2500) -- Account for distance to height of lock
			local ClampedMeter = math.Clamp(DistanceToMeters/4,1,12.5)
			local Position = ( GlobalTargetedNpc:WorldSpaceCenter() + Vector( 0,0,40 + Clamp ) ):ToScreen() 
			local CenterPosition = GlobalTargetedNpc:WorldSpaceCenter():ToScreen() 
			
			local NameHeight = 10
			local HealthHeight = 20
			
			local HealthRatio = math.Clamp( GlobalTargetedNpc:Health() / GlobalTargetedNpc:GetMaxHealth(),0,1)
			local NameLength = (string.len(tostring(GlobalTargetedNpc))*3)
			
			local MagnitudeVelocity = Vector( math.abs(GlobalTargetedNpc:GetVelocity().x) , math.abs(GlobalTargetedNpc:GetVelocity().y) , math.abs(GlobalTargetedNpc:GetVelocity().z)  )
			local TargetVelocity = (GlobalTargetedNpc:WorldSpaceCenter() + ( MagnitudeVelocity * GlobalTargetedNpc:GetVelocity():GetNormalized() ) ):ToScreen() 
			
			surface.SetDrawColor( 255, 255, 0, 250	)
			surface.DrawOutlinedRect( (TargetVelocity.x)-25/ClampedMeter,(TargetVelocity.y)-25/ClampedMeter,50/ClampedMeter,50/ClampedMeter )
			draw.DrawText( "Velocity - "..MeterVelocity.." m/s", "DermaDefault", TargetVelocity.x + 75, TargetVelocity.y-10, Color( 10, 50, 255, 220 ), 1 )
			draw.DrawText( "Velocity - "..MeterVelocity.." m/s", "DermaDefault", TargetVelocity.x + 75, TargetVelocity.y-12, Color( 255, 255, 255, 255 ), 1 )
			
			--NameOutline
			surface.SetDrawColor( 0, 0, 0, 230  )
			surface.DrawRect( Position.x-string.len(tostring(GlobalTargetedNpc))*3, Position.y, string.len(tostring(GlobalTargetedNpc))*6, NameHeight*1.75 )
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.DrawOutlinedRect( Position.x-string.len(tostring(GlobalTargetedNpc))*3, Position.y, string.len(tostring(GlobalTargetedNpc))*6, NameHeight*1.75 )
			--HealthOutline
			surface.SetDrawColor( 0, 0, 0, 230	)
			surface.DrawRect( Position.x-string.len(tostring(GlobalTargetedNpc))*3, Position.y-(HealthHeight), string.len(tostring(GlobalTargetedNpc))*6, HealthHeight )
			surface.SetDrawColor( 255, 255, 255, 200 )
			surface.DrawOutlinedRect( Position.x-string.len(tostring(GlobalTargetedNpc))*3, Position.y-(HealthHeight), string.len(tostring(GlobalTargetedNpc))*6, HealthHeight )
			--HealthBack
			surface.SetDrawColor( 200, 100, 100, 100	)
			surface.DrawRect( Position.x-string.len(tostring(GlobalTargetedNpc))*2.8, Position.y-(HealthHeight*0.8), string.len(tostring(GlobalTargetedNpc))*5.6, HealthHeight*0.6 )
			--HealthBar
			surface.SetDrawColor( 0, 200, 0, 240	)
			surface.DrawRect( Position.x-string.len(tostring(GlobalTargetedNpc))*2.8, Position.y-(HealthHeight*0.8), (string.len(tostring(GlobalTargetedNpc))*5.6)*HealthRatio, HealthHeight*0.6 )
			
			if DistanceToMeters < 500 then
			
				draw.DrawText( "Distance - "..DistanceToMeters.." Meters", "DermaDefault", Position.x, Position.y+18, Color( 10, 50, 255, 220 ), 1 )
				draw.DrawText( "Distance - "..DistanceToMeters.." Meters", "DermaDefault", Position.x, Position.y+16, Color( 255, 255, 255, 255 ), 1 )
			else
			
				draw.DrawText( "Distance - 500+ Meters", "DermaDefault", Position.x, Position.y+18, Color( 10, 50, 255, 220 ), 1 )
				draw.DrawText( "Distance - 500+ Meters", "DermaDefault", Position.x, Position.y+16, Color( 255, 255, 255, 255 ), 1 )
			end
			
			if TargetedRadiationExposure then
				local ColorExposure = 1 - math.Round( TargetedRadiationExposure * 20 , 3 )
				draw.DrawText( "Radiation Exposure - "..comma_value(math.Round( TargetedRadiationExposure , 3 )).." Sieverts", "SystemBatteryFont", Position.x, Position.y-(HealthHeight*4), Color( 255, 255*ColorExposure, 255*ColorExposure, 220 ), 1 )
				draw.DrawText( "Radiation Prevention PWR Usage - "..comma_value(math.Round( TotalEnergyUsage , 3 )).." Joules", "SystemBatteryFont", Position.x, Position.y-(HealthHeight*5), Color( 255, 255, 255, 220 ), 1 )
			end
			
			draw.DrawText( "WARNING - Beware of Damage Immunity!", "DermaDefault", Position.x+NameLength+5, Position.y+16, Color( 255, 200, 150, 240 ), 0 )
			
			local EGreen = 150-(150*math.Clamp((1+GlobalTargetedNpc:Health())/(1000*2100),0,1))
			local ERed = 255*((1+GlobalTargetedNpc:Health())/(1000*2100))
			
			
			draw.DrawText( "Health - "..GlobalTargetedNpc:Health().."/"..GlobalTargetedNpc:GetMaxHealth(), "DermaDefault", Position.x, Position.y-38, Color( 10, 50, 255, 220 ), 1 )
			draw.DrawText( "Health - "..GlobalTargetedNpc:Health().."/"..GlobalTargetedNpc:GetMaxHealth(), "DermaDefault", Position.x, Position.y-40, Color( 255, 255, 255, 255 ), 1 )
			
			draw.DrawText( Name, "DermaDefault", Position.x, Position.y-1, Color( 50, 50, 255, 180 ), 1 )
			draw.DrawText( Name, "DermaDefault", Position.x, Position.y+1, Color( 50, 50, 255, 180 ), 1 )
			draw.DrawText( Name, "DermaDefault", Position.x, Position.y, Color( 255, 10, 10, 255 ), 1 )
			
			
			cam.End2D()
			
		end
		
	end
		
		
		----------------------------------Finding & Scanning-----------------------------------------------------------------
		
		local Target = self:GetNWEntity( "TargetSelected" )
		
		if (IsValid(GlobalTargetedNpc) and not GlobalTargetedNpc:IsWorld()) and not self.MainCapacitorMJLocked then
			
			
			local DistanceInCm = ( self:WorldSpaceCenter():Distance(GlobalTargetedNpc:GetPos()) * 0.524934 )
			local DistanceToMeters = math.Round( DistanceInCm/100,3 )
			
			TargetAimingDegrees = 15 
			
			local PlayerBounds_Min, PlayerBounds_Max = self:GetHitBoxBounds(0,0)
			PlayerBounds_Min = PlayerBounds_Min or Vector()
			PlayerBounds_Max = PlayerBounds_Max or Vector()
			local RealGunPos = self:WorldSpaceCenter() + (PlayerBounds_Max * Vector(0,0,4))
			
			local linetotarget = ( Target:WorldSpaceCenter() - RealGunPos ):GetNormalized()
			TargetAimingAngleBetween = math.deg(math.acos(self:GetAimVector():Dot(linetotarget) / (self:GetAimVector():Length() * linetotarget:Length())))
			TargetAimingAngleTooMuch = TargetAimingAngleBetween > TargetAimingDegrees
			
			if IsValid(Target) then
				
				self.CordinateAlarm = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm.wav" )
				self.CordinateAlarm_Scrambled = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_Scrambled.wav" )
				
				self.LockedFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/LockedFilter.wav" )
				self.CloseFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/CloseFilter.wav" )
				self.VeryCloseFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/VeryCloseFilter.wav" )
				self.CautionFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/CautionFilter.wav" )
				self.DangerFilter = CreateSound( self,"ahee_suit/alramm_system/FilterTones/DangerFilter.wav" )
				
				if not self.LockedFilter:IsPlaying() then
					self.LockedFilter:PlayEx( math.Clamp(1-(TargetAimingAngleBetween/TargetAimingDegrees),0.05,0.1) , 100 )
				end
				
				if not self.CordinateAlarm:IsPlaying() then
					self.CordinateAlarm:PlayEx( math.Clamp(1-(TargetAimingAngleBetween/TargetAimingDegrees),0.05,0.1) , 100 + (TargetAimingAngleBetween>TargetAimingDegrees/2 and 0 or 50) )
				end
				
				---------------------------------------------LockingCalc----------
				
				tcd.start = RealGunPos
				tcd.endpos = tcd.start + linetotarget * 100000
				tcd.filter = self
				
				local tcr = util.TraceLine(tcd)

				if not AngleTooMuch then
					self.CordinateAlarm_CalcOn = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_CalcOn.wav")
					if not self.CordinateAlarm_CalcOn:IsPlaying() then
						self.CordinateAlarm_CalcOn:PlayEx( math.Clamp(1-(TargetAimingAngleBetween/TargetAimingDegrees),0.1,0.15) , math.Clamp(1-(TargetAimingAngleBetween/TargetAimingDegrees),0.25,1)*100 )
					end
				else
						self.CordinateAlarm_CalcOn:Stop()
				end
				
				if tcr.Entity == Target then
					self.CordinateAlarm_JackingDesignation = CreateSound( self,"ahee_suit/alramm_system/CordinateTones/CordinateAlarm_JackingDesignation.wav")
					if not self.CordinateAlarm_JackingDesignation:IsPlaying() then
						self.CordinateAlarm_JackingDesignation:PlayEx( 0.25 , 100 )
					end
				else
					self.CordinateAlarm_JackingDesignation:Stop()
				end
				
				if IsValid(Target) then
					if Target:IsPlayer() then
						if DistanceToMeters < 100 and DistanceToMeters > 50  then
							if not self.CautionFilter:IsPlaying() then
								self.CautionFilter:PlayEx( 1-math.Clamp((DistanceToMeters-50)/50,0.9,0.95), 50 )
							end
							self.DangerFilter:Stop()
						elseif DistanceToMeters < 50 then
							if not self.DangerFilter:IsPlaying() then
								self.DangerFilter:PlayEx( 0.1 , 100 )
							end
							self.CautionFilter:Stop()
						else
							self.CautionFilter:Stop()
							self.DangerFilter:Stop()
						end
					end
				
				end
				
			end
		
		else
			
			if self.MainCapacitorMJLocked then
				self:SetNWEntity( "TargetSelected", nil )
			end
			
		end
		
		EntArray = {}
		
		local SqSize = (ScrH() * 0.075)
		local TargetMarkerSize = SqSize/1.25
		
		EngageBarLength = SqSize * 6
		EngageBarLengthHalf = EngageBarLength / 2
		
		MouseDownAnimation_Num = MouseDownAnimation_Num or 0
		
		local tcv = {}
		tcv.start = RealGunPos
		tcv.endpos = tcv.start + self:EyeAngles():Forward() * (5000*52.4934)
		tcv.filter = self
		tcv.ignoreworld = true
		
		local LookingAtTarget = util.TraceLine(tcv)
		
		local FinderIcon = (ScrH() * 0.025)
		
		local InteractTrace = {}
		InteractTrace.start = self:EyePos()
		InteractTrace.endpos = InteractTrace.start + self:EyeAngles():Forward() * ( 5 * 52.4934 )
		InteractTrace.filter = self
		InteractTrace.ignoreworld = true
		
		AbleToInteract = util.TraceLine(InteractTrace)
		
		for key, Entity in pairs(ents.FindInSphere( self:WorldSpaceCenter() , (52.4934 * 50000) )) do
			local HighVelo = (Entity:GetVelocity():Length() > 150)
			local TooManyObjects = (#EntArray > 50)
			local AliveObject = Entity:IsNPC() or Entity:IsPlayer() or Entity:IsNextBot()
			local Collidable = (Entity:GetCollisionGroup() != COLLISION_GROUP_NONE)
			local NotOwner = Entity != self and Entity:GetParent() != self and Entity:GetOwner() != self
			local SpecialCase = string.match( tostring(Entity) , "bone" ) or string.match( tostring(Entity) , "C_" ) or string.match( tostring(Entity) , "CLuaEffect" )
			local IS_ON_PSEUDO_TEAM = IsValid( self.A9_Team_List[table.KeyFromValue( self.A9_Team_List, Entity )] )
			
			
			if IsValid(Entity) and (Entity:GetMoveCollide() != nil) and not Entity.InternalTagged and NotOwner and not SpecialCase and self.HeldItem != Entity and not IS_ON_PSEUDO_TEAM then
				Entity.Interactable = true
			else
				Entity.Interactable = nil
			end
			
			if IsValid(Entity) and (AliveObject or HighVelo) and (Entity:GetMoveCollide() != nil) and not SpecialCase and NotOwner then
				table.insert(EntArray,Entity)
				local DistanceInCm = ( LocalPlayer():WorldSpaceCenter():Distance(Entity:WorldSpaceCenter()) / 52.4934 ) * 100
				local DistanceToMeters = math.Round( DistanceInCm / 100 , 1 )
				local Clamp = math.Clamp(DistanceInCm^0.675,100,2500) -- Account for distance to height of lock
				local Position = ( Entity:WorldSpaceCenter() + Vector( 0 , 0 , Clamp/2 ) ):ToScreen() 
				local CenterPosition = Entity:WorldSpaceCenter():ToScreen()
				
				local mins, maxs = Entity:GetModelBounds()
				local MeterVelocity = math.Round( ( Entity:GetVelocity():Length() / 52.4934 ) / 100 , 2 )
				local Width = 50
				local Height = 7
				local Name = tostring( (Entity:IsPlayer() and Entity:Name()) or Entity:GetClass() )
				
				local DistanceToTarget = self:WorldSpaceCenter():Distance( Entity:WorldSpaceCenter() ) / 52.4934
				local Tranparence = (1-math.Clamp((DistanceToMeters)/100,0,1))
				
				local Enemy_Color = ((GlobalTargetedNpc == Entity and Color(0,120,255,140)) or (HighVelo and Color(255,math.Clamp(DistanceToMeters*2,0,255),0,Tranparence*140)) or Color(255,255,0,Tranparence*140))
				local Enemy_Color_Text = ((GlobalTargetedNpc == Entity and Color(0,120,255,100)) or (HighVelo and Color(255,math.Clamp(DistanceToMeters*2,0,255),0,100)) or Color(255,255,0,100))
				local ClamperOutline = (HighVelo and 10) or 20
				
				local HealthRatio = math.Clamp( Entity:Health() / Entity:GetMaxHealth(),0,1)
				
				local WorldMarkSize = (ScrH() * 0.025)
				local WorldTargetMarkerSize = WorldMarkSize
				local UnassignedIconSize = WorldMarkSize / 1.5
				
				local Nametext = "Name - "..Name
				local Nametextwidth, Nametextheight = surface.GetTextSize( Nametext )
				
				if not IsValid(GlobalTargetedNpc) then 
					TargetDistance = 100
				end
				
				local MinBound, MaxBound = Entity:GetCollisionBounds()
				
				Entity.InternalTagged = true
				
				local NormalToTarget = (Entity:WorldSpaceCenter() - self:WorldSpaceCenter()):GetNormalized()
				local EyeNormal = self:LocalEyeAngles():Forward()
				local DegreesBetween = math.Round( math.deg( math.acos( NormalToTarget:Dot(EyeNormal) ) / ( EyeNormal:Length() * NormalToTarget:Length() ) ) , 3 )
				
				if not HighVelo then
					cam.Start3D()
						render.SetColorMaterial()
						render.DrawBox( Entity:GetPos(), Entity:GetAngles(), MinBound, MaxBound, Color( 0, 0, 0, 200*math.abs(math.sin(CurTime()*2)) ) )
						Entity:DrawModel()
					cam.End3D()
				end
				
				if not Entity.CalcDied and Entity.Toggled and (Entity:Health() <= 0 and Entity:GetMaxHealth() > 0) then
					Entity.CalcDied = true
					self:EmitSound( "ahee_suit/suit_radeonicexposure_warn.mp3", 60, 100, 1, CHAN_STATIC, 0, 0 )
				end
				
				if Entity == GlobalTargetedNpc then
					if not Entity.Targeted then
						Entity.Targeted = true
						self:EmitSound( "ahee_suit/signersystem/coder_target.wav", 60, 100, 0.9, CHAN_STATIC, 0, 0 )
						self:EmitSound( "ahee_suit/taiko_target_inner.wav", 60, 200, 0.5, CHAN_STATIC, 0, 0 )
					end
					
				else
					if Entity.Targeted then
						Entity.Targeted = nil
						self:EmitSound( "ahee_suit/signersystem/coder_anti.wav", 60, 100, 0.9, CHAN_STATIC, 0, 0 )
						self:EmitSound( "ahee_suit/taiko_target_inner.wav", 60, 200, 0.5, CHAN_STATIC, 0, 0 )
					end
				
				end
				
				if DegreesBetween <= 5 or LookingAtTarget.Entity == Entity then
					
					if Entity.Toggled != 1 then
						if not Entity.Toggled then
							self:EmitSound( "ahee_suit/suit_system_calc.mp3", 60, 100, 0.8, CHAN_STATIC, 0, 0 )
						end
						Entity.Toggled = Entity.Toggled and math.Clamp( Entity.Toggled + RealFrameTime() , 0 , 1 ) or 0
						draw.DrawText( "Signature Starting."..string.rep(".", Entity.Toggled*5), "HudSelectionText", CenterPosition.x, CenterPosition.y + 70 , Color( 255, 50+math.abs(math.sin(CurTime()*18))*255, math.abs(math.sin(CurTime()*18))*255, 200 ), TEXT_ALIGN_CENTER )
						
						local HealthSize = (ScrH()*0.02)
						surface.SetDrawColor( Color( 255, 255, 255, 200 * (Entity.Toggled^2) ) )
						surface.SetMaterial( engage_marker_target )
						surface.DrawTexturedRect( CenterPosition.x - HealthSize , CenterPosition.y + 70 + HealthSize , HealthSize*2 , HealthSize*2 )
						
						if not Entity.OpeningCalc and Entity.Toggled == 1 then
							Entity.OpeningCalc = true
							self:EmitSound( "ahee_suit/hud_systemmenu_newmenu.wav", 60, 30, 0.1, CHAN_STATIC, 0, 0 )
						end
						
					end
					
					if Entity.Toggled then
						
						if Entity.Toggled == 1 then
							Entity.Rooted = true
						end
						
						draw.DrawText( string.Left( "Rooted", (Entity.Toggled^3)*6 ), "GModNotify", Position.x, Position.y - 50 , Color( 255, math.abs(math.sin(CurTime()*5))*255, math.abs(math.sin(CurTime()*5))*255, 200 ), TEXT_ALIGN_CENTER )
						
						local HealthSize = (ScrH()*0.02) * math.ease.InOutCirc(Entity.Toggled)
						local AntiHealthSize = (ScrH()*0.02) * (1-(Entity.Toggled))
						local HealthBar = (HealthSize*8)
						local Margin = 6
						
						local HealthBarSize = (HealthBar * math.ease.InOutCirc(HealthRatio)) * math.ease.InCubic(Entity.Toggled)
						
						if not (Entity:Health() <= 0) then
							local Text = math.Round((Entity:Health() * math.ease.InCubic(Entity.Toggled)),2) .." / ".. Entity:GetMaxHealth()
							surface.SetFont("DermaDefault")
							local Textwidth, Textheight = surface.GetTextSize( Text )
							
							surface.SetDrawColor( 10, 50, 100, 200 )
							surface.DrawRect( CenterPosition.x-(Margin/2) + (HealthBar) , CenterPosition.y-(Margin/2) - (HealthBar/2) , HealthSize+Margin , HealthBar+Margin )
							
							surface.SetDrawColor( 255 , 255 , 255 , 100 )
							surface.DrawRect( CenterPosition.x + (HealthBar) , CenterPosition.y - (HealthBar/2) , HealthSize , HealthBar )
							
							surface.SetDrawColor( 255 , (255*HealthRatio^2) , (255*HealthRatio^2) , 150 )
							surface.DrawRect( CenterPosition.x + (HealthBar) , CenterPosition.y - (HealthBar/2) , HealthSize , HealthBarSize )
							
							surface.SetDrawColor( 10, 50, 100, 200 )
							surface.DrawRect( CenterPosition.x + (HealthBar) - (Margin/2) + ((Textwidth/2) + (Margin/2)) , CenterPosition.y - (Textheight/2) - (Margin/2) , Textwidth + (Margin/2) , Textheight + (Margin/2) )
							draw.DrawText( Text , "DermaDefault", CenterPosition.x + (HealthBar) - (Margin/2) + ((Textwidth/2) + (Margin/2)) , CenterPosition.y - (Textheight/2) - (Margin/2) , Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
						end
						
						local Signage = (HealthSize * (1 + math.abs((1-Entity.Toggled)*5)))
						
						surface.SetDrawColor( 255, 120, 0, 80 ) -- Set the drawing color
						surface.SetMaterial( object_marker_unassigned ) -- Use our cached material
						surface.DrawTexturedRect( CenterPosition.x - Signage/2 , CenterPosition.y - Signage/2 , Signage , Signage )
						
						surface.SetDrawColor( Color( 50, 50, 50, 150 ) )
						surface.SetMaterial( vitalsymbol_lineofsight_out )
						surface.DrawTexturedRect( Position.x - AntiHealthSize , Position.y - AntiHealthSize , AntiHealthSize*2 , AntiHealthSize*2 )
						
						surface.SetDrawColor( Color( 255, math.abs(math.sin(CurTime()*5))*255, math.abs(math.sin(CurTime()*5))*255, 200 ) )
						surface.SetMaterial( vitalsymbol_lineofsight_in )
						surface.DrawTexturedRect( Position.x - (Signage/2) , Position.y - (Signage/2) , Signage , Signage )
						
					end
					
				else
					
					 if Entity.Toggled then
						if Entity.Toggled !=0 then
							
							local HealthSize = (ScrH()*0.05) * math.ease.InOutCubic(Entity.Toggled)
							local AntiHealthSize = (ScrH()*0.1) * (1-math.ease.InOutCubic(Entity.Toggled^0.5))
							
							if Entity.CalcDied then
								Entity.Toggled = Entity.Toggled and math.Clamp( Entity.Toggled - RealFrameTime() / 2 , 0 , 1 ) or 0
								draw.DrawText( "Signature Invalid!!!", "HudSelectionText", CenterPosition.x, CenterPosition.y + 70 , Color( 255, 50+math.abs(math.sin(CurTime()*5))*255, math.abs(math.sin(CurTime()*5))*255, 200 ), TEXT_ALIGN_CENTER )
								
								surface.SetDrawColor( Color( 50, 50, 50, 200*(Entity.Toggled) ) )
								surface.SetMaterial( vitalsymbol_lineofsight_out )
								surface.DrawTexturedRect( Position.x - HealthSize , Position.y - HealthSize - AntiHealthSize*10 , HealthSize*2 , HealthSize*2 )
								
							else
								Entity.Toggled = Entity.Toggled and math.Clamp( Entity.Toggled - RealFrameTime() * 2 , 0 , 1 ) or 0
								draw.DrawText( "Signature Insufficient!", "HudSelectionText", CenterPosition.x, CenterPosition.y + 70 , Color( 255, 50+math.abs(math.sin(CurTime()*5))*255, math.abs(math.sin(CurTime()*5))*255, 200 ), TEXT_ALIGN_CENTER )
								
							end
							
						end
						
						if Entity.OpeningCalc then
							Entity.OpeningCalc = nil
							self:EmitSound( "ahee_suit/suit_connectioncode_detect.mp3", 60, 100, 0.9, CHAN_STATIC, 0, 0 )
						end
						
						if Entity.Toggled == 0 then
							Entity.Toggled = nil
							Entity.Rooted = nil
						end
						
					end
					
				if GlobalTargetedNpc == Entity then
				
					TargetDistance = DistanceToMeters
					
					WorldTargetMarkerSize = WorldMarkSize * 1.25
					
					surface.SetDrawColor( 150, 200, 255, 210 ) -- Set the drawing color
					surface.SetMaterial( object_marker_selected ) -- Use our cached material
					surface.DrawTexturedRect( CenterPosition.x - WorldTargetMarkerSize/2 , CenterPosition.y + WorldTargetMarkerSize/2 , WorldTargetMarkerSize , WorldTargetMarkerSize )
					
				else
					
					local TargetDistance = TargetDistance or 100
					local NameHeight,HealthHeight
					local DistanceRatio = math.Clamp( (1 - (DistanceToMeters/TargetDistance)) , 0.125 , 1 )
					
					local TargetToEngagementBarX = ((ScrW() * 0.525) + EngageBarLengthHalf - WorldTargetMarkerSize) - (DistanceRatio*EngageBarLength)
					local TargetToEngagementBarY = (ScrH() * 0.2) - WorldTargetMarkerSize
					
					if Entity:Health() > 0 and not IS_ON_PSEUDO_TEAM then
						
						HealthHeight = 10
						surface.SetFont("DermaDefault")
						
						local RadiationPreventation = (self.RadiationTargetingPrevention/100)
						local UsedEnergy = (DistanceToTarget^(DistanceToTarget/1000))
						local TotalAntiEnergy = UsedEnergy - ( UsedEnergy * RadiationPreventation )
						local TotalEnergyUsage = ((UsedEnergy^3) * RadiationPreventation)
						
						TargetedRadiationExposure = TotalAntiEnergy or 0
						
						local ColorExposure = 1 - math.Round( math.Round( TargetedRadiationExposure , 3 ) * 50 , 3 )
						
						surface.SetDrawColor( 255, 255, 255, 40 ) -- Set the drawing color
						surface.SetMaterial( object_marker_unselected ) -- Use our cached material
						surface.DrawTexturedRect( CenterPosition.x - WorldTargetMarkerSize/2 , CenterPosition.y - WorldTargetMarkerSize/2 , WorldTargetMarkerSize , WorldTargetMarkerSize )
						
						local Metertext = DistanceToMeters.." Meters"
						local Metertextwidth, Metertextheight = surface.GetTextSize( Metertext )
						
						local NameLength = string.len(tostring(Entity)) + Metertextwidth
						local CriticalHealthMovementX = (math.sin(math.random(-1,1)) * (1-HealthRatio)^2)*math.random(-2,2)
						local CriticalHealthMovementY = (math.cos(math.random(-1,1)) * (1-HealthRatio)^2)*math.random(-5,5)
						
						local PotentRadiation = comma_value(math.Round( TargetedRadiationExposure , 3 ))
						local RadiationName = "Potential Radiation - "..PotentRadiation.." Sieverts"
						local WattageName = "Radiation PWR Estimate - "..comma_value(math.Round( TotalEnergyUsage , 3 )).." Joules"
						
						draw.DrawText( RadiationName, "DermaDefault", Position.x, Position.y - 16, Color( 255, 255*ColorExposure, 255*ColorExposure, 255 ), 1 )
						draw.DrawText( WattageName, "DermaDefault", Position.x, Position.y - Metertextheight - 16, Color( 255, 255, 255, 255 ), 1 )
						
						draw.DrawText( Nametext, "DermaDefault", CenterPosition.x, CenterPosition.y + 16 , Color( 255, 255, 255, 255 ), 1 )
						draw.DrawText( Metertext, "DermaDefault", CenterPosition.x, CenterPosition.y + Metertextheight + 16 , Color( 255, 255, 255, 255 ), 1 )
						
						surface.SetDrawColor( 10, 50, 100, 200	)
						surface.DrawRect( CriticalHealthMovementX + Position.x - (HealthHeight/2) - 2 , CriticalHealthMovementY + Position.y + (HealthHeight/2) - 2 , HealthHeight+4 , HealthHeight+4 )
						
						surface.SetDrawColor( 100+500*(HealthRatio), 100+500*(HealthRatio), 100+500*(HealthRatio), 255 )
						surface.DrawRect( CriticalHealthMovementX + Position.x - (HealthHeight/2) , CriticalHealthMovementY + Position.y + (HealthHeight/2) + (HealthHeight * (1-HealthRatio) ) , HealthHeight , HealthHeight * HealthRatio )
						
						-- Unassigned Target
						surface.SetDrawColor( 255, 255, 255, 50 ) -- Set the drawing color
						surface.SetMaterial( object_marker_unselected ) -- Use our cached material
						surface.DrawTexturedRect( TargetToEngagementBarX, TargetToEngagementBarY, WorldTargetMarkerSize , WorldTargetMarkerSize )
						
						local Metertext = (DistanceToMeters<TargetDistance and DistanceToMeters or TargetDistance.."+").." M"
						local Metertextwidth, Metertextheight = surface.GetTextSize( Metertext )
						draw.DrawText( Metertext, "DermaDefault", ((ScrW() * 0.525) + EngageBarLengthHalf - WorldTargetMarkerSize) - (DistanceRatio*EngageBarLength) + Metertextwidth/2, (ScrH() * 0.275) - WorldTargetMarkerSize, Color(255,255,255,150), 1 )
						
					else
						NameHeight = -5
						HealthHeight = -5
						
						surface.SetDrawColor( 255, 120, 50, 80 ) -- Set the drawing color
						surface.SetMaterial( object_marker_unassigned ) -- Use our cached material
						surface.DrawTexturedRect( CenterPosition.x - UnassignedIconSize/2 , CenterPosition.y - UnassignedIconSize/2 , UnassignedIconSize , UnassignedIconSize )
						
						local Metertext = DistanceToMeters.." Meters"
						local Metertextwidth, Metertextheight = surface.GetTextSize( Metertext )
						draw.DrawText( Metertext, "DermaDefault", CenterPosition.x - ((Metertextwidth/2) + 20), CenterPosition.y - (Metertextheight/2) - 2, Enemy_Color_Text, 1 )
						draw.DrawText( Metertext, "DermaDefault", CenterPosition.x - ((Metertextwidth/2) + 20), CenterPosition.y - (Metertextheight/2), Color( 255, 255, 255, 100 ), 1 )
						
						draw.DrawText( Nametext, "DermaDefault", CenterPosition.x + ((Nametextwidth/2) + 20), CenterPosition.y - (Nametextheight/2) - 2, Enemy_Color_Text, 1 )
						draw.DrawText( Nametext, "DermaDefault", CenterPosition.x + ((Nametextwidth/2) + 20), CenterPosition.y - (Nametextheight/2), Color( 255, 255, 255, 100 ), 1 )
						
					end
					
				end
				
				end
				
				cam.Start3D()
					render.DrawLine( LocalPlayer():WorldSpaceCenter(), Entity:WorldSpaceCenter(), Color( 255, 255, 255, 50 ) )
				cam.End3D()
				
				surface.SetFont("GModNotify")
				local TargetsNeartextwidth, TargetsNeartextheight = surface.GetTextSize( 1 )
				draw.DrawText( 1, "GModNotify", CenterPosition.x + (40), CenterPosition.y - (TargetsNeartextheight/2) , Color( 0, 0, 0, 200 ), TEXT_ALIGN_LEFT )
				draw.DrawText( 1, "GModNotify", CenterPosition.x + (40), CenterPosition.y - (TargetsNeartextheight/2) - 2 , Color( 255, 255, 255, 230 ), TEXT_ALIGN_LEFT )
				
				if CLIENT then
					if HighVelo and Entity:GetOwner() ~= self then
						
						if Targeting or IsValid(Entity) then 
							net.Start( "GettingTargeted_Server" )
								net.WriteEntity( Entity ) 
							net.SendToServer()
						end
						
						net.Receive( "GettingTargeted", function()
							Targeting = net.ReadBool()
						end)
						
						if (not lockingnoise and Targeting) then
							EmitSound( "ahee_suit/alramm_system/cordinatetones/cordinatealarm_enemylocking.mp3" , Vector() , -1 , CHAN_AUTO , 0.35 , 90 , 0 , 100 )
							EmitSound( "ahee_suit/signersystem/coder_track.wav" , Vector() , -1 , CHAN_AUTO , 1 , 90 , 0 , math.random(95,103) )
							
							lockingnoise = true
							timer.Simple( 2.385, function()
								lockingnoise = false
							end)
						end
						
						if not ticklockingnoise and Targeting then
							local ChangeInTiming = math.Clamp(DistanceToMeters/500,0,1)
							EmitSound( "main/mechanism_borcheltick.wav" , Vector() , -1 , CHAN_AUTO , 1 , 80 , 0 , 150-(50*ChangeInTiming) )
							ticklockingnoise = true
							timer.Simple( 0.25-(0.20*ChangeInTiming), function()
								ticklockingnoise = false
							end)
						end
					end
					
					local eyeAng = EyeAngles()
					eyeAng.p = 0
					eyeAng.y = eyeAng.y + 90
					eyeAng.r = 90
					eyeAng:RotateAroundAxis( Vector( 0, 0, 1 ), 180 )
					
				end
				
			else
				
				Entity.InternalTagged = nil
				table.remove( EntArray , key )
				
			end
			
		end
		
		ClosestTarget = FindClosestToPos( EntArray )
		if ClosestTarget then	
			local CenterPosition = ClosestTarget:WorldSpaceCenter():ToScreen()
			draw.DrawText( "Closest", "GModNotify", CenterPosition.x + (40), CenterPosition.y + 10 , Color( 255, 0, 0, 200 ), TEXT_ALIGN_LEFT )
			draw.DrawText( "Closest", "GModNotify", CenterPosition.x + (40), CenterPosition.y + 8 , Color( 255, 255, 255, 230 ), TEXT_ALIGN_LEFT )
		end
		
		
		cam.Start2D()
		
			local Padding = 5
			surface.SetDrawColor( 0, 0, 0, 200	)
			surface.DrawRect( 0 - (Padding/2) , 0 - (Padding/2) , FrameSizeW + Padding , FrameSizeH + Padding )
			surface.SetDrawColor( 0, 0, 0, 200	)
			surface.DrawRect( (ScrW() - FrameSizeW) - (Padding/2) , 0 - (Padding/2) , FrameSizeW + Padding , FrameSizeH + Padding )
		
		cam.End2D()
		
		----------------------------------Interactability Hud-----------------------------------------------------------------
		
		Suit_Interaction()
		
		if IsValid(self.HeldItem) then
			local FinderIcon = (ScrH() * 0.05)
			if not self.HeldItemStrPrep then self.HeldItemStrPrep = 0 end
			
			local Margin = 4
			local BarX, BarY = (FinderIcon*4), (FinderIcon/2)
			local ColorBar = ((self.HeldItemStrPrep/1)^6)
			surface.SetDrawColor( 255, 255, 255, 100 ) -- Set the drawing color
			surface.DrawOutlinedRect( (ScrW() * 0.5) - (BarX/2) , ( ScrH() * 0.55 ) + BarY , BarX , BarY, 2 )
			surface.SetDrawColor( 100 + (155*ColorBar), 190 - (90*ColorBar), 255 - (75*ColorBar), 100 ) -- Set the drawing color
			surface.DrawRect( (ScrW() * 0.5) - (BarX/2) + Margin , ( ScrH() * 0.55 ) + BarY + Margin , (BarX*(self.HeldItemStrPrep/1)) - (Margin*2) , BarY - (Margin*2) )
			
			if self.HeldItemStrPrep > 0.1 and self.DragShieldingSetting then
				local Movement = CreateSound( self,"tunneling_physics/tunnelingphysics_conjuctspeak"..math.random(1,5)..".wav")
				Movement:PlayEx((self.HeldItemStrPrep/1)^3,math.random(70,90))
			end
			
			draw.DrawText( "Power - "..math.Round(self.HeldItemStrPrep,2), "DermaDefault", (ScrW() * 0.5), ( ScrH() * 0.55 ) + BarY*2 , Color( 255, 255, 255, 200), 1 )
		end
		
		ArrayRemoveInvalid( EntArray )
		
		if input.IsMouseDown( MOUSE_LEFT ) then
			MouseDownAnimation_Num = math.Clamp( (MouseDownAnimation_Num + RealFrameTime()) , 0 , 1 )^0.9
		else
			MouseDownAnimation_Num = math.Clamp( (MouseDownAnimation_Num - RealFrameTime()) , 0 , 1 )^1.1
		end
		
		local Center_Size = (ScrH()*0.05) + ((MouseDownAnimation_Num) * (ScrH()*0.1))
		
		surface.SetMaterial( interact_240_a3_high )
		surface.SetDrawColor( Color( 255, 255*MouseDownAnimation_Num, 255*MouseDownAnimation_Num , 200 ) )
		surface.DrawTexturedRectRotated( ScrW()/2, ScrH()/2, Center_Size, Center_Size, math.sin(SysTime()*math.pi*5)*MouseDownAnimation_Num )
		
		Center_Size = (ScrH()*0.05) + ((MouseDownAnimation_Num) * (ScrH()*0.25))
		
		surface.SetMaterial( interact_240_high )
		surface.SetDrawColor( Color( 255, 255-(255*MouseDownAnimation_Num), 0 , 120 ) )
		surface.DrawTexturedRectRotated( ScrW()/2, ScrH()/2, Center_Size, Center_Size, 0 )
		
		----------------------------------Degrees Hud-----------------------------------------------------------------
		
		local Rotation = LocalPlayer():LocalEyeAngles().yaw - 0
		
		if true then
			local RoundSize = (ScrH()*0.1)
			local Circle_Size = (ScrH()*0.1)
			local centerX, centerY = (ScrH()*0.075), (ScrH()*0.35)
			
			local RoundDiameter = (ScrH()*0.0)
			local RotToSinCos = math.rad(Rotation+180)
			
			draw.RoundedBox( RoundSize*2, centerX-RoundSize/2, centerY-RoundSize/2, RoundSize, RoundSize, Color( 0, 0, 0 , 230 ) )
			RoundSize = RoundSize * 0.2
			draw.RoundedBox( RoundSize*2, centerX-RoundSize/2, centerY-RoundSize/2, RoundSize, RoundSize, Color( 255, 255, 255 , 150 ) )
			
			surface.SetDrawColor( Color( 255, 255, 255 , 200 ) )
			surface.SetMaterial( interact_240_mark_tamiral )
			surface.DrawTexturedRectRotated( centerX, centerY, Circle_Size, Circle_Size, Rotation )
			
			local Degrees_Simulate_Bar = math.abs(Rotation+180)/360
			local Degrees_Bar_SizeX, Degrees_Bar_SizeY = (ScrW()*0.1), ((ScrW()*0.1)/10)
			
			surface.SetDrawColor( 10, 130, 200, 100 ) -- Set the drawing color
			surface.DrawRect( Circle_Size + centerX , centerY - (Degrees_Bar_SizeY/2) , Degrees_Bar_SizeX , Degrees_Bar_SizeY )
			
			surface.SetDrawColor( 200, 255, 255, 50 ) -- Set the drawing color
			surface.DrawRect( Circle_Size + centerX , centerY - (Degrees_Bar_SizeY/2) , (Degrees_Bar_SizeX*Degrees_Simulate_Bar) , Degrees_Bar_SizeY )
			
			local Degrees_Value, Degrees_Value_Hundred = comma_value(tostring(math.Round( Degrees_Simulate_Bar * 4000 ))) , comma_value(tostring(math.Round( Degrees_Simulate_Bar * 40 )*100))
			
			draw.SimpleText( Degrees_Value.." : "..Degrees_Value_Hundred, "Trebuchet24", Circle_Size + centerX + (Degrees_Bar_SizeX/2), 2+centerY-Degrees_Bar_SizeY*1.5, Color( 50, 130, 255 , 200 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			draw.SimpleText( Degrees_Value.." : "..Degrees_Value_Hundred, "Trebuchet24", Circle_Size + centerX + (Degrees_Bar_SizeX/2), centerY-Degrees_Bar_SizeY*1.5, Color( 255, 255, 255 , 150 ), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
		end
		
		if MouseDownAnimation_Num and MouseScrollAnimation_Desired then
			draw.DrawText( 1+math.Round((MouseScrollAnimation_Num*9) / 10,2) .. "x - ".. 1+math.Round((MouseScrollAnimation_Desired*9) / 10,2) .. "x" , "GModNotify", ScrW() * 0.5, ((ScrH() * 0.55) + MouseDownAnimation_Num * (ScrH() * 0.03)) + 2, Color( 255, 255, 255, 100 ), TEXT_ALIGN_CENTER )
			draw.DrawText( 1+math.Round((MouseScrollAnimation_Num*9) / 10,2) .. "x - ".. 1+math.Round((MouseScrollAnimation_Desired*9) / 10,2) .. "x", "GModNotify", ScrW() * 0.5, ((ScrH() * 0.55) + MouseDownAnimation_Num * (ScrH() * 0.03)), Color( 80, 130, 255, 255 ), TEXT_ALIGN_CENTER )
			
			if ZoomKeyToggled then
				draw.DrawText( "Applied", "GModNotify", ScrW() * 0.5, ((ScrH() * 0.57) + MouseDownAnimation_Num * (ScrH() * 0.03)) + 2, Color( 255, 255, 255, 100 ), TEXT_ALIGN_CENTER )
				draw.DrawText( "Applied", "GModNotify", ScrW() * 0.5, ((ScrH() * 0.57) + MouseDownAnimation_Num * (ScrH() * 0.03)), Color( 255, 120, 50, 255 ), TEXT_ALIGN_CENTER )
			end
		end
		
		MainHudSystem_MainStats()
		
		Suit_Compensation()
		
		Reactor_Draw()
		
		Suit_Zoom_Function()
		
		if not IsValid( AHEE_HUD_PseudoTeam_Panel ) then
			AHEE_HUD_PseudoTeam_Panel = AHEE_HUD_PseudoTeam()
		end
		
		Alert_Draw()
		--render.PushRenderTarget( oldRT )
		
		-- if (self.frame and self.frame2) then
			-- if not self then return end
			-- local Target = self:GetNWEntity( "TargetSelected" )
			
			-- local YawEyeAngles = Angle( 0 , LocalPlayer():EyeAngles().y , 0 )
			
			-- function self.frame:Paint( w, h )
			
				-- local x, y = self:GetPos()
				
				-- local old = DisableClipping( true ) -- Avoid issues introduced by the natural clipping of Panel rendering
				-- render.SetLightingMode( 2 )
				
				-- render.RenderView( {
					-- origin = LocalPlayer():WorldSpaceCenter() + Vector( 0, 0, 0 ),
					-- angles = YawEyeAngles + Angle( math.cos( CurTime() ) * 10 , math.sin( CurTime() * 4 ) * 90 , 0 ),
					-- x = x, 
					-- y = y,
					-- w = FrameSizeW, 
					-- h = FrameSizeH,
					-- drawviewmodel = false,
					-- drawhud = false,
					-- drawmonitors = false,
					-- fov = 120
				-- } )
				
				-- render.SetLightingMode( 0 )
				
				-- DisableClipping( old )
			
			-- end
			
			-- function self.frame2:Paint( w, h )
				
				-- local x, y = self:GetPos()
				
				-- local old = DisableClipping( true ) -- Avoid issues introduced by the natural clipping of Panel rendering
				
				
				-- if not IsValid(Target) then
					-- render.RenderView( {
						-- origin = LocalPlayer():WorldSpaceCenter() + Vector( 0, 0, 0 ),
						-- angles = YawEyeAngles + Angle( 0 , 180 - math.sin( CurTime() * 8 ) * 45 , 0 ),
						-- x = x, 
						-- y = y,
						-- w = FrameSizeW, 
						-- h = FrameSizeH,
						-- drawviewmodel = false,
						-- drawhud = false,
						-- drawmonitors = false,
						-- fov = 140 + math.cos( CurTime() * 3 ) * 10
					-- } )
					-- DisableClipping( old )
				-- else
					-- local TargetMin, TargetMax = Target:GetCollisionBounds()
					-- local TargetVolume = (TargetMin * TargetMax):Length()/52.4934
					-- local FOV = 120 / math.Clamp( ( (Target:WorldSpaceCenter() ):Distance( LocalPlayer():WorldSpaceCenter() )/52.4934) / (TargetVolume^(1/3)) , 1 , 500 )
					-- local NTFOV = 80 / math.Clamp( ( (Target:WorldSpaceCenter() ):Distance( LocalPlayer():WorldSpaceCenter() )/52.4934) / (TargetVolume^(1/3)) , 1 , 500 )
					-- local UnfocusedLineOfSight = LineOfSightBool and FOV or NTFOV
					-- render.RenderView( {
						-- origin = LocalPlayer():WorldSpaceCenter() + Vector( 0, 0, 0 ),
						-- angles = ( Target:WorldSpaceCenter() - LocalPlayer():WorldSpaceCenter() ):Angle(),
						-- x = x, 
						-- y = y,
						-- w = FrameSizeW, 
						-- h = FrameSizeH,
						-- drawviewmodel = false,
						-- drawhud = false,
						-- drawmonitors = false,
						-- fov = UnfocusedLineOfSight
					-- } )
					-- DisableClipping( old )
				-- end
				
			-- end
			
		--end
		
		--render.RenderView()
		
		--render.PushRenderTarget( oldRT )
		
	
end



































net.Receive( "AHEE_System_Alert_Receive", function( len, ply )
	local self = LocalPlayer()
	local Owner = net.ReadEntity()
	if not LocalAlertSystem then LocalAlertSystem = {} end
	
	New_Alert = {}
	
	New_Alert.Alert_Time = 6
	New_Alert.Alert_TimeOut = SysTime() + New_Alert.Alert_Time
	
	New_Alert.Alert_Owner = (Owner != LocalPlayer) and Owner:GetName() or "Self"
	New_Alert.Alert_Ent = net.ReadEntity()
	New_Alert.Alert_Pos = net.ReadVector()
	
	EmitSound( "ahee_suit/ahee_system_revital_click.mp3", (self:WorldSpaceCenter()-New_Alert.Alert_Pos):GetNormalized(), -1, CHAN_STATIC, 0.6, 60, 0, math.random(150,190) )
	
	table.insert(LocalAlertSystem,New_Alert)
end)

function Alert_Draw()
	if not LocalAlertSystem then LocalAlertSystem = {} end
	
	local self = LocalPlayer()
	for Alert_Index, Alert in pairs( LocalAlertSystem ) do
		local Alert_Time_Left = Alert.Alert_TimeOut - SysTime()
		if SysTime() < Alert.Alert_TimeOut then
			local Alert_Pos_ToScr = Alert.Alert_Pos:ToScreen()
			local OwnerFrom = Alert.Alert_Owner
			
			local Signage_Scalar = Alert_Time_Left/Alert.Alert_Time
			local Sign_Scalar_Ease = math.ease.OutExpo(Signage_Scalar)
			
			local Signage = (ScrH()*0.075) * Sign_Scalar_Ease
			surface.SetFont("Trebuchet24")
			
			if IsValid( Alert.Alert_Ent ) then
				local Alert_Ent_ToScr = Alert.Alert_Ent:WorldSpaceCenter():ToScreen()
				local Alert_Ent_Text_X, Alert_Ent_Text_Y = 0, Signage
				local Alert_Ent_CD_Text_X, Alert_Ent_CD_Text_Y = Signage, 0
				
				--Alert Entity
				surface.SetDrawColor( 255, 120, 0, 80 ) -- Set the drawing color
				surface.SetMaterial( interact_240_a3_low ) -- Use our cached material
				surface.DrawTexturedRect( Alert_Ent_ToScr.x - Signage/2 , 2-Alert_Ent_ToScr.y - Signage/2 , Signage , Signage )
				--Alert Entity Overline
				surface.SetDrawColor( 255, 255, 255, 120 ) -- Set the drawing color
				surface.DrawTexturedRect( Alert_Ent_ToScr.x - Signage/2 , Alert_Ent_ToScr.y - 2 - Signage/2 , Signage , Signage )
				
				local String_Text = OwnerFrom
				local String_Text_width, String_Text_height = surface.GetTextSize( String_Text )
				--Alert Entity Text
				draw.DrawText( String_Text, "Trebuchet24", Alert_Ent_ToScr.x + (Alert_Ent_Text_X), Alert_Ent_ToScr.y + (Alert_Ent_Text_Y) - (String_Text_height/2) , Color( 255, 120, 0, 60 ), TEXT_ALIGN_CENTER )
				draw.DrawText( String_Text, "Trebuchet24", Alert_Ent_ToScr.x + (Alert_Ent_Text_X), Alert_Ent_ToScr.y + (Alert_Ent_Text_Y) - (String_Text_height/2) - 2 , Color( 255, 255, 255, 100*Sign_Scalar_Ease ), TEXT_ALIGN_CENTER )
				
				local String_Text = math.Round( Alert_Time_Left , 1 )
				local String_Text_width, String_Text_height = surface.GetTextSize( String_Text )
				--Alert Entity CountDown Text
				draw.DrawText( String_Text, "Trebuchet24", Alert_Ent_ToScr.x + (Alert_Ent_CD_Text_X), Alert_Ent_ToScr.y + (Alert_Ent_CD_Text_Y) - (String_Text_height/2) , Color( 255, 120, 0, 60 ), TEXT_ALIGN_LEFT )
				draw.DrawText( String_Text, "Trebuchet24", Alert_Ent_ToScr.x + (Alert_Ent_CD_Text_X), Alert_Ent_ToScr.y + (Alert_Ent_CD_Text_Y) - (String_Text_height/2) - 2 , Color( 255, 255, 255, 100*Sign_Scalar_Ease ), TEXT_ALIGN_LEFT )
				
			end
			
			local Alert_Pos_Text_X, Alert_Pos_Text_Y = 0, Signage
			local Alert_Pos_CD_Text_X, Alert_Pos_CD_Text_Y = Signage, 0
			
			--Alert Position
			surface.SetDrawColor( 0, 120, 255, 80 ) -- Set the drawing color
			surface.SetMaterial( interact_240_a1_high_mark ) -- Use our cached material
			surface.DrawTexturedRect( Alert_Pos_ToScr.x - Signage/2 , Alert_Pos_ToScr.y - Signage/2 , Signage , Signage )
			
			--Alert Position Overline
			surface.SetDrawColor( 255, 255, 255, 120 ) -- Set the drawing color
			surface.DrawTexturedRect( Alert_Pos_ToScr.x - Signage/2 , Alert_Pos_ToScr.y - 2 - Signage/2 , Signage , Signage )
			
			local String_Text = OwnerFrom
			local String_Text_width, String_Text_height = surface.GetTextSize( String_Text )
			--Alert Position Text
			draw.DrawText( String_Text, "Trebuchet24", Alert_Pos_ToScr.x + (Alert_Pos_Text_X), Alert_Pos_ToScr.y + (Alert_Pos_Text_Y) - (String_Text_height/2) , Color( 0, 120, 255, 60 ), TEXT_ALIGN_CENTER )
			draw.DrawText( String_Text, "Trebuchet24", Alert_Pos_ToScr.x + (Alert_Pos_Text_X), Alert_Pos_ToScr.y + (Alert_Pos_Text_Y) - (String_Text_height/2) - 2 , Color( 255, 255, 255, 100*Sign_Scalar_Ease ), TEXT_ALIGN_CENTER )
			
			local String_Text = math.Round( Alert_Time_Left , 1 )
			local String_Text_width, String_Text_height = surface.GetTextSize( String_Text )
			--Alert Position CountDown Text
			draw.DrawText( String_Text, "Trebuchet24", Alert_Pos_ToScr.x + (Alert_Pos_CD_Text_X), Alert_Pos_ToScr.y + (Alert_Pos_CD_Text_Y) - (String_Text_height/2) , Color( 0, 120, 255, 60 ), TEXT_ALIGN_LEFT )
			draw.DrawText( String_Text, "Trebuchet24", Alert_Pos_ToScr.x + (Alert_Pos_CD_Text_X), Alert_Pos_ToScr.y + (Alert_Pos_CD_Text_Y) - (String_Text_height/2) - 2 , Color( 255, 255, 255, 100*Sign_Scalar_Ease ), TEXT_ALIGN_LEFT )
			
		else
			table.remove(LocalAlertSystem,Alert_Index)
		end
	end
	
end

function Hint_Setup( Text , Severe , Time )
	
	local self = LocalPlayer()
	local Text = Text or "System Online"
	local Severe = Severe or false
	local Time = Time and math.Clamp( Time , 1 , 10 ) or 5
	
	local FrameSizeW = ScrW() * 0.2
	local FrameSizeH = ScrH() * 0.03
	
	local FramePos = Vector( -(FrameSizeH * 0.9) , ScrH()*(math.random(60,80)/100) )
	local FramePosEnd = Vector( ScrW()*0.5 , (ScrH()*0.85) )
	
	local Hint = vgui.Create( "DPanel", nil , nil )
	Hint:SetSize( FrameSizeW, FrameSizeH )
	Hint:SetPos( FramePos.x , FramePos.y )
	
	Hint.Number = #LocalHintSystem+1
	
	if #LocalHintSystem >= 10 then 
		table.remove(LocalHintSystem,1) 
	end
	
	table.insert(LocalHintSystem,Hint)
	
	Hint.Desired = 0
	Hint.Opacity = 100
	
	local HintTime = SysTime()
	
	Hint.Paint = function( Main, w, h )
		if not IsValid(Hint) then return end
		local OpacityNum = (Hint.Opacity/100)
		
		Hint.Desired = math.Clamp( ( ( SysTime() - HintTime ) / (Time/5) ) , 0 , 1 )
		Hint.Opacity = math.Round( math.Clamp( 100 * ( (Time/3) - ( ( SysTime() - HintTime ) / (Time/3) ) ) , 0 , 100 ) )
		
		if #LocalHintSystem < Hint.Number then 
			Hint.Number = Hint.Number - 1
		end
		
		local DesiredPos = LerpVector( math.ease.OutElastic( Hint.Desired ) , FramePos, FramePosEnd )
		
		local XPos = (DesiredPos.x - (FrameSizeW/2))
		local YPos = ((DesiredPos.y - (FrameSizeH/2)) - (FrameSizeH * math.Clamp( Hint.Number , 0 , 10 )))
		
		Hint:SetPos( Hint:GetX() + (XPos - Hint:GetX()) * 0.1 , Hint:GetY() + (YPos - Hint:GetY()) * 0.1 )
		
		local FrameText = Text
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local FrameMargin = w/30
		
		if Severe then
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,155,60,150*OpacityNum) )
		else
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,255,255,150*OpacityNum) )
		end
		draw.SimpleText( FrameText .. " - " .. Hint.Opacity .. "%", "DermaDefault", (w/2), (h/2), Color(0,0,0,200*OpacityNum), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if Hint.Opacity == 0 then Hint:Remove() table.remove(LocalHintSystem,1) end
		
	end
	
	timer.Simple( Time , function() 
		if IsValid( Hint ) then
			Hint:Remove() 
			table.remove(LocalHintSystem,1) 
		end
	end )
	
end

function Warn_Setup( Text , Severe )
	
	local self = LocalPlayer()
	local Text = Text or "Warning System Online"
	local Severe = Severe or false
	
	local FrameSizeW = ScrW() * 0.16
	local FrameSizeH = ScrH() * 0.02
	
	local FramePos = Vector( ScrW() * 0.5 , ScrH()-FrameSizeH )
	local FramePosEnd = Vector( FrameSizeW/2 , (ScrH()*0.7) )
	
	local Warn = vgui.Create( "DPanel", nil , nil )
	Warn:SetSize( FrameSizeW, FrameSizeH )
	Warn:SetPos( FramePos.x , FramePos.y )
	
	Warn.Number = table.Count(LocalWarningSystem)+1
	
	if table.Count(LocalWarningSystem) >= 20 then 
		table.remove(LocalWarningSystem,1) 
	end
	
	table.insert(LocalWarningSystem,Warn)
	
	Warn.Desired = 0
	Warn.Opacity = 100
	
	local WarnTime = SysTime()
	
	if Severe then
		self:EmitSound( "ahee_suit/extreme_warning.wav", 60, 150, 0.5, CHAN_STATIC, 0, 0 )
	else
		self:EmitSound( "ahee_suit/low_buffer_warning.wav", 60, 200, 0.15, CHAN_STATIC, 0, 0 )
	end
	
	Warn.Paint = function( Main, w, h )
		if not IsValid(Warn) then return end
		local OpacityNum = (Warn.Opacity/100)
		
		Warn.Desired = math.Clamp( ( ( SysTime() - WarnTime ) / 0.5 ) , 0 , 1 )
		Warn.Opacity = math.Round( math.Clamp( 100 * ( 2 - ( ( SysTime() - WarnTime ) / 3 ) ) , 0 , 100 ) )
		
		if table.Count(LocalWarningSystem) < Warn.Number then 
			Warn.Number = Warn.Number - 1
		elseif table.HasValue(LocalWarningSystem,Warn.Number) then
			Warn.Number = Warn.Number + 1
		end
		
		local DesiredPos = LerpVector( math.ease.InCirc( Warn.Desired ) , FramePos, FramePosEnd )
		
		local XPos = (DesiredPos.x - (FrameSizeW/2))
		local YPos = ((DesiredPos.y - (FrameSizeH/2)) - (FrameSizeH * math.Clamp( Warn.Number , 0 , 20 )))
		
		Warn:SetPos( Warn:GetX() + (XPos - Warn:GetX()) * 0.5 , Warn:GetY() + (YPos - Warn:GetY()) * 0.5 )
		
		local FrameText = Text
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local FrameMargin = w/30
		
		local FrameSideWidth = w * 0.8
		local LightWarnCos = math.abs(math.sin(RealTime()*2))
		
		if Severe then
			IconColor = Color( 200+(50*LightWarnCos), 25+(200*LightWarnCos), 25+(200*LightWarnCos), 200*OpacityNum )
			draw.RoundedBox( FrameMargin, 0, 0, FrameSideWidth, h, Color( 255 , 40+(200*LightWarnCos) , 5+(200*LightWarnCos) , 150*OpacityNum ) )
		else
			IconColor = Color( 255, 200, 50, 200*OpacityNum )
			draw.RoundedBox( FrameMargin, 0, 0, FrameSideWidth, h, Color( 255 , 255 , 60 , 150*OpacityNum ) )
		end
		draw.RoundedBox( FrameMargin, 3, 3, FrameSideWidth-6, h-6, Color( 255 , 80 , 60 , 150*OpacityNum ) )
		
		surface.SetDrawColor( IconColor ) -- Set the drawing color
		surface.SetMaterial( vitalsymbol_lineofsight_in ) -- Use our cached material
		surface.DrawTexturedRect( w - h , 0 , h , h )
		
		draw.SimpleText( FrameText .. " - " .. Warn.Opacity .. "%", "DermaDefault", (FrameSideWidth/2), (h/2), Color(0,0,0,200*OpacityNum), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		draw.SimpleText( Warn.Number , "DermaDefaultBold", (w*0.85), (h/2), Color(0,0,0,200*OpacityNum), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		if Warn.Opacity == 0 then table.remove(LocalWarningSystem,1) Warn:Remove() end
		
	end
	
	timer.Simple( 7.5 , function() 
		if IsValid( Warn ) then
			table.remove(LocalWarningSystem,1) 
			Warn:Remove() 
		end
	end )
	
end





function Interaction_Option_Setup( Interaction_Table )
	
	local self = LocalPlayer()
	local Interaction_Option = {}
	
	Interaction_Option.Name = Interaction_Table.Text
	Interaction_Option.Hint = Interaction_Table.SubText
	
	if Interaction_Table.Texture == "" or Interaction_Table.Texture == nil then
		Interaction_Option.Picture = Material( "hud/interaction_hud/hand_grab.png", "smooth unlitgeneric" )
	else
		Interaction_Option.Picture = Material( Interaction_Table.Texture , "smooth unlitgeneric" )
	end
	
	if Interaction_Table.Action then
		Interaction_Option.Command = Interaction_Table.Action
	end
	
	if not Interaction_Option or not LocalInteractables then return end
	
	table.insert(LocalInteractables,Interaction_Option)
	
	return Interaction_Option
	
end


function MainMenu_SetUp()
	if SERVER then return end
	
	local FrameSizeW = ScrW() / 2
	local FrameSizeH = ScrH() / 2
	
	local RandomStart = math.random(0,1) == 1 and -1 or 2
	local StartPos = FrameSizeW * RandomStart
	local self = LocalPlayer()
	
	local FrameWidthPosCurrent = StartPos
	
	local TabArray = {}
	
	MainFrame = vgui.Create( "DPanel", nil , "Main Frame" )
	MainFrame:SetSize( FrameSizeW, FrameSizeH )
	MainFrame:SetPos( StartPos, FrameSizeH/2 )
	MainFrame:MakePopup()
	MainFrame:SetKeyboardInputEnabled( false )
	
	MainFrame.TabSelected = nil
	
	MainMenu_Modules_Load()
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeW/4, FrameSizeH/8
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeW/2) - (CloseButtonSizeX/2), (FrameSizeH/2) - (CloseButtonSizeY/2)
	
	local CloseButton = vgui.Create( "DButton", MainFrame )
	CloseButton:SetText( "Close" )
	CloseButton:SetFont( "SystemWarningFont" )
	CloseButton:SetColor( Color(0,0,0,240) )
	CloseButton:SetPos( CloseButtonPositionX, CloseButtonPositionY )
	CloseButton:SetSize( CloseButtonSizeX, CloseButtonSizeY )
	
	local CloseButtonColor = Color(200,200,200,240)
	
	CloseButton.OnDepressed = function()
		CloseButtonColor = Color(130,130,130,240)
	end
	
	CloseButton.Paint = function( self, w, h )
		local CloseButtonMargin = CloseButtonSizeY/5
		draw.RoundedBox( CloseButtonMargin, 0, 0, w, h, Color(200,200,200,240) )
		draw.RoundedBox( CloseButtonMargin/1.5, CloseButtonMargin/2, CloseButtonMargin/2, w-CloseButtonMargin, h-CloseButtonMargin, CloseButtonColor )
	end
	
	CloseButton.OnReleased = function()
		for Key , Value in pairs(TabArray) do
			if Key != nil then
				TabArray[Key]:Remove()
			end
		end
		
		Toggle_AHEE_Menu( false )
	end
	
	local FrameMargin = FrameSizeW/150
	local GridSizes = FrameSizeH/6
	local GridColumns = 9
	local grid = vgui.Create( "DGrid", MainFrame )
	grid:SetPos( (FrameSizeW/2)-((GridSizes*GridColumns)/2), CloseButtonSizeY*1.5 )
	grid:SetCols( GridColumns )
	grid:SetColWide( GridSizes )
	grid:SetRowHeight( GridSizes )
	
	FrameMargin = FrameMargin / 2
	for ItemOrder, Item in pairs( System_Mains_Tabs ) do
		local Volume = math.random()
		local but = vgui.Create( "DButton" )
		but:SetText( "" )
		but:SetSize( GridSizes, GridSizes )
		but.ButtonCol = Color(0,0,0,200)
		but.Down = false
		
		but.Name = "M"..ItemOrder
		but.Identification = Item.Identification
		
		grid:AddItem( but )
		
		but.DoClick = function()
			Item:Fire_Function()
		end
		
		but.Paint = function( ButtonSelf, w, h )
			surface.SetFont("DermaDefaultBold")
			
			if ButtonSelf:IsHovered() then
				ButtonSelf.ButtonCol = Color(10,200,255,100)
				if input.IsMouseDown( MOUSE_LEFT ) then
					ButtonSelf.ButtonCol = Color(255,200,130,150)
					if not ButtonSelf.Down then
						if MainFrame.ItemSelected == ButtonSelf then MainFrame.ItemSelected = nil else MainFrame.ItemSelected = ButtonSelf end
						ButtonSelf.Down = true
						self:EmitSound( "ahee_suit/fire_warning.wav", 90, 230, 0.25, CHAN_STATIC, 0, 0 )
					end
				else
					if ButtonSelf.Down then
						ButtonSelf.Down = false
					end
				end
			else
				if MainFrame.ItemSelected == ButtonSelf then 
					ButtonSelf.ButtonCol = Color(255,200,130,150)
				else 
					ButtonSelf.ButtonCol = Color(0,0,0,200)
				end
				
				if ButtonSelf.Down then
					ButtonSelf.Down = false
				end
			end
			
			draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(255,90,90,100) )
			draw.RoundedBox( FrameMargin, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, ButtonSelf.ButtonCol )
			
			local Width, Height = (w*0.5), (h*0.5)
			local Glow = 255+(math.sin((CurTime()+ItemOrder)/3)*600)
			
			surface.SetDrawColor( Glow , Glow , Glow , 200 )
			
			surface.SetMaterial( Item.Image )
			surface.DrawTexturedRectRotated( (w/2), (h/2), Width, Height, math.sin((CurTime()+ItemOrder)/3)*30 )
			
			local String1 = ButtonSelf.Name
			local FrameTextX, FrameTextY = surface.GetTextSize( String1 )
			local TextMargin = FrameMargin*2
			local TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.25) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
			draw.SimpleText( String1, "DermaDefault", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
			
			local String2 = "ID : "..ButtonSelf.Identification
			FrameTextX, FrameTextY = surface.GetTextSize( String2 )
			TextPositionX, TextPositionY = (w/2) - (FrameTextX/2), (h*0.75) - (TextMargin/2)
			draw.RoundedBox( FrameMargin/10, TextPositionX - (TextMargin/2) , TextPositionY - (TextMargin/2) , FrameTextX + TextMargin , FrameTextY + TextMargin , Color(255,255,255,200) )
			draw.SimpleText( String2, "DermaDefault", TextPositionX + (FrameTextX/2) , TextPositionY + (FrameTextY/2) , Color(0,0,0,240), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
	end
	
	local Tychronic_Slider_PanelPosition = Vector( 0.6*FrameSizeW , 0.05*FrameSizeH )
	local Tychronic_Slider_PanelSize = Vector( FrameSizeW*0.2 , FrameSizeH*0.1 )
	
	local Tychronic_Slider_Panel = vgui.Create( "DButton", MainFrame )
	Tychronic_Slider_Panel:SetText( "" )
	Tychronic_Slider_Panel:SetColor( Color(0,0,0,0) )
	Tychronic_Slider_Panel:SetPos( Tychronic_Slider_PanelPosition.x, Tychronic_Slider_PanelPosition.y )
	Tychronic_Slider_Panel:SetSize( Tychronic_Slider_PanelSize.x, Tychronic_Slider_PanelSize.y )
	
	local SliderSettings = {}
	SliderSettings.Name= "Tycronic Light "
	SliderSettings.Pos = Vector( 0 , 0 )
	SliderSettings.Size = Vector( Tychronic_Slider_PanelSize.x , Tychronic_Slider_PanelSize.y )
	SliderSettings.PosMult = Vector( 1 , 1 )
	SliderSettings.SizeMult = Vector( 1 , 1 )
	SliderSettings.ValueChange = "TychronicLight"
	SliderSettings.ValueMult = 1
	SliderSettings.MinMax = Vector( 0 , 5000 )
	SliderSettings.Decimals = 0
	SliderSettings.Intervals = 1
	SliderSettings.RoundValue = 0
	SliderSettings.ColorMulted = Color(255,255,255)
	SliderSettings.FrameMargin = 1
	NormalSlider( "TychronicLight" , "TycronicSlider" , "Tycronic Power" , Tychronic_Slider_Panel , SliderSettings )
	
	Tychronic_Slider_Panel.Paint = function( self, w, h )
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(200,200,200,100) )
	end
	
	local WADSuppression_PanelPosition = Vector( 0.8*FrameSizeW , 0.05*FrameSizeH )
	local WADSuppression_PanelSize = Vector( FrameSizeW*0.2 , FrameSizeH*0.1 )
	
	local WADSuppression_Panel = vgui.Create( "DButton", MainFrame )
	WADSuppression_Panel:SetText( "" )
	WADSuppression_Panel:SetColor( Color(0,0,0,0) )
	WADSuppression_Panel:SetPos( WADSuppression_PanelPosition.x, WADSuppression_PanelPosition.y )
	WADSuppression_Panel:SetSize( WADSuppression_PanelSize.x, WADSuppression_PanelSize.y )
	
	local SliderSettings = {}
	SliderSettings.Name= "WAD Suppression "
	SliderSettings.Pos = Vector( 0 , 0 )
	SliderSettings.Size = Vector( WADSuppression_PanelSize.x , WADSuppression_PanelSize.y )
	SliderSettings.PosMult = Vector( 1 , 1 )
	SliderSettings.SizeMult = Vector( 1 , 1 )
	SliderSettings.ValueChange = "WADSuppression"
	SliderSettings.ValueMult = 1
	SliderSettings.MinMax = Vector( 1 , 4 )
	SliderSettings.Decimals = 0
	SliderSettings.Intervals = 1
	SliderSettings.RoundValue = 0
	SliderSettings.ColorMulted = Color(255,255,255)
	SliderSettings.FrameMargin = 1
	NormalSlider( "WADSuppression" , "WADSuppressionSlider" , "WAD Power" , WADSuppression_Panel , SliderSettings )
	
	WADSuppression_Panel.Paint = function( self, w, h )
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(200,200,200,100) )
	end
	
	MainFrame.Paint = function( Main, w, h )
		if not (FrameWidthPosCurrent) then return end
		
		local FrameWidthPosDesired = (ScrW()/2) - (FrameSizeW/2)
		local Desired = math.Round( (FrameWidthPosDesired - FrameWidthPosCurrent) * 0.5 , 1 )
		
		if Desired ~= 0 then
			FrameWidthPosCurrent = math.Clamp( FrameWidthPosCurrent + Desired , -FrameSizeW , FrameSizeW*2 )
			MainFrame:SetPos( FrameWidthPosCurrent , FrameSizeH/2 )
		end
		
		BlurBackground( Main )
		
		surface.SetFont("SystemWarningFont")
		
		local FrameText = MainFrame.TabSelected or "Systematic"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local FrameMargin = w/100
		
		draw.RoundedBox( FrameMargin, 0, 0, w, h, Color(40,40,50,200) )
		draw.RoundedBox( FrameMargin/1.5, FrameMargin/2, FrameMargin/2, w-FrameMargin, h-FrameMargin, Color(0,0,0,100) )
		
		local TextMargin = FrameMargin/4
		local TextPositionX, TextPositionY = ((FrameSizeW/2) - (FrameTextX/2)), (CloseButtonPositionY - (CloseButtonSizeY/2) - FrameTextY/2)
		
		draw.RoundedBox( FrameMargin/10, TextPositionX-((TextMargin*3)/2), TextPositionY-(TextMargin/2), FrameTextX+(TextMargin*3), FrameTextY+TextMargin, Color(20,20,20,200) )
		
		draw.SimpleText( FrameText, "SystemWarningFont", (FrameSizeW/2), (CloseButtonPositionY-(CloseButtonSizeY/2)), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		local Button_Settings = {}
		Button_Settings.Name= "APS "
		Button_Settings.Pos = Vector( w , h )
		Button_Settings.Size = Vector( h , h )
		Button_Settings.PosMult = Vector( 0.1 , 0.05 )
		Button_Settings.SizeMult = Vector( 0.1 , 0.1 )
		Button_Settings.ValueChange = "ShieldingActiveShot"
		Button_Settings.ColorMulted = Color(255,255,255)
		Button_Settings.FrameMargin = h*0.01
		
		Suit_System_Button( "APS" , Main , Button_Settings )
		
		local Button_Settings = {}
		Button_Settings.Name= "Fraise "
		Button_Settings.Pos = Vector( w , h )
		Button_Settings.Size = Vector( h , h )
		Button_Settings.PosMult = Vector( 0.2 , 0.05 )
		Button_Settings.SizeMult = Vector( 0.1 , 0.1 )
		Button_Settings.ValueChange = "ShieldingSetting"
		Button_Settings.ColorMulted = Color(255,255,255)
		Button_Settings.FrameMargin = h*0.01
		
		Suit_System_Button( "Fraise" , Main , Button_Settings )
		
		local Button_Settings = {}
		Button_Settings.Name= "Anti-Talform "
		Button_Settings.Pos = Vector( w , h )
		Button_Settings.Size = Vector( h , h )
		Button_Settings.PosMult = Vector( 0.3 , 0.05 )
		Button_Settings.SizeMult = Vector( 0.1 , 0.1 )
		Button_Settings.ValueChange = "DragShieldingSetting"
		Button_Settings.ColorMulted = Color(255,255,255)
		Button_Settings.FrameMargin = h*0.01
		
		Suit_System_Button( "Talform" , Main , Button_Settings )
		
		local Button_Settings = {}
		Button_Settings.Name= "Tycronic Vision "
		Button_Settings.Pos = Vector( w , h )
		Button_Settings.Size = Vector( h , h )
		Button_Settings.PosMult = Vector( 0.45 , 0.05 )
		Button_Settings.SizeMult = Vector( 0.1 , 0.1 )
		Button_Settings.ValueChange = "TycronicVision"
		Button_Settings.ColorMulted = Color(255,255,255)
		Button_Settings.FrameMargin = h*0.01
		
		Suit_System_Button( "TycronicVision" , Main , Button_Settings )
		
	end
	
	local function CreateCoreValue( NameText , NameString , Panel , Part , ButtonSettings, CustomOnChangeFunction , Suffix )
		
		local Button = vgui.Create( "DButton", Panel )
		
		local PanelX, PanelY = ButtonSettings.Pos.X, ButtonSettings.Pos.Y
		local PosPercentX, PosPercentY = ButtonSettings.PosMult.X, ButtonSettings.PosMult.Y
		local SizePercentX, SizePercentY = ButtonSettings.SizeMult.X, ButtonSettings.SizeMult.Y
		
		local SizeX, SizeY = PanelX * SizePercentX, PanelX * SizePercentY
		Button:SetSize( SizeX , SizeY )
		Button:SetPos( (PanelX * PosPercentX) - SizeX/2 , (PanelY * PosPercentY) - SizeY/2 )
		Button:SetText( "" )
		
		if CustomOnChangeFunction and type( CustomOnChangeFunction ) != "string" then
			CustomOnChangeFunction()
			Suffix = Suffix or ""
		else
			Suffix = CustomOnChangeFunction or ""
		end
		
		local Core = LocalPlayer().AHEE_Core
		local SetCol = Color( 200 , 200 , 200 , 50 )
		
		Button.Paint = function( Main, w, h )
			
			Button.OnDepressed = function()
				SetCol = Color( 135 , 135 , 200 , 100 )
			end
			
			Button.OnReleased = function()
				SetCol = Color( 200 , 200 , 200 , 50 )
				LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
			end
			
			draw.RoundedBox( w*0.05, 0, 0, w, h, SetCol )
			
			local ConfirmedType = { type( Core[Part] ) , Core[Part] }
			
			if ConfirmedType[1] == "boolean" then
				ConfirmedType[2] = ConfirmedType[2] and "Yes" or "No"
			elseif ConfirmedType[1] == "table" then
				for i, Val in pairs( ConfirmedType[2] ) do
					if type( Val ) == "number" then
						
						ConfirmedType[2][i] = math.Round( Val , 1 )
					end
				end
				ConfirmedType[2] = table.concat( ConfirmedType[2], ", " )
			end
			
			if ConfirmedType[1] == "number" then
				ConfirmedType[2] = math.Round(ConfirmedType[2],1)
			end
			
			draw.SimpleText( NameString..comma_value(ConfirmedType[2])..Suffix , "DermaDefault", w*0.5, h*0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
		return Button
	end
	
	local function CreateFanValue( NameText , NameString , Panel , Part , ButtonSettings, CustomOnChangeFunction , Suffix )
		
		local Button = vgui.Create( "DButton", Panel )
		
		local PanelX, PanelY = ButtonSettings.Pos.X, ButtonSettings.Pos.Y
		local PosPercentX, PosPercentY = ButtonSettings.PosMult.X, ButtonSettings.PosMult.Y
		local SizePercentX, SizePercentY = ButtonSettings.SizeMult.X, ButtonSettings.SizeMult.Y
		
		local SizeX, SizeY = PanelX * SizePercentX, PanelX * SizePercentY
		Button:SetSize( SizeX , SizeY )
		Button:SetPos( (PanelX * PosPercentX) - SizeX/2 , (PanelY * PosPercentY) - SizeY/2 )
		Button:SetText( "" )
		
		if CustomOnChangeFunction and type( CustomOnChangeFunction ) != "string" then
			CustomOnChangeFunction()
			Suffix = Suffix or ""
		else
			Suffix = CustomOnChangeFunction or ""
		end
		
		local Fan = LocalPlayer().AHEE_Cooling
		local SetCol = Color( 200 , 200 , 200 , 50 )
		
		Button.Paint = function( Main, w, h )
			
			Button.OnDepressed = function()
				SetCol = Color( 135 , 135 , 200 , 100 )
			end
			
			Button.OnReleased = function()
				SetCol = Color( 200 , 200 , 200 , 50 )
				LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
			end
			
			draw.RoundedBox( w*0.05, 0, 0, w, h, SetCol )
			
			local ConfirmedType = { type( Fan[Part] ) , Fan[Part] }
			
			if ConfirmedType[1] == "boolean" then
				ConfirmedType[2] = ConfirmedType[2] and "Yes" or "No"
			elseif ConfirmedType[1] == "table" then
				for i, Val in pairs( ConfirmedType[2] ) do
					if type( Val ) == "number" then
						
						ConfirmedType[2][i] = math.Round( Val , 1 )
					end
				end
				ConfirmedType[2] = table.concat( ConfirmedType[2], ", " )
			end
			
			if ConfirmedType[1] == "number" then
				ConfirmedType[2] = math.Round(ConfirmedType[2],1)
			end
			
			draw.SimpleText( NameString..comma_value(ConfirmedType[2])..Suffix , "DermaDefault", w*0.5, h*0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
		return Button
	end
	
	local function CreateGeneralizedVital( NameText , NameString , Panel , Part , ButtonSettings, CustomOnChangeFunction , Suffix )
		
		local Button = vgui.Create( "DButton", Panel )
		
		local PanelX, PanelY = ButtonSettings.Pos.X, ButtonSettings.Pos.Y
		local PosPercentX, PosPercentY = ButtonSettings.PosMult.X, ButtonSettings.PosMult.Y
		local SizePercentX, SizePercentY = ButtonSettings.SizeMult.X, ButtonSettings.SizeMult.Y
		
		local SizeX, SizeY = PanelX * SizePercentX, PanelX * SizePercentY
		Button:SetSize( SizeX , SizeY )
		Button:SetPos( (PanelX * PosPercentX) - SizeX/2 , (PanelY * PosPercentY) - SizeY/2 )
		Button:SetText( "" )
		
		if CustomOnChangeFunction and type( CustomOnChangeFunction ) != "string" then
			CustomOnChangeFunction()
			Suffix = Suffix or ""
		else
			Suffix = CustomOnChangeFunction or ""
		end
		
		local Medical = LocalPlayer().MedicalStats
		local SetCol = Color( 200 , 200 , 200 , 50 )
		
		Button.Paint = function( Main, w, h )
			
			Button.OnDepressed = function()
				SetCol = Color( 135 , 135 , 200 , 100 )
			end
			
			Button.OnReleased = function()
				SetCol = Color( 200 , 200 , 200 , 50 )
				LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
			end
			
			draw.RoundedBox( w*0.05, 0, 0, w, h, SetCol )
			
			local Margin = 40
			surface.SetMaterial( medicalsymbol_man ) -- Use our cached material
			surface.DrawTexturedRect( Margin/2, Margin/2, PanelX - Margin, PanelY - Margin ) -- Actually draw the rectangle
			
			local ConfirmedType = { type( Medical[Part] ) , Medical[Part] }
			
			if ConfirmedType[1] == "boolean" then
				ConfirmedType[2] = ConfirmedType[2] and "Yes" or "No"
			elseif ConfirmedType[1] == "table" then
				for i, Val in pairs( ConfirmedType[2] ) do
					if type( Val ) == "number" then
						
						ConfirmedType[2][i] = math.Round( Val , 1 )
					end
				end
				ConfirmedType[2] = table.concat( ConfirmedType[2], ", " )
			end
			
			if ConfirmedType[1] == "number" then
				ConfirmedType[2] = math.Round(ConfirmedType[2],1)
			end
			
			draw.SimpleText( NameString..tostring(ConfirmedType[2])..Suffix , "DermaDefault", w*0.5, h*0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		end
		
		return Button
	end
	
	CreateGeneralizedVital( Mobility , "Bodily Rating - " , MainFrame , "Mobility" , {
		PosMult = Vector(0.5,0.6),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " / 100")
	
	CreateGeneralizedVital( PhysiologicalMobility , "Physio Rating - " , MainFrame , "PhysiologicalMobility" , {
		PosMult = Vector(0.5,0.64),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " / 100")
	
	CreateGeneralizedVital( HeartRate , "Heart Rate - " , MainFrame , "HeartRate" , {
		PosMult = Vector(0.5,0.68),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " BPM")
	
	CreateGeneralizedVital( Bleeding , "Bleeding - " , MainFrame , "Bleeding" , {
		PosMult = Vector(0.5,0.72),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	})
	
	CreateGeneralizedVital( Internal_Bleeding , "Bleeding Internal - " , MainFrame , "Internal_Bleeding" , {
		PosMult = Vector(0.5,0.76),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	})
	
	CreateGeneralizedVital( Blood , "Blood Amount - " , MainFrame , "Blood" , {
		PosMult = Vector(0.5,0.8),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " ML")
	
	CreateGeneralizedVital( Tension , "Tension - " , MainFrame , "Tension" , {
		PosMult = Vector(0.5,0.84),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " %")
	
	CreateGeneralizedVital( Consciousness , "Consciousness - " , MainFrame , "Consciousness" , {
		PosMult = Vector(0.5,0.88),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " %")
	
	CreateGeneralizedVital( BloodPressure , "Blood Pressure - " , MainFrame , "BloodPressure" , {
		PosMult = Vector(0.5,0.92),
		SizeMult = Vector(0.25,0.02),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	})
	
	CreateGeneralizedVital( BloodToxicity , "Blood Toxicity - " , MainFrame , "BloodToxicity" , {
		PosMult = Vector(0.5,0.3),
		SizeMult = Vector(0.2,0.03),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " %")
	
	CreateGeneralizedVital( Hydration , "Hydration - " , MainFrame , "Hydration" , {
		PosMult = Vector(0.5,0.25),
		SizeMult = Vector(0.2,0.03),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	}, " %")
	
	CreateGeneralizedVital( HeartAttack , "Heart Attack - " , MainFrame , "HeartAttack" , {
		PosMult = Vector(0.5,0.2),
		SizeMult = Vector(0.2,0.03),
		Pos = Vector(MainFrameWidth,MainFrameHeight),
	})
	
	return MainFrame
	
end

function Interactable_Button_Check( Frame , InteractionButtons )
	
	local self = LocalPlayer()
	if InteractionButtons==nil or LocalInteractables==nil then return end
	if not Frame then return end
	
	local HintMenu = Frame.HintMenu
	
	for Key, Interactable in ipairs( LocalInteractables ) do
		local Picture = Interactable.Picture
		
		if InteractionButtons[ Key ] == nil then
			local Button = vgui.Create( "DButton", Frame )
			local FrameW, FrameH = Frame:GetSize()
			local FrameX, FrameY = Frame:GetPos()
			
			Button:SetText( "" )
			Button:SetFont( "Default" )
			Button:SetColor( Color(0,0,0,240) )
			Button:SetPos( 0, 0 )
			Button:SetSize( 0, 0 )
			
			Button.Text = Interactable.Name
			Button.SubText = Interactable.Hint
			
			local ButtonColor = Color(255,255,255,140)
			local BackingColor = Color(80,120,230,90)
			local InteractIcon = Picture
			
			Button.OnDepressed = function()
				if input.IsMouseDown( MOUSE_RIGHT ) then
					ButtonColor = Color(255,255,255,140)
					BackingColor = Color(255,80,80,200)
				else
					ButtonColor = Color(0,0,0,140)
					BackingColor = Color(80,230,255,200)
				end
				
			end
			
			Button.OnReleased = function()
				ButtonColor = Color(255,255,255,140)
				BackingColor = Color(80,120,230,90)
			end
			
			Button.Paint = function( self, w, h )
				local wM = w/1.5
				local hM = h/1.5
				
				if not Button.Active then
					InteractIcon = other_icon
				else
					InteractIcon = Picture
				end
				
				if Button.OutofBounds then
					local Margin = h / 8
					local OutOfBoundIcon = h / 2
					local Margin = OutOfBoundIcon / 6
					local Flash = math.abs(math.sin( CurTime() * 8 )) * 200
					
					draw.RoundedBox( (h/2), 0, 0, w, h, Color(110,230,140,90)  )
					draw.RoundedBox( (h/2)-(Margin/2), Margin/2, Margin/2, w-Margin, h-Margin, Color(255,255,255,90)  )
					
					surface.SetDrawColor( Color(255,255,255,230) ) -- Set the drawing color
					surface.SetMaterial( InteractIcon ) -- Use our cached material
					surface.DrawTexturedRect( (w/2) - (wM/2), (h/2) - (hM/2), wM, hM ) -- Actually draw the rectangle
					
					draw.RoundedBox( (OutOfBoundIcon/2), OutOfBoundIcon, OutOfBoundIcon, OutOfBoundIcon, OutOfBoundIcon, Color(Flash,0,0,255)  )
					surface.SetDrawColor( Color(255,255,255,240) ) -- Set the drawing color
					surface.SetMaterial( cycle_icon ) -- Use our cached material
					surface.DrawTexturedRect( OutOfBoundIcon + Margin/2, OutOfBoundIcon + Margin/2, OutOfBoundIcon - Margin, OutOfBoundIcon - Margin ) -- Actually draw the rectangle
				else
					draw.RoundedBox( (h/2), 0, 0, w, h, BackingColor )
					surface.SetDrawColor( ButtonColor ) -- Set the drawing color
					surface.SetMaterial( InteractIcon ) -- Use our cached material
					surface.DrawTexturedRect( (w/2) - (wM/2), (h/2) - (hM/2), wM, hM ) -- Actually draw the rectangle
					
				end
				
			end
			
			Button.DoRightClick = function()
				self:EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", 90, 210, 1, CHAN_STATIC, 0, 0 ) 
				HintMenu.Text = Button.SubText
			end
			
			Button.DoClick = function()
				if Interactable.Command then 
					Interactable.Command() 
				end
				self:EmitSound( "ahee_suit/hud_systemmenu_resetmenu.wav", 90, 50, 1, CHAN_STATIC, 0, 0 ) 
				table.Empty( InteractionButtons )
				Toggle_Interaction_Menu( false )
			end
			
			table.insert( InteractionButtons , Button )
			
		end
	end
	
	for Key, Button in ipairs( InteractionButtons ) do
		if LocalInteractables[ Key ] == nil then
			table.remove( InteractionButtons , Key )
			Button:Remove()
			self:EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", 90, 210, 1, CHAN_STATIC, 0, 0 ) 
		end
	end
	
end

function Interaction_Menu( Panel )
	if SERVER then return end
	local self = LocalPlayer()
	
	local FrameSizeW = ScrW() / 2
	local FrameSizeH = ScrH() / 2
	
	local FrameMargin = FrameSizeW / 20
	local FrameOpacity = 0
	local OpacityTime = 0.3 -- Seconds
	local RandomSpin = math.random(-1,1)
	local IdleDegrees = 0
	
	local FrameOpacityDesired , PopProduct , AntiPopProduct = 0, 0, 0
	
	local InteractButton = nil
	local InteractionButtons = {}
	
	local Frame = vgui.Create( "DPanel", nil , "Interaction Menu" )
	Frame:SetSize( FrameSizeH, FrameSizeH )
	Frame:SetPos( FrameSizeW - FrameSizeH/2, FrameSizeH/2 )
	Frame:MakePopup()
	Frame:SetKeyboardInputEnabled( false )
	Frame:SetMouseInputEnabled( true )
	
	local HintW, HintH = (FrameSizeW/3) , (FrameSizeH/3)
	local HintMenu = vgui.Create( "DPanel", nil , "Interaction Menu Hint" )
	HintMenu:SetSize( HintW, HintH )
	HintMenu:SetPos( FrameSizeW - (HintW) - (FrameSizeH/2), FrameSizeH - (HintH/2) )
	
	HintMenu.Text = "NaN"
	
	local HintLabel = vgui.Create( "DLabel", HintMenu )
	HintLabel:SetFont( "Trebuchet24" )
	HintLabel:SetText( HintMenu.Text )
	HintLabel:DockMargin(10, 10, 10, 10)
	HintLabel:Dock( FILL )
	HintLabel:SetWrap(true)
	
	Frame.HintMenu = HintMenu
	
	local CloseButtonSizeX, CloseButtonSizeY = FrameSizeH/6, FrameSizeH/6
	local CloseButtonPositionX, CloseButtonPositionY = (FrameSizeH/2) - (CloseButtonSizeX/2), (FrameSizeH/2) - FrameMargin
	
	local CloseButton = vgui.Create( "DButton", Frame )
	CloseButton:SetText( "Close" )
	CloseButton:SetFont( "SystemWarningFont" )
	CloseButton:SetColor( Color(0,0,0,240) )
	CloseButton:SetPos( CloseButtonPositionX, CloseButtonPositionY )
	CloseButton:SetSize( CloseButtonSizeX, CloseButtonSizeY )
	
	local CloseButtonColor = Color(255,255,255,150)
	local CloseButtonTextColor = Color(0,0,0,240)
	
	CloseButton.OnDepressed = function()
		if not input.IsMouseDown( MOUSE_RIGHT ) then
			CloseButtonColor = Color(90,200,255,200)
			CloseButtonTextColor = Color(255,255,255,200)
		end
	end
	
	CloseButton.OnReleased = function()
		CloseButtonColor = Color(255,255,255,150)
		CloseButtonTextColor = Color(0,0,0,240)
	end
	
	CloseButton.Paint = function( self, w, h )
		local CloseButtonMargin = CloseButtonSizeY / 5
		draw.RoundedBox( CloseButtonSizeY/2, 0, 0, w, h, Color(255,255,255,150) )
		draw.RoundedBox( CloseButtonSizeY/2, CloseButtonMargin/2, CloseButtonMargin/2, w-CloseButtonMargin, h-CloseButtonMargin, CloseButtonColor )
		self:SetColor( CloseButtonTextColor )
	end
	
	CloseButton.DoClick = function()
		self:EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", 90, 80, 1, CHAN_STATIC, 0, 0 ) 
		Toggle_Interaction_Menu( false )
	end
	
	HintMenu.Paint = function( Main, w, h )
		local Margin , RndMargin = (h / 20) , (h / 20)
		
		draw.RoundedBox( RndMargin*1.0, 0, 0, w, h, Color(0,0,0,FrameOpacity) )
		draw.RoundedBox( RndMargin*0.75, (Margin/2), (Margin/2), w-Margin, h-Margin, Color(120,200,255,FrameOpacity/5) )
		
		HintLabel:SetText( Main.Text )
		HintLabel:SetColor( Color( 255, 255, 255, FrameOpacity ) )
		
	end
	
	Frame.Paint = function( Main, w, h )
		if not (FrameOpacity) then return end
		
		FrameOpacityDesired = 220
		PopProduct = ((FrameOpacity/FrameOpacityDesired)^0.5)
		AntiPopProduct = (1-((FrameOpacity/FrameOpacityDesired)^0.5))
		
		if FrameOpacity ~= FrameOpacityDesired then
			FrameOpacity = math.Round(math.Clamp( FrameOpacity + (RealFrameTime() * FrameOpacityDesired / OpacityTime) , 0 , FrameOpacityDesired ) , 1 )
		end
		
		local numSquares = #InteractionButtons
		local interval = 360 / numSquares
		local centerX, centerY = w/2, h/2
		local radius = (h/3) * PopProduct
		
		draw.RoundedBox( (h/2), (h/2)*AntiPopProduct, (h/2)*AntiPopProduct, h*PopProduct, h*PopProduct, Color(0,0,0,FrameOpacity) )
		draw.RoundedBox( (h/2)+FrameMargin, ((h/2)*AntiPopProduct)+(FrameMargin/2), ((h/2)*AntiPopProduct)+(FrameMargin/2), (h-FrameMargin)*PopProduct, (h-FrameMargin)*PopProduct, Color(0,0,0,FrameOpacity/2) )
		
		if InteractButton then
			IdleDegrees = 0
		else
			IdleDegrees = (math.sin(CurTime()*6) * 5) + (math.cos(CurTime()*6) * 5)
		end
		
		Interactable_Button_Check( Frame , InteractionButtons )
		
		if numSquares > 0 then
			local RefSize = math.Clamp( h / (numSquares ^ 0.7) , 0 ,  h / 4 )
			local Size = RefSize * (PopProduct + AntiPopProduct*2)
			
			for i = 1, #InteractionButtons do --Start at 1, go to 360, and skip forward at even intervals.
				local LocalizedButton = InteractionButtons[i]
				if IsValid(InteractionButtons[i]) then
				
				if LocalizedButton.FirstTime == nil then
					timer.Simple( (i/15) , function() 
						if IsValid(Frame) and IsValid(InteractionButtons[i]) then 
							self:EmitSound( "main/target_tick.wav", 90, 10+(5*i), 1, CHAN_STATIC, 0, 0 ) 
							InteractionButtons[i].Active = true
						end 
					end)
					LocalizedButton.DesiredX = 0
					LocalizedButton.DesiredY = 0
					LocalizedButton:SetPos( (w/2) - RefSize, (h/2) - RefSize )
					LocalizedButton.FirstTime = false
				end
				
				local x, y = PointOnCircle( (i * interval) + IdleDegrees + (AntiPopProduct * 30 * RandomSpin), radius, centerX, centerY )
				
				local ButtonX , ButtonY = LocalizedButton:GetPos()
				local ButtonW , ButtonH = LocalizedButton:GetSize()
				local LocalizedX , LocalizedY = (x-(Size/2)) , (y-(Size/2))
				
				LocalizedButton.DesiredX = (LocalizedButton.DesiredX*0.75) + (ButtonX - LocalizedX)/2
				LocalizedButton.DesiredY = (LocalizedButton.DesiredY*0.75) + (ButtonY - LocalizedY)/2
				LocalizedButton:SetSize( ButtonW - (ButtonW - Size) , ButtonH - (ButtonH - Size) )
				
				local BoundsY = (math.abs(ButtonY - LocalizedY) > h/3 )
				local BoundsX = (math.abs(ButtonX - LocalizedX) > h/3 )
				
				if (BoundsY or BoundsX) and not LocalizedButton.OutofBounds then
					LocalizedButton.OutofBounds = true
					self:EmitSound( "ahee_suit/hud_systemmenublip.wav", 60, 240, 1, CHAN_STATIC, 0, 0 ) 
				elseif not (BoundsY or BoundsX) and LocalizedButton.OutofBounds then
					LocalizedButton.OutofBounds = nil
				end
				
				if input.IsMouseDown( MOUSE_RIGHT ) and LocalizedButton:IsHovered() then
					local X, Y = Frame:ScreenToLocal( input.GetCursorPos() )
					LocalizedButton:SetPos( (X-(Size/2)) , (Y-(Size/2)) )
				else
					LocalizedButton:SetPos( ButtonX - (LocalizedButton.DesiredX) , ButtonY - (LocalizedButton.DesiredY) )
				end
				
				if LocalizedButton:IsHovered() then
					InteractButton = LocalizedButton
				elseif CloseButton:IsHovered() then
					InteractButton = nil
				elseif Frame:IsHovered() then
					InteractButton = nil
				end
				
				end
			end
		end
		
			-- Title
		surface.SetFont("SystemWarningFont")
		local FrameText = "Interact"
		local FrameTextX, FrameTextY = surface.GetTextSize( FrameText )
		local TextPositionX, TextPositionY = (FrameSizeH/2), (FrameSizeH/2) - (FrameTextY/2) - CloseButtonSizeY
		
		draw.SimpleText( FrameText, "SystemWarningFont", TextPositionX , TextPositionY + (FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
			-- Interaction Amount
		surface.SetFont("DermaDefault")
		local FrameText = (numSquares > 1) and (numSquares .. " Interactions") or (numSquares == 1) and (numSquares .. " Interaction") or "No Interactions"
		local SubFrameTextX, SubFrameTextY = surface.GetTextSize( FrameText )
		local TextPositionX, TextPositionY = (FrameSizeH/2), (FrameSizeH/2) + (FrameTextY/2) - CloseButtonSizeY
		
		draw.SimpleText( FrameText, "DermaDefault", TextPositionX , TextPositionY + (SubFrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
			-- Interaction Name
		surface.SetFont("DermaDefault")
		local FrameText = InteractButton and InteractButton.Text or "Nothing"
		local Sub2FrameTextX, Sub2FrameTextY = surface.GetTextSize( FrameText )
		local TextPositionX, TextPositionY = (FrameSizeH/2), (FrameSizeH/2) + (FrameTextY/2) + SubFrameTextY - CloseButtonSizeY
		
		draw.SimpleText( FrameText, "DermaDefault", TextPositionX , TextPositionY + (Sub2FrameTextY/2) , color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		if IsValid( Interactable_MainFrame ) then Interactable_MainFrame:Remove() end
		if input.IsKeyDown( KEY_E ) and not IsValid( LockSite_MainFrame ) then
			Toggle_Interaction_Menu( false )
			LockSite_MainFrame = Menu_Lock_Site_Setup()
		end
		
	end
	
	Frame.OnRemove = function()
		if HintMenu then HintMenu:Remove() end
	end
	
	Interactable_Button_Check( Frame , InteractionButtons )
	
	return Frame
	
end

net.Receive( "Pelvareign_Interactive_Spawn", function( len )
	local Ply = LocalPlayer()
	
	local SentText = net.ReadString()
	local SentSubText = net.ReadString()
	local SentTexture = net.ReadString()
	local SentInteractionName = net.ReadString()
	
	local ActionFunction = function()
		net.Start( SentInteractionName )
		net.SendToServer( LocalPlayer() )
	end
	
	local Spawned_Interactive = {
		Text = SentText,
		SubText = SentSubText,
		Texture = SentTexture,
		Action = ActionFunction
	}
	
	Interaction_Option_Setup( Spawned_Interactive )
end)

net.Receive( "Pelvareign_Interactive_Collect", function( len )
	local Ply = LocalPlayer()
	local OptionRemove = net.ReadString()
	
	for Key, Option in pairs( LocalInteractables ) do
		if Option.Name == OptionRemove then
			table.remove( LocalInteractables, Key )
		end
		
	end
end)

net.Receive( "IsTarget_Rooted", function( len )
	local Ply = LocalPlayer()
	local Ent = net.ReadEntity() or nil
	if (IsValid(Interaction_MainFrame) or IsValid(MainFrame) or IsValid(LockSite_MainFrame)) then return end
	
	if IsValid(Ent) then
		if Ent.Rooted then
			net.Start("IsTarget_Rooted_Confirm")
				net.WriteEntity( Ent )
			net.SendToServer()
			Ply:EmitSound("ahee_suit/alramm_system/tag_target.wav", 50, 100,0.1)
		else
			net.Start("IsTarget_Rooted_Confirm")
			net.SendToServer()
			Ply:EmitSound("ahee_suit/alramm_system/notag_target.wav", 50, 100,0.1)
		end
	else
		net.Start("IsTarget_Rooted_Confirm")
		net.SendToServer()
		Ply:EmitSound("ahee_suit/alramm_system/notag_target.wav", 50, 90,0.1)
	end
	
end)

net.Receive( "GetClient_AngleToTarget", function( len )
	local Ply = LocalPlayer()
	if (IsValid(Interaction_MainFrame) or IsValid(MainFrame) or IsValid(LockSite_MainFrame)) then return end
	
	local Return_Angle = EyeAngles()
	
	net.Start("GetClient_AngleToTarget_Recieve")
	net.WriteAngle(Return_Angle)
	net.SendToServer()
	
end)


net.Receive( "AHEE_Change_Suit_Equipment", function( len, ply )
	
	local String_1 = net.ReadString()
	local Type = net.ReadString()
	
	if Type == "Float" then
		local Float = net.ReadFloat() or nil
		local RoundInt = net.ReadInt(10) or 5
		ply[String_1] = math.Round(Float,RoundInt)
	elseif Type == "Bool" then
		local Bool = net.ReadBool() or nil
		ply[String_1] = Bool
	end
	
end)

function Pelvareign_Interaction_Menu( ply , cmd , args )
	if not IsValid( LocalPlayer() ) then return end
	if not LocalPlayer():GetNWBool("AHEE_EQUIPED") then print( "No Suit" ) return end
	
	local self = LocalPlayer()
	if IsValid(LockSite_MainFrame) then
		LockSite_MainFrame:Remove()
		
	elseif IsValid(Interactable_MainFrame) then
		Interactable_MainFrame:Remove()
		
	else
		if IsValid(AbleToInteract.Entity) then
			Interactable_MainFrame = Menu_Interactable_Setup()
			if IsValid( Interaction_MainFrame ) then
				Interaction_MainFrame:Remove()
			end
			
			return
		end
		
	end
	
	if self.InteractionMenu_Open == nil then self.InteractionMenu_Open = false end
	
	function Toggle_Interaction_Menu( Key )
		self.InteractionMenu_Open = Key
		if Key then
			Interaction_MainFrame = Interaction_Menu()
			self:EmitSound( "ahee_suit/interactionmenu_open.mp3", 90, 100, 1, CHAN_STATIC, 0, 0 )
		else
			if IsValid(Interaction_MainFrame) then Interaction_MainFrame:Remove() end
			self:EmitSound( "ahee_suit/interactionmenu_close.mp3", 90, 100, 1, CHAN_STATIC, 0, 0 )
		end
	end
	
	Toggle_Interaction_Menu( not self.InteractionMenu_Open )
	
end

function AHEE_Menu_Client( ply , cmd , args )
	if not IsValid( LocalPlayer() ) then return end
	if not LocalPlayer():GetNWBool("AHEE_EQUIPED") then print( "No AHEE" ) return end
	
	local self = LocalPlayer()
	
	if self.AHEEMENU_ISOPEN == nil then self.AHEEMENU_ISOPEN = false end
	
	function Toggle_AHEE_Menu( Key )
		if AHEE_HUD_PseudoTeam_Panel then 
			AHEE_HUD_PseudoTeam_Panel:Remove()
		end
		
		self.AHEEMENU_ISOPEN = Key
		if Key then
			MainFrame = MainMenu_SetUp()
			self:EmitSound( "ahee_suit/hud_systemmenublip.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
		else
			if IsValid(MainFrame) then MainFrame:Remove() BlurBackground(MainFrame) end
			self:EmitSound( "ahee_suit/hud_systemmenuantiblip.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
		end
	end
	
	Toggle_AHEE_Menu( not self.AHEEMENU_ISOPEN )
	
end

if CLIENT then
	concommand.Add( "ahee_mainmenu", AHEE_Menu_Client, nil, nil, FCVAR_LUA_CLIENT )
	concommand.Add( "pelvareign_interaction", Pelvareign_Interaction_Menu, nil, nil, FCVAR_LUA_CLIENT )
end

