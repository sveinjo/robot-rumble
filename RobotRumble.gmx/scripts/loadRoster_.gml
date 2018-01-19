if (initial == 0)
{
hero1 = instance_create(15, 68, hero);
heroFrame1 = instance_create(0, -176, actorFrame);
heroFrame1.parentActor = hero1;
hero1.sprite_index = Chronomancer;
hero1.skillSlot1 = 25;
hero1.level = 2;

hero2 = instance_create(15, 260, hero);
heroFrame2 = instance_create(0, -176, actorFrame);
heroFrame2.parentActor = hero2;
hero2.sprite_index = Hackbot;
hero2.skillSlot1 = 50;

hero3 = instance_create(15, 452, hero);
heroFrame3 = instance_create(0, -176, actorFrame);
heroFrame3.parentActor = hero3;
hero3.sprite_index = Hunter;
hero3.skillSlot1 = 75;

hero4 = instance_create(15, 644, hero);
heroFrame4 = instance_create(0, -176, actorFrame);
heroFrame4.parentActor = hero4;
hero4.sprite_index = Scout;
hero4.skillSlot1 = 75;

hero5 = instance_create(15, 836, hero);
heroFrame5 = instance_create(0, -176, actorFrame);
heroFrame5.parentActor = hero5;
hero5.sprite_index = Tank;
hero5.skillSlot1 = 75;

hero6 = instance_create(381, 68, hero);
heroFrame6 = instance_create(0, -176, actorFrame);
heroFrame6.parentActor = hero6;
hero6.sprite_index = Hunter;
hero6.skillSlot1 = 75;

initial = 1;
}
instance_create(913, 761, object9);


mainData.varEngageSlot1 = instance_create(913, 452, engageSlot);
mainData.varEngageSlot1.fighterSlotObject = 1;

mainData.varEngageSlot2 = instance_create(1238, 452, engageSlot);
mainData.varEngageSlot2.fighterSlotObject = 2;

mainData.varEngageSlot3 = instance_create(1563, 452, engageSlot);
mainData.varEngageSlot3.fighterSlotObject = 3;
