tempHero = argument0;
tempObject = activeHero.id;

if (tempHero.image_alpha == 1)
{


if (mainData.varEngageSlot1.sprite_index == Empty)
{
    //mainData.varEngageSlot1.sprite_index = Hunter;    
    
    // Click activeHero into engageSlot     
    mainData.varEngageSlot1.sprite_index = tempObject.sprite_index;    
    mainData.varEngageSlot1.containsObject = bufferHero;
    resetActiveHero();
    bufferHero.image_alpha = 0.25;
    calculateWinChance(mainData.varEngageSlot1.containsObject, true);
    
    // Assign activeHero to fighterSlot
    updateFighterSlots(mainData.varEngageSlot1, mainData.varEngageSlot1.fighterSlotObject);

}
else if (mainData.varEngageSlot1.sprite_index != Empty)
{
    if (mainData.varEngageSlot2.sprite_index == Empty)   
    {
        mainData.varEngageSlot2.sprite_index = tempObject.sprite_index;    
        mainData.varEngageSlot2.containsObject = bufferHero;
        resetActiveHero();
        bufferHero.image_alpha = 0.25;
        calculateWinChance(mainData.varEngageSlot2.containsObject, true);
        
        // Assign activeHero to fighterSlot
        updateFighterSlots(mainData.varEngageSlot2, mainData.varEngageSlot2.fighterSlotObject);
    }
    else if (mainData.varEngageSlot2.sprite_index != Empty)
    {
        if (mainData.varEngageSlot3.sprite_index == Empty)
        {
            mainData.varEngageSlot3.sprite_index = tempObject.sprite_index;    
            mainData.varEngageSlot3.containsObject = bufferHero;
            resetActiveHero();
            bufferHero.image_alpha = 0.25;
            calculateWinChance(mainData.varEngageSlot3.containsObject, true);
            
            // Assign activeHero to fighterSlot
            updateFighterSlots(mainData.varEngageSlot3, mainData.varEngageSlot3.fighterSlotObject);
        }
    }
}

}
