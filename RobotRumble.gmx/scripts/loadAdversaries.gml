arrayButtonPosX[1] = 913;
arrayButtonPosX[2] = 1238;
arrayButtonPosX[3] = 1563;

arrayButtonPosY = 143;
i = 1;

for (xPos = 1; xPos <= 3; xPos += 1)
{
    intBadGuy = mainData.arrayMissions[mainData.intMissionSelected].arrayEnemies[i];
    varBadGuy = instance_create(arrayButtonPosX[xPos], arrayButtonPosY, badGuy1);
    varBadGuy.sprite_index = mainData.arrayEnemies[mainData.arrayMissions[mainData.intMissionSelected].arrayEnemies[i], 0];
    varBadGuyFrame = instance_create(arrayButtonPosX[xPos], arrayButtonPosY, badGuyFrame);
    //varBadGuyFrame.intParent = intBadGuy;
    varBadGuyFrame.intParent = mainData.intMissionSelected;
    varBadGuyFrame.parentBadGuy = intBadGuy;
    
    i++;
}
