//range = 330;
range = 1080;

//upperLower = random(1);
upperLower = 0;

starLine = random(range);
starType = random(3);
particleType = particleStar1;
startPosition = 1920;
//if (room == fightRoom)
//    starType

if (argument0 > 0)
    startPosition = argument0;

if (starType > 1)
{    
    if (starType > 2)
    {
        particleType = particleStar3;
    }
    else
    {
        particleType = particleStar2;
    }
}

// if center arae is to be clear
if (upperLower <= 0.5)
{
    starLine = 1080 - 20 - range + starLine;           
}

instance_create(startPosition, starLine, particleType);
