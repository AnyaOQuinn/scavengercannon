SWEP.Author = "Ghor"
SWEP.Contact = ""
SWEP.Purpose = "Sometimes you just need a gun."
SWEP.Instructions = "Primary fire to shoot. Be careful, this gun uses your stamina for ammo!"
SWEP.Spawnable = true
SWEP.AdminSpawnable = true

SWEP.ViewModel = "models/weapons/scav/c_backuppistol.mdl"
SWEP.WorldModel = "models/weapons/scav/c_backuppistol.mdl"
SWEP.UseHands = true

SWEP.Primary.Clipsize = 0
SWEP.Primary.Defaultclip = -1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"
SWEP.Secondary.Clipsize = -1
SWEP.Secondary.Defaultclip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"
SWEP.BeginIdle = 0
SWEP.ChargeTime = 0
SWEP.ChargeRate = 5
SWEP.MaxCharge = 10
SWEP.ShotCost = 5
SWEP.NextChargeUp = 0
SWEP.ForcedShots = 0
SWEP.LastFired = 0

SWEP.SoundShoot = "weapons/gauss/fire1.wav"
SWEP.SoundEmpty = "weapons/pistol/pistol_empty.wav"
SWEP.SoundChargeFailure = "buttons/button18.wav"
SWEP.SoundCharge = "ambient/energy/NewSpark03.wav"
SWEP.SoundCharged = "buttons/button3.wav"

PrecacheParticleSystem("scav_exp_bp")

function SWEP:SetupDataTables()
	self:DTVar("Int",0,"Charges")
end

function SWEP:ViewmodelAnimation(anim)
	self:SendWeaponAnim(anim)
	self.BeginIdle = CurTime()+self.Owner:GetViewModel():SequenceDuration()
end

function SWEP:SetNextFire(time)
	self:SetNextPrimaryFire(time)
	self:SetNextSecondaryFire(time)
end

function SWEP:GetAmmo()
	return math.floor(self.Weapon.Owner:GetEnergy()/self.ShotCost)
end

function SWEP:TakeAmmo(amt)
	if self.Owner:GetEnergy() >= amt then
		self.Owner:SetEnergy(self.Owner:GetEnergy()-amt)
		return true
	else
		return false
	end
end

function SWEP:CanFire(amt)
	return self:GetAmmo() > 0
end

function SWEP:Initialize()
end

function SWEP:Think()
	if (self.BeginIdle != 0) && (self.BeginIdle < CurTime()) then
		self:SendWeaponAnim(ACT_VM_IDLE)
		self.BeginIdle = 0
	end
	if CLIENT then
		self.HUD:SetVisible(true)
		self.HUD:SetWeapon(self)
		if !IsFirstTimePredicted() then
			return
		end
	end
	if (self.ChargeTime != 0) then
		if (self.ForcedShots < self.MaxCharge) && (self.NextChargeUp < CurTime()) && self:CanFire(self.ShotCost) then
			self:TakeAmmo(self.ShotCost)
			self.NextChargeUp = CurTime() + 1/self.ChargeRate
			self.ForcedShots = self.ForcedShots+1
			self.dt.Charges = self.ForcedShots
			if IsValid(self.BPChargeEffect) then
				self.BPChargeEffect.dt.level = self.ForcedShots
			end
		end
		if !self.Owner:KeyDown(IN_ATTACK2) then
			self:ReleaseCharge()
		end
	end
end

local bullet = {}

	bullet.Tracer = 1
	bullet.Force = 100
	bullet.Damage = 0
	bullet.TracerName = "ef_scav_tr1"
	bullet.Spread = vector_origin
	local callbackreturnstruct = {["damage"]=CLIENT,["effects"]=true}
	function bullet.Callback(attacker,tr,dmginfo)
		bullet.Damage = math.Clamp((120-tr.Entity:Health())/2,8,25)
		//print("bulletdamage: "..bullet.Damage)
		dmginfo:SetDamage(math.Clamp((116-tr.Entity:Health())/2,8,25))
		dmginfo:SetDamageType(bit.bor(DMG_BULLET,DMG_ENERGYBEAM))
		local dodamage = gamemode.Call("PlayerTraceAttack",attacker,dmginfo,tr.Normal,tr)
		if SERVER then
			local class = tr.Entity:GetClass()
			if (class == "prop_physics") || (class == "prop_physics_respawnable") || (class == "prop_physics_multiplayer") then
				tr.Entity:SetHealth(1)
				//print("setting ent health to 1: "..tostring(tr.Entity:Health()))
			end
			//print(dodamage)
			//if dodamage then
			local mp = !game.SinglePlayer()
			if (mp) then
				SuppressHostEvents(NULL)
			end
				tr.Entity:TakeDamageInfo(dmginfo) --see about modifying the bullet table instead, not sure how the damage is worked out but it's worth a shot
			if (mp) then
				SuppressHostEvents(attacker)
			end
			//end
		elseif GetConVarNumber("cl_scav_high") == 1 then
			//makedlight(tr.HitPos)
		end
		//tr.Entity:TakeDamageInfo(dmginfo)
		//return true,true
		return callbackreturnstruct
	end
	
	function SWEP:Shoot(shots)
		self:ViewmodelAnimation(ACT_VM_PRIMARYATTACK)
		if !IsFirstTimePredicted() then
			return
		end
		if CLIENT then
			//print(CurTime(),"|",UnPredictedCurTime(),"[]",self.Owner:GetEnergy(),"|",self.Owner:GetPredictedEnergy())
		end
		shots = shots || 1
		if shots == 1 then
			if CurTime()-self.LastFired > 0.5 then 
				bullet.Spread = vector_origin
			else
				bullet.Spread = Vector(0.025,0.025,0)
			end
		else
			bullet.Spread = Vector(0.01*shots,0.01*shots,0)
		end
		bullet.Num = shots
		bullet.Dir = self.Owner:GetAimVector()
		bullet.Src = self.Owner:GetShootPos()
		self.Owner:FireBullets(bullet)
		self:EmitSound(self.SoundShoot,100,200)
		self.LastFired = CurTime()
		//self:SetNextFire(UnPredictedCurTime()+self.Owner:GetUnPredictedEnergy())
	end
	
	function SWEP:PrimaryAttack()
		if self:CanFire(self.ShotCost) then
			self:Shoot()
			if IsFirstTimePredicted() then
				self:TakeAmmo(self.ShotCost)
			end
		elseif IsFirstTimePredicted() then
			self:EmitSound(self.SoundEmpty)
		end
	end
	
	function SWEP:SecondaryAttack()
		if !IsFirstTimePredicted() then
			return
		end
		if self.ChargeTime == 0 then
			self.ChargeTime = CurTime()
			self.NextChargeUp = CurTime() + 1/self.ChargeRate
			if SERVER then
				local ef = ents.Create("scav_stream_bpcharge")
				ef:SetOwner(self)
				ef:Spawn()
				self.BPChargeEffect = ef
			end
		end
	end
	
	function SWEP:ReleaseCharge()
		if self.ForcedShots == 0 then
			return
		end
		self.ChargeTime = 0
		self:Shoot(self.ForcedShots)
		self.ForcedShots = 0
		self.dt.Charges = self.ForcedShots
		if IsValid(self.BPChargeEffect) then
			self.BPChargeEffect:Kill()
		end
	end
	
function SWEP:Deploy()
	self:EmitSound("npc/combine_soldier/zipline_clip1.wav")
	self:ViewmodelAnimation(ACT_VM_DEPLOY)
	return true
end

function SWEP:Holster()
	if self.Owner:KeyDown(IN_ATTACK2) then
		return false
	end
	return true
end

function SWEP:OnRemove()
end