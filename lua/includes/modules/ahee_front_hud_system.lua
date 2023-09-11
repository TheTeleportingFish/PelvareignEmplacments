AddCSLuaFile()

include( "includes/modules/ahee_suit_hud_material_module.lua" )
include( "includes/modules/suit_functions.lua" )

function MainHudSystem_MainStats()
	
	----------------------------------Main Hud-----------------------------------------------------------------
	
	local self = LocalPlayer()
	local GlobalTargetedNpc = self:GetNWEntity( "TargetSelected" )
	
	local FrameSizeW = ScrW() / 5
	local FrameSizeH = ScrH() / 5
	
	local w, h = ScrW(), ScrH()
	local oldRT = GetRenderTarget( "currentcamera", w, h )
	
	local FullEnergy = (self.MainCapacitorMJ / self.MainCapacitorMJLimit)
	
	local PlayerBounds_Min, PlayerBounds_Max = self:GetHitBoxBounds(0,0)
	PlayerBounds_Min = PlayerBounds_Min or Vector()
	PlayerBounds_Max = PlayerBounds_Max or Vector()
	local RealGunPos = FindRealGunPos( self )
	
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
	
	cam.Start2D()
	
	-- Screen Calcs
	draw.DrawText( "Velocity - "..math.Round(MeterVelocity).." Meters/second", "SystemBatteryFont", VelocityPosition.x, VelocityPosition.y, Color( 255, 250, 0, 255 ), 1 )
	draw.DrawText( "Velocity - "..math.Round(MeterVelocity).." Meters/second", "SystemBatteryFont", VelocityPosition.x, VelocityPosition.y-2, Color( 255, 255, 255, 255 ), 1 )
	
	draw.DrawText( "Acceleration - "..math.Round(self.InducedGForce).." G's", "SystemWarningFont", VelocityPosition.x, VelocityPosition.y-30, Color( 100, 255, 100, 255 ), 1 )
	draw.DrawText( "Acceleration - "..math.Round(self.InducedGForce).." G's", "SystemWarningFont", VelocityPosition.x, VelocityPosition.y-32, Color( 255, 255, 255, 255 ), 1 )
	
	-- HUD Calcs
	draw.DrawText( "Velocity - "..math.Round(MeterVelocity).." Meters/second", "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1)-30, Color( 255, 250, 0, 255 ), 1 )
	draw.DrawText( "Velocity - "..math.Round(MeterVelocity).." Meters/second", "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1)-32, Color( 255, 255, 255, 255 ), 1 )
	
	draw.DrawText( "Acceleration - "..math.Round(self.InducedGForce).." G's", "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1), Color( 100, 255, 100, 255 ), 1 )
	draw.DrawText( "Acceleration - "..math.Round(self.InducedGForce).." G's", "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1)-2, Color( 255, 255, 255, 255 ), 1 )
	
	EntAliveArray = {}
	
	ArrayRemoveInvalid( EntAliveArray )
	
	for k, Entity in pairs( ents.GetAll() ) do
		local HighVelo = (Entity:GetVelocity():Length() > 150)
		local Alive = Entity:IsNPC() or Entity:IsPlayer() or Entity:IsNextBot()
		if IsValid(Entity) and (Alive or HighVelo) and Entity ~= LocalPlayer() then
			table.insert(EntAliveArray,Entity)
		end
	end
	
	local PotentTargetsTxt = "Targets on Grid - "..#EntAliveArray
	local PotentTargetsTxtCount = string.len(PotentTargetsTxt)
	
	draw.DrawText( PotentTargetsTxt, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.075)-60, Color( 100, 100, 100, 255 ), 1 )
	draw.DrawText( PotentTargetsTxt, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.075)-62, Color( 255, 255, 255, 255 ), 1 )
	
	local TraceText = "Trace And Distance - "..math.Round(self:GetPos():Distance(GrdTrace.HitPos)/100,2).." Meters"
	local TraceTextCount = string.len(TraceText)
	surface.SetDrawColor( 10, 10, 10, 200)
	surface.DrawRect( (ScrW() * 0.5)-(TraceTextCount*8)/2, (ScrH() * 0.1)-65, TraceTextCount*8, 30 )
	surface.SetDrawColor( 255, 255, 255, 255)
	surface.DrawOutlinedRect( (ScrW() * 0.5)-(TraceTextCount*8)/2, (ScrH() * 0.1)-65, TraceTextCount*8, 30, 1 )
	
	draw.DrawText( TraceText, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1)-60, Color( 100, 100, 255, 255 ), 1 )
	draw.DrawText( TraceText, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.1)-62, Color( 255, 255, 255, 255 ), 1 )
	
	if self:KeyDown(IN_ZOOM) then
		draw.DrawText( "Distance - "..DistanceToMeters.." Meters", "SystemBatteryFont", GrapplePosition.x, GrapplePosition.y - 55, Color( 100, 100, 255, 255 ), 1 )
		draw.DrawText( "Distance - "..DistanceToMeters.." Meters", "SystemBatteryFont", GrapplePosition.x, GrapplePosition.y - 53, Color( 255, 255, 255, 255 ), 1 )
	end
	
	---------Shields
	
	SqSize = (ScrH() * 0.075)
	TargetMarkerSize = SqSize/1.25
	
	MeterSize = (ScrW() * 0.008)
	MeterSizeLength = MeterSize * 15
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	PlaceOnScreenMiddleMove = (7*MeterSize) * 1.5
	
	PlaceOnScreenShieldX = (ScrW() * 0.85)
	PlaceOnScreenShieldY = (ScrH() * 0.5)-PlaceOnScreenMiddleMove
	
	if self.ShieldingList then
		for Shield, Value in pairs(self.ShieldingList) do
			local Num = Value[1]
			local TurnedOut = Value[2]
			local Power = Value[3]
			local MaxPower = Value[4]
			local PowerMult = Value[6]
			
			local LocalizedShieldPower = Power/MaxPower
			
			local Distance = (Num*MeterSize) * 1.5
			local Naming = (math.Round(LocalizedShieldPower,3)*100).."% | PRS - "..math.Round(PowerMult*100).."% - "
			local PowerNaming = Value[5].." | "..comma_value(math.Round(Power,1)).." MegaJoules"
			
			surface.SetFont("DermaDefault")
			local Nametextwidth, Nametextheight = surface.GetTextSize( Naming )
			local PowerNametextwidth, PowerNameNametextheight = surface.GetTextSize( PowerNaming )
			
			surface.SetDrawColor( 50, 50, 50, 200)
			surface.DrawRect( (PlaceOnScreenShieldX - MeterSizeHalfBG) , (PlaceOnScreenShieldY + Distance ) - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
			
			surface.SetDrawColor( 150, 255, 200, 200)
			surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + Distance , (LocalizedShieldPower * MeterSizeLength) , MeterSize/1.5 )
			
			surface.SetDrawColor( 40, 130, 255, 100)
			surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + Distance , ((LocalizedShieldPower^2) * MeterSizeLength) , MeterSize )
			
			draw.DrawText( Naming , "DermaDefault", (PlaceOnScreenShieldX - (Nametextwidth/2)) , ( PlaceOnScreenShieldY + Distance ) , Color(255,255,255,200), 1 )
			draw.DrawText( PowerNaming , "DermaDefault", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + Distance ) - 2 , Color(0,0,0,100), 1 )
			draw.DrawText( PowerNaming , "DermaDefault", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + Distance ) , Color(255,255,255,240), 1 )
			
			surface.SetFont("DermaDefault")
			local On = TurnedOut and true or false
			local OnColor = TurnedOut and Color(200,50,50,120) or Color(255,255,255,100)
			
			surface.SetDrawColor( OnColor )
			surface.DrawRect( PlaceOnScreenShieldX + MeterSizeLength + (MeterSizeBG * 2), PlaceOnScreenShieldY + Distance , MeterSize , MeterSize )
			
		end
	
	end
	
	---------Drag Shield
	
	MeterSize = (ScrW() * 0.02)
	MeterSizeLength = MeterSize * 8
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	PlaceOnScreenShieldX = (ScrW() * 0.85) - MeterSizeLength/4
	
	local DragDistance = (-MeterSize) * 1.5
	
	local FullDragEnergy = self.DragShielding/self.DragShieldingLimit
	local FullDragBufferEnergy = self.DragShieldingBuffer/100
	
	local DragAmount = math.Round(self.DragShielding,2)
	local DragNaming = math.Round(self.DragShieldingBuffer,2).."% : "..(math.Round(FullDragEnergy,3)*100).."% - "
	local DragPowerNaming = comma_value( DragAmount ).." Joules"
	
	surface.SetFont("SystemBatteryFont")
	local DragNametextwidth, DragNametextheight = surface.GetTextSize( DragNaming )
	local DragPowerNametextwidth, DragPowerNameNametextheight = surface.GetTextSize( DragPowerNaming )
	
	surface.SetDrawColor( 50, 50, 50, 200)
	surface.DrawRect( (PlaceOnScreenShieldX - MeterSizeHalfBG) , (PlaceOnScreenShieldY + DragDistance ) - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
	
	surface.SetDrawColor( 255, 200, 100*FullDragBufferEnergy, 200)
	surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + DragDistance , (FullDragBufferEnergy * MeterSizeLength) , MeterSize * 0.2 )
	surface.SetDrawColor( 100, 255, 150, 100)
	surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + DragDistance , (FullDragEnergy * MeterSizeLength) , MeterSize )
	
	draw.DrawText( DragNaming , "SystemBatteryFont", (PlaceOnScreenShieldX - (DragNametextwidth/2)) , ( PlaceOnScreenShieldY + DragDistance ) + MeterSizeHalfBG + DragNametextheight/4 , Color(255,255,255,200), 1 )
	draw.DrawText( DragPowerNaming , "SystemBatteryFont", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + DragDistance ) + MeterSizeHalfBG + DragNametextheight/4 , Color(255,255,255,200), 1 )
	
	---------Buffer Shield
	
	MeterSize = (ScrW() * 0.005)
	MeterSizeLength = MeterSize * 32
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	PlaceOnScreenShieldX = (ScrW() * 0.85) - MeterSizeLength/4
	
	local LockedColor = self.ShieldingBufferEnergyLocked and Color( 100, 100, 100, 200 ) or Color( 100, 130, 255, 200 )
	
	local FullBufferEnergy = self.ShieldingBufferEnergy/self.ShieldingBufferEnergyLimit
	local BufferDistance = (-MeterSize) * 1.5
	
	local BufferAmount = math.Round(self.ShieldingBufferEnergy,2)
	local BufferNaming = (math.Round(FullBufferEnergy,3)*100).."% - "
	local BufferPowerNaming = comma_value(BufferAmount).." MegaJoules"
	
	surface.SetFont("SystemPowerFont")
	local BufferNametextwidth, BufferNametextheight = surface.GetTextSize( BufferNaming )
	local BufferPowerNametextwidth, BufferPowerNameNametextheight = surface.GetTextSize( BufferPowerNaming )
	
	surface.SetDrawColor( 50, 50, 50, 200 )
	surface.DrawRect( (PlaceOnScreenShieldX - MeterSizeHalfBG) , (PlaceOnScreenShieldY + BufferDistance ) - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
	
	surface.SetDrawColor( LockedColor )
	surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + BufferDistance , (FullBufferEnergy * MeterSizeLength) , MeterSize )
	
	draw.DrawText( BufferNaming , "SystemPowerFont", (PlaceOnScreenShieldX - (BufferNametextwidth/2)) , ( PlaceOnScreenShieldY + BufferDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	draw.DrawText( BufferPowerNaming , "SystemPowerFont", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + BufferDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	
	---------Fraise Stats
	
	MeterSize = (ScrW() * 0.005)
	MeterSizeLength = MeterSize * 32
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	PlaceOnScreenShieldX = (ScrW() * 0.85) - MeterSizeLength/4
	
	local LockedColor = self.ShieldingBufferEnergyLocked and Color( 100, 100, 100, 200 ) or Color( 150, 180, 240, 200 )
	
	local FullStability = self.Fraise_Stability/100
	local StabilityDistance = (-MeterSize) * 10.5
	
	local StabilityAmount = math.Round(self.Fraise_Stability,1)
	local StabilityNaming = math.Round(FullStability*100,1).."% - "
	
	surface.SetFont("SystemPowerFont")
	local StabilityNametextwidth, StabilityNametextheight = surface.GetTextSize( StabilityNaming )
	
	surface.SetDrawColor( 50, 50, 50, 200 )
	surface.DrawRect( (PlaceOnScreenShieldX - MeterSizeHalfBG) , (PlaceOnScreenShieldY + StabilityDistance ) - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
	
	surface.SetDrawColor( LockedColor )
	surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + StabilityDistance , (FullStability * MeterSizeLength) , MeterSize )
	
	draw.DrawText( StabilityNaming , "SystemPowerFont", (PlaceOnScreenShieldX - (BufferNametextwidth/2)) , ( PlaceOnScreenShieldY + StabilityDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	draw.DrawText( "Unit Density = "..(StabilityAmount/100).." Universal Constant" , "SystemPowerFont", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + StabilityDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	
	---------Temperature Shield
	
	MeterSize = (ScrW() * 0.005)
	MeterSizeLength = MeterSize * 42
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	PlaceOnScreenShieldX = (ScrW() * 0.825) - MeterSizeLength/4
	
	FullBufferEnergy = self.FireCapacitorEnergy / self.FireCapacitorEnergyLimit
	BufferDistance = (-MeterSize) * 8.5
	
	BufferColor = Color( 255 , 255-(155*FullBufferEnergy) , 255-(155*FullBufferEnergy) , 200 )
	
	BufferNaming = (math.Round(FullBufferEnergy,3)*100).."% - "
	BufferPowerNaming = comma_value(math.Round((self.FireCapacitorEnergy/1000),2)).." MegaJoules"
	
	surface.SetFont("SystemPowerFont")
	local BufferNametextwidth, BufferNametextheight = surface.GetTextSize( BufferNaming )
	local BufferPowerNametextwidth, BufferPowerNameNametextheight = surface.GetTextSize( BufferPowerNaming )
	
	surface.SetDrawColor( 50, 50, 50, 200 )
	surface.DrawRect( (PlaceOnScreenShieldX - MeterSizeHalfBG) , (PlaceOnScreenShieldY + BufferDistance ) - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
	
	surface.SetDrawColor( BufferColor )
	surface.DrawRect( PlaceOnScreenShieldX , PlaceOnScreenShieldY + BufferDistance , (FullBufferEnergy * MeterSizeLength) , MeterSize )
	
	draw.DrawText( BufferNaming , "SystemPowerFont", (PlaceOnScreenShieldX - (BufferNametextwidth/2)) , ( PlaceOnScreenShieldY + BufferDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	draw.DrawText( BufferPowerNaming , "SystemPowerFont", (PlaceOnScreenShieldX) + (MeterSizeLength/2), ( PlaceOnScreenShieldY + BufferDistance ) - (MeterSize)/2 , Color(255,255,255,200), 1 )
	
	---------Grapple Stats
	
	local RadeonicGrapplePack = self.RadeonicGrapplePack
	local GrappleStability = RadeonicGrapplePack.Stability
	local RadeonicHooking = RadeonicGrapplePack.Hooking
	
	MeterSize = (ScrW() * 0.01)
	MeterSizeLength = MeterSize * 16
	
	MeterSizeBG = 4
	MeterSizeHalfBG = MeterSizeBG / 2 
	
	GrappleScreenY = (ScrH() * 0.51) + (MeterSize + MouseDownAnimation_Num * (ScrH() * 0.03))
	GrappleScreenX = (ScrW() * 0.5) - (MeterSizeLength/2)
	
	StabilityAlert = StabilityAlert and StabilityAlert or false
	StabilitySettingNumber = StabilitySettingNumber and ( StabilitySettingNumber + ((5*(1-(GrappleStability/100))) * RealFrameTime()) ) or 0
	local GrappleColor = Color( 200, 200, 200, 100 )
	local StabilityColorNumber = math.abs(math.sin(StabilitySettingNumber*5))
	local GrappleHookingColor = RadeonicGrapplePack.Hooking and Color( 255, 155+100*StabilityColorNumber, 155+100*StabilityColorNumber, 200 ) or Color( 150, 50+100*StabilityColorNumber, 50+100*StabilityColorNumber, 200 )
	
	local FullGrappleStability = math.Clamp( RadeonicGrapplePack.Stability/100 , 0 , 1 )
	local FullGrapple = RadeonicGrapplePack.BufferEnergy/RadeonicGrapplePack.MaxBufferEnergy
	local ArmAngle = RadeonicGrapplePack.Hooking and GetArmAngle(self) or 0
	
	local GrappleAmount = comma_value(math.Round(RadeonicGrapplePack.BufferEnergy,1))
	local GrappleNaming = math.Round(FullGrapple*100,1).."% - "
	
	surface.SetFont("SystemPowerFont")
	local GrappleNametextwidth, GrappleNametextheight = surface.GetTextSize( GrappleNaming )
	
	surface.SetDrawColor( 50, 50, 50, 100 )
	surface.DrawRect( (GrappleScreenX - MeterSizeHalfBG) , GrappleScreenY - MeterSizeHalfBG , (MeterSizeLength) + MeterSizeBG, MeterSize + MeterSizeBG )
	
	surface.SetDrawColor( GrappleColor )
	surface.DrawRect( GrappleScreenX , GrappleScreenY , (FullGrapple * MeterSizeLength) , MeterSize )
	
	--Stability
	surface.SetDrawColor( 150+200*(GrappleStability/100), 150, 150, 200 )
	surface.DrawRect( GrappleScreenX , GrappleScreenY+MeterSize*2 , (FullGrappleStability * MeterSizeLength/3) , MeterSize/2 )
	--Bar
	surface.SetDrawColor( 150+200*(GrappleStability/100), 150, 150, 200 )
	surface.DrawRect( GrappleScreenX , GrappleScreenY+MeterSize*2 , (FullGrappleStability * MeterSizeLength/3) , MeterSize/2 )
	
	draw.DrawText( "Stability : "..math.Round(RadeonicGrapplePack.Stability,1).." %", "Default", ( GrappleScreenX + ((MeterSizeLength/3)/2) ), GrappleScreenY+(MeterSize*2)-((MeterSize/3)/2) , Color(0,0,0,200), TEXT_ALIGN_CENTER )
	
	draw.DrawText( GrappleNaming , "SystemPowerFont", (GrappleScreenX - (GrappleNametextwidth/2)) , GrappleScreenY , Color(255,255,255,200), 1 )
	draw.DrawText( "Buffer = "..(GrappleAmount).." Joules", "SystemPowerFont", (GrappleScreenX) + (MeterSizeLength/2), GrappleScreenY , Color(0,0,0,200), 1 )
	
	local Wattage, WattageDivision = energy_seperation(math.Round(RadeonicGrapplePack.BufferLoad))
	
	draw.DrawText( "Arm Angle = "..math.Round(ArmAngle).." Arc", "SystemPowerFont", (GrappleScreenX) + (MeterSizeLength), GrappleScreenY + MeterSize , Color(255,255,255,150), TEXT_ALIGN_RIGHT )
	draw.DrawText( "Buffer Load = "..math.Round(RadeonicGrapplePack.BufferLoad/WattageDivision,1).." "..Wattage, "SystemPowerFont", (GrappleScreenX), GrappleScreenY + MeterSize , Color(255,255,255,150), TEXT_ALIGN_LEFT )
	
	-- RightSymbol
	local SymbolSize = MeterSize*3
	local SymbolPositionX = GrappleScreenX + (MeterSizeLength)
	local SymbolPositionY = GrappleScreenY - (SymbolSize/2) + (MeterSize/2)
	
	surface.SetDrawColor( GrappleHookingColor ) -- Set the drawing color
	surface.SetMaterial( radeonicgrapple_tychronic_associate_symbol ) -- Use our cached material
	surface.DrawTexturedRect( SymbolPositionX , SymbolPositionY , SymbolSize , SymbolSize ) -- 1st rectangle
	
	if GrappleStability < 100 then
		if StabilitySettingNumber >= 1 and StabilitySettingNumber < 2 then
			local LocalSize = SymbolSize/2
			
			surface.SetDrawColor( 0, 90, 220, 150 ) -- Set the drawing color
			surface.SetMaterial( cycle_icon ) -- Use our cached material
			surface.DrawTexturedRect( SymbolPositionX + LocalSize , SymbolPositionY + LocalSize , LocalSize , LocalSize ) -- 1st rectangle
			
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( cycle_icon ) -- Use our cached material
			surface.DrawTexturedRect( SymbolPositionX + LocalSize , SymbolPositionY + LocalSize - 2 , LocalSize , LocalSize ) -- 1st rectangle
			
			if not StabilityAlert then
				EmitSound( "ahee_suit/alert_capacitor_notice.mp3", Vector(), -1, CHAN_AUTO, 0.2+0.5*(GrappleStability/100), 75, 0, 100, 0 )
			end
			
			StabilityAlert = true
			
		elseif StabilitySettingNumber >= 2 then
			StabilitySettingNumber = 0
			StabilityAlert = false
		end
	else
		StabilitySettingNumber = 1
		StabilityAlert = false
	end
	
	local LeftSize = MeterSize*4
	local LeftPositionX = GrappleScreenX
	local LeftPositionY = GrappleScreenY + (MeterSize*3)
	
	local RightSize = MeterSize*4
	local RightPositionX = GrappleScreenX + (MeterSizeLength) - (LeftSize)
	local RightPositionY = GrappleScreenY + (MeterSize*3)
	
	if (AnglePulling!=nil) and AnglePulling then
		surface.SetDrawColor( 255, 255, 255, 150 ) -- Set the drawing color
		surface.SetMaterial( radeongrapple_gimbal_move ) -- Use our cached material
		surface.DrawTexturedRect( LeftPositionX , LeftPositionY , LeftSize , LeftSize ) -- 1st rectangle
	else
		surface.SetDrawColor( 150, 150, 150, 150 ) -- Set the drawing color
		surface.SetMaterial( radeongrapple_gimbal ) -- Use our cached material
		surface.DrawTexturedRect( LeftPositionX , LeftPositionY , LeftSize , LeftSize ) -- 1st rectangle
	end
	
	if (RadeonicHooking!=nil) and RadeonicHooking then
		surface.SetDrawColor( 255, 255, 255, 150 ) -- Set the drawing color
		surface.SetMaterial( radeongrapple_nucleusform_open ) -- Use our cached material
		surface.DrawTexturedRect( RightPositionX , RightPositionY , RightSize , RightSize ) -- 1st rectangle
	else
		surface.SetDrawColor( 150, 150, 150, 150 ) -- Set the drawing color
		surface.SetMaterial( radeongrapple_nucleusform_close ) -- Use our cached material
		surface.DrawTexturedRect( RightPositionX , RightPositionY , RightSize , RightSize ) -- 1st rectangle
	end
	
	---------Blood Brain Level
	
	
	
	---------Engagement HUD
	
	local HasTargetBool = IsValid(GlobalTargetedNpc)
	local HasTargetColorNum = HasTargetBool and 200 or 20
	
	TargetSelectedIcon = HasTargetBool and engage_marker_target or engage_marker_notarget
	TargetDistanceInCm = HasTargetBool and (( LocalPlayer():GetPos():Distance(GlobalTargetedNpc:GetPos()) / 52.4934 ) * 100) or "100"
	TargetDistanceToMeters = HasTargetBool and math.Round( TargetDistanceInCm / 100 ) or "100"
	
	TargetDangerColor = (HasTargetBool and (TargetDistanceToMeters < 100)) and Color( 255, TargetDistanceToMeters*2, TargetDistanceToMeters*2, 255) or Color( 255, 255, 255, 100)
	TargetCloseString = (HasTargetBool and TargetDistanceToMeters < 100) and "Target closing in at - " or "Distance - "
	
	EngageLerpBool = HasTargetBool and 1 or -1
	EngagementLerp = EngagementLerp and (EngagementLerp - math.Clamp( EngagementLerp - EngageLerpBool , -1 , 1 )*0.1) or 0
	
	if HasTargetBool then
		EngageBarLength = SqSize * (3 + (3*math.Clamp(TargetDistanceToMeters,20,100)/100))
		EngageBarLengthHalf = EngageBarLength / 2
	end
	
	-- Meter
		surface.SetDrawColor( 100, 100, 100, 200 ) -- Set the drawing color
		surface.SetMaterial( EngagementMeter ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.5) - EngageBarLengthHalf , (ScrH() * 0.2) * (EngagementLerp) , EngageBarLength , SqSize/2 )
		
	-- Self Target
		surface.SetDrawColor( 255, 255, 255, HasTargetColorNum ) -- Set the drawing color
		surface.SetMaterial( main_marker_antitarget ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.475) - EngageBarLengthHalf , ((ScrH() * 0.175) - TargetMarkerSize) * (EngagementLerp) , TargetMarkerSize , TargetMarkerSize )
		
	-- Target
		surface.SetDrawColor( 255, 255, 255, HasTargetColorNum ) -- Set the drawing color
		surface.SetMaterial( TargetSelectedIcon ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.525) + EngageBarLengthHalf - TargetMarkerSize , ((ScrH() * 0.175) - TargetMarkerSize) * (EngagementLerp) , TargetMarkerSize , TargetMarkerSize )
		
	-- Distance
		draw.DrawText( TargetCloseString..TargetDistanceToMeters.." Meters", "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.16) * (EngagementLerp) , TargetDangerColor, 1 )
	
	---------Vital Symbols HUD
	
	local VitalsSize = (ScrH() * 0.075)
	
	LineOfSightBool = (IsValid(GlobalTargetedNpc) and tcr.Entity == GlobalTargetedNpc) 
	LineOfSightNaming = LineOfSightBool and vitalsymbol_lineofsight_in or vitalsymbol_lineofsight_out
	LineOfSightColor = LineOfSightBool and 255 or 100
	
	AccurateColizerBool = (IsValid(GlobalTargetedNpc) and TargetAimingAngleBetween and not TargetAimingAngleTooMuch)
	AccurateAimingNumber = (AccurateColizerBool and math.Clamp((1-(TargetAimingAngleBetween/TargetAimingDegrees)^2)*255,100,255)) or 100
	AccurateColizerColor = IsValid(GlobalTargetedNpc) and 255 or 100
	
	if IsValid(GlobalTargetedNpc) then
		
		if GlobalTargetedNpc:Health() > 10000000 or GlobalTargetedNpc:GetNWBool("AHEE_EQUIPED") then
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( object_marker_danger_class4 ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.8) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
			
		elseif GlobalTargetedNpc:Health() < 1000 then
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( object_marker_danger_class1 ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.8) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
			
		elseif GlobalTargetedNpc:Health() > 1000 and GlobalTargetedNpc:Health() < 120000 then
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( object_marker_danger_class2 ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.8) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
			
		elseif GlobalTargetedNpc:Health() > 120000 and GlobalTargetedNpc:Health() < 10000000 then
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( object_marker_danger_class3 ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.8) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
			
		end
		
	end
	
	net.Receive( "Scan_Target", function( len )
		GlobalTargetedNpcFocus = net.ReadEntity()
		GlobalTargetedNpcFocusPos = net.ReadVector()
	end)
	
	local FocusReadingBool = IsValid(GlobalTargetedNpc) and GlobalTargetedNpcFocus == self
	local FocusReadingColor = FocusReadingBool and 255 or 100
	
	local CenteredPosition = IsValid(GlobalTargetedNpc) and GlobalTargetedNpc:WorldSpaceCenter():ToScreen()
	
	-- LineOfSight
		surface.SetDrawColor( LineOfSightColor, LineOfSightColor, LineOfSightColor, 200 ) -- Set the drawing color
		surface.SetMaterial( LineOfSightNaming ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.85) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
	
	-- AccuracyColizer
		surface.SetDrawColor( AccurateColizerColor, AccurateAimingNumber, AccurateAimingNumber, 200 ) -- Set the drawing color
		surface.SetMaterial( vitalsymbol_accuracycolizer ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.9) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
		
	-- FocusReading
		surface.SetDrawColor( FocusReadingColor, FocusReadingColor, FocusReadingColor, 200 ) -- Set the drawing color
		surface.SetMaterial( vitalsymbol_focusreading ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.95) - VitalsSize/2 , (ScrH() * 0.65) , VitalsSize , VitalsSize )
		
		
		if IsValid(GlobalTargetedNpc) and TargetAimingAngleBetween then 
			local AimingFallOff = math.Clamp(TargetAimingAngleBetween/TargetAimingDegrees,0.25,1)
			local DegreesSimulated = math.Round(math.Clamp(TargetAimingAngleBetween/TargetAimingDegrees,0,1) * 100)
			local DegreesSimulatedString = DegreesSimulated < 5 and "<5%" or DegreesSimulated.."%"
			local DegreesFire = DegreesSimulated < 5 and Color( 0, 255, 0, 200 ) or Color( 255, AccurateAimingNumber, AccurateAimingNumber, 200 )
			
			local Nametextwidth, Nametextheight = surface.GetTextSize( DegreesSimulatedString )
			local DegreesSimulatedHelperTrack = (DegreesSimulated/100)^2
			local AccuracySize = TargetMarkerSize*DegreesSimulatedHelperTrack
			
			local MagnitudeVelocity = Vector( math.abs(GlobalTargetedNpc:GetVelocity().x) , math.abs(GlobalTargetedNpc:GetVelocity().y) , math.abs(GlobalTargetedNpc:GetVelocity().z)  )
			local TargetVelocity = (GlobalTargetedNpc:WorldSpaceCenter() + ( MagnitudeVelocity * GlobalTargetedNpc:GetVelocity():GetNormalized() ) ):ToScreen() 
			local Distance = ( LocalPlayer():GetPos():Distance(GlobalTargetedNpc:GetPos()) / 52.4934 )
			local Gravity_Acclimation = ( (GlobalTargetedNpc:WorldSpaceCenter() + ( (Distance^0.5) * (GlobalTargetedNpc:GetVelocity() / 52.4934) ) ) + Vector(0,0,(Distance^0.5) * ( physenv.GetGravity():Length() / 52.4934 )^0.5) ):ToScreen() 
			
			surface.SetDrawColor( 100, 255-(255*DegreesSimulatedHelperTrack), 100, 200-(100*DegreesSimulatedHelperTrack) ) -- Set the drawing color
			surface.SetMaterial( TargetSelectedIcon ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.525) + EngageBarLengthHalf - (TargetMarkerSize-(AccuracySize))  , (ScrH() * 0.175) - (TargetMarkerSize+(AccuracySize*2)) , TargetMarkerSize+AccuracySize , TargetMarkerSize+AccuracySize )
			
			surface.DrawCircle( CenteredPosition.x, CenteredPosition.y, AimingFallOff * (ScrH() * 0.175) , Color( 100, AccurateAimingNumber, 100, 200 ) )
			surface.DrawCircle( CenteredPosition.x, CenteredPosition.y, (AimingFallOff^2) * (ScrH() * 0.175) , Color( 100, AccurateAimingNumber, 100, 200 ) )
			
			local ColizerSize = (ScrH() * 0.01)
			
			surface.SetDrawColor( Color( 255, 255, 255, 240 ) ) -- Set the drawing color
			surface.SetMaterial( main_colizerbeam ) -- Use our cached material
			surface.DrawTexturedRect( TargetVelocity.x - ColizerSize/2, TargetVelocity.y - ColizerSize/2, ColizerSize, ColizerSize )
			
			surface.SetDrawColor( Color( 60, 150, 60, 240 ) ) -- Set the drawing color
			surface.SetMaterial( main_colizerbeam ) -- Use our cached material
			surface.DrawTexturedRect( Gravity_Acclimation.x - ColizerSize/2, Gravity_Acclimation.y - ColizerSize/2, ColizerSize, ColizerSize)
			
			draw.DrawText( DegreesSimulatedString, "SystemWarningFont",  (ScrW() * 0.9) + (VitalsSize/2) - (Nametextwidth), (ScrH() * 0.625) , DegreesFire, 1 )
		end
	
	
	----------------------------------------------------------------------------------------------EXHAUST------------------------------------------------------------------------------
	
	Margin = 8
	MarginHalf = Margin/2
	
	BarSizeX, BarSizeY = (ScrW() * 0.15) , (ScrH() * 0.05)
	BarPosX, BarPosY = (ScrW() * 0.225) - (BarSizeX/2) , (ScrH() * 1) - (BarSizeY) - 16
	
	local ExertionLevel = math.Clamp( (self.MedicalStats.PhysiologicalExertion / 200) , 0 , 1 )
	
	local EnergyLevel = math.Clamp( (self.MedicalStats.PhysiologicalExhaustion / 100) , 0 , 1 )
	local NextEnergyLevel = math.Clamp( (self.MedicalStats.PhysiologicalExhaustion / 100)  - 1 , 0 , 1 )
	
	String = "Cellular Staticity Level : " .. math.Round( self.MedicalStats.PhysiologicalExhaustion , 1 ) .. " %  "
	
	surface.SetFont( "SystemPowerFont" )
	local StringSizeX, StringSizeY = surface.GetTextSize( String )
	
	--- BackGround
	surface.SetDrawColor( 50, 90, 200, 50 )
	surface.DrawRect( BarPosX - MarginHalf, (BarPosY - MarginHalf) , BarSizeX + Margin, BarSizeY + Margin )
	--- BackGround Bar
	surface.SetDrawColor( 0, 0, 100, 120 )
	surface.DrawRect( BarPosX, BarPosY , BarSizeX , BarSizeY )
	--- Outline
	surface.SetDrawColor( 50, 150, 255, 240 )
	surface.DrawOutlinedRect( BarPosX - MarginHalf, (BarPosY - MarginHalf) , BarSizeX + Margin, BarSizeY + Margin )
	--- Bar
	surface.SetDrawColor( 100 + (155*EnergyLevel), (50*EnergyLevel) + 90, (50*EnergyLevel) + 90, 200 )
	surface.DrawRect( BarPosX, BarPosY , EnergyLevel * BarSizeX , BarSizeY )
	
	if NextEnergyLevel > 0 then
		surface.SetDrawColor( 230, 200, 60, 200 )
		surface.DrawRect( BarPosX, BarPosY , NextEnergyLevel * BarSizeX , BarSizeY * 0.1 )
	end
	
	--- ExertionBar
	surface.SetDrawColor( 255, 255, 255, 200 )
	surface.DrawRect( BarPosX, BarPosY - (BarSizeY * 0.5), ExertionLevel * BarSizeX , BarSizeY * 0.25 )
	--- ExertionBarBack
	surface.SetDrawColor( 0, 0, 0, 150 )
	surface.DrawRect( BarPosX, BarPosY - (BarSizeY * 0.5), BarSizeX , BarSizeY * 0.25 )
	
	--- Percentage
	draw.DrawText( String, "SystemPowerFont", (BarPosX + BarSizeX/2) , (BarPosY + BarSizeY/2) - (StringSizeY/2) , Color( 50, 150, 255, 255 ), TEXT_ALIGN_CENTER )
	draw.DrawText( String, "SystemPowerFont", (BarPosX + BarSizeX/2) , (BarPosY + BarSizeY/2) - (StringSizeY/2) - 2 , Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	
	--- ExertionBarText
	String = "Systematic Muscular Exertion : " .. math.Round( self.MedicalStats.PhysiologicalExertion , 1 ) .. " %  "
	draw.DrawText( String, "Default", (BarPosX + BarSizeX/2) , (BarPosY - (BarSizeY * 0.5)) + ((BarSizeY*0.25)/2) - (StringSizeY/2) , Color( 150, 200, 255, 200 ), TEXT_ALIGN_CENTER )
	
	----------------------------------------------------------------------------------------------OXYGEN------------------------------------------------------------------------------
	
	Margin = 8
	MarginHalf = Margin/2
	
	BarSizeX, BarSizeY = (ScrW() * 0.35) , (ScrH() * 0.02)
	BarPosX, BarPosY = (ScrW() * 0.5) - (BarSizeX/2) , (ScrH() * 0.93) - (BarSizeY)
	
	String = "Brain Oxygen Level : " .. math.Round( self.MedicalStats.Consciousness ) .. " %  "
	local ConsciousVisionNum = ( self.MedicalStats.Consciousness/100 )
	local ConsciousVisionOpposedNum = 1 - ( self.MedicalStats.Consciousness/100 )
	
	surface.SetFont( "SystemPowerFont" )
	StringSizeX, StringSizeY = surface.GetTextSize( String )
	
	--- BackGround
	surface.SetDrawColor( 50, 90, 200, 50 )
	surface.DrawRect( BarPosX - MarginHalf, (BarPosY - MarginHalf) , BarSizeX + Margin, BarSizeY + Margin )
	--- BackGround Bar
	surface.SetDrawColor( 0, 0, 100, 120 )
	surface.DrawRect( BarPosX, BarPosY , BarSizeX , BarSizeY )
	--- Outline
	surface.SetDrawColor( 50, 150, 255, 240 )
	surface.DrawOutlinedRect( BarPosX - MarginHalf, (BarPosY - MarginHalf) , BarSizeX + Margin, BarSizeY + Margin )
	--- Bar
	surface.SetDrawColor( 100 + (155*ConsciousVisionNum), (50*ConsciousVisionOpposedNum) + 90, (50*ConsciousVisionOpposedNum) + 90, 200 )
	surface.DrawRect( BarPosX, BarPosY , ConsciousVisionNum * BarSizeX , BarSizeY )
	--- Percentage
	draw.DrawText( String, "SystemPowerFont", (BarPosX + BarSizeX/2), (BarPosY + BarSizeY/2) - (StringSizeY/2) , Color( 255, 150, 150, 255 ), TEXT_ALIGN_CENTER )
	draw.DrawText( String, "SystemPowerFont", (BarPosX + BarSizeX/2), (BarPosY + BarSizeY/2) - (StringSizeY/2) - 2 , Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	
	----------------------------------------------------------------------------------------------ENERGY------------------------------------------------------------------------------
	
	Margin = 8
	MarginHalf = Margin/2
	
	BarSizeX, BarSizeY = (ScrW() * 0.35) , (ScrH() * 0.05)
	BarPosX, BarPosY = (ScrW() * 0.5) - (BarSizeX/2) , (ScrH() * 1) - (BarSizeY) - 16
	
	local EnergyColor = Color( 100, 200*FullEnergy^2, 255*FullEnergy^2, 255)
	
	String1 = "Main Capacitor Energy : "..math.Round(FullEnergy*100,2).." % "
	String2 = "Main Capacitor Energy : "..comma_value(math.Round(self.MainCapacitorMJ,3)).." MegaJoules / "..comma_value(self.MainCapacitorMJLimit).." MegaJoules"
	
	surface.SetFont( "SystemPowerFont" )
	String1SizeX, String1SizeY = surface.GetTextSize( String1 )
	String2SizeX, String2SizeY = surface.GetTextSize( String2 )
	
	--- BackGround
	surface.SetDrawColor( 50, 90, 200, 50 )
	surface.DrawRect( BarPosX - MarginHalf, BarPosY - MarginHalf, BarSizeX + Margin, BarSizeY + Margin )
	--- BackGround Bar
	surface.SetDrawColor( 0, 0, 100, 120 )
	surface.DrawRect( BarPosX, BarPosY , BarSizeX , BarSizeY )
	--- Outline
	surface.SetDrawColor( 50, 150, 255, 240 )
	surface.DrawOutlinedRect( BarPosX - MarginHalf, BarPosY - MarginHalf, BarSizeX + Margin, BarSizeY + Margin, 1 )
	--- Bar
	surface.SetDrawColor( 100, 200*FullEnergy, 255*FullEnergy, 200 )
	surface.DrawRect( BarPosX, BarPosY , FullEnergy * BarSizeX , BarSizeY )
	
	draw.DrawText( String1, "SystemPowerFont", (BarPosX + BarSizeX/2) , (BarPosY + BarSizeY/2) - (StringSizeY/2) , EnergyColor, TEXT_ALIGN_CENTER )
	draw.DrawText( String1, "SystemPowerFont", (BarPosX + BarSizeX/2) , (BarPosY + BarSizeY/2) - (StringSizeY/2) - 2 , Color( 255, 255, 255, 255 ), TEXT_ALIGN_CENTER )
	
	draw.DrawText( String2, "SystemPowerFont", (ScrW() * 0.5), (ScrH() * 0.845) , EnergyColor, 1 )
	draw.DrawText( String2, "SystemPowerFont", (ScrW() * 0.5), (ScrH() * 0.845) - 2 , Color( 255, 255, 255, 255), 1 )
	
	local EnergyLevelString = energy_seperation( math.Round( self.MainCapacitorMJ*1000000 ) )
	local VitalsSize = (ScrH() * 0.1)
	
	if self.ShieldingSetting then
		surface.SetDrawColor( 120, 200, 250, 200 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_activeshieldtoggle ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.775) - VitalsSize/2 , (ScrH() * 0.795) , VitalsSize , VitalsSize )
	else
		surface.SetDrawColor( 50, 50, 50, 200 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_activeshieldtoggle ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.775) - VitalsSize/2 , (ScrH() * 0.795) , VitalsSize , VitalsSize )
	end
	
	if self.DragShieldingSetting then
		surface.SetDrawColor( 170, 250, 190, 200 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_shieldtoggle ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.775) - VitalsSize/2 , (ScrH() * 0.895) , VitalsSize , VitalsSize )
	else
		surface.SetDrawColor( 50, 50, 50, 200 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_shieldtoggle ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.775) - VitalsSize/2 , (ScrH() * 0.895) , VitalsSize , VitalsSize )
	end
	
	if self.MainCapacitorBreak then
		draw.DrawText( "BREAK", "SystemWarningFont", (ScrW() * 0.5), (ScrH() * 0.8) , Color( 255, 20, 20, 255 ), 1 )
		draw.DrawText( "BREAK", "SystemWarningFont", (ScrW() * 0.5), (ScrH() * 0.8) - 2 , Color( 255, 255, 255, 255 ), 1 )
	end
	
	draw.DrawText( EnergyLevelString, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.82) , EnergyColor, TEXT_ALIGN_CENTER )
	draw.DrawText( EnergyLevelString, "SystemBatteryFont", (ScrW() * 0.5), (ScrH() * 0.82) - 2 , Color( 255, 255, 255, 255), TEXT_ALIGN_CENTER )
	
	ReactorEnergyMeasured = math.Round( self.ReactorToAdaptiveMains , 3 )
	NetDeltaMains = math.Round( self.InducedDeltaMains , 3 )
	DeltaMains = math.Round( NetDeltaMains - ReactorEnergyMeasured , 3 )
	
	NetNegativeDeltaMainsColor = 1+math.Clamp(math.ceil(NetDeltaMains),-1,0)
	NegativeDeltaMainsColor = 1+math.Clamp(math.ceil(DeltaMains),-1,0)
	
	NNDMCColor = Color( 255-(55*NetNegativeDeltaMainsColor), (200*NetNegativeDeltaMainsColor), 100+(155*NetNegativeDeltaMainsColor), 255)
	NDMCColor = Color( 255-(55*NegativeDeltaMainsColor), (200*NegativeDeltaMainsColor), 100+(155*NegativeDeltaMainsColor), 255)
	
	NetDBarSizeX, NetDBarSizeY = (ScrW() * 0.25), (ScrH() * 0.015)
	NetDBarX, NetDBarY = (ScrW() * 0.5), (ScrH() * 0.865)
	
	surface.SetDrawColor( 100, 200, 255, 130 )
	surface.DrawRect( NetDBarX - (NetDBarSizeX/2) , NetDBarY , NetDBarSizeX , NetDBarSizeY )
	draw.DrawText( "Net Delta Mains - ["..comma_value(NetDeltaMains).." MegaJoules]", "SystemBatteryFont", NetDBarX, NetDBarY , NNDMCColor, TEXT_ALIGN_CENTER )
	draw.DrawText( "Net Delta Mains - ["..comma_value(NetDeltaMains).." MegaJoules]", "SystemBatteryFont", NetDBarX, NetDBarY - 2 , Color( 255, 255, 255, 255), TEXT_ALIGN_CENTER )
	
	DBarSizeX, DBarSizeY = (ScrW() * 0.25), (ScrH() * 0.0175)
	DBarX, DBarY = (ScrW() * 0.5), (ScrH() * 0.8825)
	surface.SetDrawColor( 100, 200, 255, 130 )
	surface.DrawRect( DBarX - (DBarSizeX/2) , DBarY , DBarSizeX , DBarSizeY )
	draw.DrawText( "Delta Mains - ["..comma_value(DeltaMains).." MegaJoules]", "SystemBatteryFont", DBarX, DBarY , NDMCColor, TEXT_ALIGN_CENTER )
	draw.DrawText( "Delta Mains - ["..comma_value(DeltaMains).." MegaJoules]", "SystemBatteryFont", DBarX, DBarY - 2 , Color( 255, 255, 255, 255), TEXT_ALIGN_CENTER )
	
	----------------------------------------------------------------------------------------------GFORCE------------------------------------------------------------------------------
	
	if self.InducedGForce and self.InducedGForce > 400 then
		draw.DrawText( "OVER G : "..math.Round(self.InducedGForce), "SystemWarningFont", ((ScrW() * 0.5)), (ScrH() * 0.5) , Color( 255, 50, 50, 200), 1 )
		draw.DrawText( "OVER G : "..math.Round(self.InducedGForce), "SystemWarningFont", ((ScrW() * 0.5)), (ScrH() * 0.5) - 2 , Color( 255, 255, 255, 200), 1 )
	end
	
	if self.InducedGForce and self.InducedGForce > 400 or self.ExtremeGForceCalibration then
		
		if not self.GForceTackle:IsPlaying() then
			self.GForceTackle:Play()
		end
		
	elseif InducedGForce and self.InducedGForce < 395 and not self.ExtremeGForceCalibration then
		self.GForceTackle:Stop()
	end
	
	----------------------------------------------------------------------------------------------Health, Armored Integrity, Ammunition------------------------------------------------------------------------------
	
	local Sys_Tacks = self.System_Tacks
	local Radeonic_Toggle = Sys_Tacks.Radeonic_Tack.System_Internal_Switch
	
	local ProcessorSize = (ScrH() * 0.06)
	local Processor_Pos_X, Processor_Pos_Y = (ScrW() * 0.95), (ScrH() * 0.575)
	local Processor_Toggle = Radeonic_Toggle and 1 or 0
	
	surface.SetDrawColor( 255, 255*Processor_Toggle, 255*Processor_Toggle, 120 ) -- Set the drawing color
	surface.SetMaterial( tack_processing_icon ) -- Use our cached material
	surface.DrawTexturedRect( Processor_Pos_X - (ProcessorSize/2) , Processor_Pos_Y , ProcessorSize , ProcessorSize )
	
	local String = " Radeonic - " .. tostring(Sys_Tacks.Radeonic_Tack.System_Internal_Switch)
	surface.SetFont( "Default" )
	width, height = surface.GetTextSize( String )
	
	draw.DrawText( String, "Default", Processor_Pos_X , Processor_Pos_Y+ProcessorSize , Color( 90, 130, 255, 150), 1 )
	
	-- Backing
	SymBackingX = (ScrW() * 0)
	SymBackingY = (ScrH() * 1)
	
	SymBackingH = (ScrH() * 0.25)
	SymBackingW = (ScrH() * 0.2)
	surface.SetDrawColor( 0, 0, 0, 200 ) -- Set the drawing color
	surface.DrawRect( SymBackingX , SymBackingY - SymBackingH , SymBackingW , SymBackingH ) -- 1st rectangle
	
	
	--Health
	BarX = 0.5
	BarY = 0.05
	
	BarH = 0.15 * SymBackingH
	BarW = 0.9 * SymBackingW
	
	-- Health Bar
	local Margin = 6
	local HealthAmt = math.Clamp( math.Round((self:Health() / self:GetMaxHealth()) * 100,2) / 100 , 0 , 1 )
	
	surface.SetDrawColor( 255, 255, 255, 230 ) -- Set the drawing color
	surface.DrawRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) + (Margin/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) + (Margin/2) , (BarW - Margin) * HealthAmt , BarH - Margin ) -- 1st rectangle
	
	-- Health Outside
	surface.SetDrawColor( 80, 120, 200, 50 ) -- Set the drawing color
	surface.DrawOutlinedRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) , BarW , BarH , 2 ) -- 1st rectangle
	
	-- Health Name
	local String = " Bodily Wellness - " .. math.Round( math.Clamp( self:Health() / self:GetMaxHealth() , 0, 1 ) * 100,2) .. "%"
	draw.DrawText( String, "Default", (SymBackingX + (SymBackingW*BarX)) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) + (BarH/2) - Margin , Color( 90, 130, 255, 230), 1 )
	
	
	--Ammunition
	BarX = 0.5
	BarY = 0.75
	
	BarH = 0.2 * SymBackingH
	BarW = 0.9 * SymBackingW
	
	ReserveBarX = 0.5
	ReserveBarY = 0.65
	
	ReserveBarH = 0.08 * SymBackingH
	ReserveBarW = 0.9 * SymBackingW
	
	-- Ammunition Bar
	Margin = 6
	Weapon = self:GetActiveWeapon()
	WeaponPrimaryMaxClip = IsValid(Weapon) and Weapon:GetMaxClip1() or nil
	WeaponSecondaryMaxClip = IsValid(Weapon) and Weapon:GetMaxClip2() or nil
	Validity = IsValid(Weapon) and ((WeaponPrimaryMaxClip > 0) or (WeaponSecondaryMaxClip > 0))
	AmmoAmt = Validity and math.Round((Weapon:Clip1() / WeaponPrimaryMaxClip) * 100,2) or 0
	
	if Validity then 
		AmmunitionReserve = self:GetAmmoCount( Weapon:GetPrimaryAmmoType() )
		AmmunitionReserveBar = AmmunitionReserve/GetConVar( "gmod_maxammo" ):GetFloat()
		if Weapon["Charge"] and type(Weapon["Charge"]) == "table" then
			local WepTable = Weapon["Charge"]
			Charge = (WepTable.Current / WepTable.Max) or 0
		end
		
		if AmmunitionReserveBar <= 0.09 then
			if not AmmunitionReserveBarWarn then
				AmmunitionReserveBarWarn = true
				Warn_Setup( "Ammunition reserve Lower than 10%" )
			end
			surface.SetDrawColor( 255, 0, 0, 50 )
			surface.DrawRect( (SymBackingX + (SymBackingW*ReserveBarX)) - (ReserveBarW/2) + (Margin/2) , ((SymBackingY - SymBackingH) + (SymBackingH*ReserveBarY)) + (Margin/2) , (ReserveBarW - Margin) , ReserveBarH - Margin )
			
		elseif AmmunitionReserveBar > 0.09 and AmmunitionReserveBarWarn then
			if AmmunitionReserveBarWarn then
				AmmunitionReserveBarWarn = false
			end
			
		end
		
		if AmmoAmt <= 14 then
			if not AmmunitionBarWarn then
				AmmunitionBarWarn = true
				Hint_Setup( "Ammunition Lower than 15%" )
			end
			AmmunitionColor = Color(200, 0, 0, 230)
			surface.SetDrawColor( 255, 50, 50, 50 )
			surface.DrawRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) + (Margin/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) + (Margin/2) , (BarW - Margin) , BarH - Margin )
			
		elseif AmmoAmt > 14 then
			if AmmunitionBarWarn then
				AmmunitionBarWarn = false
			end
			AmmunitionColor = Color(255, 255, 255, 230)
			
		end
		
		String = Weapon:Clip1() >= 0 and Weapon:Clip1() or "Invalid"
		surface.SetFont( "SystemWarningFont" )
		width, height = surface.GetTextSize( String )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.53) + (MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) + 2 , Color( 90, 130, 255, 230), 0 )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.53) + (MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) , Color( 255, 255, 255, 230), 0 )
		
		String = Weapon:Clip2() >= 0 and Weapon:Clip2() or "Invalid"
		surface.SetFont( "SystemWarningFont" )
		width, height = surface.GetTextSize( String )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.53) + (MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) - height + 2 , Color( 90, 130, 255, 230), 0 )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.53) + (MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) - height , Color( 255, 255, 255, 230), 0 )
		
		String = AmmunitionReserve >= 0 and AmmunitionReserve or "Invalid"
		surface.SetFont( "SystemWarningFont" )
		width, height = surface.GetTextSize( String )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.47) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) - (height/2) + 2 , Color( 110, 200, 255, 230), 2 )
		draw.DrawText( String, "SystemWarningFont", (ScrW() * 0.47) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) , (ScrH() * 0.5) - (height/2) , Color( 255, 255, 255, 230), 2 )
		
		
		String = Charge and "Charge : "..math.Truncate(Charge*100,1).."%" or "No Nephronic"
		surface.SetFont( "DermaDefaultBold" )
		width, height = surface.GetTextSize( String )
		if Charge then
			surface.SetDrawColor( 0, 0, 0, 130 )
			surface.DrawRect( (ScrW() * 0.5) - (width/2) , (ScrH() * 0.45) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) - height*2 , width , height )
			surface.SetDrawColor( 90, 200, 255, 130 )
			surface.DrawRect( (ScrW() * 0.5) - (width/2) , (ScrH() * 0.45) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) - height*2 , width * Charge , height )
			surface.SetDrawColor( 255, 255, 255, 230 )
			surface.DrawRect( (ScrW() * 0.5) - (width/2) , (ScrH() * 0.45) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) - height*2 , width * Charge^3 , height*0.3 )
		end
		draw.DrawText( String, "DermaDefaultBold", (ScrW() * 0.5) + (width/2) , (ScrH() * 0.45) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) - (height/2) + 2 , Color( 110, 200, 255, 230), 2 )
		draw.DrawText( String, "DermaDefaultBold", (ScrW() * 0.5) + (width/2) , (ScrH() * 0.45) + (-MouseDownAnimation_Num * (ScrH() * 0.05)) - (height/2) , Color( 255, 255, 255, 230), 2 )
		
		surface.SetDrawColor( 255, 255, 255, 230 )
		surface.DrawRect( (SymBackingX + (SymBackingW*ReserveBarX)) - (ReserveBarW/2) + (Margin/2) , ((SymBackingY - SymBackingH) + (SymBackingH*ReserveBarY)) + (Margin/2) , (ReserveBarW - Margin) * AmmunitionReserveBar , ReserveBarH - Margin )
		
		surface.SetDrawColor( AmmunitionColor:Unpack() )
		surface.DrawRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) + (Margin/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) + (Margin/2) , (BarW - Margin) * (AmmoAmt / 100) , BarH - Margin )
	end
	
	--Ammuntion Reserve
	surface.SetDrawColor( 80, 120, 200, 150 ) -- Set the drawing color
	surface.DrawOutlinedRect( (SymBackingX + (SymBackingW*ReserveBarX)) - (ReserveBarW/2) , ((SymBackingY - SymBackingH) + (SymBackingH*ReserveBarY)) , ReserveBarW , ReserveBarH , 2 ) -- 1st rectangle
	
	surface.SetDrawColor( 255, 255, 255, 180 ) -- Set the drawing color
	surface.DrawOutlinedRect( (SymBackingX + (SymBackingW*ReserveBarX)) - (ReserveBarW/2) , ((SymBackingY - SymBackingH) + (SymBackingH*ReserveBarY)) , ReserveBarW * 0.1 , ReserveBarH , 2 ) -- 1st rectangle
	
	-- Ammunition Outside
	surface.SetDrawColor( 80, 120, 200, 150 ) -- Set the drawing color
	surface.DrawOutlinedRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) , BarW , BarH , 2 ) -- 1st rectangle
	
	surface.SetDrawColor( 255, 255, 255, 180 ) -- Set the drawing color
	surface.DrawOutlinedRect( (SymBackingX + (SymBackingW*BarX)) - (BarW/2) , ((SymBackingY - SymBackingH) + (SymBackingH*BarY)) , BarW * 0.15 , BarH , 2 ) -- 1st rectangle
	
	-- Ammunition Name
	String = Validity and Weapon:Clip1() .. " / " .. Weapon:GetMaxClip1() or "Invalid"
	surface.SetFont( "GModNotify" )
	width, height = surface.GetTextSize( String )
	
	draw.DrawText( String, "GModNotify", (SymBackingX + (SymBackingW*BarX)) , (((SymBackingY - SymBackingH) + (SymBackingH*BarY)) + (BarH/2)) - (height/2) , Color( 90, 130, 255, 230), 1 )
	
	-- Ammunition Reserve Name
	String = Validity and (" Reserve - " .. AmmunitionReserve) or "Invalid"
	surface.SetFont( "Default" )
	width, height = surface.GetTextSize( String )
	
	draw.DrawText( String, "Default", (SymBackingX + (SymBackingW*ReserveBarX)) , (((SymBackingY - SymBackingH) + (SymBackingH*ReserveBarY)) + (ReserveBarH/2)) - (height/2) , Color( 90, 130, 255, 230), 1 )
	
	----------------------------------------------------------------------------------------------ShownVitals------------------------------------------------------------------------------
	
	-- Radiation
	
	PosX = (ScrW() * 0.13)
	PosY = (ScrH() * 0.75)
	
	SqSize = (ScrH() * 0.05)
	
		surface.SetDrawColor( 0, 0, 0, 220 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_radiationwarning ) -- Use our cached material
		surface.DrawTexturedRect( PosX, PosY , SqSize , SqSize ) -- 1st rectangle
		
		local ActualRadiation = ( self.ReceivedRadiation*1000 ) or 0
		ReceivedRadiation = ReceivedRadiation and math.Clamp( ReceivedRadiation + ( ActualRadiation*0.01 ) - ( ReceivedRadiation*0.01 ) , 0 , math.huge ) or 0
		
		if ActualRadiation > 0.1 then
			local Rad = math.Clamp(math.Round(self.ReceivedRadiation*1000,3)*(math.random(25,100)/50),150,250)
			surface.SetDrawColor( 255, 255, 255, Rad ) -- Set the drawing color
			surface.SetMaterial( selfidentify_radiationwarning ) -- Use our cached material
			surface.DrawTexturedRect( PosX, PosY , SqSize , SqSize ) -- 1st rectangle
		end
		
	-- Radiation Text
	
		surface.SetDrawColor( 0, 0, 0, 220 ) -- Set the drawing color
		surface.SetMaterial( selfidentify_radiationwarning ) -- Use our cached material
		surface.DrawTexturedRect( PosX, PosY , SqSize , SqSize ) -- 1st rectangle
		draw.SimpleText( "Radiation Exposure Estimate ~ "..comma_value(math.Round(ReceivedRadiation,2)).." Sieverts", "Default", PosX + 5, PosY + SqSize, Color( 255, 255, 255, 100 ) )
		
		if (self.ShieldingSetting and not CheckShieldingDown( self )) then
			draw.SimpleText( "Radiation Prevention = 100%", "Default", PosX + 5, PosY + SqSize + 12, Color( 255, 255, 255, 200 ) )
		elseif not (self.ShieldingSetting and not CheckShieldingDown(self)) and (FullDragEnergy >= 0.1 and self.DragShieldingSetting) then
			draw.SimpleText( "Radiation Prevention = 98%", "Default", PosX + 5, PosY + SqSize + 12, Color( 255, 200, 50, 200 ) )
		else
			draw.SimpleText( "Radiation Prevention = 0%", "Default", PosX + 5, PosY + SqSize + 12, Color( 255, 0, 0, 200 ) )
		end
		
		draw.SimpleText( "Radiation Exposure Sensor = "..comma_value(math.Round(ActualRadiation,2)).." Sieverts", "Default", PosX + 5, PosY + SqSize + 24, Color( 255, 255, 255, 200 ) )
	
	cam.End2D()
	
	
end

function Reactor_Draw()
	
	local self = LocalPlayer()
	local SymSized = (ScrH() * 0.2)
	
	local ResistiveRPM = math.Round( (((1 - (self.MainCapacitorMJ / self.MainCapacitorMJLimit)) * 0.9) + math.abs(math.sin(math.random(0,math.random(0,1))/7)*0.07)) * 100 )
	
	-- Backing
	local SymBackingH = (ScrH() * 0.25)
	local SymBackingW = (ScrH() * 0.3)
	surface.SetDrawColor( 0, 0, 0, 200 ) -- Set the drawing color
	surface.DrawRect( (ScrW() * 1) - SymBackingW , (ScrH() * 1) - SymBackingH , SymBackingW , SymBackingH ) -- 1st rectangle
	
	local ResistiveLoadText = "Resistive Load : "..tostring(ResistiveRPM).."%"
	local ResistiveLoadwidth, ResistiveLoadheight = surface.GetTextSize( ResistiveLoadText )
	draw.DrawText( ResistiveLoadText, "SystemWarningFont", ((ScrW() * 1) - SymBackingW/2) , ((ScrH() * 1) - SymBackingH) + ResistiveLoadheight/2 , Color( 255, 255-(50*(ResistiveRPM/100)), 255-(50*(ResistiveRPM/100)), 200), 1 )
	
	-- InnerSymbol
	local ReactorAdherance = (1 - (self.MainCapacitorMJ / self.MainCapacitorMJLimit))
	local RotationSpeed = (math.sin( CurTime() ) * 45)
	surface.SetDrawColor( 255, 255, 255, 255 ) -- Set the drawing color
	surface.SetMaterial( symbol_core_innerstage ) -- Use our cached material
	surface.DrawTexturedRectRotated( ((ScrW() * 1) - SymSized) + SymSized/2 , ((ScrH() * 1) - SymSized) + SymSized/2 , SymSized , SymSized, ( CurTime() * (20 * (ReactorAdherance + 0.5)) ) + RotationSpeed  ) -- 3st rectangle
	
	-- OuterSymbol
	surface.SetDrawColor( 255, 255, 255, 255 ) -- Set the drawing color
	surface.SetMaterial( symbol_core_outerstage ) -- Use our cached material
	surface.DrawTexturedRectRotated( ((ScrW() * 1) - SymSized) + SymSized/2 , ((ScrH() * 1) - SymSized) + SymSized/2 , SymSized , SymSized, CurTime() * (-40 * (ReactorAdherance + 0.5)) ) -- 2st rectangle
	
	-- RightSymbol
	surface.SetDrawColor( 255, 255, 255, 255 ) -- Set the drawing color
	surface.SetMaterial( symbol_core ) -- Use our cached material
	surface.DrawTexturedRect( (ScrW() * 1) - SymSized , (ScrH() * 1) - SymSized , SymSized , SymSized ) -- 1st rectangle
	
	local BarPadding = (ScrH() * 0.01)
	local BarWidth = (SymBackingW * 0.05)
	local CoreSettings = self.AHEE_Core
	
	-- Speed Bar
	local Speed_Set = math.Clamp( CoreSettings.AHEE_CORE_SPEED / CoreSettings.AHEE_CORE_PRESSUREFLOW , 0 , 1 )
	surface.SetDrawColor( 255, 255, 255, 150 ) -- Set the drawing color
	surface.DrawRect( (ScrW() * 1) - SymBackingW + (BarPadding/2) + BarWidth * 0 , (ScrH() * 1) - SymSized + (BarPadding/2) , BarWidth - BarPadding , (SymSized - BarPadding) * Speed_Set )
	
	-- Temperature Bar
	local Temp_Set = math.Clamp( CoreSettings.AHEE_CORE_TEMPERATURE / 50000000000 , 0 , 1 )
	surface.SetDrawColor( 255, 255, 255, 150 ) -- Set the drawing color
	surface.DrawRect( (ScrW() * 1) - SymBackingW + (BarPadding/2) + BarWidth * 1 , (ScrH() * 1) - SymSized + (BarPadding/2) , BarWidth - BarPadding , (SymSized - BarPadding) * Temp_Set )
	
	-- Density Bar
	local Density_Set = math.Clamp( CoreSettings.AHEE_CORE_DENSITY / (self.MainCapacitorMJLimit * 1000) , 0 , 1 )
	surface.SetDrawColor( 255, 255, 255, 150 ) -- Set the drawing color
	surface.DrawRect( (ScrW() * 1) - SymBackingW + (BarPadding/2) + BarWidth * 2 , (ScrH() * 1) - SymSized + (BarPadding/2) , BarWidth - BarPadding , (SymSized - BarPadding) * Density_Set )
	
end

function Suit_Interaction()
	local self = LocalPlayer()
	
	local SqSize = (ScrH() * 0.075)
	local TargetMarkerSize = SqSize/1.25
	local RealGunPos = FindRealGunPos( self )
	
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
	
	if AbleToInteract.Hit then
		local FinderIcon = (ScrH() * 0.05) * math.Clamp(1-AbleToInteract.Fraction^2,0.5,1)
		
		local Object = AbleToInteract.Entity
		local NameObject = Object:GetClass() or "unknown"
		
		local ObjectPosition = Object:GetPos()
		local ObjectAngle = Object:GetAngles()
		local ObjectMin, ObjectMax = Object:GetModelBounds()
		
		local GrabBool = (AbleToInteract.Fraction < 0.4)
		local GrabBit = GrabBool and 1 or 0
		local CanGrab = GrabBool and 255 or 50
		
		local Fract = (1-AbleToInteract.Fraction)
		
		cam.Start3D()
			
			render.SetColorMaterial()
			render.DrawSphere( AbleToInteract.HitPos, 2, 8, 8, GrabBool and Color( 160, 160, 255, 200 ) or Color( 200, 100, 100, 100 ) )
			
		cam.End3D()
		
		if (Object:IsNPC() or Object:IsNextBot() or Object:IsPlayer()) then
			draw.DrawText( "Strip Item / Shove", "SystemBatteryFont", (ScrW() * 0.5), ( ScrH() * 0.5 ) + FinderIcon + 2 , Color( 0, 0, 0, 255 ), 1 )
			draw.DrawText( "Strip Item / Shove", "SystemBatteryFont", (ScrW() * 0.5), ( ScrH() * 0.5 ) + FinderIcon , Color( CanGrab, CanGrab, CanGrab, 255 ), 1 )
		else
			draw.DrawText( "Shove / Grab", "SystemBatteryFont", (ScrW() * 0.5), ( ScrH() * 0.5 ) + FinderIcon + 2 , Color( 0, 0, 0, 255 ), 1 )
			draw.DrawText( "Shove / Grab", "SystemBatteryFont", (ScrW() * 0.5), ( ScrH() * 0.5 ) + FinderIcon , Color( CanGrab, CanGrab, CanGrab, 255 ), 1 )
		end
		
		if not IsValid(self.HeldItem) then
			local FinderIcon = (ScrH() * 0.05)
			
			local Margin = 4
			local BarX, BarY = (FinderIcon*4), (FinderIcon/2)
			local Fraction = math.Clamp( ((1-AbleToInteract.Fraction)-0.6) / 0.4 , 0 , 1 )
			
			surface.SetDrawColor( 255, 255*(1-Fraction^2), 255*(1-Fraction^2), 200 ) -- Set the drawing color
			surface.DrawRect( (ScrW() * 0.5) - (BarX/2) + Margin , ( ScrH() * 0.55 ) + BarY + Margin , (BarX*(math.Clamp((0.9-(AbleToInteract.Fraction-0.1))*1.1,0,1))) - (Margin*2) , BarY - (Margin*2) )
			
			surface.SetDrawColor( 255, 255, 255, 255 ) -- Set the drawing color
			
			if Fract > 0.6 then
				local KilogramForce = math.Round( (Fraction ^ 3) * (self.NetMass * 450) ) -- 450cm hand surface area
				local KilogramForceText = comma_value(KilogramForce) .. " Kilogram/Cm^2"
				
				draw.DrawText( KilogramForceText, "SystemBatteryFont", (ScrW() * 0.5) , ( ScrH() * 0.5 ) + (FinderIcon + BarY*2) + 2 , Color( 0, 0, 0, 255 ), 1 )
				draw.DrawText( KilogramForceText, "SystemBatteryFont", (ScrW() * 0.5) , ( ScrH() * 0.5 ) + (FinderIcon + BarY*2) , Color( 255, 255, 255, 255 ), 1 )
				
				if Fraction > 0.5 then
					surface.SetDrawColor( 255, 200, 0, 255 )
					draw.DrawText( "Caution : High Deform Rate", "GModNotify", (ScrW() * 0.5) , ( ScrH() * 0.5 ) + (FinderIcon + BarY*2.75) + 2 , Color( 200, 0, 0, 150 ), 1 )
					draw.DrawText( "Caution : High Deform Rate", "GModNotify", (ScrW() * 0.5) , ( ScrH() * 0.5 ) + (FinderIcon + BarY*2.75) , Color( 255, math.abs(math.sin(CurTime()*5)) * 230, 0, 255 ), 1 )
				end
			end
			
			surface.DrawOutlinedRect( (ScrW() * 0.5) - (BarX/2) , ( ScrH() * 0.55 ) + BarY , BarX , BarY, 2 )
			surface.DrawOutlinedRect( (ScrW() * 0.5) - (BarX/2) , ( ScrH() * 0.55 ) + BarY , BarX*0.65 , BarY, 4 )
			
		end
		
		local WhiteCull = CanGrab
		surface.SetDrawColor( WhiteCull, WhiteCull, WhiteCull, 100 + (155 * Fract) ) -- Set the drawing color
		surface.SetMaterial( hand_grab ) -- Use our cached material
		surface.DrawTexturedRect( (ScrW() * 0.5) - FinderIcon/2 , ( ScrH() * 0.5 ) - FinderIcon/1.5 , FinderIcon , FinderIcon )
		
	else
		
		if IsValid(LookingAtTarget.Entity) then
			
			local Object = LookingAtTarget.Entity
			local NameObject = Object:GetClass() or "unknown"
			
			local ObjectModel = Object:GetModel() or "models/hunter/blocks/cube025x025x025.mdl"
			local ObjectPosition = Object:GetPos()
			local ObjectAngle = Object:GetAngles()
			local ObjectMin, ObjectMax = Object:GetModelBounds()
			
			cam.Start3D()
				
				render.ModelMaterialOverride( Material("models/debug/debugwhite") )
				Object:DrawModel()
				
				render.DrawWireframeBox( ObjectPosition, ObjectAngle, ObjectMin, ObjectMax, Color( 60, 100, 255, 200), false )
				
			cam.End3D()
			
			draw.DrawText( "Object - "..NameObject, "SystemBatteryFont", (ScrW() * 0.5), ( ScrH() * 0.5 ) + FinderIcon , Color( 255, 255, 255, 200), 1 )
			surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
			surface.SetMaterial( main_colizerbeam ) -- Use our cached material
			surface.DrawTexturedRect( (ScrW() * 0.5) - FinderIcon/2 , ( ScrH() * 0.5 ) - FinderIcon/2 , FinderIcon , FinderIcon )
			
		end
		
	end
	
end

function Suit_Compensation()
	
	local self = LocalPlayer()
	
	cam.Start2D()
	
	Force = Force or 0
	ScaleNum = ScaleNum or 0
	ScaleType = ScaleType or ""
	
	
	if self:GetVelocity():Length() > (52.4934) and(SlamNormal_z > 0.1 or SlamNormal_z < -0.1) and (TouchingGround or self:IsOnGround()) then
		MalPlhasealSqueeze( false )
		Force = math.Clamp( self:GetVelocity():Length()/52.4934, 0 , 1000000 ) ^ 3
		if math.Round(Force,2) < 1000 then
			ScaleType = "KG / CM^2 "
			ScaleNum = math.Round(Force,2)
		elseif math.Round(Force,2) > 1000 then
			ScaleType = "TONS / CM^2 "
			ScaleNum = math.Round((Force)/1000,2)
		end
	end
	
	if self.MalPlhasealSqueeze then
		local Scr_Pos_X = (ScrW() * 0.5)
		local Scr_Pos_Y = (ScrH() * 0.4)
		local Image_Size = (ScrH() * 0.05)
		local HalfSize = Image_Size/2
		
		surface.SetFont( "SystemWarningFont" )
		
		if self.SevereRadiation then
			local CompensateString = " RADIATION DANGER "
			local width, height = surface.GetTextSize( CompensateString )
			
			draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y , Color( 255, 0, 0, 100), 1 )
			draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y - 2 , Color( 255, 50, 50, 100), 1 )
			
			-- RightSymbol
			surface.SetDrawColor( 255, 255, 255, 160 ) -- Set the drawing color
			surface.SetMaterial( selfidentify_radiationwarning ) -- Use our cached material
			surface.DrawTexturedRect( (Scr_Pos_X+width/2) , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
			
			-- LeftSymbol
			surface.SetDrawColor( 255, 255, 255, 160 ) -- Set the drawing color
			surface.SetMaterial( selfidentify_radiationwarning ) -- Use our cached material
			surface.DrawTexturedRect( (Scr_Pos_X-width/2)-Image_Size , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
			
		else
			if (math.Round(Force,2)/1000) < 25 then
				local CompensateString = " BODILY STRESS COMPENSATION - "..ScaleNum.." - "..ScaleType
				local width, height = surface.GetTextSize( CompensateString )
				
				draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y , Color( 255, 50, 50, 100), 1 )
				draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y - 2 , Color( 255, 255, 255, 100), 1 )
				
				-- RightSymbol
				surface.SetDrawColor( 50, 0, 0, 200 ) -- Set the drawing color
				surface.SetMaterial( WeightSymbol ) -- Use our cached material
				surface.DrawTexturedRect( (Scr_Pos_X+width/2) , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
				
				-- LeftSymbol
				surface.SetDrawColor( 50, 0, 0, 200 ) -- Set the drawing color
				surface.SetMaterial( WeightSymbol ) -- Use our cached material
				surface.DrawTexturedRect( (Scr_Pos_X-width/2)-Image_Size , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
				
			else
				local CompensateString = " ALERT - BODILY STRESS COMPENSATION - "..ScaleNum.." - "..ScaleType.." - ALERT "
				local width, height = surface.GetTextSize( CompensateString )
				local ColorWarn = math.abs(math.sin(CurTime()*10))
				
				if math.abs(math.sin(CurTime()*20)) > 0.25 then
					draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y , Color( 255, 0, 0, 200), 1 )
					draw.DrawText( CompensateString, "SystemWarningFont", Scr_Pos_X, Scr_Pos_Y - 2 , Color( 255-(ColorWarn*155), (ColorWarn*255), 100+(ColorWarn*155), 255), 1 )
				end
				
				-- RightSymbol
				surface.SetDrawColor( 255, (ColorWarn*255), (ColorWarn*255), 200 ) -- Set the drawing color
				surface.SetMaterial( WeightSymbol ) -- Use our cached material
				surface.DrawTexturedRect( (Scr_Pos_X+width/2) , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
				
				-- LeftSymbol
				surface.SetDrawColor( 255, (ColorWarn*255), (ColorWarn*255), 200 ) -- Set the drawing color
				surface.SetMaterial( WeightSymbol ) -- Use our cached material
				surface.DrawTexturedRect( (Scr_Pos_X-width/2)-Image_Size , (Scr_Pos_Y-height/2) , Image_Size , Image_Size )
				
			end
		end
	end
	
	if self.MedicalStats.Consciousness < 20 then
		self.ExtremeGForceCalibration = true
		Compensation_Number = math.random(412,592)
	end
	
	if self.ExtremeGForceCalibration then
		draw.DrawText( "BLACK OUT WARNING - STALL - 0x2"..Compensation_Number.." Compensation", "SystemWarningFont", ((ScrW() * 0.5)), (ScrH() * 0.47) , Color( 255, 0, 0, 230), 1 )
		draw.DrawText( "BLACK OUT WARNING - STALL - 0x2"..Compensation_Number.." Compensation", "SystemWarningFont", ((ScrW() * 0.5)), (ScrH() * 0.47) - 2 , Color( 255, 155, 155, 255), 1 )
		timer.Simple(1.5, function() 
			if not IsValid(self) then return end
			if self.MedicalStats.Consciousness > 20 then 
				self.ExtremeGForceCalibration = false
			end
		end)
	end
	
	cam.End2D()
	
	cam.Start2D()
	
	if self.MedicalStats.Consciousness < 95 or self.InducedGForce > 1000 then
		local Vision = self.MedicalStats.Consciousness / 100
		for i=1, 10 do
			surface.SetDrawColor( 0, 0, 0, (1 - Vision)*255 ) -- Set the drawing color
			surface.SetMaterial( TunnelVision ) -- Use our cached material
			surface.DrawTexturedRect( 0, 0, ScrW() , ScrH()  ) -- Actually draw the rectangle
		end
		surface.SetDrawColor( 0, 0, 0, (1 - Vision)*255 ) -- Set the drawing color
		surface.DrawRect( 0, 0, ScrW() , ScrH()  )
		
		if not self.GForceBreathing:IsPlaying() then
			self.GForceBreathing:Play()
		end
		self.GForceBreathing:ChangeVolume( (1 - Vision)^1.5 )
		self.GForceBreathing:ChangePitch( 100 - ((1 - Vision) * 50) )
		
		
		if not self.PullingGForce:IsPlaying() then
			self.PullingGForce:Play()
		end
		self.PullingGForce:ChangeVolume( (1 - Vision) + (self.InducedGForce/1000) )
		
		local blurMat = Material("pp/blurscreen")
		surface.SetDrawColor(255,255,255,255)
		surface.SetMaterial(blurMat)
		
		blurMat:SetFloat("$blur", (((1 - Vision)^3) * math.sin(RealTime()) * 20 + math.random(-3,3)) + math.Clamp(self.InducedGForce/1000,0,10) )
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect( 0, 0, ScrW() , ScrH() )
		
	end
	
	cam.End2D()
	
end



