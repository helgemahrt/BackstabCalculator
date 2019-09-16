SLASH_BackstabCalculator1, SLASH_BackstabCalculator2 = '/bsc', '/backstabcalculator';
SlashCmdList["BackstabCalculator"] = function(msg)
    local _, class, _ = UnitClass("player");    
    if (class == "ROGUE")
    then
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

        -- Min-Max damage on the main hand
        local lowDmg, hiDmg, _, _, _, _, _ = UnitDamage("player");

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

        local mainHandLink = GetInventoryItemLink("player", GetInventorySlotInfo("MainHandSlot"));
        local _, _, _, _, _, itemType, itemSubType, _, _, _, _ = GetItemInfo(mainHandLink);

        if (itemType == "Weapon")
        then
            if (itemSubType == "Daggers")
            then
                -- Backstab damage
                if (backStabRank ~= nil)
                then
                    local bsMin = lowDmg + (1.5 + 0.04 * opportunityRank) + BS_BONUS[backStabRank];
                    local bsMax = hiDmg  + (1.5 + 0.04 * opportunityRank) + BS_BONUS[backStabRank];
                    local bsCritMin = bsMin * 2 * (1 + 0.06 * lethalityRank);
                    local bsCritMax = bsMax * 2 * (1 + 0.06 * lethalityRank);
                    print("Backstab:", floor(bsMin), "-", floor(bsMax), "crit:", floor(bsCritMin), "-", floor(bsCritMax));
                else
                    print("Backstab not learned.")
                end;

                -- Ambush damage
                if (ambushRank ~= nil) 
                then
                    local ambushMin = lowDmg + (2.5 + 0.04 * opportunityRank) + AB_BONUS[ambushRank];
                    local ambushMax = hiDmg  + (2.5 + 0.04 * opportunityRank) + AB_BONUS[ambushRank];
                    local ambushCritMin = ambushMin * 2;
                    local ambushCritMax = ambushMax * 2;
                    print("Ambush:", floor(ambushMin), "-", floor(ambushMax), "crit:", floor(ambushCritMin), "-", floor(ambushCritMax));
                else
                    print("Ambush not learned.")
                end;
            else
                print("No dagger equipped in main hand. Skipping Backstab and Ambush damage.")
            end;

            -- Sinister Strike damage
            local ssMin = (lowDmg + SS_BONUS[sinisterStrikeRank]) * (1 + 0.02 * aggressionRank);
            local ssMax = (hiDmg  + SS_BONUS[sinisterStrikeRank]) * (1 + 0.02 * aggressionRank);
            local ssCritMin = ssMin * 2 * (1 + 0.06 * lethalityRank);
            local ssCritMax = ssMax * 2 * (1 + 0.06 * lethalityRank);
            print("Sinister Strike:", floor(ssMin), "-", floor(ssMax), "crit:", floor(ssCritMin), "-", floor(ssCritMax));
        else
            print("No weapon equipped in the main hand.");
        end;
    end;
end;