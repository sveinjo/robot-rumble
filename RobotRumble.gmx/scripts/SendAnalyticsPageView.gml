///SendAnalyticsPageView(pageViewDocumentHostname,pageViewPage, pageViewTitle)

/*
&t=pageview     // Pageview hit type.
&dh=mydemo.com  // Document hostname.
&dp=/home       // Page.
&dt=homepage    // Title.

*/
pageViewDocumentHostname = argument0;
pageViewPage = argument1;
pageViewTitle = argument2;

var str = "&tid=" + global.trackingID + "&cid=" + string(global.playerID) + "&t=pageview" +"&dh="+pageViewDocumentHostname + "&dp="+pageViewPage+ "&dt="+pageViewTitle;
 post = http_post_string("http://www.google-analytics.com/collect?v=1", str);
