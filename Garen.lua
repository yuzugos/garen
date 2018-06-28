-- Hero
if GetObjectName(GetMyHero()) ~= "Garen" then return end

-- Load Libs
require ("DamageLib")

-- Main Menu
GMenu = Menu("G", "Garen")

print("<font color=\"#0099FF\"><b>[Garen]: </b></font><font color=\"#FFFFFF\"> Garen Test!</font>")

-- Combo Menu
GMenu:SubMenu("c", "Combo")
GMenu.c:Boolean("Q", "Use Q", true)
GMenu.c:Slider("Qrange", "Min. range for use Q", 300, 0, 1000, 10)
GMenu.c:Boolean("E", "Use E", true)

-- Ultimate Menu
GMenu:SubMenu("u", "Ultimate")
GMenu.u:Boolean("R", "Use R")
GMenu.u:SubMenu("black", "Ultimate White List")
DelayAction(function()
    for _, unit in pairs(GetEnemyHeroes()) do
        GMenu.u.black:Boolean(unit.name, "Use R On: "..unit.charName, true)
    end
end, 0.01)

--Auto Menu
GMenu:SubMenu("a", "Auto")
GMenu.a:Boolean("W", "Use W", true)
GMenu.a:Slider("Whp", "Use W if HP(%) <= X", 70, 0, 100, 5)
GMenu.a:Slider("Wlim", "Use W if Enemy Count >= X", 1, 1, 5, 1)

--LastHit Menu
GMenu:SubMenu("l", "Last Hit")
GMenu.l:Boolean("Q", "Use Q", true)

--Harass Menu
GMenu:SubMenu("h", "Harass")
GMenu.h:Boolean("Q", "Use Q", true)
GMenu.h:Slider("Qrange", "Min. range for use Q", 300, 0, 1000, 10)
GMenu.h:Boolean("E", "Use E", true)

--Clear Menu
GMenu:SubMenu("cl", "Clear")
GMenu.cl:SubMenu("l", "Lane Clear")
GMenu.cl.l:Boolean("Q", "Use Q", true)
GMenu.cl.l:Boolean("E", "Use E", true)
GMenu.cl:SubMenu("j", "Jungle Clear")
GMenu.cl.j:Boolean("Q", "Use Q", true)
GMenu.cl.j:Boolean("E", "Use E", true)

--Draw Menu
GMenu:SubMenu("d", "Draw")
GMenu.d:SubMenu("dt", "Text")
GMenu.d.dt:Boolean("Stats", "Draw HP and R Damage Info", true)
GMenu.d.dt:Boolean("R", "Draw R kill Notification", true)
GMenu.d:SubMenu("ds", "Spells")
GMenu.d.ds:Boolean("E", "Draw E Range", true)
GMenu.d.ds:Boolean("R", "Draw R Range", true)

--Skin Menu
GMenu:SubMenu("s", "Skin Changer")
  skinMeta = {["Garen"] = {"Classic", "Sanguine", "Desert Trooper", "Commando", "Dreadknight", "Rugged", "Steel Legion", "Chroma Pack: Garnet", "Chroma Pack: Plum", "Chroma Pack: Ivory", "Rogue Admiral"}}
  GMenu.s:DropDown('skin', myHero.charName.. " Skins", 1, skinMeta[myHero.charName],function(model)
        HeroSkinChanger(myHero, model - 1) print(skinMeta[myHero.charName][model] .." ".. myHero.charName .. " Loaded!") 
    end,
true)

--Locals
local LoL = "6.19"

--Spells
local Garen_E = { range = 300 }
local Garen_R = { range = 400 }

--Mode
function Mode() --Deftsu
    if IOW_Loaded then
        return IOW:Mode()
    elseif DAC_Loaded then
        return DAC:Mode()
    elseif PW_Loaded then
        return PW:Mode()
    elseif GoSWalkLoaded and GoSWalk.CurrentMode then
        return ({"Combo", "Harass", "LaneClear", "LastHit"})[GoSWalk.CurrentMode+1]
    elseif AutoCarry_Loaded then
        return DACR:Mode()
    elseif _G.SLW_Loaded then
        return SLW:Mode()
    elseif EOW_Loaded then
        return EOW:Mode()
    end
    return ""
end

--Start
OnTick(function (myHero)
	if not IsDead(myHero) then
		--Locals
		local target = GetCurrentTarget()
		--Functions
		OnCombo(target)
        OnLastHit()
        OnHarass(target)
        OnClear()
        CastR()
	end
end)

OnDraw(function(myHero)
    --Text
    for x,unit in pairs(GetEnemyHeroes()) do 
        if ValidTarget(unit,20000) and WorldToScreen(0,unit.pos).flag and GMenu.d.dt.Stats:Value() then
            if Ready(_R) then
                DrawText("R Damage: "..getdmg("R",unit,myHero), 16, GetHPBarPos(unit).x, GetHPBarPos(unit).y-58, GoS.Yellow)
            end
            if not Ready(_R) then
                DrawText("R Damage: Not Ready", 16, GetHPBarPos(unit).x, GetHPBarPos(unit).y-58, GoS.Yellow)
            end
            DrawText("Current HP:  "..math.round(GetCurrentHP(unit)), 16, GetHPBarPos(unit).x, GetHPBarPos(unit).y-43, GoS.Red)
        end
        if GMenu.d.dt.R:Value() and Ready(_R) and ValidTarget(unit,1500) and GetCurrentHP(unit) + GetDmgShield(unit) <  getdmg("R",unit,myHero) then
            if GMenu.u.black[unit.name]:Value() then
                DrawText("Finish Him!", 25, GetHPBarPos(unit).x, GetHPBarPos(unit).y+18, GoS.Red)
                DrawCircle(unit, 120, 3, 25, GoS.Red)
                DrawCircle(unit, 90, 3, 25, GoS.Red)
                DrawCircle(unit, 60, 3, 25, GoS.Red)
            end
        end
    end

    --Range
    if not IsDead(myHero) then
        if GMenu.d.ds.E:Value() then DrawCircle(myHero, Garen_E.range, 2, 25, GoS.Red) end
        if GMenu.d.ds.R:Value() then DrawCircle(myHero, Garen_R.range, 2, 25, GoS.Green) end
    end 
end)

--Functions
function OnCombo(target)
	if Mode() == "Combo" then
		--Q
		if Ready(_Q) and GMenu.c.Q:Value() and ValidTarget(target, GMenu.c.Qrange:Value()) then
			CastSpell(_Q)
		end
		--E
		if Ready(_E) and GMenu.c.E:Value() and ValidTarget(target, Garen_E.range) and GetCastName(myHero, _E) == "GarenE" then
			CastSpell(_E)
		end
	end
end

function OnLastHit()
    if Mode() == "LastHit" then
        for _, minion in pairs(minionManager.objects) do
            if GetTeam(minion) == MINION_ENEMY then
                if GMenu.l.Q:Value() and Ready(_Q) and ValidTarget(minion, 400) then
                    if getdmg("Q",minion,myHero) > GetCurrentHP(minion) then
                        CastSpell(_Q)
                        AttackUnit(minion)
                    end
                end
            end
        end
    end
end

function OnHarass(target)
    if Mode() == "Harass" then
        --Q
        if Ready(_Q) and GMenu.h.Q:Value() and ValidTarget(target, GMenu.h.Qrange:Value()) then
            CastSpell(_Q)
        end
        --E
        if Ready(_E) and GMenu.h.E:Value() and ValidTarget(target, Garen_E.range) and GetCastName(myHero, _E) == "GarenE" then
            CastSpell(_E)
        end
    end
end

function OnClear()
    if Mode() == "LaneClear" then
        for _, minion in pairs(minionManager.objects) do
            if GetTeam(minion) == MINION_ENEMY then
                --Q
                if Ready(_Q) and GMenu.cl.l.Q:Value() and ValidTarget(minion, 300) then
                    CastSpell(_Q)
                end
                --E
                if Ready(_E) and GMenu.cl.l.E:Value() and ValidTarget(minion, Garen_E.range) and GetCastName(myHero, _E) == "GarenE" and MinionsAround(minion, 950) >= 3 then
                    CastSpell(_E)
                end
            end
        end
    end
    if Mode() == "LaneClear" then --[[JungleClear doesnt work :doge:]]
        for _, mob in pairs(minionManager.objects) do
            if GetTeam(mob) == MINION_JUNGLE then
                --Q
                if Ready(_Q) and GMenu.cl.j.Q:Value() and ValidTarget(mob, 300) then
                    CastSpell(_Q)
                end
                --E
                if Ready(_E) and GMenu.cl.j.E:Value() and ValidTarget(mob, Garen_E.range) and GetCastName(myHero, _E) == "GarenE" then
                    CastSpell(_E)
                end
            end
        end
    end
end

function CastR()
    for _,unit in pairs(GetEnemyHeroes()) do
        if GMenu.u.R:Value() and Ready(_R) and ValidTarget(unit, Garen_R.range) and GetCurrentHP(unit) + GetDmgShield(unit) <  getdmg("R",unit,myHero) then
            if GMenu.u.black[unit.name]:Value() then
                CastTargetSpell(unit,_R)
            end
        end
    end
end

--CB
OnProcessSpell(function(unit,spellProc)    
    if unit.isMe and spellProc.name:lower():find("attack") and EnemiesAround(myHero, 950) >= GMenu.a.Wlim:Value() then     
        if GMenu.a.W:Value() and Ready(_W) and GetPercentHP(myHero) < GMenu.a.Whp:Value() then 
            CastSpell(_W)   
        end
    end
end)

print("<font color=\"#0099FF\"><b>[Garen]: Loaded</b></font> || Version: "..ver," ", "|| LoL Patch : "..LoL)
