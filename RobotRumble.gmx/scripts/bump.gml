//varDirection = y;

if (x != vbase) // if we are in the air
{
    grav = -1.7; // set the gravity to .5
    hspd += grav; // add .5 to our vspd once every step


}

repeat(abs(hspd)) // we want to check for a collision every pixel, so we use a repeat() function to check every pixel while falling
{
    if (x != vbase - 1) // vspd can be negative or positive, so we check 1 pixel above or below, depending on which direction we are going
    {
        x += sign(hspd); // add to our y value 1 pixel at a time, letting use check for a collision every pixel
    }
}
