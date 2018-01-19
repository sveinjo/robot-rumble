backPanel = argument0

if (backPanel.hspeed > -50)
{
    backPanel.hspeed -= panelAcceleration;
}
    
// scroll badguys out
/*
if (room == playField)
{
    badGuy1.hspeed += panelAcceleration;
    badGuy2.hspeed = badGuy1.hspeed / 2;
}*/

if (backPanel.x <= -732)
{
    backPanel.hspeed = 0;
    //x = 0;
    if (backPanel.sideBarShown == 3)
    {
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
        with (fighterSlot)
        {
            instance_destroy();
        }
        mainData.varFighterSlot1 = 0;
        
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
    else if (backPanel.sideBarShown == 10)
    {
        saveButton.visible = 1;
        loadButton.visible = 1;
        exitButton.visible = 1;
        backPanel.sideBarShown = 1;    
    }
    
    
}

/*if (objInfoBack.x > -732)
{
    //hspeed = (0 - x) / 2;
    hspeed = -(0 - x) / 2;
}
else
{
    hspeed = 0;
    collapsed = 1;
}*/
