///SendAnalyticsEvent(eventCategory,eventAction, eventLabel, eventValue)
/*
&ec=home%20movement — the event category is home movement

&ea=door%20open — the event action is door open.

&el=bedroom — the event label is bedroom
*/

eventCategory = argument0;
eventAction = argument1;
eventLabel = argument2;
eventValue = argument3;

var str = "&tid=" + global.trackingID + "&cid=" + string(global.playerID) + "&t=event" +"&ec="+eventCategory + "&ea="+eventAction+ "&el="+eventLabel+ "&ev="+eventValue;
 post = http_post_string("http://www.google-analytics.com/collect?v=1", str);
