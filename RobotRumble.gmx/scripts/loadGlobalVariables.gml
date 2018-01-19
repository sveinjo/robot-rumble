randomize();

// Initialize environment
globalvar deployTarget;
globalvar playMusic;
globalvar speechBubbles;
//deployTarget = "html5";
deployTarget = "win";
playMusic = 1;
speechBubbles = 0;

///Load Startup Script for google analytics
GameStartUp();


globalvar grabbed;
grabbed=false;

globalvar bufferHero;
bufferHero = 0;


globalvar initial;
initial = 0;

globalvar panelAcceleration;
panelAcceleration = 4;

globalvar starSpeed;
//starSpeed = 24;
starSpeed = 2;

globalvar starSize;
//starSize = 12;
starSize = 1;

globalvar mainData;
mainData = buttonMenu.id;

//arrayHeroes = ds_list_create();


// Roster

mainData.varHero1 = instance_create(15, 68, heroData);
mainData.varHero1.class = "Chronomancer";
mainData.varHero1.sprite_index = Chronomancer;
mainData.varHero1.skillSlot1 = 2;
mainData.varHero1.intLevel = 1;
mainData.varHero1.intXp = 0;
mainData.arrayHeroes[1] = mainData.varHero1;

mainData.varHero2 = instance_create(15, 260, heroData);
mainData.varHero2.class = "Hackbot";
mainData.varHero2.sprite_index = Hackbot;
mainData.varHero2.skillSlot1 = 1;
mainData.varHero2.intLevel = 1;
mainData.varHero2.intXp = 0;
mainData.arrayHeroes[2] = mainData.varHero2;

mainData.varHero3 = instance_create(15, 452, heroData);
mainData.varHero3.class = "Hunter";
mainData.varHero3.sprite_index = Hunter;
mainData.varHero3.skillSlot1 = 5;
mainData.varHero3.intLevel = 1;
mainData.varHero3.intXp = 0;
mainData.arrayHeroes[3] = mainData.varHero3;

mainData.varHero4 = instance_create(15, 644, heroData);
mainData.varHero4.class = "Scout";
mainData.varHero4.sprite_index = Scout;
mainData.varHero4.skillSlot1 = 7;
mainData.varHero4.intLevel = 1;
mainData.varHero4.intXp = 0;
mainData.arrayHeroes[4] = mainData.varHero4;

mainData.varHero5 = instance_create(15, 836, heroData);
mainData.varHero5.class = "Tank";
mainData.varHero5.sprite_index = Tank;
mainData.varHero5.skillSlot1 = 4;
mainData.varHero5.intLevel = 1;
mainData.varHero5.intXp = 0;
mainData.arrayHeroes[5] = mainData.varHero5;

/*mainData.varHero6 = instance_create(381, 68, heroData);
mainData.varHero6.sprite_index = Hunter;
mainData.varHero6.skillSlot1 = 25;
mainData.varHero6.intLevel = 1;
mainData.varHero6.intXp = 0;
mainData.arrayHeroes[6] = mainData.varHero6;
*/

// missions

mainData.arrayMissions[1] = 0;
mainData.arrayMissions[2] = 0;
mainData.arrayMissions[3] = 0;
mainData.arrayMissions[4] = 0;
mainData.arrayMissions[5] = 0;
mainData.arrayMissions[6] = 0;
mainData.arrayMissions[7] = 0;
mainData.arrayMissions[8] = 0;
mainData.arrayMissions[9] = 0;

// XP
// levels
/*mainData.arrayLevels[1] = 0;
mainData.arrayLevels[2] = 400;
mainData.arrayLevels[3] = 800;
mainData.arrayLevels[4] = 1200;
mainData.arrayLevels[5] = 1600;
mainData.arrayLevels[6] = 2000;
mainData.arrayLevels[7] = 3000;
mainData.arrayLevels[8] = 4000;
mainData.arrayLevels[9] = 5400;
mainData.arrayLevels[10] = 6000;
*/

// D&D
mainData.arrayLevels[1] = 0;
//mainData.arrayLevels[2] = 1000;
mainData.arrayLevels[2] = 500;
mainData.arrayLevels[3] = 3000;
mainData.arrayLevels[4] = 6000;
mainData.arrayLevels[5] = 10000;
mainData.arrayLevels[6] = 15000;
mainData.arrayLevels[7] = 21000;
mainData.arrayLevels[8] = 28000;
mainData.arrayLevels[9] = 36000;
//mainData.arrayLevels[10] = 45000;
mainData.arrayLevels[10] = 1045000;


// enemies



mainData.arrayAbilities[1, 0] = "Troll"
mainData.arrayAbilities[2, 0] = "Time-Warp"
mainData.arrayAbilities[3, 0] = "Blink"
mainData.arrayAbilities[4, 0] = "Armored"
mainData.arrayAbilities[5, 0] = "Counter-Shot"
mainData.arrayAbilities[6, 0] = "Healing"
mainData.arrayAbilities[7, 0] = "Headshot"
mainData.arrayAbilities[8, 0] = "Multi-Shot"

mainData.arrayAbilities[1, 1] = "Wild Aggro";
mainData.arrayAbilities[2, 1] = "Timed Battle";
mainData.arrayAbilities[3, 1] = "Danger Zones";
mainData.arrayAbilities[4, 1] = "Massive Strike";
mainData.arrayAbilities[5, 1] = "Debuff";
mainData.arrayAbilities[6, 1] = "Group Damage";
mainData.arrayAbilities[7, 1] = "Mind Control";
mainData.arrayAbilities[8, 1] = "Minion Swarms"

mainData.arrayEnemies[1, 0] = Henchbot;
mainData.arrayEnemies[2, 0] = Bomb;
mainData.arrayEnemies[3, 0] = Electron;
mainData.arrayEnemies[4, 0] = Mchammer;
mainData.arrayEnemies[5, 0] = Magnetron;
mainData.arrayEnemies[6, 0] = Octobot;
mainData.arrayEnemies[7, 0] = Techromancer;

mainData.arrayEnemies[1, 1] = 1;
mainData.arrayEnemies[2, 1] = 2;
mainData.arrayEnemies[3, 1] = 3;
mainData.arrayEnemies[4, 1] = 4;
mainData.arrayEnemies[5, 1] = 5;
mainData.arrayEnemies[6, 1] = 6;
mainData.arrayEnemies[7, 1] = 7;

mainData.arrayEnemies[1, 2] = "Henchbot";
mainData.arrayEnemies[2, 2] = "Bombot";
mainData.arrayEnemies[3, 2] = "Electron";
mainData.arrayEnemies[4, 2] = "McHammer";
mainData.arrayEnemies[5, 2] = "Magnetron";
mainData.arrayEnemies[6, 2] = "Octobot";
mainData.arrayEnemies[7, 2] = "Tech Romancer";
