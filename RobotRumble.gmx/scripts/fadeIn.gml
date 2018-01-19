if (fadeFlag == 1)
{
    tempAlpha = clamp(image_alpha + 0.025, 0, 1);    
    if tempAlpha < 1    
    {
        image_alpha = tempAlpha;    
    }
    else
    {
        image_alpha = 1;
        fadeFlag = 0;
        //alarm[4] = 10;
    }
}
