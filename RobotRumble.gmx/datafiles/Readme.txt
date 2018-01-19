The attached scripts are a way to utilises platform independent analytic to quickly log pages / rooms visited and key game event data.

The demo shows a typical game scenario with a start up script, room transitions and game events. To use analytics there are a couple of steps:

1. Create an account and profile as per http://help.yoyogames.com/entries/23673291-Analytics-Google-Analytics. 
Note the tracking ID it should have a similar format to this 'UA-XXXXXXXX-X'

2.In the game's startup code two variables are required

As defined in your Google analytics account above
global.trackingID = 'UA-XXXXXXXX-X'

and

global.playerID
This allows you to track return vists.

3. Log page views when loading a different room
SendAnalyticsPageView("www.anything.com","GameRooms",room_get_name(room));

4. Log game events and values
SendAnalyticsEvent("RoomActions","Bubbles","Popped",global.BubblesPopped);

I generally try and store these values and send them when a level ends.

You can log any number of events and event types things like level times,  level deaths, level collectables etc.