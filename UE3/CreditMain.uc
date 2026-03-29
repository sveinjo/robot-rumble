class CreditMain extends Actor
    placeable;

// Story text content
var string StoryText;

// Scrolling and timing variables
var float ScrollSpeed;
var float StarSpawnTimer;
var float StarSpawnInterval;

// Font reference
var Font ArcadeFont;

// Particle classes (would need to be defined separately)
var class<Actor> ParticleStar1Class;
var class<Actor> ParticleStar2Class;
var class<Actor> ParticleStar3Class;

// Canvas for drawing
var Canvas CanvasRef;

function PostBeginPlay()
{
    Super.PostBeginPlay();

    // Initialize variables
    ScrollSpeed = 1.0;
    StarSpawnInterval = 20.0 / 60.0; // 20 frames at 60 FPS
    StarSpawnTimer = StarSpawnInterval;

    // Load font (UDK path)
    ArcadeFont = Font(DynamicLoadObject("YourPackage.Fonts.PressStart2P", class'Font'));

    // Set up particle classes
    ParticleStar1Class = class<Actor>(DynamicLoadObject("YourPackage.Particles.ParticleStar1", class'Class'));
    ParticleStar2Class = class<Actor>(DynamicLoadObject("YourPackage.Particles.ParticleStar2", class'Class'));
    ParticleStar3Class = class<Actor>(DynamicLoadObject("YourPackage.Particles.ParticleStar3", class'Class'));

    // Set timer for ticking
    SetTimer(1.0/60.0, true); // 60 FPS tick
}

function Timer()
{
    // Scroll upward
    Location.Z -= ScrollSpeed; // Note: UE3 uses Z for up/down in 3D, but for 2D you'd adjust

    // Loop when scrolled too far
    if (Location.Z <= -1088)
    {
        Location.Z = 1088;
    }

    // Spawn particles
    StarSpawnTimer -= (1.0/60.0);
    if (StarSpawnTimer <= 0)
    {
        CreateStarParticle();
        StarSpawnTimer = StarSpawnInterval;
    }
}

function CreateStarParticle()
{
    local float RangeVal, StarLine, StarType;
    local Actor NewParticle;
    local class<Actor> ParticleClass;

    RangeVal = 1080;
    StarLine = FRand() * RangeVal;
    StarType = FRand() * 3;

    // Choose particle type
    if (StarType > 2)
        ParticleClass = ParticleStar3Class;
    else if (StarType > 1)
        ParticleClass = ParticleStar2Class;
    else
        ParticleClass = ParticleStar1Class;

    // Position
    StarLine = 1080 - 20 - RangeVal + StarLine;

    // Spawn particle
    NewParticle = Spawn(ParticleClass, self,, vect(1920, StarLine, 0), rot(0,0,0));
}

function PostRender(Canvas C)
{
    local float FontSize, TextWidth;
    local vector TextPos;

    CanvasRef = C;

    // Draw text with shadow
    FontSize = 18;
    TextWidth = 640;
    TextPos = vect(640, 10, 0); // Adjust for centering

    // Blue shadow
    C.SetPos(TextPos.X + 3, TextPos.Y + 3);
    C.SetDrawColor(0, 0, 255); // Blue
    DrawTextOnCanvas(StoryText, TextWidth);

    // White text
    C.SetPos(TextPos.X, TextPos.Y);
    C.SetDrawColor(255, 255, 255); // White
    DrawTextOnCanvas(StoryText, TextWidth);
}

function DrawTextOnCanvas(string Text, float Width)
{
    local array<string> Lines;
    local int i;

    // Split text into lines and draw (simplified)
    Split(Text, "\n", Lines);
    for (i = 0; i < Lines.Length; i++)
    {
        CanvasRef.DrawText(Lines[i]);
        CanvasRef.SetPos(CanvasRef.CurX, CanvasRef.CurY + 20); // Line spacing
    }
}

defaultproperties
{
    StoryText="It's the future!\\n\\n\\n\\nMankind has evolved!\\n\\n\\n\\nBy infusing their biology with nano-machines and robotics, they have acquired fantastic powers.\\n\\n\\n\\nHowever, this came at a price...\\n\\n\\n\\nEveryone also acquired the 'power' of diabetes, and thus insulin became the world's most valuable resource.\\n\\n\\n\\nYour stores of food and insulin have been taken, and you must get them back!"

    bHidden=false
    bStatic=false
}