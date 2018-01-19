

if (fadeFlag == 2)
{
    tempAlpha = clamp(image_alpha - 0.025, 0, 1);    
    if tempAlpha > 0    
    {
        image_alpha = tempAlpha;    
    }
    else
    {
        image_alpha = 0;
        fadeFlag = 0;
        alarm[4] = 10;
    }
}
