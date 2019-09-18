-- lookups
local rank_names =
{
    [ 1]=1,[ 2]= 2,[ 3]= 3,[ 4]= 4,[ 5]= 5,[ 6]= 6,[ 7]= 7,[ 8]=8,
    [ 9]=9,[10]=10,[11]=11,[12]=12,[13]=13,[14]=14,[15]=15,[16]=16,

    ["Rank 1" ]= 1,["Rank 2" ]= 2,["Rank 3" ]= 3,["Rank 4" ]= 4,["Rank 5" ]=5,
    ["Rank 6" ]= 6,["Rank 7" ]= 7,["Rank 8" ]= 8,["Rank 9" ]= 9,["Rank 11"]=10,
    ["Rank 12"]=11,["Rank 13"]=12,["Rank 14"]=13,["Rank 15"]=15,["Rank 16"]=16,
};
local BS_BONUS = { 15, 30, 48, 69, 90, 135, 165, 210 };
local AB_BONUS = { 70, 100, 125, 185, 230, 290 };
local SS_BONUS = { 3, 6, 10, 15, 22, 33, 52, 68 };

-- currently equipped weapon
local currentWeapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"));
local currentLowDmg, currentHighDmg;

function nextarg(msg, pattern)
    if ( not msg or not pattern ) then
        return nil, nil;
    end;
    local s,e = string.find(msg, pattern);
    if ( s ) then
        local word = strsub(msg, s, e);
        msg = strsub(msg, e+1);
        return word, msg;
    end;
    return nil, msg;
end;

function GetWeaponType(weaponLink)
    local _, _, _, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo(weaponLink);
    if (itemType == "Weapon")
    then
        return itemSubType;
    else
        return nil;
    end;
end;

function IsWeaponOfType(weaponLink, type)
    local weaponType = GetWeaponType(weaponLink);
    if weaponType == nil
    then
        return false;
    else
        return weaponType == type;
    end;
end;

function ShowBackstab(weaponLink)
    return rank_names[GetSpellSubtext("Backstab")] ~= nil and IsWeaponOfType(weaponLink, "Daggers");
end;

function ShowAmbush(weaponLink)
    return rank_names[GetSpellSubtext("Ambush")] ~= nil and IsWeaponOfType(weaponLink, "Daggers");
end;

function ShowSinisterStrike(weaponLink)
    return rank_names[GetSpellSubtext("Sinister Strike")] ~= nil and IsRogueWeapon(weaponLink);
end;

function ShowHemorrhage(weaponLink)
    return false;
end;

function ShowGhostlyStrike(weaponLink)
    return false;
end;

function IsRogueWeapon(weaponLink)
    local _, _, _, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo(weaponLink);
    if (itemType == "Weapon")
    then
        return  itemSubType == "One-Handed Swords" or 
                itemSubType == "One-Handed Maces" or 
                itemSubType == "Daggers" or 
                itemSubType == "Fist Weapons";
    else
        return false;
    end;
end;

function GetWeapon(msg)
    local cmd;
    cmd, msg = nextarg(msg, "[%w]+");

    if (not cmd) -- use equipped weapon
    then
        return currentWeapon;
    else
        return msg;
    end;
end;

function GetAttackPowerOnWeapon(weaponLink)
    if (weaponLink)
    then
        local stats = GetItemStats(weaponLink);
        
        if (stats)
        then
            local agi = stats["ITEM_MOD_AGILITY_SHORT"] or 0;
            local str = stats["ITEM_MOD_STRENGTH_SHORT"] or 0;
            local rawAP = stats["ITEM_MOD_ATTACK_POWER_SHORT"] or 0;
            
            local agiAPonWeapon = GetAttackPowerForStat(2, agi);
            local strAPonWeapon = GetAttackPowerForStat(1, str);
            
            return strAPonWeapon + agiAPonWeapon + rawAP;
        end;
    end;
end;

function GetWeaponMinMaxSpeedDamage(weaponLink, tooltip)
    if (not tooltip)
    then
        GameTooltip:SetOwner(UIParent,"ANCHOR_NONE");
        GameTooltip:SetHyperlink(weaponLink);
    end;

    local tooltipToParse = tooltip or GameTooltip;
    local tooltipName = tooltipToParse:GetName();
    
    local _, minDmg, maxDmg, speed;
    for k=1,tooltipToParse:NumLines(),1
    do
        if (not minDmg and not maxDmg)
        then
            local line = _G[string.format("%s%s", tooltipName, "TextLeft")..k]:GetText() or "";
            _, _, minDmg, maxDmg = string.find(line, "(%d+)[^%d]+(%d+)%sDamage");
        end;

        if (not speed)
        then
            local line = _G[string.format("%s%s", tooltipName, "TextRight")..k]:GetText() or "";
            _, _, speed = string.find(line, "Speed%s([%d%.]+)");
        end;

        if (minDmg and maxDmg and speed)
        then
            break;
        end;
    end;

    if (not tooltip)
    then
        GameTooltip:Hide();
    end;

    if minDmg and maxDmg and speed then
        return tonumber(minDmg), tonumber(maxDmg), tonumber(speed);
    else
        return 0, 0, 1.0;
    end
end;

function GetWeaponDamage(weaponLink, tooltip)
    if (weaponLink and currentWeapon)
    then
        local baseAP, posAPBuff, negAPBuff = UnitAttackPower("player");
        --print("UnitAttackPower", baseAP, posAPBuff, negAPBuff);

        local currentWeaponAP = GetAttackPowerOnWeapon(currentWeapon);
        local targetWeaponAP = GetAttackPowerOnWeapon(weaponLink);
        --print("Weapon AP", currentWeaponAP, targetWeaponAP);

        local attackPowerWithTargetWeapon = baseAP - currentWeaponAP + targetWeaponAP;
        --print("attackPowerWithTargetWeapon", attackPowerWithTargetWeapon);

        local attackPowerBonusDamage = attackPowerWithTargetWeapon / 14;
        --print("attackPowerBonusDamage", attackPowerBonusDamage);

        local lowDmg, hiDmg, speed = GetWeaponMinMaxSpeedDamage(weaponLink, tooltip);
        --print("GetWeaponMinMaxSpeedDamage", lowDmg, hiDmg, speed);
        local weaponDamageBonus = speed * attackPowerBonusDamage;
        --print("weaponDamageBonus", weaponDamageBonus);

        --print("weapon base damage", lowDmg + weaponDamageBonus, hiDmg + weaponDamageBonus);
        return lowDmg + weaponDamageBonus, hiDmg + weaponDamageBonus;
    end;
end;

function round(x)
    return x + 0.5 - (x + 0.5) % 1
end;

function GetBackstabDamage(lowDmg, hiDmg, opportunityRank, backStabRank, lethalityRank)
    local bsMin = lowDmg * (1.5 + 0.04 * opportunityRank) + BS_BONUS[backStabRank];
    local bsMax = hiDmg  * (1.5 + 0.04 * opportunityRank) + BS_BONUS[backStabRank];
    local bsCritMin = bsMin * 2 * (1 + 0.06 * lethalityRank);
    local bsCritMax = bsMax * 2 * (1 + 0.06 * lethalityRank);

    return bsMin, bsMax, bsCritMin, bsCritMax;
end;

function GetAmbushDamage(lowDmg, hiDmg, opportunityRank, ambushRank)
    local ambushMin = lowDmg * (2.5 + 0.04 * opportunityRank) + AB_BONUS[ambushRank];
    local ambushMax = hiDmg  * (2.5 + 0.04 * opportunityRank) + AB_BONUS[ambushRank];
    local ambushCritMin = ambushMin * 2;
    local ambushCritMax = ambushMax * 2;

    return ambushMin, ambushMax, ambushCritMin, ambushCritMax;
end;

function GetSinisterStringDamage(lowDmg, hiDmg, sinisterStrikeRank, aggressionRank, lethalityRank)
    local ssMin = (lowDmg + SS_BONUS[sinisterStrikeRank]) * (1 + 0.02 * aggressionRank);
    local ssMax = (hiDmg  + SS_BONUS[sinisterStrikeRank]) * (1 + 0.02 * aggressionRank);
    local ssCritMin = ssMin * 2 * (1 + 0.06 * lethalityRank);
    local ssCritMax = ssMax * 2 * (1 + 0.06 * lethalityRank);

    return ssMin, ssMax, ssCritMin, ssCritMax;
end;

function GetDiffSign(diff)
    if diff == 0
    then
        return ""
    else if diff > 0
        then
            return "|cFF00FF00+";
        else
            return "|cffff0000";
        end;
    end;
end;

function GetSkillDamageString(skillName, newMin, newMax, newCritMin, newCritMax, oldMin, oldMax, oldCritMin, oldCritMax)
    if (oldMin and oldMax and oldCritMin and oldCritMax)
    then
        local diffMin = newMin - oldMin;
        local diffMax = newMax - oldMax;
        local diffCritMin = newCritMin - oldCritMin;
        local diffCritMax = newCritMax - oldCritMax;

        return string.format("%s: %d - %d (%s%d|r - %s%d|r), crit: %d - %d (%s%d|r - %s%d|r)", 
            skillName, 
            round(newMin), round(newMax),
            GetDiffSign(diffMin), round(diffMin),
            GetDiffSign(diffMax), round(diffMax),
            round(newCritMin), round(newCritMax),
            GetDiffSign(diffCritMin), round(diffCritMin),
            GetDiffSign(diffCritMax), round(diffCritMax));
    else
        return string.format("%s: %d - %d, crit: %d - %d", 
            skillName, 
            round(newMin), round(newMax),
            round(newCritMin), round(newCritMax));
    end
end;

SLASH_BackstabCalculator1, SLASH_BackstabCalculator2 = '/bsc', '/backstabcalculator';
SlashCmdList["BackstabCalculator"] = function(msg)
    local _, class, _ = UnitClass("player");    
    if (class == "ROGUE")
    then
        local weaponLink = GetWeapon(msg);
        if (IsRogueWeapon(weaponLink))
        then
            print("Damage with:", weaponLink);

            -- Min-Max damage on the weapon
            local targetLowDmg, targetHighDmg = GetWeaponDamage(weaponLink, nil);
            print ("Weapon dmg:", currentLowDmg, currentHighDmg, targetLowDmg, targetHighDmg);
            
            print(GetSkillDamageString("White damage", targetLowDmg, targetHighDmg, targetLowDmg * 2, targetHighDmg * 2, currentLowDmg, currentHighDmg, currentLowDmg * 2, currentHighDmg * 2));

            -- points in Opportunity
            local _, _, _, _, opportunityRank, _, _, _ = GetTalentInfo(3, 2);

            -- points in Improved Ambush
            local _, _, _, _, impAmbushRank, _, _, _ = GetTalentInfo(3, 8);

            -- points in Improved Backstab
            local _, _, _, _, impBackstabRank, _, _, _ = GetTalentInfo(2, 4);

            -- points in Lethality
            local _, _, _, _, lethalityRank, _, _, _ = GetTalentInfo(1, 9);

            -- points in Aggression
            local _, _, _, _, aggressionRank, _, _, _ = GetTalentInfo(2, 18);

            local backStabRank = rank_names[GetSpellSubtext("Backstab")];
            local ambushRank = rank_names[GetSpellSubtext("Ambush")];
            local sinisterStrikeRank = rank_names[GetSpellSubtext("Sinister Strike")];    

            -- Backstab damage
            if (ShowBackstab(weaponLink))
            then
                local newBsMin, newBsMax, newBsCritMin, newBsCritMax = GetBackstabDamage(targetLowDmg, targetHighDmg, opportunityRank, backStabRank, lethalityRank);

                if (IsWeaponOfType("Daggers", currentWeapon))
                then
                    local currentBsMin, currentBsMax, currentBsCritMin, currentBsCritMax = GetBackstabDamage(currentLowDmg, currentHighDmg, opportunityRank, backStabRank, lethalityRank);
                    
                    print(GetSkillDamageString("Backstab", newBsMin, newBsMax, newBsCritMin, newBsCritMax, currentBsMin, currentBsMax, currentBsCritMin, currentBsCritMax));
                else
                    print(GetSkillDamageString("Backstab", newBsMin, newBsMax, newBsCritMin, newBsCritMax));
                end;
            end;

            -- Ambush damage
            if (ShowAmbush(weaponLink)) 
            then
                local newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax = GetAmbushDamage(targetLowDmg, targetHighDmg, opportunityRank, ambushRank);

                if (IsWeaponOfType("Daggers", currentWeapon))
                then
                    local currentAmbushMin, currentAmbushMax, currentAmbushCritMin, currentAmbushCritMax = GetAmbushDamage(currentLowDmg, currentHighDmg, opportunityRank, ambushRank);

                    print(GetSkillDamageString("Ambush", newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax, currentAmbushMin, currentAmbushMax, currentAmbushCritMin, currentAmbushCritMax));
                else
                    print(GetSkillDamageString("Ambush", newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax));
                end;
            end;

            -- Sinister Strike damage
            if (ShowSinisterStrike(weaponLink))
            then
                local currentSsMin, currentSsMax, currentSsCritMin, currentSsCritMax = GetSinisterStringDamage(currentLowDmg, currentHighDmg, sinisterStrikeRank, aggressionRank, lethalityRank);
                local newSsMin, newSsMax, newSsCritMin, newSsCritMax = GetSinisterStringDamage(targetLowDmg, targetHighDmg, sinisterStrikeRank, aggressionRank, lethalityRank);
                
                print(GetSkillDamageString("Sinister Strike", newSsMin, newSsMax, newSsCritMin, newSsCritMax, currentSsMin, currentSsMax, currentSsCritMin, currentSsCritMax));
            end;
        else
            print("Not a Rogue weapon.");
        end;
    end;
end;

function BackStabCalculator_OnTooltipSetItem(tooltip)
    local _, weaponLink = tooltip:GetItem();
    if weaponLink 
    then
        AddLinesToTooltip(tooltip, weaponLink);
    end;

    return tooltip;
end;

function AddLinesToTooltip(tooltip, weaponLink)
    if (IsRogueWeapon(weaponLink) and currentLowDmg and currentHighDmg)
    then
        -- Min-Max damage on the weapon
        local targetLowDmg, targetHighDmg = GetWeaponDamage(weaponLink, tooltip);

        tooltip:AddLine(" ") --blank line

        tooltip:AddLine(GetSkillDamageString("White damage", targetLowDmg, targetHighDmg, targetLowDmg * 2, targetHighDmg * 2, currentLowDmg, currentHighDmg, currentLowDmg * 2, currentHighDmg * 2));

        -- points in Opportunity
        local _, _, _, _, opportunityRank, _, _, _ = GetTalentInfo(3, 2);

        -- points in Improved Ambush
        local _, _, _, _, impAmbushRank, _, _, _ = GetTalentInfo(3, 8);

        -- points in Improved Backstab
        local _, _, _, _, impBackstabRank, _, _, _ = GetTalentInfo(2, 4);

        -- points in Lethality
        local _, _, _, _, lethalityRank, _, _, _ = GetTalentInfo(1, 9);

        -- points in Aggression
        local _, _, _, _, aggressionRank, _, _, _ = GetTalentInfo(2, 18);

        local backStabRank = rank_names[GetSpellSubtext("Backstab")];
        local ambushRank = rank_names[GetSpellSubtext("Ambush")];
        local sinisterStrikeRank = rank_names[GetSpellSubtext("Sinister Strike")];    

        -- Backstab damage
        if (ShowBackstab(weaponLink))
        then
            local newBsMin, newBsMax, newBsCritMin, newBsCritMax = GetBackstabDamage(targetLowDmg, targetHighDmg, opportunityRank, backStabRank, lethalityRank);

            if (IsWeaponOfType("Daggers", currentWeapon))
            then
                local currentBsMin, currentBsMax, currentBsCritMin, currentBsCritMax = GetBackstabDamage(currentLowDmg, currentHighDmg, opportunityRank, backStabRank, lethalityRank);

                tooltip:AddLine(GetSkillDamageString("Backstab", newBsMin, newBsMax, newBsCritMin, newBsCritMax, currentBsMin, currentBsMax, currentBsCritMin, currentBsCritMax));
            else
                tooltip:AddLine(GetSkillDamageString("Backstab", newBsMin, newBsMax, newBsCritMin, newBsCritMax));
            end;
        end;

        -- Ambush damage
        if (ShowAmbush(weaponLink)) 
        then
            local newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax = GetAmbushDamage(targetLowDmg, targetHighDmg, opportunityRank, ambushRank);

            if (IsWeaponOfType("Daggers", currentWeapon))
            then
                local currentAmbushMin, currentAmbushMax, currentAmbushCritMin, currentAmbushCritMax = GetAmbushDamage(currentLowDmg, currentHighDmg, opportunityRank, ambushRank);
                tooltip:AddLine(GetSkillDamageString("Ambush", newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax, currentAmbushMin, currentAmbushMax, currentAmbushCritMin, currentAmbushCritMax));
            else
                tooltip:AddLine(GetSkillDamageString("Ambush", newAmbushMin, newAmbushMax, newAmbushCritMin, newAmbushCritMax));
            end;
        end;

        -- Sinister Strike damage
        if (ShowSinisterStrike(weaponLink))
        then
            local currentSsMin, currentSsMax, currentSsCritMin, currentSsCritMax = GetSinisterStringDamage(currentLowDmg, currentHighDmg, sinisterStrikeRank, aggressionRank, lethalityRank);
            local newSsMin, newSsMax, newSsCritMin, newSsCritMax = GetSinisterStringDamage(targetLowDmg, targetHighDmg, sinisterStrikeRank, aggressionRank, lethalityRank);
            
            tooltip:AddLine(GetSkillDamageString("Sinister Strike", newSsMin, newSsMax, newSsCritMin, newSsCritMax, currentSsMin, currentSsMax, currentSsCritMin, currentSsCritMax));
        end;
    end;
end;

local _, class, _ = UnitClass("player");    
if (class == "ROGUE")
then
    GameTooltip:HookScript("OnTooltipSetItem", BackStabCalculator_OnTooltipSetItem);

    local frame = CreateFrame("FRAME", "BackstabCalculatorFrame");
    frame:RegisterEvent("UNIT_INVENTORY_CHANGED");
    frame:RegisterEvent("PLAYER_ENTERING_WORLD");
    frame:RegisterEvent("UNIT_ATTACK_POWER");

    function eventHandler(self, event, ...)
        if (event == "PLAYER_ENTERING_WORLD")
        then
            currentWeapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"));
            currentLowDmg, currentHighDmg = GetWeaponDamage(currentWeapon, nil);
        else
            local unitName = ...;
            if (unitName == "player")
            then
                currentWeapon = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"));
                currentLowDmg, currentHighDmg = GetWeaponDamage(currentWeapon, nil);
            end;
        end;
    end
    frame:SetScript("OnEvent", eventHandler);

    local origChatFrame_OnHyperlinkShow = ChatFrame_OnHyperlinkShow;
    ChatFrame_OnHyperlinkShow = function(...)
        local chatFrame, link, text, button = ...;
        local result = origChatFrame_OnHyperlinkShow(...);
        
        if (IsRogueWeapon(link))
        then
            ShowUIPanel(ItemRefTooltip);
            if (not ItemRefTooltip:IsVisible()) then
                ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
            end
            
            local _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(link);
            if (itemLink)
            then
                AddLinesToTooltip(ItemRefTooltip, itemLink);
            end;

            ItemRefTooltip:Show(); ItemRefTooltip:Show();
        end;

        return result;
    end;
end;