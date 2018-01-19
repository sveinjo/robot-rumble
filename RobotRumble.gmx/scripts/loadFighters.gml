xOffset = 730;
yOffset = 452;
arrayLeftSide = 0;

// heroes
if (array_length_1d(mainData.arrayFightingHeroes) != 0)
{
    for (i = 1; i < array_length_1d(mainData.arrayFightingHeroes); i += 1)
    {
    
        if (mainData.arrayFightingHeroes[i].sprite_index != Empty)
        {
            // line fighters
            arrayLeftSide[i] = instance_create(xOffset, 452, leftSide);
            arrayLeftSideReward[i] = instance_create(xOffset, 652, rewardFrameFight);
            arrayLeftSide[i].sprite_index = mainData.arrayFightingHeroes[i].sprite_index;
            xOffset -= 224;
            
            // info fighters (not shown atm.)
            mainData.arrayFightingHeroes[i].y = yOffset;
            mainData.arrayFightingHeroes[i].hbase = yOffset;
            yOffset += 192;
            mainData.arrayFightingHeroes[i].visible = 1;
        }
    }
}

// badguys

varMission = mainData.arrayMissions[mainData.intMissionSelected];
xOffset = 1014;

for (i = 1; i < array_length_1d(varMission.arrayEnemies); i += 1)
{
    arrayRightSide[i] = instance_create(xOffset, 452, badGuy1); 
    arrayRightSide[i].sprite_index = mainData.arrayEnemies[varMission.arrayEnemies[i], 0];    
    xOffset += 224;  
}
