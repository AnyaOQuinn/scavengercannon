include("shared.lua")
include("surfaces.lua")
include("ghost.lua")
include("meltdown.lua")
include("menu.lua")

SWEP.PrintName = "Alchemy Gun"
SWEP.Category = "Scavenger Deathmatch"
SWEP.Slot = 2
SWEP.SlotPos = 0
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true
SWEP.wmodel = NULL
killicon.Add("weapon_alchemygun","hud/weapons/weapon_alchemygun",color_white) --This will probably never be seen, but it is possible.
killicon.Add("scav_alchghost","hud/weapons/weapon_alchemygun",color_white)

CreateClientConVar("scav_ag_model","models/props_debris/metal_panel02a.mdl",true,true)
CreateClientConVar("scav_ag_skin",0,true,true)

local shinymat = Material("models/shiny")

local selecttex = surface.GetTextureID("hud/weapons/weapon_alchemygun")
function SWEP:DrawWeaponSelection(x,y,w,h,a)
	surface.SetTexture(selecttex)
	local size = math.min(w,h)
	surface.SetDrawColor(255,255,255,a)
	surface.DrawTexturedRect(x+(w-size)/2,y+(h-size)/2,size,size)
end

function SWEP:ViewModelDrawn()
	local tr = self.Owner:GetEyeTraceNoCursor()
	local ent = tr.Entity
	if !ent:IsValid() || (ent:GetMoveType() != MOVETYPE_VPHYSICS) then
		return
	end
	
	local model = ScavData.FormatModelname(ent:GetModel())
	if !self:CheckForAlchemyInfo(model) then
		timer.Simple(0,function() self:GetAlchemyInfo(model) end)
		return
	end

	local surf = self:GetAlchemyInfo(model).material
	local surftable = self:GetSurfaceInfo(surf)
	r = surftable.metal+surftable.org+surftable.earth
	g = surftable.metal+surftable.chem+surftable.earth*0.8
	b = surftable.metal+surftable.earth*0.6
	render.MaterialOverride(shinymat)
	render.SetColorModulation(r,g,b)
	render.SetBlend(0.4)
	cam.Start3D(EyePos(),EyeAngles())
	ent:DrawModel()
	cam.End3D()
	render.SetBlend(1)
	render.SetColorModulation(1,1,1)
	render.MaterialOverride()
end

local vec_col = Vector(1,1,1)

function SWEP:DrawWorldModel()
	if IsValid(self.wmodel) then
		if self:GetOwner():IsValid() && (self.wmodel.parent != self:GetOwner()) then
			timer.Simple(0, function() self:BuildWModel(self:GetOwner()) end)
		elseif !self:GetOwner():IsValid() && (self.wmodel.parent != self) then
			timer.Simple(0, function() self:BuildWModel(self) end)
		end
		if self.dt.Ghosting then
			self.PanelPose = math.Approach(self.PanelPose,1,FrameTime()*5)
		else
			self.PanelPose = math.Approach(self.PanelPose,0,FrameTime()*5)
		end
		self.wmodel:SetPoseParameter("panel",self.PanelPose)
		render.MaterialOverride(self:GetMaterial())
		local col = self:GetColor()
		if col then
			vec_col.x = col.r/255
			vec_col.y = col.g/255
			vec_col.z = col.b/255
			render.SetBlend(col.a/255)
			render.SetColorModulation(col.r/255,col.g/255,col.b/255)
		end
		self.wmodel:DrawModel()
		render.SetColorModulation(255,255,255)
		render.SetBlend(1)
		render.MaterialOverride()
	else
		local parent = self:GetOwner()
		if !parent:IsValid() then
			parent = self
		end
		timer.Simple(0, function() self.BuildWModel(self,parent) end)
	end
end

function SWEP:BuildWModel(parent) --using a cmodel since SetPoseParameter only works on the LocalPlayer's weapon normally
	if !IsValid(self) || !IsValid(parent) then
		return
	end
	if IsValid(self.wmodel) then
		self.wmodel:Remove()
	end
	local model = self:GetModel()
	self.wmodel = ClientsideModel(model,RENDERGROUP_OPAQUE)
	self.wmodel:SetParent(parent) --just a heads up, if you parent it to the weapon its pose parameters won't work because of bonemerging to existing bones
	local meffects = bit.bor(EF_BONEMERGE,EF_NODRAW)
	if parent:IsPlayer() then
		meffects = bit.bor(meffects,EF_NOSHADOW)
	end
	self.wmodel:AddEffects(meffects)
	self.wmodel.parent = parent
	self.wmodel:SetSkin(self:GetSkin())
end

function SWEP:DestroyWModel()
	if IsValid(self.wmodel) then
		self.wmodel:Remove()
	end
end

function SWEP:ResetMenu()
	if CLIENT && (self:GetOwner() == LocalPlayer()) then
		self.Menu:PopulateWithStock()
		self.Menu:SelectIcon(self.Menu.StockBox.Items[1])
		self.HUD:Update()
	end
end

hook.Add("InputMouseApply","scav_alchrot",function(cmd,x,y,ang)
	local pl = LocalPlayer()
	if pl:Alive() then
		wep = pl:GetActiveWeapon()
	else
		return
	end
	if IsValid(wep) && pl:KeyDown(IN_USE) && (wep:GetClass() == "weapon_alchemygun") && wep.dt.Ghosting  then
		RunConsoleCommand("sg_alch_x",x/30)
		RunConsoleCommand("sg_alch_y",y/30)
		cmd:SetMouseX(0)
		cmd:SetMouseY(0)
		return true
	end
end)

function SWEP:OpenMenu()
	if self.Menu then
		self.Menu:SetWeapon(self)
		self.Menu:OpenMenu()
	end
end

function SWEP:CloseMenu()
	if self.Menu then
		self.Menu:CloseMenu()
	end
end

