justShowPanel = argument0;
roomName = argument1;

/*if alarm[alarmNumber] = 0
{
    room_goto(roomName);
}*/

if (justShowPanel = 1)
{
    //if (objInfoBack.collapsed == 0)
    objInfoBack.sideBarShown = 1;
}    
else if (roomName == playField)
{
    objInfoBack.sideBarShown = 3;
} 
else if (roomName == fightRoom)
{
    objInfoBack.sideBarShown = 4;
}
else if (roomName == missionSelect)
{
    objInfoBack.sideBarShown = 5;    
}
else if (roomName == credits)
{
    objInfoBack.sideBarShown = 6;    
}
else if (roomName == charge)
{
    objInfoBack.sideBarShown = 7;    
}
else if (roomName == homeBase)
{
    objInfoBack.sideBarShown = 8;    
}
