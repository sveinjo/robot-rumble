arrayRoster[1] = instance_create(15, 68, hero);
arrayRoster[2] = instance_create(15, 260, hero);
arrayRoster[3] = instance_create(15, 452, hero);
arrayRoster[4] = instance_create(15, 644, hero);
arrayRoster[5] = instance_create(15, 836, hero);
//arrayRoster[6] = instance_create(381, 68, hero);

for (i = 1; i < array_length_1d(arrayRoster); i += 1)
{
    arrayRoster[i].sprite_index = mainData.arrayHeroes[i].sprite_index;
    //arrayRoster[i].skillSlot1 = mainData.arrayHeroes[i].skillSlot1;
    //arrayRoster[i].level = mainData.arrayHeroes[i].level;
    arrayRoster[i].intParent = i;
    //arrayFrame[i] = instance_create(0, -176, actorFrame);
    arrayFrame[i] = instance_create(15, arrayRoster[i].y, actorFrame);
    arrayFrame[i].parentActor = arrayRoster[i];
    arrayFrame[i].intParent = i;
    
}
