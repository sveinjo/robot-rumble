//var buffHero;
engagedHero = argument0;
added = argument1;
missionLevel = mainData.arrayMissions[mainData.intMissionSelected].intLevel;
missionEnemies = mainData.arrayMissions[mainData.intMissionSelected].arrayEnemies;
heroLevel = 0;
chance = 0;
chanceModifier = 0;
counterFlag = 0;

if (engagedHero != 0)
{
    heroLevel = mainData.arrayHeroes[engagedHero.intParent].intLevel;
    heroAbility = mainData.arrayHeroes[engagedHero.intParent].skillSlot1;
    
    // Does it counter anything
    
    for (i = 1; i < array_length_1d(missionEnemies); i += 1)
    {
        if (heroAbility == mainData.arrayEnemies[missionEnemies[i], 1])
        {
            counterFlag = 100 / 3;
        }                    
    }
    
    if (heroLevel <= missionLevel - 3)
    {
        chanceModifier = 0;           
    } 
    else if (heroLevel = missionLevel - 2)
    {
        chanceModifier = 0.25;    
    }
    else if (heroLevel = missionLevel - 1)
    {
        chanceModifier = 0.50;    
    }
    else if (heroLevel = missionLevel)
    {
        chanceModifier = 1;    
    }
    else if (heroLevel = missionLevel + 1)
    {
        chanceModifier = 1.25;    
    }
    else if (heroLevel >= missionLevel + 2)
    {
        chanceModifier = 1.50;    
    }
    chance = ((50 / 3) + counterFlag) * chanceModifier;    
    
    if (added)
    {
        //chanceBar.chance += mainData.arrayHeroes[engagedHero.intParent].skillSlot1;
        chanceBar.chance += chance;
        
    }
    else
    {
        //chanceBar.chance -= mainData.arrayHeroes[engagedHero.intParent].skillSlot1;
        chanceBar.chance -= chance;
    }
    
    mainData.winChance = chanceBar.chance;
    
    if (mainData.winChance == 0)
        missionStartButton.visible = 0;
    else
        missionStartButton.visible = 1;
    //mainData.winChance = 100;
    audio_play_sound(sound1, 10, false);
    
    moveMarker();
}
