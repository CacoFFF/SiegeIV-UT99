class FV_ConstructorWheelButton expands FV_GUI_Button;

//Very basic button drawing support
//TODO: Notify panel that pointer is hovering above me
/*
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
*/

//Cached during setup
var vector CachedOffset; //Calc XOffset, YOffset using this ||| only for drawing
var float MinAngle, MaxAngle; //Calc collision using this
var int ButtonId;
var string Abbreviation;

//Status
var bool bIsSelected; //Only valid during rendering
var bool bIsCategory;

//Used for buildings and actions
var bool bIsBuilding;
var int RuleSlot; 

//We're using relative position to draw, not absolute coordinates
//The panel drawing these buttons may alter clip regions
function PostRender( Canvas C)
{
	local int i;
	local float Scale, XL, YL, XO, YO;
	local string Text;
	
	Scale = FV_ConstructorWheel(Parent).Scale;
	XOffset = C.ClipX * 0.5 + (CachedOffset.X - SizeX * 0.5) * Scale;
	YOffset = C.ClipY * 0.5 + (CachedOffset.Y - SizeY * 0.5) * Scale;

	if ( bIsSelected )	ColorScale = 1;
	else				ColorScale = FV_ConstructorWheel(Parent).ColorScale * 0.8;
LOOP:
	C.DrawColor = Colors[i];
	C.Style = Style[i];

	if ( Style[i] != 4 )
	{
		if ( bIsBuilding && !sgConstructor(LocalPlayer.Weapon).CatActor.RulesAllow( RuleSlot) )
		{
			C.DrawColor.R = 80; //Temporary
			C.DrawColor.G = 0;
			C.DrawColor.B = 30;
		}
		else
			C.DrawColor = ScaleColor(Colors[i]);
	}
	C.SetPos( XOffset, YOffset);
	C.DrawTileClipped( Texture[i], SizeX * Scale * ScalePos[i].X, SizeY * Scale * ScalePos[i].Y, 0, 0, Texture[i].USize, Texture[i].VSize);
	if ( ++i < iTex )
		Goto LOOP;
		
	if ( Abbreviation != "" && (ColorScale >= 0.2) && (C.Font != None) )
	{
		if ( bIsSelected )
		{
			Text = Abbreviation;
			Abbreviation = ButtonName;
		}
		C.StrLen( Abbreviation, XL, YL);
		XO = C.ClipX * 0.5 + CachedOffset.X * Scale * 1.3;
		YO = C.ClipY * 0.5 + CachedOffset.Y * Scale * 1.3 - YL * 0.5;
		if ( CachedOffset.X < 0 )
			XO -= XL;
		else if ( CachedOffset.X < 8 )
			XO -= XL * CachedOffset.X / 8;
		C.SetPos( XO+1, YO+1);
		C.Style = 2;
		C.DrawColor = class'SiegeStatics'.default.BlackColor;
		C.DrawText( Abbreviation);
		C.SetPos( XO, YO);
		C.DrawColor = FV_ConstructorWheel(Parent).WhiteColor;
		C.DrawText( Abbreviation);
		if ( bIsSelected )
			Abbreviation = Text;
	}
}

//Wheel styled setup
function Setup( float sX, float sY, float mySlot, float numSlots, string aName, optional string aDescription, optional string ButtonCode)
{
	local float Angle;
	local int i;
	local string aStr;
	
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
	
//Generate an abbreviation	
	Abbreviation = "";
	aStr = aName;
CHOP_AGAIN_A:
	Abbreviation = Abbreviation $ Left(aStr,1); //Get first letter
	i = InStr( aStr, " ");
	if ( i >= 0 )
	{
		if ( Len(Abbreviation) == 1 ) //First letter, let's see if remaining letter in first word are upper case
		{
			while ( i > 1 )
			{
				aStr = Mid( aStr, 1);
				i--;
				if ( !IsUpperCase(Asc(aStr)) )
					break;
				if ( i==2 )
				{
					Abbreviation = Left(aName, InStr(aName," "));
					return;
				}
			}
		}
		aStr = Mid( aStr, i+1);
		goto CHOP_AGAIN_A;
	}

	//Find other upper case letters if there's only 1 word
	if ( Len(Abbreviation) == 1 )
	{
		aStr = Mid(aName, 1);
		while ( aStr != "" )
		{
			i = Asc( aStr); //Upper case letter
			if ( IsUpperCase(i) )
				Abbreviation = Abbreviation $ Chr(i);
			aStr = Mid(aStr, 1);
		}
	}
}

final function bool IsUpperCase( int Char)
{
	return Char>=65 && Char <=90;
}


defaultproperties
{
    bNoTick=True
    ColorScale=1
}