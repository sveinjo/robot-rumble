arrayButtonPosX[1] = 913;
arrayButtonPosX[2] = 1238;
arrayButtonPosX[3] = 1563;

arrayButtonPosY[1] = 143;
arrayButtonPosY[2] = 452;
arrayButtonPosY[3] = 761;

i = 1;
varMissionData = 0;
varMissionButton = 0;
varBossNumber = 0;
varHenchmenNumber = 0;

instance_create(1326, 540, marker);
instance_create(1326, 540, marker2);

stripe1 = instance_create(-1900, 231, particleOverlay);
//stripe1.image_yscale = 14;

stripe2 = instance_create(-1900, 540, particleOverlay);
//stripe2.image_yscale = 14;

stripe3 = instance_create(-1900, 849, particleOverlay);
//stripe3.image_yscale = 14;

baseOvertaken = 0;

for (yPos = 1; yPos <= 3; yPos += 1)        
{
    for (xPos = 1; xPos <= 3; xPos += 1)
    {
        if (mainData.arrayMissions[i] == 0)
        {
            // decide level range
            varLevelMin = 100;
            varLevelMax = -100;
            for (n = 1; n < array_length_1d(mainData.arrayHeroes); n += 1)
            {
                varTempLevel = mainData.arrayHeroes[n].intLevel;
                if (varTempLevel < varLevelMin)
                    varLevelMin = varTempLevel;
                if (varTempLevel > varLevelMax)
                    varLevelMax = varTempLevel;
            }
            
            // center square
            // que dialogue
            // Food button
            
            // baseOvertaken = 1;
            
            if (i == 5)
            {          
                if (baseOvertaken == 1)
                { 
                    varLevel = irandom(varLevelMax - varLevelMin) + 4 + varLevelMin;
                    if (mainData.intEventMarker == 1)
                    {
                        if (speechBubbles == 1)
                        {
                            marker.alarm[0] = 80;
                            //instance_create(873, 103, speechBubble); 
                            //mainData.intEventMarker = 0;
                        }
                    }
                } 
            }
            else
                varLevel = irandom(varLevelMax - varLevelMin + 1) + varLevelMin;
                
            // randomize if button shows up 
            // (center button always appears)       
            
            // (lower level missions have a greater chance of appearing)
            if (varLevel == varLevelMin)
                varBonus = 20;
            else
                varBonus = 0;

            if (irandom(100) > (80 - varBonus) || i == 5 )
            {                
                // decide XP reward
                varXp = varLevel * 100 * 3;
                
                // decide bonus reward
                varBonus = varXp;
                
                // create mission data
                varMissionData = instance_create(-176, -176, missionData);
                varBossNumber = irandom(4) + 3;
                varHenchmenNumber = irandom(1) + 1;            
                varMissionData.sprite_index = mainData.arrayEnemies[varBossNumber, 0];
                varMissionData.arrayEnemies[1] = varHenchmenNumber;
                varMissionData.arrayEnemies[2] = varBossNumber;
                varMissionData.arrayEnemies[3] = varHenchmenNumber;
                varMissionData.intLevel = varLevel;
                varMissionData.intXp = varXp;
                varMissionData.intBonusXp = varBonus;
                varMissionData.isNew = 1;
                mainData.arrayMissions[i] = varMissionData;                                       
            }
        }
        
        if (mainData.arrayMissions[i] != 0)
        {
            drawDiabetesButton = 0;
            if (i == 5 && baseOvertaken == 0)
            {
                drawDiabetesButton = 1;          
            }
            
            if (drawDiabetesButton == 1)
            {
                varMissionButton = instance_create(arrayButtonPosX[xPos], arrayButtonPosY[yPos], homeBaseButton);                
            } else if (drawDiabetesButton == 0)
            {
                // create mission button
                varMissionButton = instance_create(arrayButtonPosX[xPos], arrayButtonPosY[yPos], missionSelectButton);
                //varMissionButton.sprite_index = mainData.arrayMissions[i].sprite_index;
                varMissionButton.spriteEnemy = mainData.arrayMissions[i].sprite_index;
                varMissionButton.intParent = i;
                
                //Fade in if new
                if (mainData.arrayMissions[i].isNew == 1)
                {
                    varMissionButton.fadeFlag = 1;
                    varMissionButton.image_alpha = 0;
                    mainData.arrayMissions[i].isNew = 0;
                }            
                
                varMissionButtonFrame = instance_create(arrayButtonPosX[xPos], arrayButtonPosY[yPos], missionFrame);
                varMissionButtonFrame.intParent = i;
                }
        }                
        i++;           
    }
    
}
