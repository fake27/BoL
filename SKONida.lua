local version = "1.3"
_G.SKONIDA_UPDATE = true
if myHero.charName ~= "Nidalee" then return end

-------------------------------------------------------------------------------------------------
------------------------------------------LIBS And Update---------------------------------
-------------------------------------------------------------------------------------------------
local SKONAME = "SKONida"
local SKOFILEPATH = SCRIPT_PATH.."SKONida.lua"
local SKOHOST = "raw.github.com"
local SKOHPATH = "/SKOBoL/BoL/master/"
local SKOUrl = "https://"..SKOHOST..SKOHPATH

local SourceLibUrl = "https://raw.githubusercontent.com/TheRealSource/public/master/common/SourceLib.lua"
local SourceLibPath = LIB_PATH.."SourceLib.lua"
printMsg = function(message) print("<font color='#2e99ea'><b>"..SKONAME..":</b></font> <font color='#FFF'>"..message.."</font>") end
if FileExist(SourceLibPath) then
    require("SourceLib")
    else
        printMsg("Downloading SourceLib, please wait...")
        DownloadingSL = true
        DownloadFile(SourceLibUrl, SourceLibPath, function() printMsg("SourceLib successfully downloaded, please reload (double [F9]).") end)
end

if _G.SKONIDA_UPDATE then
SourceUpdater(SKONAME, version, SKOHOST, SKOHPATH, SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, SKOHPATH..SKONAME..".version"):CheckUpdate()
end

local RequireL = Require("SourceLib")
RequireL:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
RequireL:Add("VPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
RequireL:Check()
if RequireL.downloadNeeded == true then return end
----------------------------------------------------------------------------------------------------------
----------------------------------------Variables---------------------------------------------------------
----------------------------------------------------------------------------------------------------------

Spells = {
        Q = {range = 1500, delay = 0.125, width = 70, speed = 1300},
        W = {range = 900, delay = 0.500, width = 80, speed = 1450},
        E = {range = 600},
        QC = {range = myHero.range + GetDistance(myHero.minBBox)},
        WC = {range = 375},
        EC = {range = 350}
}

levelSequence = {
        QE = {1,3,2,1,1,4,1,3,1,3,4,3,3,2,2,4,2,2},
        QW = {1,2,3,1,1,4,1,2,1,2,4,2,2,3,3,4,3,3}
}

RangesDraw = {[_Q] = 1500, [_W] = 900, [_E] = 600}
local QREADY, WREADY, EREADY, RREADY, IREADY = false, false, false, false, false
local DFGReady, HXGReady, BWCReady, BRKReady, HYDReady = false, false, false, false, false
local DFGSlot, HXGSlot, BWCSlot, BRKSlot, HYDSlot = nil, nil, nil, nil, nil  
local VP = nil
local ts
local Recall = false
ts = TargetSelector(TARGET_LOW_HP, Spells.Q.range, DAMAGE_MAGIC, true)
ts.name = "Nidalee"
local Target = nil
function OnLoad()
    --Ignite
    IgniteSlot()
    --Libs
    VP = VPrediction()
    DM = DrawManager()
    NSOW = SOW(VP)

    --SKOMENU  
    SKOMenu = scriptConfig("SKONida", "SKONida")

    SKOMenu:addSubMenu("Combo Settings", "Combo")
    SKOMenu.Combo:addParam("useQH", "Use Q in combo(Human)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useWH", "Use W in combo(Human)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useEH", "Use E in combo(Human)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useQC", "Use Q in combo(Cougar)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useWC", "Use W in combo(Cougar)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useEC", "Use E in combo(Cougar)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useR", "Use R in combo", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("useitems", "Use items", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.Combo:addParam("ignite", "Use ignite", SCRIPT_PARAM_ONOFF, true)

    SKOMenu:addSubMenu("Jungle Clear", "jungle")
    SKOMenu.jungle:addParam("useQH", "Use Q (HUMAN)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.jungle:addParam("useQ", "Use Q (COUGAR)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.jungle:addParam("useW", "Use W (COUGAR)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.jungle:addParam("useE", "Use E (COUGAR)", SCRIPT_PARAM_ONOFF, true)


    SKOMenu:addSubMenu("Lane Clear", "farm")
    SKOMenu.farm:addParam("useQH", "Use Q (HUMAN)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.farm:addParam("useQ", "Use Q (COUGAR)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.farm:addParam("useW", "Use W (COUGAR)", SCRIPT_PARAM_ONOFF, true)
    SKOMenu.farm:addParam("useE", "Use E (COUGAR)", SCRIPT_PARAM_ONOFF, true)


    SKOMenu:addSubMenu("Extra", "extra")
    SKOMenu.extra:addParam("autolevel", "Auto Level", SCRIPT_PARAM_LIST, 1, {"Disable", "Q>E>R>W", "Q>W>R>E"})
    SKOMenu.extra:addParam("useautoHeal", "Use Auto Heal", SCRIPT_PARAM_ONKEYTOGGLE, true, string.byte("X"))
    SKOMenu.extra:addParam("autoHeal", "Auto Heal if Health %", SCRIPT_PARAM_SLICE, 40, 0, 100, 0)


    SKOMenu:addParam("activeCombo", "Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    SKOMenu:addParam("activeFarm", "Lane Clear/Jungle Clear", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))

    SKOMenu:addSubMenu("Drawing", "drawing")
    for spell, range in pairs(RangesDraw) do
        DM:CreateCircle(myHero, range, 1, {255, 255, 255, 255}):AddToMenu(SKOMenu.drawing, SpellToString(spell).." Range", true, true ,true)
    end
    SKOMenu:addTS(ts)

    SKOMenu:addSubMenu("OrbWalking", "OrbWalking")
    NSOW:LoadToMenu(SKOMenu.OrbWalking)

    enemyMinion = minionManager(MINION_ENEMY, 1000, myHero, MINION_SORT_HEALTH_ASC)
    jungleMinion = minionManager(MINION_JUNGLE, 1000, myHero, MINION_SORT_HEALTH_ASC)

    PrintChat("<font color='#fff'>"..SKONAME.." Loaded!</font>")

end

function OnTick()
    if myHero.dead then return end
    Target = GetOthersTarget()
    NSOW:ForceTarget(Target)
    Checks()
    CheckSpells()
    if SKOMenu.extra.autolevel == 2 then
        autoLevelSetSequence(levelSequence.QE)
    elseif SKOMenu.extra.autolevel == 3 then
        autoLevelSetSequence(levelSequence.QW)
    end

    if ISCOUGAR and myHero.health <= (myHero.maxHealth * (SKOMenu.extra.autoHeal/100)) and EREADY and not Recall then
        CastSpell(_R)
    end
    if SKOMenu.extra.useautoHeal and not Recall and not ISCOUGAR then
        UseEHuman()
    end

    if SKOMenu.activeCombo then
        activeCombo()
    end
    if SKOMenu.activeFarm then
        Farm()
        JungleFarm()
    end

end

function Checks()
    --Spell Check
    QREADY = (myHero:CanUseSpell(_Q) == READY)
    WREADY = (myHero:CanUseSpell(_W) == READY)
    EREADY = (myHero:CanUseSpell(_E) == READY)
    RREADY = (myHero:CanUseSpell(_R) == READY)
    IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)

    --Items
    DFGReady = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
    BRKReady = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
    BWCReady = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
    HXGReady = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
    HYDReady = (HYDSlot ~= nil and myHero:CanUseSpell(HYDSlot) == READY)

    --Items slot
    DFGSlot = GetInventorySlotItem(3128)
    BRKSlot = GetInventorySlotItem(3153)
    BWCSlot = GetInventorySlotItem(3144)
    HXGSlot = GetInventorySlotItem(3146)
    HYDSlot = GetInventorySlotItem(3074)
end

function activeCombo()
    if ValidTarget(Target) then
        if SKOMenu.Combo.useitems then
            UseItems(Target)
        end
        if SKOMenu.Combo.ignite then
            UseIgnite(Target)
        end
        if ISHUMAN and GetDistance(Target) >= Spells.W.range then
            if SKOMenu.Combo.useQH then UseQHuman() end
            if SKOMenu.Combo.useQH then UseEHuman() end
        end
        if ISHUMAN and GetDistance(Target) < Spells.W.range then
            HumanCombo()
        end
        if ISHUMAN and SKOMenu.Combo.useR and GetDistance(Target) <= 625 then
            CougarCombo()
        end
        if ISCOUGAR and GetDistance(Target) < 625 then
            CougarCombo()
        end
        if ISCOUGAR and SKOMenu.Combo.useR and GetDistance(Target) > Spells.W.range
                        then CastSpell(_R)
        end
    end
end

function HumanCombo()
    
    if SKOMenu.Combo.useQH then UseQHuman() end
    if SKOMenu.Combo.useEH then UseEHuman() end
    if SKOMenu.Combo.useWH then UseWHuman() end
    
end

function CougarCombo()
    if ISHUMAN then CastSpell(_R) end
    if ISCOUGAR then
            if SKOMenu.Combo.useWC and GetDistance(Target) <= 400 then UseWCougar(Target) end
            if SKOMenu.Combo.useEC and GetDistance(Target) <= 300 then UseECougar(Target) end
            if SKOMenu.Combo.useQC and GetDistance(Target) <= Spells.QC.range then UseQCougar(Target) end
    end
end
function UseQHuman()

            local CastPosition,  HitChance,  Position = VP:GetLineCastPosition(Target, Spells.Q.delay, Spells.Q.width, Spells.Q.range, Spells.Q.speed, myHero, true)
            if HitChance >= 2 and (GetDistance(Target) - getHitBoxRadius(Target)/2) <= Spells.Q.range and QREADY
            then CastSpell(_Q,CastPosition.x,CastPosition.z)
            end
end

function UseEHuman()
    if myHero.health < (myHero.maxHealth *(SKOMenu.extra.autoHeal/100)) and EREADY then
        CastSpell(_E, myHero)
    end
end

function UseWHuman()
        if ISHUMAN == true then
            local CastPosition,  HitChance,  Position = VP:GetCircularCastPosition(Target, Spells.W.delay, Spells.W.width, Spells.W.range) 
            if HitChance >= 2 and GetDistance(CastPosition) <= 1200 and WREADY
            then CastSpell(_W, CastPosition.x, CastPosition.z)
            end
        end
end

function UseQCougar(enemy)
    if not enemy then enemy = Target end
        if (not QREADY or (GetDistance(enemy) > Spells.QC.range))
            then return false
        end
        if not NSOW:CanAttack() then
            if ValidTarget(enemy) then
               NSOW:resetAA()
                CastSpell(_Q)
                return true
            end
        end
        return false
end

function UseWCougar(enemy)
        if not enemy then enemy = Target end
        if not WREADY or (GetDistance(enemy) > Spells.WC.range) or (GetDistance(enemy) < 150)
            then return false
        end
        if not NSOW:CanAttack() then
            if ValidTarget(enemy) and isFacing(myHero, enemy, 100)
                then CastSpell(_W)
                return true
            end
        end
        return false
end

function UseECougar(enemy)
        if not enemy then enemy = Target end
        if (not EREADY or (GetDistance(enemy) > Spells.EC.range) or ISHUMAN)
            then return false
        end
        if not NSOW:CanAttack() then
            if ValidTarget(enemy) and isFacing(myHero, enemy, 200) then 
                CastSpell(_E)
                return true
            end
        end
        return false
end


function UseIgnite(enemy)
    if GetDistance(enemy) <= 600 and enemy.health <= getDmg("IGNITE", enemy, myHero) and ignite ~= nil and IREADY then
        CastSpell(ignite, enemy)
    end  
end

function Farm()
    enemyMinion:update()
    for _, minion in pairs(enemyMinion.objects) do
        if ValidTarget(minion) then
                if ISHUMAN == true then CastSpell(_R) end
                    if SKOMenu.farm.useQ and GetDistance(minion) <= Spells.QC.range and QREADY and ISCOUGAR then CastSpell(_Q, minion.x, minion.z) end
                    if SKOMenu.farm.useW and GetDistance(minion) <= Spells.WC.range and WREADY and ISCOUGAR and isFacing(myHero, minion, 100) then  CastSpell(_W, minion.x, minion.y) end
                    if SKOMenu.farm.useE and GetDistance(minion) <= Spells.EC.range and EREADY and ISCOUGAR and isFacing(myHero, minion, 200) then  CastSpell(_E, minion.x, minion.z) end
        end
    end
end

function JungleFarm()
    jungleMinion:update()
    for _, minion in pairs(jungleMinion.objects) do
        if ValidTarget(minion) then
                if ISHUMAN == true then CastSpell(_R) end
                    if SKOMenu.jungle.useQ and GetDistance(minion) <= Spells.QC.range and QREADY and ISCOUGAR then CastSpell(_Q, minion.x, minion.z) end
                    if SKOMenu.jungle.useW and GetDistance(minion) <= Spells.WC.range and WREADY and ISCOUGAR and isFacing(myHero, minion, 100) then  CastSpell(_W, minion.x, minion.z) end
                    if SKOMenu.jungle.useE and GetDistance(minion) <= Spells.EC.range and EREADY and ISCOUGAR and isFacing(myHero, minion, 200) then  CastSpell(_E, minion.x, minion.z) end
        end
    end
end


function IgniteSlot()
    if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then
            ignite = SUMMONER_1
    elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then
            ignite = SUMMONER_2
    end
end

function UseItems(enemy)
    if not enemy then enemy = Target end
    if ValidTarget(enemy) then
        if DFGReady and GetDistance(enemy) <= 750 then CastSpell(DFGSlot, enemy) end
        if BWCReady and GetDistance(enemy) <= 450 then CastSpell(BWCSlot, enemy) end
        if BRKReady and GetDistance(enemy) <= 450 then CastSpell(BRKSlot, enemy) end
        if HXGReady and GetDistance(enemy) <= 700 then CastSpell(HXGSlot, enemy) end
        if HYDReady and GetDistance(enemy) <= 185 then CastSpell(HYDSlot, enemy) end
    end
end

function CheckSpells()
    if myHero:GetSpellData(_Q).name == "JavelinToss" 
    or myHero:GetSpellData(_W).name == "Bushwhack"
    or myHero:GetSpellData(_E).name == "PrimalSurge"
        then ISHUMAN = true ISCOUGAR = false
    end
    if myHero:GetSpellData(_Q).name == "Takedown"
    or myHero:GetSpellData(_W).name == "Pounce"
    or myHero:GetSpellData(_E).name == "Swipe"
        then ISCOUGAR = true ISHUMAN = false
    end
end
function GetOthersTarget()
    ts:update()
    if _G.MMA_Target and _G.MMA_Target.type == myHero.type then return _G.MMA_Target end
    if _G.AutoCarry and _G.AutoCarry.Crosshair and _G.AutoCarry.Attack_Crosshair and _G.AutoCarry.Attack_Crosshair.target and _G.AutoCarry.Attack_Crosshair.target.type == myHero.type then return _G.AutoCarry.Attack_Crosshair.target end
    return ts.target
end
function OnCreateObj(obj)
    if obj ~= nil then
        if obj.name:find("TeleportHome.troy") then
            if GetDistance(obj) <= 70 then
                Recall = true
            end
        end 
    end
end
function OnDeleteObj(obj)
if obj ~= nil then
        
        if obj.name:find("TeleportHome.troy") then
            if GetDistance(obj) <= 70 then
                Recall = false
            end
        end 
        
    end
end

function OnRecall(hero, channelTimeInMs)
    if hero.networkID == player.networkID then
        Recall = true
    end
end
function OnAbortRecall(hero)
    if hero.networkID == player.networkID
        then Recall = false
    end
end
function OnFinishRecall(hero)
    if hero.networkID == player.networkID
        then Recall = false
    end
end
--By Feez
function isFacing(source, ourtarget, lineLength)
local sourceVector = Vector(source.visionPos.x, source.visionPos.z)
local sourcePos = Vector(source.x, source.z)
sourceVector = (sourceVector-sourcePos):normalized()
sourceVector = sourcePos + (sourceVector*(GetDistance(ourtarget, source)))
return GetDistanceSqr(ourtarget, {x = sourceVector.x, z = sourceVector.y}) <= (lineLength and lineLength^2 or 90000)
end
local function getHitBoxRadius(target)
        return GetDistance(target, target.minBBox)
end