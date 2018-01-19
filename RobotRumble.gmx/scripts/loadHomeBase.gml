arrayButtonPosX[1] = 913;
arrayButtonPosX[2] = 1238;
arrayButtonPosX[3] = 1563;

arrayButtonPosY[1] = 143;
arrayButtonPosY[2] = 452;
arrayButtonPosY[3] = 761;

instance_create(1326, 540, marker);
instance_create(1326, 540, marker2);

i = 1;

for (yPos = 1; yPos <= 2; yPos += 1)        
{
    for (xPos = 1; xPos <= 3; xPos += 1)
    {
        if (i == 5)
            tempButton = instance_create(arrayButtonPosX[xPos], arrayButtonPosY[yPos], hero);
        else
            tempButton = instance_create(arrayButtonPosX[xPos], arrayButtonPosY[yPos], genericButton);
        
        if (i == 1)
        {
            tempButton.strCaption = "CARBS";
            tempButton.intValue = 10;
        }
        if (i == 2)
        {
            tempButton.strCaption = "PROTEIN";
            tempButton.intValue = 20;
        }
        if (i == 3)
        {
            tempButton.strCaption = "FATS";
            tempButton.intValue = 30;
        }
        if (i == 4)
        {
            tempButton.strCaption = "FAST INSULIN";
            tempButton.intValue = 3;
        }
        if (i == 6)
        {
            tempButton.strCaption = "SLOW INSULIN";
            tempButton.intValue = 6;
        }
        else
        {
            //tempButton.strCaption = "";
        }
        i++;
    }
    
}
