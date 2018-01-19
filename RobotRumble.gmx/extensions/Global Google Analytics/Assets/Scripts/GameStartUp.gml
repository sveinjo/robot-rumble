///Load all the required global variables

//Load the player ID 
ini_open("savedata.ini");
global.playerID = ini_read_real("settings", "playerID", 0);

//If we haven't fount it generate a new one
if(global.playerID == 0)
{
    randomize();
    global.playerID = irandom(90000000);
    
    //Write it back so it can be used next time
    ini_write_real("settings", "playerID", global.playerID);
}
ini_close();


//This is your tracking ID generated when you created your google analytics details 
//For more details on setting up a tracking ID: http://help.yoyogames.com/entries/23673291-Analytics-Google-Analytics
global.trackingID = 'UA-XXXXXXXX-X'