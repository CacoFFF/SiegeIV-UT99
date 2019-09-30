class FV_ConstructorWheelButtonFav expands FV_ConstructorWheelButton;


//We're using relative position to draw, not absolute coordinates
//The panel drawing these buttons may alter clip regions
function PostRender( Canvas C)
{
	local int i;
	local float Scale;
	
	Scale = FV_ConstructorWheel(Parent).Scale;
	XOffset = C.ClipX * 0.5 + (CachedOffset.X - SizeX * 0.5) * Scale;
	YOffset = C.ClipY * 0.5 + (CachedOffset.Y - SizeY * 0.5) * Scale;

	ColorScale = 1;
	if ( !bIsSelected )
		ColorScale -= FV_ConstructorWheel(Parent).ColorScale * 0.8;
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
}


//Fixed setup
function Setup( float sX, float sY, float mySlot, float numSlots, string aName, optional string aDescription, optional string ButtonCode)
{
	SizeX = sX;
	SizeY = sY;
	ButtonID = 31; //This crap had better not fail
	ButtonName = aName;
	ButtonDescription = aDescription;
	if ( ButtonCode != "" ) //THIS IS THE CONSOLE COMMAND!
		GUI_Code = ButtonCode;
}
