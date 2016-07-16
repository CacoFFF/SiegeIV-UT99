class FV_ConstructorWheelButton expands FV_GUI_Button;

//Very basic button drawing support
//TODO: Notify panel that pointer is hovering above me
/*
var Texture Texture[4];
var byte Style[4]; //Change style to zero in order to cancel drawing
var Color Colors[4];
var float SizeX, SizeY;
var float ColorScale;
var int iTex;
var string ButtonName;
var string ButtonDescription;

var float XOffset, YOffset;
*/

//Cached during setup
var vector CachedOffset; //Calc XOffset, YOffset using this ||| only for drawing
var float MinAngle, MaxAngle; //Calc collision using this
var int ButtonId;

//Used for buildings
var bool bIsBuilding;
var int RuleSlot; 

//We're using relative position to draw, not absolute coordinates
//The panel drawing these buttons may alter clip regions
function PostRender( Canvas C)
{
	local int i;
	local float Scale;
	
	Scale = FV_ConstructorWheel(Parent).Scale;
	XOffset = C.ClipX * 0.5 + (CachedOffset.X - SizeX * 0.5) * Scale;
	YOffset = C.ClipY * 0.5 + (CachedOffset.Y - SizeY * 0.5) * Scale;

	ColorScale = FV_ConstructorWheel(Parent).ColorScale;
	LOOP:
	if ( ColorScale < 1 && (Style[i] != 4) )
		C.DrawColor = ScaleColor(Colors[i]);
	else if ( bIsBuilding && !sgConstructor(LocalPlayer.Weapon).CatActor.RulesAllow( RuleSlot) )
	{
		C.DrawColor.R = 40; //Temporary
		C.DrawColor.G = 0;
		C.DrawColor.B = 20;
	}
	else
		C.DrawColor = Colors[i];
	C.Style = Style[i];
	C.SetPos( XOffset, YOffset);
	C.DrawTileClipped( Texture[i], SizeX * Scale, SizeY * Scale, 0, 0, Texture[i].USize, Texture[i].VSize);
	if ( ++i < iTex )
		Goto LOOP;
}

//Wheel styled setup
function Setup( float sX, float sY, float mySlot, float numSlots, string aName, optional string aDescription, optional string ButtonCode)
{
	local float Angle;

	SizeX = sX;
	SizeY = sY;
	ButtonID = int(mySlot + 0.1); //This crap had better not fail

	if ( numSlots < 4 ) //Arrange at least in 4 cardinal points
		numSlots = 4;
	Angle = 2*pi / numSlots; //Get reference position 1
	MinAngle = Angle*mySlot - Angle*0.5; //Adjust boundaries
	MaxAngle = MinAngle + Angle;
	Angle *= mySlot;
	CachedOffset.X = sin( Angle) * 140;
	CachedOffset.Y = -cos( Angle) * 140;
	
	ButtonName = aName;
	ButtonDescription = aDescription;
	if ( ButtonCode != "" ) //THIS IS THE CONSOLE COMMAND!
		GUI_Code = ButtonCode;
}

/*
function RegisterTex( Texture aTex, byte aStyle, Color aColor)
{
	assert( aTex != none);
	assert( iTex < arrayCount(Texture) );
	Texture[iTex] = aTex;
	Style[iTex] = aStyle;
	Colors[iTex++] = aColor;
}

function Color ScaleColor( Color C)
{
	local float f;
	f = float(C.R) * ColorScale;
	C.R = byte(f);
	f = float(C.G) * ColorScale;
	C.G = byte(f);
	f = float(C.B) * ColorScale;
	C.B = byte(f);
	return C;
}
*/


defaultproperties
{
    bNoTick=True
    ColorScale=1
}