-- 这里是热修复C#逻辑代码的地方
local util = require 'xlua.util'

local RULER_ID = 13 -- 八尺戒尺
local POTION_ID = 38 -- 和天下
local PLAYER_ID = 0

local function is_ruler(item)
    return item ~= nil and item.Id == RULER_ID
end

local function is_weapon(item)
    return item ~= nil and item.EquipmentType == 0
end

local function is_armor(item)
    return item ~= nil and item.EquipmentType == 1
end

local function notify_locked(message)
    CS.GameUtil.DisplayPopinfo(message)
end

-- 主角只能使用八尺戒尺，其他角色不能把这把武器换走
util.hotfix_ex(CS.Jyx2.RoleInstance, "CanUseItem", function(self, arg)
    local item = arg
    if type(arg) == "number" then
        item = CS.Jyx2.LuaToCsBridge.ItemTable[arg]
    end
    if is_weapon(item) then
        if is_ruler(item) and self.Key ~= PLAYER_ID then
            return false
        end
        if not is_ruler(item) and self.Key == PLAYER_ID then
            return false
        end
    end
    return self:CanUseItem(arg)
end)

-- 除和天下以外，药品和道具不再回复生命
util.hotfix_ex(CS.Jyx2.RoleInstance, "UseItem", function(self, item)
    local hp = self.Hp
    local maxHp = self.MaxHp
    local hurt = self.Hurt
    self:UseItem(item)
    if item == nil or item.Id == POTION_ID or is_weapon(item) or is_armor(item) then
        return
    end
    self.Hp = hp
    self.MaxHp = maxHp
    self.Hurt = hurt
    self:SetHPAndRefreshHudBar(hp)
end)

util.hotfix_ex(CS.Jyx2.Jyx2LuaBridge, "RoleUseItem", function(roleId, itemId)
    local item = CS.Jyx2.LuaToCsBridge.ItemTable[itemId]
    if roleId == PLAYER_ID and is_weapon(item) and not is_ruler(item) then
        notify_locked("八尺戒尺不可替换")
        return
    end
    if is_ruler(item) and roleId ~= PLAYER_ID then
        notify_locked("八尺戒尺不可替换")
        return
    end
    CS.Jyx2.Jyx2LuaBridge.RoleUseItem(roleId, itemId)
end)

util.hotfix_ex(CS.Jyx2.Jyx2LuaBridge, "RoleUnequipItem", function(roleId, itemId)
    if roleId == PLAYER_ID and itemId == RULER_ID then
        notify_locked("八尺戒尺不可替换")
        return
    end
    CS.Jyx2.Jyx2LuaBridge.RoleUnequipItem(roleId, itemId)
end)

-- 人物界面里点武器会直接卸下或换上，主角这里整段拦住
util.hotfix_ex(CS.XiakeUIPanel, "OnWeaponClick", function(self)
    xlua.private_accessible(CS.XiakeUIPanel)
    local role = self.m_currentRole
    if role ~= nil and role.Key == PLAYER_ID then
        notify_locked("八尺戒尺不可替换")
        return
    end
    self:OnWeaponClick()
end)

-- 开局发放八尺戒尺与和天下，并让主角装备戒尺
util.hotfix_ex(CS.Jyx2.GameRuntimeData, "CreateNew", function()
    local runtime = CS.Jyx2.GameRuntimeData.CreateNew()
    local role = runtime:GetRole(PLAYER_ID)
    local ruler = CS.Jyx2.LuaToCsBridge.ItemTable[RULER_ID]
    role.Weapon = RULER_ID
    role:UseItem(ruler)
    runtime:SetItemUser(RULER_ID, PLAYER_ID)
    return runtime
end)
