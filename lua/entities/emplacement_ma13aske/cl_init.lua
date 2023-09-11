include("shared.lua")

	local cablemat = Material( "cable/physbeam" )
	local elecmat = Material( "cable/blue_elec" )
	local redmat = Material( "cable/redlaser" )

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	self:SetModel(self.Model) 
	
	net.Receive( "ShockwaveFunction", function( len )
		local Dist = net.ReadFloat()
		--print(Dist,Dist^2)
		EmitSound( "main/explodeair0_"..math.random(1,4).."far.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^0.5,120, 0, 100)
		EmitSound( "main/airshockwave.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^2, 120, 0, 100)
		EmitSound( "main/antispatialknock_highsavor.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist^2, 120, 0, math.random(190,200))
		EmitSound( "ambient/explosions/explode_4.wav", LocalPlayer():GetPos(), -2, CHAN_AUTO, Dist/2, 120, 0, math.random(200,230))
	end )
	
	net.Receive( "ma13aske_arc_client", function( len ) 
		local NewSelf = net.ReadEntity() or nil
		local TargetDirect = net.ReadVector()
		local Target = net.ReadEntity() or nil
		local Dist = net.ReadFloat()
	
		if Target:IsWorld() then 
			Target = nil  
		end
		
		hook.Run( "FireClientArc", NewSelf ,TargetDirect , Target , Dist ) 
	end)
	
end

	function ArcToTargetOrPos( self, TargetDirection , Target , MegaAmp )
		if not IsValid(self) then return end
		local TargetDirection = TargetDirection + self:WorldSpaceCenter()
		local MegaAmp = MegaAmp or 1
		local Target = Target
		local HitPos = TargetDirection
		
		if IsValid(Target) then
			HitPos = Target:WorldSpaceCenter()
			Target.Emitter = ParticleEmitter(Target:WorldSpaceCenter())
			Target.ParticleDelay = 0
		end
		
		hook.Add( "Think", self, function ()
			if IsValid(Target) then
				local part = Target.Emitter:Add("particle/smokesprites_0003" , Target:WorldSpaceCenter())
				part:SetStartSize(math.random(40, 200))
				part:SetEndSize(30)
				part:SetStartAlpha(255)
				part:SetEndAlpha(0)
				part:SetDieTime(0.5)
				part:SetRoll(math.random(0, 360))
				part:SetRollDelta(0.01)
				part:SetColor(60, 60, 60)
				part:SetLighting(false)
				part:SetVelocity((self:GetVelocity()*math.random(0.1, 0.3))+(VectorRand() * math.random(100,1000)/5))
			end
		end)
		
		local entiter = nil
		
			hook.Add( "PostDrawTranslucentRenderables", self, function ( isDrawingDepth, isDrawSkybox )
				if isDrawSkybox then return end
				local MegaAmp = MegaAmp or 0
				MegaAmp = math.Clamp( MegaAmp , 0 , 120 )
				if not HitPos then return end
				ParticleEffect( "DirtFireballHit", HitPos , Angle(0,0,0) ) 
				ParticleEffect( "Flashed", HitPos , Angle(0,0,0) )
				HitPos = HitPos + (VectorRand()*20)
					local BeamDepth = 30
					
				cam.Start3D()
				
				render.SetColorModulation( 1, 0, 0 )
				
					for w=1, math.random(1,1+math.Round(MegaAmp/30)) do
						if not IsValid(self) then return end
						local B_P_Table = {}
						local StrikeWidth = 5 + MegaAmp
						local RandomLean = (VectorRand() * 0.35) * StrikeWidth
						local Branches = math.random(3,8)
						local BEAM_DIR = (HitPos - self:WorldSpaceCenter()):GetNormalized()
						render.SetMaterial( cablemat )
						render.StartBeam( BeamDepth )
						render.AddBeam( self:WorldSpaceCenter() , StrikeWidth, 0, ColorRand(false) )
						for k=1, BeamDepth do
							BEAM_DIR = ((BEAM_DIR) + (RandomLean) + (VectorRand() * 20))
							local BeamPlacement = LerpVector( k/BeamDepth , self:WorldSpaceCenter() + BEAM_DIR, HitPos )
							table.insert(B_P_Table,k,BeamPlacement)
							render.AddBeam( BeamPlacement , StrikeWidth, k, Color( 255,0,0,255 ))
						end
						render.EndBeam()
						
						for i=1, Branches do
							local AttachPos = B_P_Table[ math.random( #B_P_Table * 0.8 ) ]
							local EndPos = ( VectorRand() * math.random(-StrikeWidth*2,StrikeWidth*2) )
							local BranchDepth = 12+math.Round(MegaAmp/30)
							
							render.SetMaterial( cablemat )
							render.StartBeam( BeamDepth )
							render.AddBeam( AttachPos, StrikeWidth, 0, ColorRand(false) )
							for s=1, BranchDepth do
								render.AddBeam( LerpVector( s/12 , AttachPos  , AttachPos + EndPos + ( VectorRand() * math.random(3,8) ) )  , StrikeWidth-(s/BranchDepth)*StrikeWidth, s, Color( 0,0,255,255 ))
							end
							render.EndBeam()
						end
						
					end
					
					for w=1, math.random(1,3+math.Round(MegaAmp/30)) do
						if not IsValid(self) then return end
						local B_P_Table = {}
						local StrikeWidth = 5 + MegaAmp
						local RandomLean = (VectorRand() * 0.35) * StrikeWidth
						local Branches = math.random(3,8)
						local BEAM_DIR = (HitPos - self:WorldSpaceCenter()):GetNormalized()
						render.SetMaterial( redmat )
						render.StartBeam( BeamDepth )
						render.AddBeam( self:WorldSpaceCenter() , StrikeWidth, 0, ColorRand(false) )
						for k=1, BeamDepth do
							BEAM_DIR = ((BEAM_DIR) + (RandomLean) + (VectorRand() * 20))
							local BeamPlacement = LerpVector( k/BeamDepth , self:WorldSpaceCenter() + BEAM_DIR, HitPos )
							table.insert(B_P_Table,k,BeamPlacement)
							render.AddBeam( BeamPlacement , StrikeWidth, k, Color( 255,0,0,255 ))
						end
						render.EndBeam()
						
						for i=1, Branches do
							local AttachPos = B_P_Table[ math.random( #B_P_Table * 0.8 ) ]
							local EndPos = ( VectorRand() * math.random(-StrikeWidth*2,StrikeWidth*2) )
							local BranchDepth = 12+math.Round(MegaAmp/30)
							
							render.SetMaterial( redmat )
							render.StartBeam( BeamDepth )
							render.AddBeam( AttachPos, StrikeWidth, 0, ColorRand(false) )
							for s=1, BranchDepth do
								render.AddBeam( LerpVector( s/12 , AttachPos  , AttachPos + EndPos + ( VectorRand() * math.random(3,8) ) )  , StrikeWidth-(s/BranchDepth)*StrikeWidth, s, Color( 0,0,255,255 ))
							end
							render.EndBeam()
						end
						
					end
				
				cam.End3D()
				
			end)
			
			timer.Simple( 0.02 , function()
				hook.Remove( "PostDrawTranslucentRenderables" , self )
			end)
			
	end

hook.Add( "FireClientArc", "ClientArcHook", ArcToTargetOrPos )



