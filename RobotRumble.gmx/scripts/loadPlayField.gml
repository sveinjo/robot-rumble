instance_create(913, 761, rewardFrame);

mainData.varEngageSlot1 = instance_create(913, 452, engageSlot);
mainData.varEngageSlot1.fighterSlotObject = 1;
//stripe1 = instance_create(-1000, 540, stillStar);
stripe2 = instance_create(-1900, 540, particleOverlay);
//stripe2.image_yscale = 12;

mainData.varEngageSlot2 = instance_create(1238, 452, engageSlot);
mainData.varEngageSlot2.fighterSlotObject = 2;

mainData.varEngageSlot3 = instance_create(1563, 452, engageSlot);
mainData.varEngageSlot3.fighterSlotObject = 3;

instance_create(1001, 540, marker);
instance_create(1001, 540, marker2);
