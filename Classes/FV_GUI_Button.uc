class FV_GUI_Button expands FV_GUI_Master;

//Very basic button drawing support
//TODO: Notify panel that pointer is hovering above me

var Texture Texture[4];
var byte Style[4]; //Change style to zero in order to cancel drawing
var Color Colors[4];
var Plane ScalePos[4]; //Use Z and W for offset later
var float SizeX, SizeY;
var float ColorScale;
var int iTex;
var string ButtonName;
var string ButtonDescription;

var float XOffset, YOffset;

//We're using relative position to draw, not absolute coordinates
//The panel drawing these buttons may alter clip regions
function PostRender( Canvas C)
{
	local int i;
	LOOP:
	if ( ColorScale < 1 && (Style[i] != 4) )
		C.DrawColor = ScaleColor(Colors[i]);
	else
		C.DrawColor = Colors[i];
	C.Style = Style[i];
	C.SetPos( XOffset, YOffset);
	C.DrawTileClipped( Texture[i], SizeX, SizeY, 0, 0, Texture[i].USize, Texture[i].VSize);
	if ( ++i < iTex )
		Goto LOOP;
}

function Setup( float sX, float sY, float oX, float oY, string aName, optional string aDescription, optional string ButtonCode)
{
	SizeX = sX;
	SizeY = sY;
	XOffset = oX;
	YOffset = oY;
	ButtonName = aName;
	ButtonDescription = aDescription;
	if ( ButtonCode != "" )
		GUI_Code = ButtonCode;
}

function CopyButton( FV_GUI_Button Other)
{
	local int i;
	For ( i=0 ; i<4 ; i++ )
	{
		Texture[i] = Other.Texture[i];
		Style[i] = Other.Style[i];
		Colors[i] = Other.Colors[i];
		ScalePos[i] = Other.ScalePos[i];
	}
	SizeX = Other.SizeX;
	SizeY = Other.SizeY;
	ColorScale = Other.ColorScale;
	iTex = Other.itex;
	ButtonName = Other.ButtonName;
	ButtonDescription = Other.ButtonDescription;
	GUI_Code = Other.GUI_Code;
}

function RegisterTex( Texture aTex, byte aStyle, Color aColor, optional float ScaleX, optional float ScaleY)
{
	assert( aTex != none);
	assert( iTex < arrayCount(Texture) );
	if ( ScaleX == 0 )
		ScaleX = 1;
	if ( ScaleY == 0 )
		ScaleY = 1;
	Texture[iTex] = aTex;
	Style[iTex] = aStyle;
	ScalePos[iTex].X = ScaleX;
	ScalePos[iTex].Y = ScaleY;
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

function FastReset()
{
	iTex = default.iTex;
	ButtonName = default.ButtonName;
	ButtonDescription = default.ButtonDescription;
	ColorScale = default.ColorScale;
	bNoTick = default.bNoTick;
}

function Reset()
{
	local int i;
	FastReset();
	For ( i=0 ; i<4 ; i++ )
	{
		Texture[i] = default.Texture[i];
		Style[i] = default.Style[i];
		Colors[i] = default.Colors[i];
	}
}

defaultproperties
{
    bNoTick=True
    ColorScale=1
}