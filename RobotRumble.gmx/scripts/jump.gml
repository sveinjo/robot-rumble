//varDirection = y;

if (y != hbase) // if we are in the air
{
    grav = 0.5; // set the gravity to .5
    vspd += grav; // add .5 to our vspd once every step
}
else // else if we are on the ground
{
    grav = 0; // set the gravity to 0
    vspd = -10; // set vspd to 0 to stop moving    
}

if keyboard_check_released(vk_up) // if we released the up button while in the in air
{
    vspd *= .5; // divide our vspd by 2, creating a smooth type of variable jumping
}

repeat(abs(vspd)) // we want to check for a collision every pixel, so we use a repeat() function to check every pixel while falling
{
    if (y != hbase + 1) // vspd can be negative or positive, so we check 1 pixel above or below, depending on which direction we are going
    {
        y += sign(vspd); // add to our y value 1 pixel at a time, letting use check for a collision every pixel
    }
    else // else if we hit a block
    {
        vspd = 0; // stop moving vertically
        y = hbase;
    }
}
