/*arrayButtonPosX[1] = 913;
arrayButtonPosX[2] = 1238;
arrayButtonPosX[3] = 1563;

arrayButtonPosY[1] = 143;
arrayButtonPosY[2] = 452;
arrayButtonPosY[3] = 761;
*/

if (mainData.varEngageSlot1.sprite_index == Empty)
{
    marker.x = 1001;
    marker2.x = 1001;
    marker.y = 540;
    marker2.y = 540;
}
else if (mainData.varEngageSlot1.sprite_index != Empty)
{
    if (mainData.varEngageSlot2.sprite_index == Empty)   
    {
        marker.x = 1326;
        marker2.x = 1326;
        marker.y = 540;
        marker2.y = 540;
    }
    else if (mainData.varEngageSlot2.sprite_index != Empty)
    {
        if (mainData.varEngageSlot3.sprite_index == Empty)
        {
            marker.x = 1651;
            marker2.x = 1651;   
            marker.y = 540;
            marker2.y = 540;     
        }
        else if (mainData.varEngageSlot3.sprite_index != Empty)
        {
            if (mainData.winChance > 0)
            {
                marker.x = 1651;
                marker2.x = 1651;
                marker.y = 849;
                marker2.y = 849;
            }
            else
            {
                marker.x = 1825;
                marker2.x = 1825;
                marker.y = 0;
                marker2.y = 0;
            }
        }
    }
}
