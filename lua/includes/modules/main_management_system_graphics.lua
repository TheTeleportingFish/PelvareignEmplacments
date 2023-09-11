AddCSLuaFile()

function BlurBackground(panel)
	if not IsValid(panel) then return end
	if panel.Dynamic == nil then panel.Dynamic = 0 return end
	
	local blurMat = Material("pp/blurscreen")
	local layers,density,alpha=20,20,255
	local x,y=panel:LocalToScreen(0,0)
	surface.SetDrawColor(255,255,255,alpha)
	surface.SetMaterial(blurMat)
	local FrameRate,Num=1/FrameTime(),5
	for i=1,Num do
		blurMat:SetFloat( "$blur" , (i/layers) * density * panel.Dynamic )
		blurMat:Recompute()
		render.UpdateScreenEffectTexture()
		surface.DrawTexturedRect( -x,-y,ScrW(),ScrH() )
	end
	
	panel.Dynamic=math.Clamp(panel.Dynamic+(1/FrameRate),0,1)
	
end

function PointOnCircle( ang, radius, offX, offY )
	ang =  math.rad( ang )
	local x = math.cos( ang ) * radius + offX
	local y = math.sin( ang ) * radius + offY
	return x, y
end

function Create_Menu( Panel, X, Y, Width, Height )
	if IsValid(Panel) then
		Panel:Remove()
		return
	end
	local FrameMargin = Width/20
	local Panel = vgui.Create( "DPanel", MainFrame , "Frame1" )
	Panel:SetSize( Width, Height )
	Panel:SetPos( X, Y )
	
	Panel.Paint = function( Main, Width, Height )
		draw.RoundedBox( FrameMargin, 0, 0, Width, Height, Color(0,0,0,180) )
	end
	
	return Panel
end

function Create_GeneralizedTab( Title, Key, TabArray, X, Y, Width, Height, ButtonFunction )
	
	surface.SetFont("SystemWarningFont")
	local FrameTextX, FrameTextY = surface.GetTextSize( Title )
	local FrameMargin = Width/20
	
	local TextMargin = FrameMargin/4
	local TextPositionX, TextPositionY = X - (FrameTextX/2) ,Y - (FrameTextY/2)
	
	local ButtonSizeX, ButtonSizeY = FrameTextX+(TextMargin*2), FrameTextY+TextMargin
	local ButtonPositionX, ButtonPositionY = X - FrameTextX, Y + (TextMargin/2)
	
	local ButtonColor = Color(0,0,0,200)
	local TabPanelPosX = 1
	
	local TabPanel = vgui.Create( "DPanel", nil )
	TabPanel:SetBackgroundColor( Color(190,190,190,120) )
	TabPanel:SetPos( ButtonPositionX - ButtonSizeY, ButtonPositionY )
	TabPanel:SetSize( ButtonSizeX + ButtonSizeY, ButtonSizeY )
	
	local Button = vgui.Create( "DButton", TabPanel )
	Button:SetText( "" )
	Button:SetColor( ButtonColor )
	Button:SetPos( ButtonSizeX , 0 )
	Button:SetSize( ButtonSizeX + ButtonSizeY, ButtonSizeY )
	
	TabPanel.Name = Title
	TabPanel.SelectionButton = Button
	
	Button.OnDepressed = function()
		ButtonColor = Color(160,160,160,200)
	end
	
	Button.OnReleased = function()
		 Button.Menus = ButtonFunction()
		 
		for Num,TabInCall in ipairs( TabArray ) do 
			MainFrame.TabSelected = TabPanel.Name
			 if TabPanel != TabInCall then 
				TabInCall.Tab = false
				
				if TabInCall.Menus then
					for Num,Menu in ipairs( TabInCall.Menus ) do 
						if IsValid(Menu) then
							Menu:Remove()
						end
					end
				end
				
			 end 
		 end
		 
		if not TabPanel.Tab then
			TabPanel.Tab = true
			LocalPlayer():EmitSound( "ahee_suit/hud_systemmenu_newmenu.wav", 120, math.random(90,96), 1, CHAN_STATIC, 0, 0 )
		else
			TabPanel.Tab = false
			MainFrame.TabSelected = nil
			LocalPlayer():EmitSound( "ahee_suit/hud_systemmenu_resetmenu.wav", 120, math.random(90,96), 1, CHAN_STATIC, 0, 0 )
		end
		 
	end
	
	TabPanel.Paint = function( self, w, h )
		
		if not IsValid(MainFrame) then TabPanel:Remove() end
		if IsValid( Key ) and MainFrame.TabSelected != TabPanel then
			TabPanel.Tab = false
			MainFrame.TabSelected = nil
			LocalPlayer():EmitSound( "ahee_suit/hud_systemmenu_resetmenu.wav", 120, math.random(90,96), 1, CHAN_STATIC, 0, 0 )
		end
		
		if TabPanel.Tab then
			TabPanelPosX = math.Clamp(TabPanelPosX+0.1,1,2)
			ButtonColor = Color(160,160,160,100)
		else
			TabPanelPosX = math.Clamp(TabPanelPosX-0.1,1,2)
			ButtonColor = Color(0,0,0,200)
		end
		
		TabPanel:SetPos( ButtonPositionX - ButtonSizeY * TabPanelPosX, ButtonPositionY )
		TabPanel:SetSize( ButtonSizeX + ButtonSizeY * TabPanelPosX, ButtonSizeY )
		Button:SetPos( ButtonSizeX + ( ButtonSizeY * (TabPanelPosX - 1) ), 0 )
		
		draw.RoundedBox( FrameMargin/5, 0, 0, w, h, ButtonColor )
		draw.SimpleText( Title, "SystemWarningFont", (w/2) - (h/2), (h/2), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	local SelecMat = Material( "hud/weapons_hud/markers/object_marker_selected.png" , "smooth unlitgeneric" )
	local UnselecMat = Material( "hud/weapons_hud/markers/object_marker_unselected.png" , "smooth unlitgeneric" )
	
	Button.Paint = function( self, w, h )
		
		local ButtonX, ButtonY = 0, 0
		local MarginFrame = FrameMargin/5
		if TabPanel.Tab then
			draw.RoundedBox(MarginFrame , ButtonX, ButtonY, h, h, Color(60,200,250,200) )
			surface.SetMaterial( SelecMat ) 
		else
			draw.RoundedBox(MarginFrame , ButtonX, ButtonY, h, h, Color(60,150,250,50) )
			surface.SetMaterial( UnselecMat ) 
		end
		surface.SetDrawColor( 255, 255, 255, 230 ) -- Set the drawing color
		surface.DrawTexturedRect( ButtonX, ButtonY, h, h ) -- Actually draw the rectangle
		
	end
	
	table.insert( TabArray , TabPanel )
	
	return TabPanel, TabPanel:GetSize()
	
end

function Create_MenuTab( Title, TabArray, X, Y, Width, Height, ButtonFunction )
	
	surface.SetFont("SystemWarningFont")
	local FrameTextX, FrameTextY = surface.GetTextSize( Title )
	local FrameMargin = Width/30
	
	local TextMargin = FrameMargin/4
	local TextPositionX, TextPositionY = X - (FrameTextX/2) ,Y - (FrameTextY/2)
	
	local ButtonSizeX, ButtonSizeY = FrameTextX+(TextMargin*2), FrameTextY+TextMargin
	local ButtonPositionX, ButtonPositionY = X+(TextMargin/2), Y+(TextMargin/2)
	
	local ButtonColor = Color(0,0,0,200)
	
	local Button = vgui.Create( "DButton", MainFrame )
	Button:SetText( "" )
	Button:SetColor( ButtonColor )
	Button:SetPos( ButtonPositionX , ButtonPositionY )
	Button:SetSize( ButtonSizeX, ButtonSizeY )
	
	Button.Name = Title
	
	Button.OnDepressed = function()
		ButtonColor = Color(160,160,160,200)
	end
	
	Button.Paint = function( self, w, h )
		 if Button.Tab then
			ButtonColor = Color(160,160,160,200)
		else
			ButtonColor = Color(0,0,0,200)
		 end
		draw.RoundedBox( FrameMargin/5, 0, 0, w, h, ButtonColor )
		draw.SimpleText( Title, "SystemWarningFont", (w/2), (h/2), color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
	
	Button.OnReleased = function()
		 Button.Menus = ButtonFunction()
		 
		 LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 76, 1, CHAN_STATIC, 0, 0 )
		 
		for Num,TabInCall in ipairs( TabArray ) do 
			MainFrame.TabSelected = Button.Name
			 if Button != TabInCall then 
				TabInCall.Tab = false
				
				if TabInCall.Menus then
				for Num,Menu in ipairs( TabInCall.Menus ) do 
					if IsValid(Menu) then
						Menu:Remove()
					end
				end
				end
				
			 end 
		 end
		 
		if not Button.Tab then
			Button.Tab = true
		else
			Button.Tab = false
			MainFrame.TabSelected = nil
		end
		 
	end
	
	table.insert( TabArray , Button )
	
	return Button, ButtonSizeX, ButtonSizeY
	
end

function NormalButton( NameText , Panel , ButtonSettings , CustomOnChangeFunction )
	local self = LocalPlayer()
	
	local NameString = ButtonSettings.Name
	
	local SizeMultX = ButtonSettings.SizeMult.x or 0
	local SizeMultY = ButtonSettings.SizeMult.y or 0
	local PosMultX = ButtonSettings.PosMult.x or 0
	local PosMultY = ButtonSettings.PosMult.y or 0
	
	local PosX = ButtonSettings.Pos.x or 0
	local PosY = ButtonSettings.Pos.y or 0
	
	local ValueChange = ButtonSettings.ValueChange
	
	local ColorMulted = ButtonSettings.ColorMult
	local FrameMargin = ButtonSettings.FrameMargin
	
	local ValueDefault = ButtonSettings.ValueDefault
	local Value = self[ValueChange] or ValueDefault
	
	local ApplyButton = vgui.Create( "DButton", Panel )
	
	local function EmitGeneralNoise( Pitch )
		EmitSound( "main/target_tick.wav", Vector(), -1, CHAN_AUTO, 1, 75, 0, Pitch, 0 )
	end
	
	local function ChangeValues( Value )
		
		if CustomOnChangeFunction then
			CustomOnChangeFunction()
		end
		
		net.Start( "AHEE_Change_Suit_Equipment" )
			net.WriteString( ValueChange )
			net.WriteString( "Bool" )
			net.WriteBool( Value )
		net.SendToServer()
		
		self[ValueChange] = Value
		
	end
	
	local Paneled = vgui.Create( "DPanel", Panel , "Framed" )
	Paneled:SetSize( PosX, ApplyButtonY )
	Paneled:SetPos( 0, PosY*PosMultY )
	
	Paneled.Paint = function( selfitem, w, h )
		MainRatio = self[ValueChange] and 1 or 0.1
		
		for i=0,10 do
			local RatioColor = (MainRatio*(i/10)) * 255
			local TabColors = Color( RatioColor * ColorMulted[1] , RatioColor * ColorMulted[2] , RatioColor * ColorMulted[3] , 140 * ColorMulted[4] )
			draw.RoundedBox( FrameMargin/5, ( (PosX*0.1) * (10-i) ) - ((PosX*PosMultX) - ApplyButtonX/2), FrameMargin/2, (PosX*0.1), h-FrameMargin, TabColors )
		end
	end
	
	local ApplyButtonX, ApplyButtonY = (PosX * SizeMultX), (PosY * SizeMultY)
	local ApplyButtonColor = Color(0,0,0,100)
	
	ApplyButton:SetText( "" )
	ApplyButton:SetFont( "Default" )
	ApplyButton:SetColor( Color(0,0,0,240) )
	ApplyButton:SetPos( (PosX*PosMultX) - ApplyButtonX/2, PosY*PosMultY )
	ApplyButton:SetSize( PosX*SizeMultX, PosY*SizeMultY )
	
	ApplyButton.Paint = function( selfitem, w, h )
		
		NameValue = self[ValueChange] and "On" or "Off"
		
		local Min = (w * 0.9)
		local Max = (w * 1.1)
		local ApplyPosMin = (w * 0.2)
		local ApplyPosMax = (w * 0.35)
		
		local IsBeingHovered = ApplyButton:IsChildHovered() or ApplyButton:IsHovered()
		
		selfitem.TextPos = selfitem.TextPos or Max
		selfitem.ApplyPos = selfitem.ApplyPos or ApplyPosMin
		
		if IsBeingHovered then
			selfitem.TextPos = math.Clamp( selfitem.TextPos - (w * 0.05) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos + (w * 0.05) , ApplyPosMin , ApplyPosMax )
		else
			selfitem.TextPos = math.Clamp( selfitem.TextPos + (w * 0.02) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos - (w * 0.02) , ApplyPosMin , ApplyPosMax )
		end
		
		if self[ValueChange] then
			ApplyButtonColor = Color(255,255,255,255)
		else
			ApplyButtonColor = Color(150,150,150,255)
		end
		
		local ApplyButtonMargin = h/6
		
		draw.RoundedBox( ApplyButtonMargin, 0, 0, w, h, ApplyButtonColor )
		
		draw.SimpleText( NameString..NameValue , "DermaDefault", w*0.5, h*0.5, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	
	ApplyButton.OnReleased = function()
		MainRatio = self[ValueChange] and 1 or 0.1
		EmitGeneralNoise( 100 + (50 * MainRatio) )
		ChangeValues( !self[ValueChange] )
		LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
	end
	
end

function NormalSlider( Name , NameText , NameString , Panel , SliderSettings, CustomOnChangeFunction )
	local self = LocalPlayer()
	
	local SizeMultX = SliderSettings.SizeMult.x or 0
	local SizeMultY = SliderSettings.SizeMult.y or 0
	local PosMultX = SliderSettings.PosMult.x or 0
	local PosMultY = SliderSettings.PosMult.y or 0
	
	local PosX = SliderSettings.Pos.x or 0
	local PosY = SliderSettings.Pos.y or 0
	local SizeX = SliderSettings.Size.x or 0
	local SizeY = SliderSettings.Size.y or 0
	
	local MinMax = SliderSettings.MinMax
	local Decimal = SliderSettings.Decimals or 0
	local Interval = SliderSettings.Intervals or 1
	local ValueChange = SliderSettings.ValueChange
	local ValueMult = SliderSettings.ValueMult
	
	local ColorMulted = SliderSettings.ColorMult
	local FrameMargin = SliderSettings.FrameMargin
	
	local ValueDefault = SliderSettings.ValueDefault
	local Value = self[ValueChange] or ValueDefault
	
	local ValueDifference = ( ValueMult > 0 and (Value * math.abs(ValueMult)) ) or ( ValueMult < 0 and (Value / math.abs(ValueMult)) )
	local ValueOpposedDifference = ( ValueMult < 0 and (Value * math.abs(ValueMult)) ) or ( ValueMult > 0 and (Value / math.abs(ValueMult)) )
	
	local Name = vgui.Create( "DNumSlider", Panel )
	local NameText = vgui.Create("DNumberWang", Name)
	local ApplyButton = vgui.Create( "DButton", Name )
	
	Name:SetPos( PosX*PosMultX, PosY*PosMultY )
	Name:SetSize( SizeX*SizeMultX, SizeY*SizeMultY )
	Name:SetMinMax( MinMax[1], MinMax[2] )
	Name:SetDecimals( Decimal )	-- Decimal places
	Name:SetValue( ValueOpposedDifference )
	
	local function EmitGeneralNoise( Pitch )
		EmitSound( "main/target_tick.wav", Vector(), -1, CHAN_AUTO, 1, 75, 0, Pitch, 0 )
	end
	
	local function ChangeValues( Value )
		ValueDifference = ( ValueMult > 0 and (Value * math.abs(ValueMult)) ) or ( ValueMult < 0 and (Value / math.abs(ValueMult)) )
		ValueOpposedDifference = ( ValueMult < 0 and (Value * math.abs(ValueMult)) ) or ( ValueMult > 0 and (Value / math.abs(ValueMult)) )
		
		if CustomOnChangeFunction then
			CustomOnChangeFunction( self , Value )
		end
		
		local Floated = ValueDifference
		local RoundValue = SliderSettings.RoundValue or 5 
		
		net.Start( "AHEE_Change_Suit_Equipment" )
			net.WriteString( ValueChange )
			net.WriteString( "Float" )
			net.WriteFloat( Floated )
			net.WriteInt( RoundValue , 10 )
		net.SendToServer()
		
		self[ValueChange] = Floated
		
	end
	
	ApplyButton:SetText( "Set" )
	ApplyButton:SetFont( "Default" )
	ApplyButton:SetColor( Color(0,0,0,240) )
	
	Name.Paint = function( selfitem, w, h )
		local MainRatio = ( Name:GetValue() - Name:GetMin() ) / ( Name:GetMax() - Name:GetMin() )
		local TextColor = color_white
		
		local NameCheck = ( ValueMult > 0 and (Name:GetValue() * math.abs(ValueMult)) ) or ( ValueMult < 0 and (Name:GetValue() / math.abs(ValueMult)) )
		local NotApplied = ( NameCheck != self[ValueChange] )
		
		if NotApplied then
			TextColor = Color(255,0,0,255)
		else
			TextColor = color_white
		end
		
		
		draw.RoundedBox( FrameMargin/5, (PosX*0.5), FrameMargin/2, PosX, h-FrameMargin, Color( 0,0,0,100 )  )
		draw.SimpleText( NameString, "SystemPowerFont", PosX*1.0, h*0.25, TextColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
		local Min = (w * 0.9)
		local Max = (w * 1.1)
		local ApplyPosMin = (w * 0.2)
		local ApplyPosMax = (w * 0.35)
		
		local IsBeingHovered = Name:IsChildHovered() or Name:IsHovered()
		
		selfitem.TextPos = selfitem.TextPos or Max
		selfitem.ApplyPos = selfitem.ApplyPos or ApplyPosMin
		
		NameText:SetPos( selfitem.TextPos , h * 0.25 )
		NameText:SetSize( PosX * 0.15 , h * 0.5 )
		NameText:SetMinMax( selfitem:GetMin() , selfitem:GetMax() )
		NameText:SetInterval( Interval )
		NameText:SetValue( math.Round( selfitem:GetValue() , selfitem:GetDecimals() ) )
		
		NameText.OnValueChanged = function( selfitem )
			Name:SetValue( NameText:GetValue() )
		end
		
		local ApplyButtonSize = (h * 0.4)
		
		ApplyButton:SetPos( selfitem.ApplyPos, (h * 0.5) - ApplyButtonSize/2 )
		ApplyButton:SetSize( ApplyButtonSize, ApplyButtonSize )
		
		if IsBeingHovered then
			selfitem.TextPos = math.Clamp( selfitem.TextPos - (w * 0.05) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos + (w * 0.05) , ApplyPosMin , ApplyPosMax )
		else
			selfitem.TextPos = math.Clamp( selfitem.TextPos + (w * 0.02) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos - (w * 0.02) , ApplyPosMin , ApplyPosMax )
		end
		
	end
	
	
	
	local ApplyButtonColor = Color(200,200,200,240)
	
	ApplyButton.OnDepressed = function()
		ApplyButtonColor = Color(130,130,130,240)
	end
	
	ApplyButton.Paint = function( selfitem, w, h )
		local ApplyButtonMargin = h/12
		
		local NameCheck = ( ValueMult > 0 and (Name:GetValue() * math.abs(ValueMult)) ) or ( ValueMult < 0 and (Name:GetValue() / math.abs(ValueMult)) )
		local NotApplied = ( NameCheck != self[ValueChange] )
		
		if NotApplied then
			ApplyButton:SetColor( Color(255,0,0,240) ) 
		else
			ApplyButton:SetColor( Color(0,0,0,240) )
		end
		
		draw.RoundedBox( ApplyButtonMargin, 0, 0, w, h, Color(200,200,200,240) )
		draw.RoundedBox( ApplyButtonMargin/1.5, ApplyButtonMargin/2, ApplyButtonMargin/2, w-ApplyButtonMargin, h-ApplyButtonMargin, ApplyButtonColor )
	end
	
	ApplyButton.OnReleased = function()
		ApplyButtonColor = Color(200,200,200,240)
		ChangeValues( Name:GetValue() )
		LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
	end
	
	Name.OnValueChanged = function( ply, value )
		local MainRatio = ( Name:GetValue() - Name:GetMin() ) / ( Name:GetMax() - Name:GetMin() )
		EmitGeneralNoise( 100 + (50 * MainRatio) )
	end
	
end

function Suit_System_Button( NameText , Panel , ButtonSettings , CustomOnChangeFunction )
	local self = LocalPlayer()
	
	local NameString = ButtonSettings.Name
	
	local SizeMultX = ButtonSettings.SizeMult.x or 0
	local SizeMultY = ButtonSettings.SizeMult.y or 0
	local PosMultX = ButtonSettings.PosMult.x or 0
	local PosMultY = ButtonSettings.PosMult.y or 0
	
	local PosX = ButtonSettings.Pos.x or 0
	local PosY = ButtonSettings.Pos.y or 0
	local SizeX = ButtonSettings.Size.x or 0
	local SizeY = ButtonSettings.Size.y or 0
	
	local ValueChange = ButtonSettings.ValueChange
	
	local ColorMulted = ButtonSettings.ColorMult
	local FrameMargin = ButtonSettings.FrameMargin
	
	local ValueDefault = ButtonSettings.ValueDefault
	local Value = self[ValueChange] or ValueDefault
	
	local ApplyButton = vgui.Create( "DButton", Panel )
	
	local function EmitGeneralNoise( Pitch )
		EmitSound( "main/target_tick.wav", Vector(), -1, CHAN_AUTO, 1, 75, 0, Pitch, 0 )
	end
	
	local function ChangeValues( Value )
		
		if CustomOnChangeFunction then
			CustomOnChangeFunction()
		end
		
		net.Start( "AHEE_Change_Suit_Equipment" )
			net.WriteString( ValueChange )
			net.WriteString( "Bool" )
			net.WriteBool( Value )
		net.SendToServer()
		
		self[ValueChange] = Value
		
	end
	
	local Paneled = vgui.Create( "DPanel", Panel , "Framed" )
	Paneled:SetSize( PosX, ApplyButtonY )
	Paneled:SetPos( 0, PosY*PosMultY )
	
	Paneled.Paint = function( selfitem, w, h )
		MainRatio = self[ValueChange] and 1 or 0.1
		
		for i=0,10 do
			local RatioColor = (MainRatio*(i/10)) * 255
			local TabColors = Color( RatioColor * ColorMulted[1] , RatioColor * ColorMulted[2] , RatioColor * ColorMulted[3] , 140 * ColorMulted[4] )
			draw.RoundedBox( FrameMargin/5, ( (PosX*0.1) * (10-i) ) - ((PosX*PosMultX) - ApplyButtonX/2), FrameMargin/2, (PosX*0.1), h-FrameMargin, TabColors )
		end
	end
	
	local ApplyButtonX, ApplyButtonY = (PosX * SizeMultX), (PosY * SizeMultY)
	local ApplyButtonColor = Color(0,0,0,100)
	
	ApplyButton:SetText( "" )
	ApplyButton:SetFont( "Default" )
	ApplyButton:SetColor( Color(0,0,0,240) )
	ApplyButton:SetPos( (PosX*PosMultX) - ApplyButtonX/2, PosY*PosMultY )
	ApplyButton:SetSize( PosX*SizeMultX, PosY*SizeMultY )
	
	ApplyButton.Paint = function( selfitem, w, h )
		
		NameValue = self[ValueChange] and "On" or "Off"
		
		local Min = (w * 0.9)
		local Max = (w * 1.1)
		local ApplyPosMin = (w * 0.2)
		local ApplyPosMax = (w * 0.35)
		
		local IsBeingHovered = ApplyButton:IsChildHovered() or ApplyButton:IsHovered()
		
		selfitem.TextPos = selfitem.TextPos or Max
		selfitem.ApplyPos = selfitem.ApplyPos or ApplyPosMin
		
		if IsBeingHovered then
			selfitem.TextPos = math.Clamp( selfitem.TextPos - (w * 0.05) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos + (w * 0.05) , ApplyPosMin , ApplyPosMax )
		else
			selfitem.TextPos = math.Clamp( selfitem.TextPos + (w * 0.02) , Min , Max )
			selfitem.ApplyPos = math.Clamp( selfitem.ApplyPos - (w * 0.02) , ApplyPosMin , ApplyPosMax )
		end
		
		if self[ValueChange] then
			ApplyButtonColor = Color(255,255,255,255)
		else
			ApplyButtonColor = Color(150,150,150,255)
		end
		
		local ApplyButtonMargin = h/6
		
		surface.SetDrawColor( 255, 255, 255, 200 ) -- Set the drawing color
		surface.SetMaterial( main_colizerbeam ) -- Use our cached material
		surface.DrawTexturedRect( 0 , 0 , w , h )
		
		draw.RoundedBox( ApplyButtonMargin, 0, 0, w, h, ApplyButtonColor )
		
		draw.SimpleText( NameString..NameValue , "DermaDefault", w*0.5, h*0.5, color_black, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
		
	end
	
	
	ApplyButton.OnReleased = function()
		MainRatio = self[ValueChange] and 1 or 0.1
		EmitGeneralNoise( 100 + (50 * MainRatio) )
		ChangeValues( !self[ValueChange] )
		LocalPlayer():EmitSound( "ahee_suit/hud_systemmenuaccept.wav", 120, 100, 1, CHAN_STATIC, 0, 0 )
	end
	
end


