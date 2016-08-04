class FV_ConstructorWheel expands FV_GUI_Panel;

#exec TEXTURE IMPORT FILE=Graphics\GWheel_Main_M.pcx GROUP=ConstructorWheel MIPS=OFF
#exec TEXTURE IMPORT FILE=Graphics\GWheel_Main_T.pcx GROUP=ConstructorWheel MIPS=OFF


/*
var FV_GUI_Panel SubElements[32]; //Visible elements
var int iElements;
//iFront is the index of the front panel, we use this to determine if there's a panel we should prioritize

var FV_GUI_Button Buttons[32];
var int iButtons;
var FV_GUI_Panel ChildPanel; //This is ahead, prioritize input

var bool bBoundaryPointer;		//Keep pointer within panel boundary (only for master panel)
var bool bRightClicked;			//Was clicked last frame? (master panel)
var bool bLeftClicked;			//Was clicked last frame? (master panel)
var bool bTrackFrame;			//Auto-notify self and children if frame changes during Render

var float TOrgX, TOrgY;			//Tracked Origin point
var float OrgX, OrgY;			//Origin point
var float TrackedX, TrackedY;	//Tracked Frame Size
var float CurX, CurY;			//Current Frame Size
*/

var Color WhiteColor, GrayColor, DarkGrayColor; //Fifty shades of gay
var Color HUDColor;
var float Scale; //Passed by sgConstructor
var vector MPos; //Scale to 256 being wheel texture, may extent between -400 to 400 or so...
var float WindupTimer; //0 to 1, goes in x4 speed (takes 0.25s)
var float ColorScale; //For buttons
var rotator LastView;
var int SelectedButton; //0 to iButtons (==iButtons is null)

var bool bSetup;
var bool bSelectingCategory;
var bool bSelectingElement;

//Input state
var bool bLastFire;
var bool bLastAltFire;

//function Created();

function Tick( float DeltaTime)
{
	local bool bFire, bAltFire;
	local byte HitAccumulator, HoldAccumulator, ReleaseAccumulator;
	local float moveX, moveY;
	local vector LastMPos;
	
	if ( sgConstructor(LocalPlayer.Weapon) == none || sgConstructor(LocalPlayer.Weapon).CatActor == none )
		return;
	
	bFire = LocalPlayer.bFire > 0;
	bAltFire = LocalPlayer.bAltFire > 0;


	//Process and absorb mouse movement if possible
	if ( bFire || bAltFire || bSelectingCategory || bSelectingElement )
	{
		LocalPlayer.bShowScores = false;
		MPos.Z = 0;
		LastMPos = MPos;

		moveX = (LocalPlayer.ViewRotation.Yaw - LastView.Yaw) & 65535;
		if ( moveX > 32370 )	moveX -= 65536;
		moveX *= 0.09;

		moveY = (LocalPlayer.ViewRotation.Pitch - LastView.Pitch) & 65535;
		if ( moveY > 32370 )	moveY -= 65536;
		moveY *= 0.09;

		//PURE IS WAY TOO GAY HERE
		if ( (bSelectingCategory || bSelectingElement) && !LocalPlayer.IsA('bbPlayer') )
			LocalPlayer.ViewRotation = LastView; //Only absorb input if we're doing something

		MPos.X -= moveX; //Even if there's no action... action may be had during this click so perform the movement
		MPos.Y += moveY; //May be reset if no action is had at all

		moveX = VSize(MPos);
		if ( moveX > 140 )
			MPos = MPos * (140 / moveX);

		//Select the button here
		if ( moveX < 120 )
			SelectedButton = iButtons;
		else
		{
			moveX = fMax(4,iButtons);
			moveY = float( (rotator(MPos).Yaw - 16384) & 65535) / 65536;
//			if ( FRand() < 0.01 )
//				Log( moveY @ string(moveY*moveX + 0.5) );
//			moveY = (moveY*moveX + 0.5) % moveX;
			SelectedButton = int(moveY*moveX + 0.5) % moveX; //Let's hope it works
		}
		
	}
	else
		MPos = vect(0,0,0);

	//Dragging not implemented yet
	if ( bFire && !bLastFire ) //Click
		HitAccumulator += 1;
	else if ( bFire && bLastFire )
		HoldAccumulator += 1;
	else if ( !bFire && bLastFire ) //Release
		PointerRelease( MPos.X, MPos.Y, 1);

	if ( bAltFire && !bLastAltFire ) //Click
		HitAccumulator += 2;
	else if ( bAltFire && bLastAltFire )
		HoldAccumulator += 2;
	else if ( !bAltFire && bLastAltFire ) //Release
		PointerRelease( MPos.X, MPos.Y, 2);
		
	//Process releases first, then both hits in a single call
	if ( HitAccumulator > 0 )
		PointerHit( MPos.X, MPos.Y, HitAccumulator); //CHECK BUTTON COLLISION HERE

	if ( HoldAccumulator > 0 )
		PointerHold( DeltaTime, HoldAccumulator);
		

	if ( bSelectingCategory || bSelectingElement )
	{
		WindupTimer = fMin( 1, WindupTimer + DeltaTime * 5);
		//Figure out where we are
	}
	else
	{
		MPos = vect(0,0,0);
		WindupTimer = fMax( 0, WindupTimer - DeltaTime * 5);
	}

		
	bLastFire = bFire;
	bLastAltFire = bAltFire;
	LastView = LocalPlayer.ViewRotation;
}


//Needs alt-fire hold + fire hit to activate wheel
function PointerHit( float X, float Y, optional byte Code)
{
	if ( !bSelectingCategory && !bSelectingElement )
	{
		if ( Code == 3 || (Code == 1 && bLastAltFire)  ) //Instant hit!
		{
			sgConstructor(LocalPlayer.Weapon).OpenGui(); //Tell constructor we cannot perform normal actions
			SetupCategories( sgConstructor(LocalPlayer.Weapon).CatActor);
			bSelectingCategory = true; //DO IT!
		}
		return;
	}

	if ( bSelectingElement )
	{
		bSelectingCategory = false;
		if ( (Code & 1) != 0 ) //Select the build!
		{
			if ( (SelectedButton >= 0) && (SelectedButton < iButtons) && (Buttons[SelectedButton] != none) )
			{
				LocalPlayer.ConsoleCommand( Buttons[Selectedbutton].GUI_Code );
				if ( FV_ConstructorWheelButton(Buttons[0]).bIsCategory ) //Action pseudo category
				{
					if ( SelectedButton == 0 )
						SetupActions();
					else
						SetupCategory( sgConstructor(LocalPlayer.Weapon).CatActor, SelectedButton-1);
				}
				else
					bSelectingElement = false;
			}
			else
				bSelectingElement = false;
		}
		else if ( (Code & 2) != 0 ) //Cancel selection!
		{
			bSelectingElement = false;
		}
		
		if ( !bSelectingElement )
			sgConstructor(LocalPlayer.Weapon).SimCloseGui();
	}
}


function PointerRelease( float X, float Y, optional byte Code)
{
	if ( bSelectingCategory && ((Code & 2) != 0) )
	{
		bSelectingCategory = false;
		bSelectingElement = true;
	}
}

function PostRender( Canvas C)
{
	local float HalfOffset, CX, CY;
	local float ProxyFactor;

	//Scale is given by constructor, override here
	Scale *= 0.5 + WindupTimer * 0.5;
	
	HalfOffset = 128.f * Scale;
	CX = C.ClipX * 0.5;
	CY = C.ClipY * 0.5;
	
	if ( LocalPlayer.Level.bHighDetailMode )
	{
		C.DrawColor = WhiteColor;
		C.Style = 4; //Modu
		C.SetPos( CX - HalfOffset, CY - HalfOffset);
		C.DrawIcon( Texture'GWheel_Main_M', Scale);
		C.DrawColor = HUDColor;
	}
	else
		C.DrawColor = GrayColor;


	ProxyFactor = fMin( 1, 0.4 + VSize(MPos) * 0.01); //0.4 to 1.0
	ColorScale = ProxyFactor * WindupTimer;
	
	C.DrawColor.R = byte( float(C.DrawColor.R) * ColorScale);
	C.DrawColor.G = byte( float(C.DrawColor.G) * ColorScale);
	C.DrawColor.B = byte( float(C.DrawColor.B) * ColorScale);

	C.SetPos( CX - HalfOffset, CY - HalfOffset);
	C.Style = 3; //Trans
	C.DrawIcon( Texture'GWheel_Main_T', Scale);

	//CURSOR IS TO BE DRAWN AT HALF SIZE
	if ( bSelectingCategory || bSelectingElement )
	{
		C.SetPos( CX - (32 + MPos.X) * Scale, CY - (32 + MPos.Y) * Scale);
		C.Style = 3; //Trans
		C.DrawColor = DarkGrayColor;
		C.DrawIcon( Texture'GWeel_Rotator_a00', Scale * 0.5);
		
		if ( Buttons[0] != none )
		{
			if ( SelectedButton >= 0 && SelectedButton < iButtons && Buttons[SelectedButton] != none )
			{
				FV_ConstructorWheelButton(Buttons[SelectedButton]).bIsSelected = true;
				DefaultRenderButtons(C);
				FV_ConstructorWheelButton(Buttons[SelectedButton]).bIsSelected = false;
			}
			else
				DefaultRenderButtons(C);
			if ( SelectedButton >= 0 && SelectedButton < iButtons )
			{
				C.DrawColor = SwapColors( HUDColor );
				C.Style = 3; //Trans
				C.SetPos( Buttons[SelectedButton].XOffset - 16 * Scale, Buttons[SelectedButton].YOffset - 16 * Scale); //Extremely ugly
				C.DrawIcon( Texture'GWeel_Rotator_a00', Scale * 0.75);
			}
		}
	}

}

function sgSetup( sgConstructor C)
{
	local FV_GUI_Button aButton;

	assert( !bSetup );

/*	BasicCat = new(self,'BasicCategoryPanel') class'FV_sgBasicCategoryPanel';
	RegisterElement( BasicCat);
	BasicCat.sgSetup( C);
*/
	bSetup = true;
}

function SetupCategories( sgCategoryInfo CatActor)
{
	local int i, NumCats;
	
	NumCats = CatActor.iCat + 1; //Actions are part of a category now

	//See that all buttons are there and cleaned up...
	for ( i=0 ; i<NumCats ; i++ )
	{
		if ( Buttons[i] == none )
		{
			Buttons[i] = new(self) class'FV_ConstructorWheelButton';
			Buttons[i].InheritFrom( self);
		}
		else
		{
			FV_ConstructorWheelButton(Buttons[i]).bIsBuilding = false;
			Buttons[i].FastReset();
		}
		FV_ConstructorWheelButton(Buttons[i]).bIsCategory = True;
	}
	iButtons = NumCats;
	
	//Setup fake action category
	Buttons[0].Setup( 64, 64, 0, NumCats, "Action", "Upgrade, Repair, Remove or Drag", "setmode 0");
	Buttons[0].RegisterTex( Texture'GUI_RepairBase', 3 /*trans*/, GrayColor);

	//Setup other categories
	for ( i=1 ; i<NumCats ; i++ )
	{
		Buttons[i].Setup( 64, 64, i, NumCats, CatActor.CatName(i-1), "", "simsetcat "$string(i+3));
		Buttons[i].RegisterTex( Texture'GUI_UpgradeModu', 4 /*modu*/, WhiteColor);
		Buttons[i].RegisterTex( Texture'GUI_UpgradeFront', 3 /*trans*/, WhiteColor); //Use a custom texture
	}
}

function SetupActions()
{
	local int i, NumCats;
	
	NumCats = 3; //Five actions... implement GUI AND DRAG!!!!

	//See that all buttons are there and cleaned up...
	for ( i=0 ; i<NumCats ; i++ )
	{
		if ( Buttons[i] == none )
		{
			Buttons[i] = new(self) class'FV_ConstructorWheelButton';
			Buttons[i].InheritFrom( self);
		}
		else
		{
			FV_ConstructorWheelButton(Buttons[i]).bIsCategory = False;
			Buttons[i].FastReset();
		}
		FV_ConstructorWheelButton(Buttons[i]).bIsBuilding = False;
		Buttons[i].Setup( 64, 64, i, NumCats, sgConstructor(LocalPlayer.Weapon).Functions[i],"", "setmode "$string(i) );
	}
	iButtons = NumCats;

	//Setup actions
	Buttons[0].RegisterTex( Texture'GUI_OrbModu', 4/*modu*/, WhiteColor);
	Buttons[0].RegisterTex( Texture'GUI_OrbFront', 3/*trans*/, WhiteColor);
	Buttons[1].RegisterTex( Texture'GUI_Settings', 3/*trans*/, WhiteColor);
	Buttons[2].RegisterTex( Texture'GUI_RemoveModu', 4/*modu*/, WhiteColor);
	Buttons[2].RegisterTex( Texture'GUI_RemoveFront', 3/*trans*/, WhiteColor);
}

function SetupCategory( sgCategoryInfo CatActor, int CatIndex)
{
	local int i, NumBuilds, BuildIndex;
	local class<sgBuilding> sgB;
	
	//Find out how many builds we have
	NumBuilds = CatActor.CountCategoryBuilds( CatIndex);
	BuildIndex = CatActor.FirstCatBuild( CatIndex);
	sgB = CatActor.GetBuild( BuildIndex);
	
	//See that all buttons are there and cleaned up...
	for ( i=0 ; i<NumBuilds ; i++ )
	{
		if ( Buttons[i] == none )
		{
			Buttons[i] = new(self) class'FV_ConstructorWheelButton';
			Buttons[i].InheritFrom( self);
		}
		else
		{
			FV_ConstructorWheelButton(Buttons[i]).bIsCategory = False;
			Buttons[i].FastReset();
		}
		FV_ConstructorWheelButton(Buttons[i]).bIsBuilding = True;
		Buttons[i].Setup( 64, 64, i, NumBuilds, sgB.default.BuildingName,"", "setmode "$string(CatIndex+4)@string(i) );
		if ( (sgB != None) && (sgB.default.GUI_Icon != None) )
			Buttons[i].RegisterTex( sgB.default.GUI_Icon, 3/*trans*/, WhiteColor );
		else if ( ClassIsChildOf( sgB, Class'sgItem') && (Class<sgItem>(sgB).default.InventoryClass != None) && (Class<sgItem>(sgB).default.InventoryClass.default.Icon != none) )
			Buttons[i].RegisterTex( Class<sgItem>(sgB).default.InventoryClass.default.Icon, 3/*trans*/, WhiteColor );
		else
			Buttons[i].RegisterTex( Texture'GUI_UpgradeFront', 3/*trans*/, WhiteColor );
		sgB = CatActor.NextBuild( sgB, BuildIndex);
	}
	iButtons = NumBuilds;
}

function ConstructorDown()
{
	bSelectingCategory = false;
	bSelectingElement = false;
	MPos = vect(0,0,0);
	WindupTimer = 0;
	bLastFire = false;
	bLastAltFire = false;
}

//Swap channels
static function color SwapColors( color aColor)
{
	local byte a;
	a = aColor.R;
	aColor.R = aColor.G;
	aColor.G = aColor.B;
	aColor.B = a;
	return aColor;
}

//Swap channels backwards
static function color SwapBack( color aColor)
{
	local byte a;
	a = aColor.B;
	aColor.B = aColor.G;
	aColor.G = aColor.R;
	aColor.R = a;
	return aColor;
}


defaultproperties
{
    GUI_Code="ConstructorWheelBase"
    WhiteColor=(R=255,B=255,G=255)
    GrayColor=(R=160,B=160,G=160)
    DarkGrayColor=(R=80,B=80,G=80)
}