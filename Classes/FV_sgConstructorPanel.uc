class FV_sgConstructorPanel expands FV_GUI_Panel;

var FV_sgBasicCategoryPanel BasicCat; //Direct reference, easier access
var Color WhiteColor, GrayColor;
var Color HUDColor;
var float Scale; //Passed by sgConstructor
var bool bOrb; //Used as a marker to pop/push action number (3)
var bool bSetup;

var Texture Borders[4], ModuBorders[4];

//var FV_GUI_Panel SubElements[32]; //Visible elements
//var int iElements;



function PostRender( Canvas C)
{
	local float OldCX, OldCY;
	local int iBorder;
	local int MidLine, BorderSize, LowLeftLine;

	OldCX = C.ClipX;
	OldCY = C.ClipY;
	iBorder = PickBorder();
	SetCanvasFrame( C);
	MidLine = int( CurY * 0.76); //Max midline size
	BorderSize = Borders[iBorder].USize;
	LowLeftLine = int( CurX * 0.21);

	if ( LocalPlayer.Level.bHighDetailMode )
	{
		C.DrawColor = WhiteColor;
		C.Style = 4; //Modu
		C.SetPos( -iBorder, -iBorder);
		C.DrawIcon( ModuBorders[iBorder], 1);
		C.SetPos( -iBorder, BorderSize - iBorder); //Left line
		C.DrawTile( ModuBorders[iBorder], BorderSize, MidLine - (BorderSize - iBorder), 0, -1, BorderSize, 0);
		C.SetPos( BorderSize - iBorder, -iBorder); //Top line
		C.DrawTile( ModuBorders[iBorder], CurX - (BorderSize - iBorder), BorderSize, -1, 0, 0, BorderSize);
		C.SetPos( 1, MidLine - 1); //Mid line
		C.DrawTile( Texture'GUI_BorderTop_M', CurX - 1, 3, 0, 2, 4, 3);
		C.SetPos( CurX - 1, 1); //Right line
		C.DrawTile( Texture'GUI_BorderLeft_M', 3, CurY - 2, 2, 0, 3, 4);
		C.SetPos( BorderSize - iBorder, BorderSize - iBorder); //Top Square
		C.DrawTile( ModuBorders[iBorder], CurX - (C.CurX+1), MidLine - (C.CurX+1), -1, -1, 0, 0);
		C.SetPos( LowLeftLine - iBorder, CurY + iBorder - BorderSize); //Bottom left turn
		C.DrawTile( ModuBorders[iBorder], BorderSize, BorderSize, 0, 0, BorderSize, -BorderSize);
		C.SetPos( LowLeftLine + BorderSize - iBorder, CurY + iBorder - BorderSize); //Bottom line
		C.DrawTile( ModuBorders[iBorder], CurX + iBorder - (LowLeftLine + BorderSize), BorderSize, -1, 0, 0, -BorderSize);

			C.SetPos( LowLeftLine - iBorder, MidLine + 2); //Bottom left line
			C.DrawTile( ModuBorders[iBorder], BorderSize, CurY - (MidLine + 1 + BorderSize), 0, -1, BorderSize, 0);
			C.SetPos( LowLeftLine + BorderSize - iBorder, MidLine + 2); //Bottom shade
			C.DrawTile( ModuBorders[iBorder], CurX + iBorder - (LowLeftLine + BorderSize), CurY - (MidLine + 1 + BorderSize), -1, -1, 0, 0);

		C.DrawColor = HUDColor;
	}
	else
		C.DrawColor = GrayColor;

	C.Style = 3; //Trans
	C.SetPos( -iBorder, -iBorder);
	C.DrawIcon( Borders[iBorder], 1);
	C.SetPos( -iBorder, BorderSize - iBorder); //Left line
	C.DrawTile( Borders[iBorder], BorderSize, MidLine - (BorderSize - iBorder), 0, -1, BorderSize, 0);
	C.SetPos( BorderSize - iBorder, -iBorder); //Top line
	C.DrawTile( Borders[iBorder], CurX - (BorderSize - iBorder), BorderSize, -1, 0, 0, BorderSize);
	C.SetPos( 1, MidLine - 1); //Mid line
	C.DrawTile( Texture'GUI_BorderTop_F', CurX - 1, 3, 0, 2, 4, 3);
	C.SetPos( CurX - 1, 1); //Right line
	C.DrawTile( Texture'GUI_BorderLeft_F', 3, CurY - 2, 2, 0, 3, 4);
	C.SetPos( BorderSize - iBorder, BorderSize - iBorder); //Top Square
	C.DrawTile( Borders[iBorder], CurX - (C.CurX+1), MidLine - (C.CurX+1), -1, -1, 0, 0);
	C.SetPos( LowLeftLine - iBorder, CurY + iBorder - BorderSize); //Bottom left turn
	C.DrawTile( Borders[iBorder], BorderSize, BorderSize, 0, 0, BorderSize, -BorderSize);
	C.SetPos( LowLeftLine + BorderSize - iBorder, CurY + iBorder - BorderSize); //Bottom line
	C.DrawTile( Borders[iBorder], CurX + iBorder - (LowLeftLine + BorderSize), BorderSize, -1, 0, 0, -BorderSize);

		C.SetPos( LowLeftLine - iBorder, MidLine + 2); //Bottom left line
		C.DrawTile( Borders[iBorder], BorderSize, CurY - (MidLine + 1 + BorderSize), 0, -1, BorderSize, 0);
		C.SetPos( LowLeftLine + BorderSize - iBorder, MidLine + 2); //Bottom shade
		C.DrawTile( Borders[iBorder], CurX + iBorder - (LowLeftLine + BorderSize), CurY - (MidLine + 1 + BorderSize), -1, -1, 0, 0);

	C.SetPos( 0, 0);

	//Do not render anything from this class yet

	//Render children
	PropagatePostRender( C);


	C.SetOrigin( 0, 0);
	C.SetClip( OldCX, OldCY);
}

function ConstructorDown()
{
	if ( BasicCat != none )
		BasicCat.ConstructorDown();
}

//Only called when constructor is up
function Tick( float DeltaTime)
{
	if ( !bSetup )
		return;
	PropagateTick( DeltaTime);
}

function sgSetup( sgConstructor C)
{
	Assert( !bSetup );

	BasicCat = new(self,'BasicCategoryPanel') class'FV_sgBasicCategoryPanel';
	RegisterElement( BasicCat);
	BasicCat.sgSetup( C);

	bSetup = true;
}

//New values not yet stored, use the parameters instead
function FrameResized( float oX, float oY, float XL, float YL)
{
	//IN A 370*250 PANEL, THIS GOES CENTERED (X) AND HAS:
	//320 * 55 ICON PANEL SIZE
	//320 * 30 TEXT BOX SIZE
	BasicCat.FrameResized( int(XL * 0.06), int(YL * 0.067), int(XL * 0.88), int(YL * 0.45));
}

function int PickBorder()
{
	local float r;
	r = Scale * 3;
	return Min( Scale, 3);
}

defaultproperties
{
    bBoundaryPointer=True
    bTrackFrame=True
    GUI_Code="ConstructorGUI"
    WhiteColor=(R=255,B=255,G=255)
    GrayColor=(R=160,B=160,G=160)
    Scale=1
    Borders(0)=Texture'GUI_Border1_F'
    Borders(1)=Texture'GUI_Border2_F'
    Borders(2)=Texture'GUI_Border3_F'
    Borders(3)=Texture'GUI_Border4_F'
    ModuBorders(0)=Texture'GUI_Border1_M'
    ModuBorders(1)=Texture'GUI_Border2_M'
    ModuBorders(2)=Texture'GUI_Border3_M'
    ModuBorders(3)=Texture'GUI_Border4_M'
}