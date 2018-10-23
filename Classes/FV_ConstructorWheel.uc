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
		if ( moveX < 40 )
			SelectedButton = 31;
		else if ( moveX < 120 )
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
		
	LocalPlayer.Weapon.bOwnsCrosshair = bSelectingCategory || bSelectingElement;
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
			sgConstructor(LocalPlayer.Weapon).FindClientActor(); //Hidden constructors won't find it
			sgConstructor(LocalPlayer.Weapon).OpenGui(); //Tell constructor we cannot perform normal actions
			SetupCategories( sgConstructor(LocalPlayer.Weapon).CatActor);
			bSelectingCategory = true; //DO IT!
			LocalPlayer.bShowScores = false;
		}
		return;
	}

	if ( bSelectingElement || (bSelectingCategory && WindupTimer > 0.9) )
	{
		bSelectingCategory = false;
		bSelectingElement = true;
		if ( (Code & 1) != 0 ) //Select the build!
		{
			if ( (SelectedButton >= 0) && (SelectedButton < iButtons) && (Buttons[SelectedButton] != none) )
			{
				if ( Buttons[SelectedButton].GUI_Code != "" )
				{
					LocalPlayer.ConsoleCommand( Buttons[SelectedButton].GUI_Code );
					if ( bLastAltFire && !FV_ConstructorWheelButton(Buttons[SelectedButton]).bIsCategory )
					{
						Buttons[31].CopyButton( Buttons[SelectedButton] );
						LocalPlayer.bAltFire = 0; //Avoid cycle after selecting
						MPos = vect(0,0,0);
						return;
					}
				}
				if ( FV_ConstructorWheelButton(Buttons[0]).bIsCategory ) //Action pseudo category
				{
					if ( SelectedButton == 0 )
						SetupActions();
					else
						SetupCategory( sgConstructor(LocalPlayer.Weapon).CatActor, SelectedButton-1);
				}
				else if ( !FV_ConstructorWheelButton(Buttons[0]).bIsBuilding && (SelectedButton == (iButtons-1)) ) //Settings (bIsCategory already filtered)
					SetupSettings();
				else
					bSelectingElement = false;
			}
			else if ( SelectedButton == 31 ) //Favorite button!
			{
				if ( Buttons[SelectedButton].GUI_Code != "" )
					LocalPlayer.ConsoleCommand( Buttons[SelectedButton].GUI_Code );
				bSelectingElement = false;
				LocalPlayer.bAltFire = 0; //Avoid cycling after selecting
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
	local float HalfOffset, CX, CY, MidFactor;
	local float ProxyFactor;
	local bool bNS;

	//Scale is given by constructor, override here
	Scale *= 0.5 + WindupTimer * 0.5;
	
	HalfOffset = 128.f * Scale;
	if ( LocalPlayer.Handedness == -1 )
		MidFactor = 0.504;
	else if ( LocalPlayer.Handedness == 1 )
		MidFactor = 0.497;
	else
		MidFactor = 0.5;
	CX = float(int(C.ClipX * MidFactor));
	CY = float(int(C.ClipY * MidFactor));
	
	if ( LocalPlayer.Level.bHighDetailMode )
	{
		if ( WindupTimer > 0 )
		{
			C.DrawColor = WhiteColor;
			C.Style = 4; //Modu
			C.SetPos( CX - HalfOffset, CY - HalfOffset);
			C.DrawIcon( Texture'GWheel_Main_M', Scale);
			C.DrawColor = HUDColor;
		}
	}
	else
		C.DrawColor = GrayColor;

	C.Style = 3; //Trans

	if ( WindupTimer > 0 )
	{
		ProxyFactor = fMin( 1, 0.4 + VSize(MPos) * 0.01); //0.4 to 1.0
		ColorScale = ProxyFactor * WindupTimer;
		
		C.DrawColor.R = byte( float(C.DrawColor.R) * ColorScale);
		C.DrawColor.G = byte( float(C.DrawColor.G) * ColorScale);
		C.DrawColor.B = byte( float(C.DrawColor.B) * ColorScale);

		C.SetPos( CX - HalfOffset, CY - HalfOffset);
		C.DrawIcon( Texture'GWheel_Main_T', Scale);
	}
	
	//CURSOR IS TO BE DRAWN AT HALF SIZE
	if ( bSelectingCategory || bSelectingElement )
	{
		if ( bLastAltFire ) //Fav select mode
		{
			if ( LocalPlayer.Level.bHighDetailMode )
			{
				C.Style = 4; //Modu
				C.SetPos( CX - 64*Scale, CY - 63.8*Scale);
				C.DrawIcon( Texture'GUI_Border4_M', Scale);
				C.DrawTile( Texture'GUI_Border4_M', 64*Scale, 64*Scale, 0, 0, -64, 64);
				C.SetPos( CX - 64*Scale, CY);
				C.DrawTile( Texture'GUI_Border4_M', 64*Scale, 64*Scale, 0, 0, 64, -64);
				C.DrawTile( Texture'GUI_Border4_M', 64*Scale, 64*Scale, 0, 0, -64, -64);
				C.Style = 3; //Trans
			}
			C.DrawColor = SwapBack( HUDColor );
			C.SetPos( CX - 64*Scale, CY - 63.8*Scale);
			C.DrawIcon( Texture'GUI_Border4_F', Scale);
			C.DrawTile( Texture'GUI_Border4_F', 64*Scale, 64*Scale, 0, 0, -64, 64);
			C.SetPos( CX - 64*Scale, CY);
			C.DrawTile( Texture'GUI_Border4_F', 64*Scale, 64*Scale, 0, 0, 64, -64);
			C.DrawTile( Texture'GUI_Border4_F', 64*Scale, 64*Scale, 0, 0, -64, -64);
			
			bNS = C.bCenter;
			C.bCenter = true;
			C.Style = 2; //Masked
			C.SetPos( 0, CY - 6 * Scale);
			C.DrawColor.R = 200.0 * ColorScale;
			C.DrawColor.G = 200.0 * ColorScale;
			C.DrawColor.B = 200.0 * ColorScale;
			C.DrawText( "+ FAV +");
			C.bCenter = bNS;
		}
		else if ( Buttons[31] != None )
		{
			FV_ConstructorWheelButton(Buttons[31]).bIsSelected = (SelectedButton==31);
			Buttons[31].PostRender(C);
		}
			
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
				if ( bLastAltFire )
					C.DrawColor = SwapBack( HUDColor );
				else
					C.DrawColor = SwapColors( HUDColor );
				C.Style = 3; //Trans
				C.SetPos( Buttons[SelectedButton].XOffset - 16 * Scale, Buttons[SelectedButton].YOffset - 16 * Scale); //Extremely ugly
				C.DrawIcon( Texture'GWeel_Rotator_a00', Scale * 0.75);
			}
		}
	}
	else
	{
	
		if ( ChallengeHUD(LocalPlayer.myHUD) != None )
		{
			C.DrawColor = ChallengeHUD(LocalPlayer.myHUD).CrosshairColor;
			C.DrawColor.R *= 15; //Why can't I compile this operator?
			C.DrawColor.G *= 15;
			C.DrawColor.B *= 15;
		}
		else
			C.DrawColor = HUDColor;
		bNS = C.bNoSmooth;
		C.bNoSmooth = false;
		C.SetPos( CX + HalfOffset - 8*Scale, CY - 32*Scale);
		if ( bLastAltFire )
			C.DrawIcon( Texture'GUI_Arrow', Scale);
		else if ( !bLastFire )
			C.DrawIcon( Texture'GUI_Arrow_Hollow', Scale);

		C.SetPos( CX - (HalfOffset + 56*Scale), CY - 32*Scale);
		if ( bLastFire )
			C.DrawTile( Texture'GUI_Arrow', 64*Scale, 64*Scale, 0, 0, -64, 64);
		else
		{
			if ( bLastAltFire )
				C.DrawColor = WhiteColor;
			C.DrawTile( Texture'GUI_Arrow_Hollow', 64*Scale, 64*Scale, 0, 0, -64, 64);
		}
		C.bNoSmooth = bNS;
	}

}

function sgSetup( sgConstructor C)
{
	local Color IconColor;

	assert( !bSetup );

	//Create favorite button, setup upgrade
	if ( Buttons[31] == None )
	{
		IconColor = SwapBack(HUDColor);
		IconColor.R = IconColor.R + (255 - IconColor.R) / 2;
		IconColor.G = IconColor.R + (255 - IconColor.G) / 2;
		IconColor.B = IconColor.R + (255 - IconColor.B) / 2;

		Buttons[31] = new(self,'ConstructorWheelFav') class'FV_ConstructorWheelButtonFav';
		Buttons[31].InheritFrom( self);
		
		Buttons[31].RegisterTex( Texture'GUI_OrbModu', 4/*modu*/, WhiteColor);
		Buttons[31].RegisterTex( Texture'GUI_OrbFront', 3/*trans*/, WhiteColor);
		Buttons[31].RegisterTex( Texture'GUI_Circle', 2/*masked*/, IconColor, 0.375, 0.375);

		Buttons[31].Setup( 64, 64, 0, 0, C.Functions[0],"", "setmode 0 0" );
	}
	
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
	local Color IconColor;
	
	NumCats = 4; //Five actions... implement GUI AND DRAG!!!!

	//See that all buttons are there and cleaned up...
	//I could use an empty button
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
		if ( i < NumCats-1 )
			Buttons[i].Setup( 64, 64, i, NumCats, sgConstructor(LocalPlayer.Weapon).Functions[i],"", "setmode "$string(i) );
		else
			Buttons[i].Setup( 64, 64, i, NumCats, "Settings", "");
	}
	

	iButtons = NumCats;

	IconColor = SwapBack(HUDColor);
	IconColor.R = IconColor.R + (255 - IconColor.R) / 2;
	IconColor.G = IconColor.R + (255 - IconColor.G) / 2;
	IconColor.B = IconColor.R + (255 - IconColor.B) / 2;
	
	//Setup actions
	Buttons[0].RegisterTex( Texture'GUI_OrbModu', 4/*modu*/, WhiteColor);
	Buttons[0].RegisterTex( Texture'GUI_OrbFront', 3/*trans*/, WhiteColor);
	Buttons[0].RegisterTex( Texture'GUI_Circle', 2/*masked*/, IconColor, 0.375, 0.375);
	FV_ConstructorWheelButton(Buttons[0]).Abbreviation = "Up";
	Buttons[1].RegisterTex( Texture'GUI_OrbModu', 4/*modu*/, WhiteColor);
	Buttons[1].RegisterTex( Texture'GUI_OrbFront', 3/*trans*/, WhiteColor);
	Buttons[1].RegisterTex( Texture'GUI_Plus', 2/*masked*/, IconColor, 0.375, 0.375);
	FV_ConstructorWheelButton(Buttons[1]).Abbreviation = "Rep";
	Buttons[2].RegisterTex( Texture'GUI_RemoveModu', 4/*modu*/, WhiteColor);
	Buttons[2].RegisterTex( Texture'GUI_RemoveFront', 3/*trans*/, WhiteColor);
	Buttons[2].RegisterTex( Texture'GUI_Minus', 2/*masked*/, IconColor, 0.375, 0.375);
	FV_ConstructorWheelButton(Buttons[2]).Abbreviation = "Rem";

	Buttons[3].RegisterTex( Texture'GUI_Settings', 3/*trans*/, IconColor);

}

function SetupCategory( sgCategoryInfo CatActor, int CatIndex)
{
	local int i, NumBuilds, BuildIndex;
	local class<sgBuilding> sgB;
	
	//Find out how many builds we have
	NumBuilds = Min(CatActor.CountCategoryBuilds( CatIndex), 31);
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
		FV_ConstructorWheelButton(Buttons[i]).RuleSlot = BuildIndex;
		Buttons[i].Setup( 64, 64, i, NumBuilds, sgB.default.BuildingName,"", "setmode "$string(CatIndex+4)@string(i) );
		Buttons[i].RegisterTex( Texture'Botpack.EnergyMark', 4/*modu*/, WhiteColor);
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

function SetupSettings()
{
	local int i, NumSettings;
	local Color C;
	
	//Buttons should already have been created here (4 actions in action fake category)
	NumSettings = 2;

	for ( i=0 ; i<NumSettings ; i++ )
	{
		FV_ConstructorWheelButton(Buttons[i]).bIsCategory = False;
		FV_ConstructorWheelButton(Buttons[i]).bIsBuilding = False;
		Buttons[i].FastReset();
		Buttons[i].RegisterTex( Texture'GUI_Settings', 3/*trans*/, WhiteColor);
	}
	Buttons[0].Setup( 64, 64, 0, NumSettings, "Constructor Panel", "Toggles the constructor panel display", "ToggleSiegePanel");
	Buttons[1].Setup( 64, 64, 1, NumSettings, "Performance Mode", "Toggles Siege high performance mode", "ToggleSiegePerformance");
	
	FV_ConstructorWheelButton(Buttons[0]).Abbreviation = "Panel";
	FV_ConstructorWheelButton(Buttons[1]).Abbreviation = "Perf";

	if ( sgConstructor(LocalPlayer.Weapon).ClientActor.bHighPerformance )
		Buttons[1].RegisterTex( Texture'GUI_Minus', 2/*masked*/, MakeColor(255,50,50), 0.375, 0.375);
	else
		Buttons[1].RegisterTex( Texture'GUI_Plus', 2/*masked*/, MakeColor(20,255,20), 0.375, 0.375);
	
	
	iButtons = NumSettings;
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