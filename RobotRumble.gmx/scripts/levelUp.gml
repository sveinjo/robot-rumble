intMission = mainData.intMissionSelected;

intXpReward = mainData.arrayMissions[intMission].intXp;
//intXpReward = 1000;

for (i = 1; i < array_length_1d(mainData.arrayFightingHeroes); i += 1)
{    
    if (mainData.arrayFightingHeroes[i].sprite_index != Empty)
    {
        tempHero = mainData.arrayHeroes[mainData.arrayFightingHeroes[i].intParent];
        tempHero.intXp += intXpReward;
        if (tempHero.intXp >= mainData.arrayLevels[tempHero.intLevel + 1])
        {
            tempHero.intLevel++;
            tempHero.jumpFlag = 1;
        }
    }
}


mainData.intXp = intXpReward;
    
mainData.arrayMissions[intMission] = 0;
