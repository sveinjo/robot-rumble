backPanel = argument0

if (backPanel.hspeed > -50)
{
    backPanel.hspeed -= panelAcceleration;
}

if (backPanel.x <= -732)
{
    backPanel.hspeed = 0;

    if (backPanel.sideBarShown == 3)
    {
        with(hero)
        {
            image_alpha = 1;
        }
        room_goto(playField);
        backPanel.sideBarShown = 1;    
    }
    else if (backPanel.sideBarShown == 4)
    {

        room_goto(fightRoom);
        backPanel.sideBarShown = 0;
        
    }
    else if (backPanel.sideBarShown == 5)
    {
        // Clear up fighting heroes
        with (fightingHero)
        {
            instance_destroy();
        }        
        mainData.arrayFightingHeroes = 0;
        
        // Clear up starfields
        with (particleStar1)
        {
            instance_destroy();
        }
        with (particleStar2)
        {
            instance_destroy();
        }
        with (particleStar3)
        {
            instance_destroy();
        }
        

        room_goto(missionSelect);
        backPanel.sideBarShown = 1;
    }
    else if (backPanel.sideBarShown == 6)
    {
        // Clear up starfields
        with (particleStar1)
        {
            instance_destroy();
        }
        with (particleStar2)
        {
            instance_destroy();
        }
        with (particleStar3)
        {
            instance_destroy();
        }
        
        room_goto(credits);
        backPanel.sideBarShown = 0;
        
    }
    else if (backPanel.sideBarShown == 7)
    {
        room_goto(charge);
        backPanel.sideBarShown = 0;
        // stuff
    }
    else if (backPanel.sideBarShown == 8)
    {
        room_goto(homeBase);
        backPanel.sideBarShown = 1;
        // stuff
    }
    else if (backPanel.sideBarShown == 10)
    {
        // Placeholder for later        
    }        
}
