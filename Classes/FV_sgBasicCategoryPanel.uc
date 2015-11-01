
class FV_sgBasicCategoryPanel expands FV_GUI_Panel;
//Buttons are dynamically placed!
//Panel consists on title and buttons

var FV_sgBasicBuildingPanel BuildingPanel;

var Color WhiteColor;
var int CurSelected, LastSelected;
var bool bBuilding; //Selection >= 0 in last check
var float ButtonSize;

var float RDelta, UDelta;

function sgSetup( sgConstructor C)
{
	local FV_GUI_Button aButton;
	local int i;

	BuildingPanel = new(self,'BasicBuildingPanel') class'FV_sgBasicBuildingPanel';
	RegisterElement( BuildingPanel);
	BuildingPanel.sgSetup( C);

	aButton = new(self,'BasicUpgradeButton') class'FV_GUI_Button';
	aButton.Setup( 64, 64, 0, 0, C.Functions[0] );					//LOCALIZED
	aButton.RegisterTex( Texture'GUI_UpgradeModu', 4, WhiteColor);
	aButton.RegisterTex( Texture'GUI_UpgradeFront',3, WhiteColor);
	RegisterButton( aButton);
	
	aButton = new(self,'BasicRepairButton') class'FV_GUI_Button';
	aButton.Setup( 64, 64, 0, 0, C.Functions[1] );					//LOCALIZED
	aButton.RegisterTex( Texture'GUI_RepairBase', 3, WhiteColor);
	aButton.RegisterTex( FireTexture'GUI_RepairEffect',3, WhiteColor);
	RegisterButton( aButton);

	aButton = new(self,'BasicRemoveButton') class'FV_GUI_Button';
	aButton.Setup( 64, 64, 0, 0, C.Functions[2] );					//LOCALIZED
	aButton.RegisterTex( Texture'GUI_RemoveModu', 4, WhiteColor);
	aButton.RegisterTex( Texture'GUI_RemoveFront',3, WhiteColor);
	RegisterButton( aButton);
	
	aButton = new(self,'BasicOrbButton') class'FV_GUI_Button';
	aButton.Setup( 64, 64, 0, 0, "Orb" );					//DYNAMIC
	aButton.RegisterTex( Texture'GUI_OrbModu', 4, WhiteColor);
	aButton.RegisterTex( Texture'GUI_OrbFront',3, WhiteColor);
	RegisterButton( aButton);
	
	//17 is the CatActor's NetCategory array size
	For ( i=0 ; i<17 ; i++ )
	{
		aButton = new(self) class'FV_GUI_Button';
		aButton.Setup( 64, 64, 0, 0, "DUMMY");
		aButton.RegisterTex( Texture'IconSelection', 3, WhiteColor);
		RegisterButton( aButton);
		aButton.bNoRender = true;
	}
	if ( C.CatActor != none )
		iButtons = 4 + C.CatActor.iCat;
}

function PostRender( Canvas C)
{
	local sgConstructor CT;

	AddCanvasFrame( C);

	assert( LocalPlayer != none);
	CT = sgConstructor(LocalPlayer.Weapon);
	assert( CT != none );
	C.bNoSmooth = false;
	DefaultRenderButtons( C);
	C.bNoSmooth = true;
	
	assert( Parent != none);
	RemCanvasFrame( C);
}

//New values not yet stored, use the parameters instead
function FrameResized( float oX, float oY, float XL, float YL)
{
	local int i;

	Super.FrameResized( oX, oY, XL, YL); //Sets new canvas boundaries

//	ButtonSize = YL * 0.66; //Big size is default
	For ( i=0 ; i<iButtons ; i++ )
		Buttons[i].YOffset = YL * 0.35;
	AdjustButtonSizes();
	AdjustButtonOffsets();

	BuildingPanel.FrameResized( oX, oY, XL, YL);
}

function Tick( float DeltaTime)
{
	assert( sgConstructor(LocalPlayer.Weapon) != none );
	if ( CurSelected < 0 ) //Setting up menu
	{
		CurSelected = sgConstructor(LocalPlayer.Weapon).Category;
		LastSelected = CurSelected;
		RDelta = 0;
		UDelta = 0;
		bBuilding = sgConstructor(LocalPlayer.Weapon).Selection >= 0;
		AdjustButtonSizes();
		AdjustButtonOffsets();
		return;
	}

	//Building status
	if ( (sgConstructor(LocalPlayer.Weapon).Selection >= 0) != bBuilding )
	{
		UDelta = 1 - UDelta;
		bBuilding = !bBuilding;
	}
	//Category status
	if ( CurSelected != sgConstructor(LocalPlayer.Weapon).Category ) //Category change has been issued
	{
		RDelta = 1;
		LastSelected = CurSelected;
		CurSelected = sgConstructor(LocalPlayer.Weapon).Category;
	}
	
	
	if ( UDelta > 0 ) //Building alpha + category
	{
		UDelta = fMax(UDelta - DeltaTime * 3 / LocalPlayer.Level.TimeDilation, 0);
		AdjustButtonSizes();
		if ( RDelta > 0 )
			Goto OFFSET_ADJ;
		AdjustButtonOffsets();
	}
	else if ( RDelta > 0 ) //Category alpha
	{
		OFFSET_ADJ:
		RDelta = fMax(RDelta - DeltaTime * 4 / LocalPlayer.Level.TimeDilation, 0);
		AdjustButtonOffsets();
		if ( RDelta == 0 )
			LastSelected = CurSelected;
	}
}


function ConstructorDown()
{
	RDelta = 0;
	UDelta = 0;
	CurSelected = -1;
	LastSelected = -1;
	bBuilding = false;
}

//Back and forth
function AdjustButtonSizes()
{
	local int i;
	local float YOff;

	if ( bBuilding )
	{
		ButtonSize = CurY * (0.33 + 0.33 * UDelta);
		YOff = CurY * (0.65 - 0.35 * UDelta);
	}
	else
	{
		ButtonSize = CurY * (0.66 - 0.33 * UDelta);
		YOff = CurY * (0.30 + 0.35 * UDelta);
	}
	For ( i=0 ; i<iButtons ; i++ )
	{
		Buttons[i].SizeX = ButtonSize;
		Buttons[i].SizeY = ButtonSize;
		Buttons[i].YOffset = YOff;
	}
}

//Always delta forward
function AdjustButtonOffsets()
{
	local int i, j, VisibleStart, k;
	local float f;
	local FV_GUI_Button aButton;

	j = CurSelected - LastSelected;

	assert( sgConstructor(LocalPlayer.Weapon) != none );
	iButtons = 4 + sgConstructor(LocalPlayer.Weapon).CatActor.iCat;

	//Substract 1 if went through disabled orb
	while ( j < 0 )
		j += iButtons;
	if ( RDelta > 0 )
	{
		f = float(j) * (1-RDelta);
		VisibleStart = (LastSelected + int(f)) % iButtons;
		while ( i < VisibleStart )
			Buttons[i++].ColorScale = 0.5;
		Buttons[i++].ColorScale = (1+RDelta) * 0.5;
		Buttons[(i++)% iButtons].ColorScale = (2-RDelta) * 0.5;
		while ( i < iButtons )
			Buttons[i++].ColorScale = 0.5;
	}
	else
	{
		VisibleStart = CurSelected % iButtons;
		while ( i < VisibleStart )
			Buttons[i++].ColorScale = 0.5;
		Buttons[i++].ColorScale = 1;
		while ( i < iButtons )
			Buttons[i++].ColorScale = 0.5;
	}

	For ( i=0 ; i<iButtons ; i++ )
		Buttons[i].bNoRender = true;

	f = (CurX / ((ButtonSize+2) * 1.10)) + 0.9; //Max button count
	k = int(f);

	f = RDelta * j;
	f -= int(f);

	i = 0;
	LOOP:
	if ( (i >= k) || (i >= iButtons) )
		return;
	aButton = Buttons[ (VisibleStart + i) % iButtons ];
	aButton.bNoRender = aButton.Texture[0] == none;
	if ( RDelta > 0 )
		aButton.XOffset = (ButtonSize * 1.15) * (i + f - 1);
	else
		aButton.XOffset = ButtonSize * 1.15 * i;
	i++;
	Goto LOOP;
}

function bool ActiveOrbs()
{
	return false;
}

defaultproperties
{
    GUI_Code="BasicCategoryBrowser"
    WhiteColor=(R=255,B=255,G=255)
    CurSelected=-1
    LastSelected=-1
}