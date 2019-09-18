//=============================================================================
// sg_XC_Constructor.
//
// Experimental constructor, model and class made by Higor
//
//=============================================================================
class sgConstructor extends TournamentWeapon;


#exec OBJ LOAD FILE="Graphics\ConstructorTex.utx" PACKAGE=SiegeIV_0032.Constructor

//Pick up view mesh contributed by DeepakOV
#exec mesh import mesh=ConstructorPick anivfile=Models\ConstructorPick_a.3d datafile=Models\ConstructorPick_d.3d x=0 y=0 z=0 mlod=0
#exec mesh origin mesh=ConstructorPick x=-460.00 y=-100.00 z=-60.00 yaw=0.00 roll=0.00 pitch=0.00
#exec mesh sequence mesh=ConstructorPick seq=All startframe=0 numframes=1

#exec meshmap new meshmap=ConstructorPick mesh=ConstructorPick
#exec meshmap scale meshmap=ConstructorPick x=0.08470 y=0.08470 z=0.16939

#exec MESHMAP SETTEXTURE MESHMAP=ConstructorPick NUM=0 TEXTURE=FrontConst
#exec MESHMAP SETTEXTURE MESHMAP=ConstructorPick NUM=1 TEXTURE=SASMD_t2



//Base constructor mesh made by Higor
#exec MESH IMPORT MESH=Constructor ANIVFILE=MODELS\Constructor_a.3d DATAFILE=MODELS\Constructor_d.3d UNMIRROR=1
//#exec MESH LODPARAMS MESH=Transloc HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=Constructor X=0.00 Y=0.00 Z=0.00 YAW=-60.00 ROLL=0.00 PITCH=0.00
//was -61
//was -5

#exec MESH SEQUENCE MESH=Constructor SEQ=All      STARTFRAME=0 NUMFRAMES=31
#exec MESH SEQUENCE MESH=Constructor SEQ=Still      STARTFRAME=1 NUMFRAMES=1
#exec MESH SEQUENCE MESH=Constructor SEQ=Point      STARTFRAME=2 NUMFRAMES=1
#exec MESH SEQUENCE MESH=Constructor SEQ=Open      STARTFRAME=3 NUMFRAMES=1
#exec MESH SEQUENCE MESH=Constructor SEQ=Spin      STARTFRAME=4 NUMFRAMES=18
#exec MESH SEQUENCE MESH=Constructor SEQ=Down      STARTFRAME=22 NUMFRAMES=4
#exec MESH SEQUENCE MESH=Constructor SEQ=Select      STARTFRAME=27 NUMFRAMES=4

#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=1 TEXTURE=tloc4
#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=2 TEXTURE=tloc3
#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=3 TEXTURE=asmd_t2
#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=4 TEXTURE=BGL_Script
//#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=4 TEXTURE=FrontConst
#exec MESHMAP SETTEXTURE MESHMAP=Constructor NUM=5 TEXTURE=BGL_PSwap

#exec MESHMAP SCALE MESHMAP=Constructor X=0.013 Y=0.009 Z=0.022


//Left handed version by DeepakOV
#exec MESH IMPORT MESH=ConstructorL ANIVFILE=MODELS\ConstructorL_a.3d DATAFILE=MODELS\ConstructorL_d.3d MIRROR=1
//#exec MESH LODPARAMS MESH=Transloc HYSTERESIS=0.00 STRENGTH=1.00 MINVERTS=10.00 MORPH=0.30 ZDISP=0.00
#exec MESH ORIGIN MESH=ConstructorL X=0.00 Y=0.00 Z=0.00 YAW=-60.00 ROLL=0.00 PITCH=0.00
//was -61
//was -5

#exec MESH SEQUENCE MESH=ConstructorL SEQ=All      STARTFRAME=0 NUMFRAMES=31
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Still      STARTFRAME=1 NUMFRAMES=1
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Point      STARTFRAME=2 NUMFRAMES=1
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Open      STARTFRAME=3 NUMFRAMES=1
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Spin      STARTFRAME=4 NUMFRAMES=18
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Down      STARTFRAME=22 NUMFRAMES=4
#exec MESH SEQUENCE MESH=ConstructorL SEQ=Select      STARTFRAME=27 NUMFRAMES=4

#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=1 TEXTURE=tloc4
#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=2 TEXTURE=tloc3
#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=3 TEXTURE=asmd_t2
#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=4 TEXTURE=BGL_Script
//#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=4 TEXTURE=FrontConst
#exec MESHMAP SETTEXTURE MESHMAP=ConstructorL NUM=5 TEXTURE=BGL_PSwap

#exec MESHMAP SCALE MESHMAP=ConstructorL X=0.013 Y=0.009 Z=0.022

//Selection icon by DeepakOV
#exec TEXTURE IMPORT FILE=Graphics\UseCon.pcx GROUP=HUD MIPS=OFF

var FontInfo MyFonts;
var Texture ColorPals[6];
var float AmbientTimer;
var bool bUseAmbient;
var bool bCanRemoveWithImpunity; //Sometimes needed

var(test) sgCategoryInfo CatActor;
var(test) sgClient ClientActor;
var(test) class<sgBuilding> SelectedBuild;
var(test) byte SelectedIndex; //Index in categoryInfo

var(test) int Category, Selection; //0 = upgrade, 1 = repair, 2 = remove, 3 = orb
var(test) float SpecialPause; //0 = nothing, >0 full lock, <0 soft lock, >50 build wheel
var(test) float ExtraTimer;
var(test) float BindAgain;

var sgBuilding Dragging;
var vector DragCoords; //From view point to building
var rotator DragViewStart; //Start view

//RenderTexture
var color OrangeColor;
var color PurpleColor;
var color WhiteColor;
var color GrayColor;
var Texture FunctionBkgs[4];
var Pawn HitPawn;
var int CachedCategory, CachedCBuildCount;

//Localized
var(test) config string Functions[4], OrbTexts[3];
var(test) config string CostText, CategoryText, BuildMessage;
var(test) config string GuiCats, GuiBuilds, GuiSettings;
var(test) config string GuiSens, GuiLights, GuiModel, GuiLang, GuiSmall, GuiFingerPrint, GuiBInfo, GuiPerf;

//GUI related
var(test) int GuiState; //Use bitwise?
var(test) float MX, MY, maxX, maxY, lastXL, lastYL;
var rotator LastView;
var bool bHadFire;
//var bool bJustOpenedGUI;
var bool bCanOpenGui;


var(Weapon) sound ChangeSound;
var bool bFreeBuild; //Hardcode Me!!!!
var int TeamSet; //Bypass PURE's PRI protection

//Simulation stuff
var bool bClientUp;
var float LastFired;

//=====GUI STATE OPTIONS
// 1 bit = open
// 5 bits = category / option window
// 5 bits = element
// 2 bits = page
// 1 bit = using wheel (select category, hold, hit alt-fire)

//Preset category bits:
// 0 upgrade
// 1 repair
// 2 remove
// 3 drag / orb?
// 31 (client settings)

var string TeamNames[5], TeamNumbers[5]; //For summon

replication
{
	reliable if ( Role<ROLE_Authority )
		ClientSetCat, ClientSetBuild, ClientSetMode, ClientBuildIt, GuiState, ClientOpenGui, ClientCloseGui, FreeBuild, ForceCorrect, GetConstructor, SummonB, AntiLeech, InstantSelect;
	reliable if ( Role==ROLE_Authority )
		CorrectStuff, bFreeBuild, bUseAmbient, bCanRemoveWithImpunity, Dragging;
}

exec simulated function ToggleSiegePanel()
{
	if ( ClientActor != none )
		ClientActor.ToggleConstructor();
}

exec simulated function ToggleSiegePerformance()
{
	if ( ClientActor != none )
		ClientActor.TogglePerformance();
}

exec simulated function StateControl()
{
	PlayerPawn(Owner).ClientMessage( string(GetStateName()) );
}

exec function SaveBuildMap()
{
	if ( PlayerPawn(Owner) != none && Owner.Role == ROLE_Authority )
		SiegeGI(Level.Game).BuildingMaps[ Pawn(Owner).PlayerReplicationInfo.Team ].FullUnParse( SiegeGI(Level.Game) );
}

exec function AntiLeech()
{
	local pawn HitActor;
	local vector HitLocation, HitNormal, start, end;
	local sgBuilding sgActor, sgBest;
	local sgPri OwnerPRI;
	local sgRemoveProt sgRP;
	local int i;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	end =  start + vector(Pawn(Owner).ViewRotation) * 90;
	ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	ForEach Owner.TraceActors ( class'sgBuilding', sgActor, HitLocation, HitNormal, end, start)
	{
		if ( sgActor == level )
			break;
		if ( !sgActor.IsA('sgBuilding') )
			continue;
		if ( (sgActor.SCount <= 0) || (sgActor.Team != ownerPRI.Team) || sgActor.IsA('sgItem') || sgActor.IsA('sgBaseCore') )
			continue;
		sgBest = sgActor;
		break; //Found candidate
	}

	if ( sgBest == none )
		return; //Nothing selected

	sgActor = none;
	ForEach sgBest.VisibleCollidingActors(class'sgBuilding', sgActor, 155)
		if ( sgActor != sgBest )
			i++;

	if ( i < 2 )
		return; //No leeches

	//HIGOR: INTEGRATE THIS INTO THE SGPRI AS WELL
	if ( !bCanRemoveWithImpunity && !BuildingOwned(sgBest) ) //Removing other player's stuff
	{
		sgRP = sgRemoveProt(Pawn(Owner).FindInventoryType(class'sgRemoveProt'));

		if ( sgRP != None )
		{
			sgRP.AddRemove();
			if ( sgRP.RemoveWarning() )
				class'SiegeStatics'.static.AnnounceAll( self, "Player "@Pawn(Owner).PlayerReplicationInfo.PlayerName@" has been warned for Team Removing.");
			if ( sgRP.ExcessRemove() )
			{
				class'SiegeStatics'.static.AnnounceAll( self, "Player "@Pawn(Owner).PlayerReplicationInfo.PlayerName@" was kicked for being a Team Remover.");
				Owner.Destroy();
			}
		}
		else
		{
			sgRP = Spawn(class'sgRemoveProt', Pawn(Owner), 'sgRemoveProt', Pawn(Owner).Location, Pawn(Owner).Rotation);
			if ( sgRP != None )
			{
				sgRP.bHeldItem = True;
				sgRP.GiveTo(Pawn(Owner));
				sgRP.Activate();
			}
		}
	}

	sgBest.RemovedBy( pawn(Owner) , true);
}

//New summon command
exec function SummonB( string Parms)
{
	local class<sgBuilding> aBuild;
	local string aWord;
	local class<Actor> aClass;
	local sgBuilding sgNew;
	local int i;

	if ( PlayerPawn(Owner) == none )
		return;
	if ( PlayerPawn(Owner).bAdmin || Level.NetMode == NM_StandAlone )
	{
		Parms = ClearSpaces( Parms);
		aWord = GetTheWord( Parms);
		if ( aWord != "" )
		{
			if ( InStr(aWord,".") < 0 )
				aWord = GetPackageName()$"."$aWord;
			aClass = class<Actor> ( DynamicLoadObject(aWord,class'class') );
			if ( aClass != none )
				aBuild = class<sgBuilding> (aClass);
			if ( aBuild != none )
			{
				sgNew = Spawn( aBuild, Owner,, Owner.Location + vect(0,0,0.8) * fMax(0,Pawn(Owner).BaseEyeHeight) - vect(0,0,10) + vector(Pawn(Owner).ViewRotation) * aBuild.Default.BuildDistance, Pawn(Owner).ViewRotation );
				Parms = EraseTheWord(Parms);
				Parms = ClearSpaces(Parms);
				aWord = GetTheWord( Parms);
				if ( aWord != "" )
				{
					For ( i=0 ; i<5 ; i++ )
						if ( aWord ~= TeamNames[i] || aWord ~= TeamNumbers[i] )
						{
							sgNew.SetTeam( i);
							break;
						}
				}
			}
			else if ( aClass != none )
				PlayerPawn(Owner).Summon(string(aClass));
			else
				Log("Wrong class name: "$aWord);
		}
	}
}

static function string GetPackageName()
{
	local string aString;
	aString = string(class'sgConstructor');
	return Left( aString, InStr(aString,".") );
}

//Old stuff

exec function FreeBuild()
{
	local sgPRI NFO;

	NFO = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	if ( NFO.bAdmin != true )
		return;

	log("FREEBUILD!!"@NFO);

	if ( SiegeGI(Level.Game) != None )
		{
			SiegeGI(Level.Game).MaxRUs[NFO.Team] = 10000000;
			// Is a billion RU enough to test? really... is it?
			NFO.RU = 10000000;
    	}
}


/////////////////////////////
// Constructor mechanics

exec function GetConstructor()
{
	if ( PlayerPawn(Owner) != None )
		PlayerPawn(Owner).GetWeapon(class);
}

exec simulated function SelectMode(int newCategory, int newSelection)
{
	SetMode( newCategory, newSelection);
	InstantSelect();
	if ( (Level.NetMode == NM_Client) && (Pawn(Owner).bFire + Pawn(Owner).bAltFire == 0) && (Pawn(Owner).Weapon != self) )
		Pawn(Owner).ClientPutDown( Pawn(Owner).Weapon, self);
}

function InstantSelect() //Immediate weapon select
{
	if ( Pawn(Owner).Weapon != self && (Pawn(Owner).bFire + Pawn(Owner).bAltFire == 0) )
	{
		Pawn(Owner).PendingWeapon = self;
		Pawn(Owner).ChangedWeapon();
	}
}

function ForceCorrect()
{
	CorrectStuff( Category, Selection, SelectedBuild, SelectedIndex);
}

simulated function CorrectStuff( int A, int B, class<sgBuilding> C, byte D)
{
	if ( Level.TimeSeconds - LastFired < 0.5 )
		return; //Prevent update if player clicked again
	Category = A;
	Selection = B;
	SelectedBuild = C;
	SelectedIndex = D;
}

function ClientSetCat( int CatMode)
{
	Category = CatMode;
	Selection = -1;
	SelectedBuild = none;
	SelectedIndex = 255;
}

exec simulated function SimSetCat( int CatMode)
{
	Category = CatMode;
	Selection = -1;
	SelectedBuild = none;
	ClientSetCat( CatMode);
	SelectedIndex = 255;
}

exec simulated function SelectBuild( string BuildToSelect)
{
	local int i;
	local class<sgBuilding> sgB;
	local string pkg;

	BuildToSelect = ClearSpaces( BuildToSelect);
	while ( Right(BuildToSelect,1) == " " )
		BuildToSelect = Left( BuildToSelect, Len(BuildToSelect)-1);

	pkg = Left( string(class), InStr(string(class),".")+1);
	sgB = class<sgBuilding>( DynamicLoadObject(pkg$BuildToSelect,class'class',true) );
	if ( sgB == none )
		sgB = class<sgBuilding>( DynamicLoadObject(pkg$"sg"$BuildToSelect,class'class',true) );
	if ( sgB == none )
		sgB = class<sgBuilding>( DynamicLoadObject(pkg$"XC_"$BuildToSelect,class'class',true) );
	if ( sgB == none )
		sgB = class<sgBuilding>( DynamicLoadObject(pkg$"Wildcards"$BuildToSelect,class'class',true) );

	if ( sgB != none )
		SetBuild( sgB,0,false);
}

exec simulated function SetBuild( class<sgBuilding> sgB, optional byte idx, optional bool bSilent)
{
	local int i;

	if ( (sgB == none) || !FindCatActor() )
		return;

	if ( !ListenPlayer() )
		ClientSetBuild( sgB, idx, bSilent);


	//Locate category and build
	if ( CatActor.GetBuild(idx) == sgB )
		i = idx;
	else
		i = CatActor.FindBuild( sgB);
	if ( i == -1 )
		return; //Building unavailable

	Category = CatActor.CatIndex(i) + 4;
	Selection = CatActor.BuildIndex(i);
	SelectedBuild = sgB;
	SelectedIndex = i;

	if ( !bSilent )
	{
		Owner.PlaySound(SelectSound, SLOT_None, Pawn(Owner).SoundDampening*5,,, 2.0);
		if ( ListenPlayer() )
			ServerAcceptSound();
	}
}

function ClientSetBuild( class<sgBuilding> sgB, byte idx, optional bool bSilent)
{
	local int i;

	if ( (sgB == none) || !FindCatActor() )
		return;

	//Locate category and build
	if ( CatActor.GetBuild(idx) == sgB )
		i = idx;
	else
		i = CatActor.FindBuild( sgB);
	if ( i == -1 )
		return; //Building unavailable

	Category = CatActor.CatIndex(i) + 4;
	Selection = CatActor.BuildIndex(i);
	SelectedBuild = sgB;
	SelectedIndex = i;

	if ( !bSilent )
		ServerAcceptSound();
}

simulated function CycleForward()
{
	local int i;

	if ( !FindCatActor() )
		return;

	Owner.PlaySound(ChangeSound, SLOT_None, Pawn(Owner).SoundDampening*1.2,,,1 + (FRand()*0.2 - 0.4));
	if ( !ListenPlayer() )
		ServerCycleSound();

	if ( (Level.NetMode != NM_Client) && !ListenPlayer() )
		return; //Client has authoritative control now

	if ( Category < 4 )
	{
		if ( (++Category == 3) && !ActiveOrbs() )
			Category++;
		SimSetCat( Category); //Redundant on client, done to update server value
		return;
	}
	if ( SelectedBuild != none )
	{
		i = SelectedIndex;
		SelectedBuild = CatActor.NextBuild( SelectedBuild, i);
		if ( SelectedBuild != none )
		{
			SetBuild( SelectedBuild, i, true);
			return;
		}
	}
	SimSetCat( CatActor.NextCategory( Category - 4) + 4 );
}

//Old method, client version of the function
exec simulated function SetMode(int newCategory, int newSelection)
{
	local int i, j;

	if ( newCategory < 4 )
		newSelection = -1;

	if ( Level.NetMode == NM_Client )
		ClientSetMode( newCategory, newSelection, true);

	if ( !FindCatActor() )
		return;
	ExtraTimer = 0.3;
	if ( (newCategory != Category) || (newSelection != Selection) )
		Owner.PlaySound(ChangeSound, SLOT_None, Pawn(Owner).SoundDampening*1.2,,,1 + (FRand()*0.2 - 0.4));

	if ( (newCategory < 4) || (newSelection < 0) || (newCategory > 28) )
	{
		SimSetCat( Clamp(newCategory,0,31) );
		return;
	}

	i = CatActor.GetSetMode( newCategory-4, newSelection);
	if ( i >= 0 )
	{
		Category = newCategory;
		Selection = newSelection;
		SelectedBuild = CatActor.GetBuild(i);
		SelectedIndex = i;
	}
}

function ClientSetMode(int newCategory, int newSelection, optional bool bBound) //Server version of the function
{
	local int i, j;

	if ( !FindCatActor() )
		return;

	ExtraTimer = 0.3;
	if ( (newCategory != Category) || (newSelection != Selection) )
		Owner.PlayOwnedSound(ChangeSound, SLOT_None, Pawn(Owner).SoundDampening*1.2,,,1 + (FRand()*0.2 - 0.4));

	if ( (newCategory < 4) || (newSelection < 0) || (newCategory > 28) )
	{
		Category = Clamp(newCategory,0,31);
		Selection = -1;
		SelectedBuild = none;
		SelectedIndex = 255;
		return;
	}

	i = CatActor.GetSetMode( newCategory-4, newSelection);
	if ( i >= 0 )
	{
		Category = newCategory;
		Selection = newSelection;
		SelectedBuild = CatActor.GetBuild(i);
		SelectedIndex = i;
	}
}

exec simulated function BuildIt()
{
	if ( BindAgain > Level.TimeSeconds ) //Do not use a bind command if putting constructor down
		return;
//	BindAgain = Level.TimeSeconds + 0.99;
	PrimaryFunc(333); //333 is one-shot mode
	if ( !ListenPlayer() )
		ClientBuildIt();
}

function ClientBuildIt()
{
	PrimaryFunc(333);
}

simulated function PrimaryFunc( optional float Code)
{
	local sgBuilding sgNew;
	local sgPRI ownerPRI;
	local sg_XC_Orb aOrb;
	local float Delta;
	local bool bResult;


	if ( Code == 333 )
	{
		Delta = 1.0; //One shot
		Goto ONLY_BUILD;
	}
	Delta = 0.1; //Default frequency of continuous actions

	if ( bCanOpenGui && (Pawn(Owner).bAltFire > 0) && (GuiState == 0) ) //Fake wheel opener, stops server action reliably
	{
//		OpenGui();
		return;
	}

	if ( GuiState > 0 )
		return;

	ONLY_BUILD:
	if ( SpecialPause > 0 )
		return;

	if ( Category == 0 ) //Upgrade
		UpgradeFunction( Delta);
	else if ( Category == 1 ) //Repair
		RepairFunction( Delta);
	else if ( Category == 2 ) //Remove
		RemoveFunction();
	else if ( Category == 3 ) //XC_Orb handling
	{
		SpecialPause = 1;
		if ( Level.NetMode != NM_Client )
		{
			aOrb = sgPRI(Pawn(Owner).PlayerReplicationInfo).XC_Orb;
			sgNew = OrbCandidate( Pawn(Owner).PlayerReplicationInfo.Team);

			if ( (aOrb == none) && (sgNew != none) && (sgNew.XC_Orb != none) ) //Retrieve
			{
				if (sgNew.XC_Orb.RetrieveFrom( Pawn(Owner) ) )
				{}	//SERVERPLAY A SOUND HERE
				else
					ServerDenySound();
			}
			else if ( (sgNew != none) && (aOrb != none) && (sgNew.XC_Orb == none) ) //Insert
			{
				if ( aOrb.InsertOn( sgNew) )
				{}	//SERVERPLAY A SOUND HERE
				else
					ServerDenySound();
			}
			else if ( (aOrb != none) && (sgNew == none) ) //Drop
			{
				aOrb.DropAt();
			}
			else if ( Delta == 0.1 )
				DragFunction();
		}
	}
	else
	{
		if ( !FindCatActor() )
			return;

		if ( (SelectedBuild == none) && (Category >= 4) )
		{
			SelectedIndex = CatActor.FirstCatBuild( Category - 4);
			SelectedBuild = CatActor.GetBuild( SelectedIndex );
			Selection = 0;
			Owner.PlaySound(SelectSound, SLOT_None, Pawn(Owner).SoundDampening*5,,, 2.0);
			SpecialPause = -999; //Do something interesting here later
			if ( !ListenPlayer() )
				ServerAcceptSound();
			return;
		}

		if ( SelectedBuild != none )
		{
			//Do not simulate
			if ( Level.NetMode == NM_Client )
				return;
			if ( !CanAfford(SelectedBuild, SelectedIndex) || IsRestricted(SelectedBuild, SelectedIndex) )
			{
				ServerDenySound();
				SpecialPause = 0.99;
				return;
			}

			sgNew = Spawn( SelectedBuild, Owner,, Owner.Location + vect(0,0,0.8) * fMax(0,Pawn(Owner).BaseEyeHeight) - vect(0,0,10) + vector(Pawn(Owner).ViewRotation) * SelectedBuild.Default.BuildDistance, Pawn(Owner).ViewRotation );
			if ( (sgNew != None) && !sgNew.bDeleteMe )
			{
				//HIGOR: Game build count is broken anyways, will only fix this once that works
				ServerBuildSound();
				ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
				sgNew.SetCustomProperties( CatActor.GetProps(SelectedIndex) );
				sgNew.iCatTag = SelectedIndex;
				if ( ownerPRI == none )
					return;
				if ( CatActor.HasCustomCost(SelectedIndex) )
				{
					sgNew.BuildCost = CatActor.CustomCost(SelectedIndex);
					sgNew.RUinvested = sgNew.BuildCost;
					if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
						ownerPRI.RU -= CatActor.CustomCost(SelectedIndex);
					ownerPRI.Score += CatActor.CustomCost(SelectedIndex) / 100;
				}
				else
				{
					if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
						ownerPRI.RU -= SelectedBuild.default.BuildCost;
					ownerPRI.Score += SelectedBuild.default.BuildCost / 100;
				}
				ownerPRI.sgInfoBuildingMaker++;
			}
			else
				ServerDenySound();
			SpecialPause = 0.99;
		}
	}
}

function bool BotBuild( int Idx, optional bool bCheat, optional vector FixedLoc)
{
	local sgBuilding sgNew;
	local sgPRI ownerPRI;
	local class<sgBuilding> classToBuild;

	if ( !FindCatActor() )
		return false;

	classToBuild = CatActor.GetBuild(Idx);
	if ( classToBuild != none )
	{
		if ( (!bCheat && !CanAfford(classToBuild,Idx)) || IsRestricted(classToBuild, Idx) )
		{
			ServerDenySound();
			LockAction( 0.95);
			return false;
		}
		if ( FixedLoc == vect(0,0,0) )
			FixedLoc = Owner.Location + vect(0,0,0.8) * fMax(0,Pawn(Owner).BaseEyeHeight) - vect(0,0,10) + vector(Pawn(Owner).ViewRotation) * classToBuild.Default.BuildDistance;
		sgNew = Spawn( classToBuild, Owner,, FixedLoc, Pawn(Owner).ViewRotation );
		if ( (sgNew != None) && !sgNew.bDeleteMe )
		{
			ServerBuildSound();
			ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
			if ( ownerPRI == none )
				return true;
			if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
				ownerPRI.RU -= CatActor.BuildCost(Idx);
			ownerPRI.Score += CatActor.BuildCost(Idx) / 100;
			ownerPRI.sgInfoBuildingMaker++;
			sgNew.iCatTag = Idx;
			sgNew.RUinvested = CatActor.BuildCost(Idx);
		}
		else
	        ServerDenySound();
		if ( !bCheat )
			LockAction( 0.95);
	}
	return sgNew != none;
}

//RUamount is either amount of ru or target level
function bool BotUpgrade( Pawn Other, optional float RUamount)
{
	local float Priority, fPri;
	local sgPRI ownerPRI;

	if ( !FastTrace(Other.Location, Owner.Location + vect(0,0,10)) )
		return false;

//	Log("BOTUPGRADE");
	ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	if ( ownerPRI.RU < 5 ) //Nothing to give
		return true;

	if ( sgPRI(Other.PlayerReplicationInfo) != none )
	{
		Priority = sgPRI(Other.PlayerReplicationInfo).RU;
		fPri=FMin(RUamount, ownerPRI.RU);
		sgPRI(Other.PlayerReplicationInfo).AddRU(fPri);
		ownerPRI.sgInfoUpgradeRepair+= fPri;
		ownerPRI.AddRU(-1 * (sgPRI(Other.PlayerReplicationInfo).RU - Priority));
		ownerPRI.Score += (sgPRI(Other.PlayerReplicationInfo).RU - Priority) / 100;
		Other.PlaySound(sound'sgMedia.sgPickRUs', SLOT_None,Other.SoundDampening*2.5);
		return true;
	}
	if ( sgBuilding(Other) != none )
	{
		if ( VSize(Other.Location - Owner.Location) > 120 + FRand() * FRand() * 70 )
			return false;
		fPri = FMin(5 - sgBuilding(Other).Grade, RUamount);

		if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
		{
			fPri = FMin(fPri, (ownerPRI.RU / (sgBuilding(Other).UpgradeCost * (sgBuilding(Other).Grade + 1))));
			ownerPRI.AddRU( (sgBuilding(Other).UpgradeCost * (sgBuilding(Other).Grade + 1)) * (-fPri) );
			sgBuilding(Other).RUinvested += sgBuilding(Other).UpgradeCost * (sgBuilding(Other).Grade + 1) * fPri;
			ownerPRI.Score += fPri;
			ownerPRI.sgInfoUpgradeRepair+= fPri;
		}
		sgBuilding(Other).Grade += fPri;
		ownerPRI.sgInfoUpgradeRepair += fPri;
		if ( fPri > 0 )
		{
			sgBuilding(Other).Upgraded();
			Owner.PlaySound(Misc3Sound, SLOT_None, pawn(Owner).SoundDampening*2.5);
		}
		if ( (ownerPRI.AIqueuer.RoleCode < 2) && (ownerPRI.RU > 100) && ((ownerPRI.RU / SiegeGI(Level.Game).MaxRUs[ownerPRI.Team]) > (sgBuilding(Other).Grade / 10) ) ) //Upgrade multiple times!
			return false;
		return true;
	}
	return false;
}

simulated function LockAction( float ActionTime)
{
	SpecialPause = ActionTime;
	ExtraTimer = 1; //Avoid insta switch
	BindAgain = Level.TimeSeconds + ActionTime;
}

simulated function bool CanAfford( class<sgBuilding> sgB, byte MyIndex)
{
	local sgPRI OwnerPRI;

	OwnerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	if ( OwnerPRI == none )
		return true;
	if ( OwnerPRI.PlayerFingerPrint == "" ) //No fingerprint, no build
		return false;
	if ( bFreeBuild )
		return true;
	if ( FindCatActor() && CatActor.HasCustomCost( SelectedIndex) )
		return ownerPRI.RU >= CatActor.CustomCost(MyIndex);
	return ownerPRI.RU >= sgB.default.BuildCost;
}

//False means allow
function bool IsRestricted( class<sgBuilding> sgB, byte aIndex)
{
	if ( !FindCatActor() )
		return true;
	if ( Pawn(Owner).PlayerReplicationInfo == none )
		return false;

	if ( (aIndex < 128) && !CatActor.RulesAllow( aIndex) )
		return true;

	if ( sgB == class'sgTeleporter' )
	{
		if ( CountBuilds( sgB, true, true, 2) < 2 )
			return false;
		Pawn(Owner).ClientMessage( Default.BuildMessage$": "$"Only one pair of Teleporters allowed per player.");
	}
	else if ( sgB == class'sgHomingBeacon' )
	{
		if ( CountBuilds( sgB, True, True, 1) < 1 )
			return false;
		Pawn(Owner).ClientMessage( Default.BuildMessage$": "$"Only one Homing Beacon allowed per player.");
	}
	else //Not in special condition list, allow
		return false;
	//Should only happen if CountBuilds exceeded a limit
	return true;
}

/*--- State code. -----------------------------------------------------------*/
//Let's let the client manage his constructor choices

State Active
{
	function Fire( float Value) {Global.Fire(Value); }
	function AltFire( float Value) {Global.AltFire(Value); }
	simulated function AnimEnd() { Global.AnimEnd(); }

	simulated function bool ClientFire( float value) //Separate this...
	{
		PrimaryFunc( value);
		return false;
	}

	simulated function bool ClientAltFire( float Value )
	{
		if ( Pawn(Owner).bFire == 0 )
			bCanOpenGui = True;
		if ( GuiState > 0 )
		{
			GuiState = 0;
			return false; //Close gui
		}
		if ( ExtraTimer <= 0 )
		{
			CycleForward();
			ExtraTimer = 0.3;
		}
	}

	simulated event EndState()
	{	}
	function bool PutDown()
	{
		GotoState('DownWeapon');
		return true;
	}
//Serverside correction if necessary
Begin:
	if ( Level.TimeSeconds - LastFired > 2.0 )
	{
		LastFired = 9999999999;
		CorrectStuff( Category, Selection, SelectedBuild, SelectedIndex);
	}
	Sleep( 0.2);
	Goto('Begin');
}

State ClientActive
{
	simulated function bool ClientFire(float Value)
	{
	}

	simulated function bool ClientAltFire(float Value)
	{
		bForceAltFire = true;
		return bForceAltFire;
	}

	simulated function AnimEnd()	{ Global.AnimEnd();	}

	simulated function BeginState()
	{
		bForceFire = false;
		bForceAltFire = false;
		bWeaponUp = false;
		PlaySelect();
		GotoState('Active');
	}

	simulated function EndState()
	{
		bForceFire = false;
		bForceAltFire = false;
	}
}

simulated function Pawn BestUpgradeCandidate( byte Team)
{
	local Pawn P, PPlayer;
	local vector HitLocation, HitNormal, start, end;
	local sgBuilding sgB, sgBest;
	local float Priority, fPri, Dist;
	local bool bNoBuilds;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	End =  Start + vector(Pawn(Owner).ViewRotation) * 10000;

	ForEach Owner.TraceActors ( class'Pawn', P, HitLocation, HitNormal, End, Start)
	{
		if ( !P.IsA('Pawn') ) //TraceActors has a bug!!! (level is last, therefore autobreak)
		{
			if ( P.bBlockActors ) //Solid
				break;
			continue;
		}
		sgB = sgBuilding(P);
		if ( sgB != none )
		{
			if ( bNoBuilds || (sgB.Team != Team) || sgB.bNoUpgrade || (sgB.SCount > 0) || (sgB.Grade >= 5) )
				continue;
			Dist = VSize(Start-HitLocation);
			if ( Dist > 92 )
			{
				bNoBuilds = true;
				continue;
			}
			fPri = 1 - (sgB.Grade * 0.2);
			fPri += 1 - (VSize( Start - HitLocation) / 92);
			if ( fPri > Priority )
			{
				Priority = fPri;
				sgBest = sgB;
			}
			continue;
		}
		if ( (PPlayer == none) && P.bIsPlayer && !P.bHidden && (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team == Team) )
			PPlayer = P;
	}
	if ( sgBest != none )
		return sgBest;
	return PPlayer;
}

//Builds up to 90, pawns up to 10000
simulated function Pawn BestRepairCandidate( byte Team)
{
	local vector HitLocation, HitNormal, Start, End;
	local Pawn P, PPlayer;
	local bool bNoBuilds;
	local sgBuilding sgB, sgBest;
	local float Priority, fPri, Dist;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	End =  Start + vector(Pawn(Owner).ViewRotation) * 10000;

	ForEach Owner.TraceActors ( class'Pawn', P, HitLocation, HitNormal, End, Start)
	{
		if ( !P.IsA('Pawn') ) //TraceActors has a bug!!! (level is last, therefore autobreak)
		{
			if ( P.bBlockActors ) //Solid
				break;
			continue;
		}
		sgB = sgBuilding(P);
		if ( sgB != none )
		{
			if ( bNoBuilds || (sgB.Team != Team) )
				continue;
			Dist = VSize(Start-HitLocation);
			if ( Dist > 92 )
			{
				bNoBuilds = true;
				continue;
			}
			if ( sgB.bIsOnFire || sgB.bDisabledByEmp )
				return sgB;
			if ( (sgB.SCount > 0) || (sgB.Energy >= sgB.MaxEnergy) )
				continue;
			fPri = 1 - (sgB.Energy / sgB.MaxEnergy);
			if ( sgBaseCore(sgB) != none )
			{
				if ( (SiegeGI(Level.Game) != none) && SiegeGI(Level.Game).bOverTime )
					continue;
				fPri += 0.3;
			}
			fPri += 1 - (Dist / 90);
			if ( fPri > Priority )
			{
				Priority = fPri;
				sgBest = sgB;
			}
			continue;
		}
		if ( (PPlayer == none) && P != Pawn(Owner) && P.bIsPlayer && !P.bHidden && (P.Health < 150) && (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team == Team) )
			PPlayer = P;
	}
	if ( sgBest != none )
		return sgBest;
	return PPlayer;
}

simulated function sgBuilding BestRemoveCandidate( byte Team)
{
	local vector HitLocation, HitNormal, Start, End;
	local sgBuilding sgB, sgBest;
	local float Priority, fPri;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	End =  start + vector(Pawn(Owner).ViewRotation) * 90;

	ForEach Owner.TraceActors ( class'sgBuilding', sgB, HitLocation, HitNormal, End, Start)
	{
		if ( !sgB.IsA('sgBuilding') ) //TraceActors has a bug!!! (level is last, therefore autobreak)
		{
			if ( sgB.bBlockActors ) //Solid
				break;
			continue;
		}
		if ( (sgB.Team != Pawn(Owner).PlayerReplicationInfo.Team) || sgB.bNoRemove )
			continue;
		fPri = 1;
		if ( sgB.bOnlyOwnerRemove && !BuildingOwned(sgB) )
		{
			if ( !bCanRemoveWithImpunity )
				continue;
			fPri = 0.8;
		}
		fPri -= VSize( Normal(sgB.Location - start) - Normal(end-start) );
		if ( fPri > Priority )
		{
			Priority = fPri;
			sgBest = sgB;
		}
	}
	return sgBest;
}

simulated function sgBuilding BestDragCandidate( byte Team)
{
	local vector HitLocation, HitNormal, Start, End;
	local sgBuilding sgB, sgBest;
	local float Priority, fPri;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	End =  start + vector(Pawn(Owner).ViewRotation) * 90;

	ForEach Owner.TraceActors ( class'sgBuilding', sgB, HitLocation, HitNormal, End, Start)
	{
		if ( !sgB.IsA('sgBuilding') ) //TraceActors has a bug!!! (level is last, therefore autobreak)
		{
			if ( sgB.bBlockActors ) //Solid
				break;
			continue;
		}
		if ( !sgB.bDragable || (sgB.Team != Pawn(Owner).PlayerReplicationInfo.Team) )
			continue;

		fPri = 1;
		if ( !BuildingOwned(sgB) )
		{
			if ( !bCanRemoveWithImpunity )
				continue;
			fPri = 0.8;
		}
		fPri -= VSize( Normal(sgB.Location - start) - Normal(end-start) );
		if ( fPri > Priority )
		{
			Priority = fPri;
			sgBest = sgB;
		}
	}
	return sgBest;
}

//Continuous repair, if SpecialPause is > 0, then delay next repair
function bool RepairFunction( float DeltaRep)
{
	local Pawn HitActor;
	local sgBuilding sgBest;
	local sgPri OwnerPRI;
	local float fPri;

	ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	HitActor = BestRepairCandidate( ownerPRI.Team);
	sgBest = sgBuilding(HitActor);

	if ( sgBest != none )
	{
		fPri = FMin(sgBest.MaxEnergy - sgBest.Energy, 60 * DeltaRep);

		if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
		{
			if ( ownerPRI.RU < fPri )
				return false;
			ownerPRI.AddRU(-0.2 * fPri);
		}
		sgBest.Energy += fPri;

		if (sgBest.bDisabledByEMP || sgBest.bIsOnFire)
		{
			sgBest.BackToNormal();
			SpecialPause = 1;
		}

		SpecialPause = DeltaRep;
		if ( SpecialPause == 1)
			Owner.PlaySound(Misc2Sound, SLOT_Misc, Pawn(Owner).SoundDampening*2.5);
//		else SETUP AMBIENT (0.10) every repair

		if (sgBaseCore(sgBest)!=None)
			ownerPRI.sgInfoCoreRepair += fPri;
		else
			ownerPRI.sgInfoUpgradeRepair += fPri;
		ownerPRI.Score += fPri/100;
		return true;
	}

	if ( HitActor != none )
	{
		REP_PLAYER:
		fPri = FMin(FMin(150 - HitActor.Health, 40), ownerPRI.RU * 2.5);
		HitActor.Health += fPri;
		ownerPRI.sgInfoUpgradeRepair += fPri;
		if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
			ownerPRI.AddRU(-0.2 * fPri);
		ownerPRI.Score += fPri/100;
		Owner.PlaySound(Misc2Sound, SLOT_Misc, Pawn(Owner).SoundDampening*2.5);
		SpecialPause = 1;
		return true;
	}
	SpecialPause = -0.01;
	if ( DeltaRep == 1 )
	{
		ServerDenySound();
		SpecialPause = -1;
	}
	return false;
}

//Continuous upgrade, if SpecialPause is > 0, then delay next repair
function bool UpgradeFunction( float DeltaRep)
{
	local pawn HitActor;
	local sgBuilding sgBest;
	local float fPri, Priority;
	local sgPri OwnerPRI;


	ownerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	HitActor = BestUpgradeCandidate( ownerPRI.Team);
	sgBest = sgBuilding(HitActor);
	SpecialPause = DeltaRep;

	if ( sgBest != none )
	{
		if ( DeltaRep == 1 ) //Don't let a single bind multi-upgrade
			SpecialPause = 0.2;
		DeltaRep = 1;
		SpecialPause = -1;
		fPri = FMin( fMin(5,int(sgBest.Grade+1.001)) - sgBest.Grade, 1 * DeltaRep);

		if ( SiegeGI(Level.Game) == None || !SiegeGI(Level.Game).FreeBuild )
		{
			fPri = FMin(fPri, (ownerPRI.RU / (sgBest.UpgradeCost * int(sgBest.Grade + 1))));
			if ( sgBest.bNoFractionUpgrade && (int(sgBest.Grade) == int(sgBest.Grade + fPri)) )
				return false;
			ownerPRI.AddRU( (sgBest.UpgradeCost * int(sgBest.Grade + 1)) * (-fPri) );
			sgBest.RUinvested += sgBest.UpgradeCost * (sgBest.Grade + 1) * fPri;
			ownerPRI.Score += fPri;
			ownerPRI.sgInfoUpgradeRepair+= fPri;
		}

		sgBest.Grade += fPri;
		ownerPRI.sgInfoUpgradeRepair += fPri;

		if ( fPri > 0 )
		{
			sgBest.Upgraded();
			if ( DeltaRep == 1 )
				Owner.PlaySound(Misc3Sound, SLOT_None, pawn(Owner).SoundDampening*2.5);
		}
		return true;
	}

	if ( HitActor != none )
	{
		UP_PLAYER:
		Priority = sgPRI(HitActor.PlayerReplicationInfo).RU;
		if ( Priority < SiegeGI(Level.Game).MaxRUs[ownerPRI.Team] )
		{
			fPri=FMin(100, ownerPRI.RU);
			sgPRI(HitActor.PlayerReplicationInfo).AddRU(fPri);
			ownerPRI.sgInfoUpgradeRepair+= fPri;
			ownerPRI.AddRU(-1 * (sgPRI(HitActor.PlayerReplicationInfo).RU - Priority));
			ownerPRI.Score += (sgPRI(HitActor.PlayerReplicationInfo).RU - Priority) / 100;
			HitActor.PlayerReplicationInfo.Score -= (sgPRI(HitActor.PlayerReplicationInfo).RU - Priority) / 100;
		}
		HitActor.PlaySound(sound'sgMedia.sgPickRUs', SLOT_None,HitActor.SoundDampening*2.5);
		SpecialPause = -1;
		return true;
	}
	if ( DeltaRep == 1 )
		ServerDenySound();
	SpecialPause = -0.01; //No repair... tick again immediately
	return false;
}

function bool RemoveFunction()
{
	local sgBuilding sgActor, sgBest;
	local float Priority, fPri;
	local string sMessage;
	local sgRemoveProt sgRP;

	if ( (sgPRI(Pawn(Owner).PlayerReplicationInfo) != none && sgPRI(Pawn(Owner).PlayerReplicationInfo).RemoveTimer < 45) ) //Wait before we can remove again, wait before being able to remove at all
		return false;

	SpecialPause = -1;
	sgBest = BestRemoveCandidate( Pawn(Owner).PlayerReplicationInfo.Team);
	if ( sgBest == none )
	{
		ServerDenySound();
		return false;
	}

	//HIGOR: INTEGRATE THIS INTO THE SGPRI AS WELL
	if ( !bCanRemoveWithImpunity && !BuildingOwned(sgBest) ) //Removing other player's stuff
	{
		sgRP = sgRemoveProt(Pawn(Owner).FindInventoryType(class'sgRemoveProt'));

		if ( sgRP != None )
		{
			sgRP.AddRemove();
			if ( sgRP.RemoveWarning() )
			{
				sMessage="Player "@Pawn(Owner).PlayerReplicationInfo.PlayerName@" has been warned for Team Removing.";
				class'SiegeStatics'.static.AnnounceAll( self, sMessage);
			}
			if ( sgRP.ExcessRemove() )
			{
				sMessage="Player "@Pawn(Owner).PlayerReplicationInfo.PlayerName@" was kicked for being a Team Remover.";
				class'SiegeStatics'.static.AnnounceAll( self, sMessage);
				Owner.Destroy();
			}
		}
		else
		{
			sgRP = Spawn(class'sgRemoveProt', Pawn(Owner), 'sgRemoveProt', Pawn(Owner).Location, Pawn(Owner).Rotation);
			if ( sgRP != None )
			{
				sgRP.bHeldItem = True;
				sgRP.GiveTo(Pawn(Owner));
				sgRP.Activate();
			}
		}
	}
	if ( sgBest.RemovedBy( pawn(Owner)) )
	{
		SpecialPause = 1;
		return true;
	}
}

function bool DragFunction() //10 times a sec
{
	local vector OtherPos, GoalPos;
	local vector X, Y, Z;
	local rotator View;
	local float MaxOffset;

	View = Pawn(Owner).ViewRotation;
	if ( Dragging == None || Dragging.bDeleteMe )
	{
		Dragging = BestDragCandidate( Pawn(Owner).PlayerReplicationInfo.Team);
		if ( Dragging != None )
		{
			GetAxes( View, X, Y, Z);
			GoalPos = Dragging.Location - (Pawn(Owner).Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight);
			DragCoords.X = GoalPos dot X;
			DragCoords.Y = GoalPos dot Y;
			DragCoords.Z = GoalPos dot Z;
			DragViewStart = View;
		}
		return Dragging != None;
	}

	MaxOffset = 5 + Dragging.CollisionRadius * 0.2;
	if ( VSize(Dragging.Location - Dragging.InitialLocation) > (2+MaxOffset * 1.2) ) //External factors moved this build, do not drag
		return false;

	GetAxes( View, X, Y, Z);
	GoalPos = Pawn(Owner).Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	GoalPos += X * DragCoords.X;
	GoalPos += Y * DragCoords.Y;
	GoalPos += Z * DragCoords.Z;
	if ( VSize( GoalPos - Dragging.InitialLocation) > MaxOffset )
		GoalPos = Dragging.InitialLocation + Normal( GoalPos-Dragging.InitialLocation) * MaxOffset;
	MaxOffset = fMin( 1.0, VSize(GoalPos-Dragging.Location) );
	OtherPos = Dragging.Location + Normal( GoalPos-Dragging.Location) * MaxOffset;
	GoalPos = Dragging.Location; //Save GoalPos in case we need to revert
	Dragging.SetLocation( OtherPos);
	if ( Dragging.Region.ZoneNumber == 0 ) //Revert if out of the world
		Dragging.SetLocation(GoalPos);
	SpecialPause = 0.1;
	return true;
}

simulated function sgBuilding OrbCandidate( byte aTeam)
{
	local vector HitLocation, HitNormal, start, end;
	local sgBuilding sgActor, sgBest;
	local float Priority, fPri;

	Start = Owner.Location + vect(0,0,1) * Pawn(Owner).BaseEyeHeight;
	end =  start + vector(Pawn(Owner).ViewRotation) * 90;

	ForEach Owner.TraceActors ( class'sgBuilding', sgActor, HitLocation, HitNormal, end, start)
	{
		if ( sgActor == level )
			break;
		if ( !sgActor.IsA('sgBuilding') || (sgActor.Team != aTeam) || !sgActor.bCanTakeOrb )
			continue;
		fPri = 1 - VSize( Normal(sgActor.Location - start) - Normal(end-start) );
		if ( fPri > Priority )
		{
			Priority = fPri;
			sgBest = sgActor;
		}
	}

	return sgBest;
}

simulated function bool BuildingOwned( sgBuilding sgB)
{
	local sgPRI aPRI;

	if ( sgB.Owner == Owner )
		return true;

	if ( Level.NetMode != NM_Client )
	{
		if ( SiegeGI(Level.Game) == none )
			return sgB.sPlayerIP == (GetPlayerNetworkAddres()@string(Pawn(Owner).PlayerReplicationInfo.Team));

		aPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);
		if ( aPRI != none )
			return aPRI.PlayerFingerPrint == sgB.sPlayerIP;
	}
	return false;
}

//=========================================
//========================== DISPLAY PANEL
simulated event RenderOverlays( canvas Canvas )
{
	local rotator NewRot;
	local bool bPlayerOwner;
	local int Hand;
	local PlayerPawn PlayerOwner;
	local vector DrawOffset, WeaponBob;
	local Pawn PawnOwner;
	local float WideScreenFactor, FovFactor;

	if ( bHideWeapon )
		return;
	PawnOwner = Pawn(Owner);
	if ( PawnOwner == None )
		return;

	PlayerOwner = PlayerPawn(Owner);

	if ( PlayerOwner != None )
	{
		if ( PlayerOwner.DesiredFOV != PlayerOwner.DefaultFOV )
			return;
		bPlayerOwner = true;
		Hand = PlayerOwner.Handedness;

		if (  (Level.NetMode == NM_Client) && (Hand == 2) )
		{
			bHideWeapon = true;
			return;
		}
	}

	if ( TeamSet < 0 )
	{
		if ( PawnOwner.PlayerReplicationInfo != none )
			TeamSet = PawnOwner.PlayerReplicationInfo.Team;
/*		else //Is the below block necessary? TEST IN DEMOPLAY!
		{
			ForEach Owner.ChildActors( class'PlayerReplicationInfo', Pawn(Owner).PlayerReplicationInfo )
			{
				TeamSet = Pawn(Owner).PlayerReplicationInfo.Team;
				break;
			}
		}
*/		TeamSet = Min( TeamSet, 4);
	}
	if ( !bPlayerOwner || (PlayerOwner.Player == None) )
		PawnOwner.WalkBob = vect(0,0,0);

	WideScreenFactor = (Canvas.ClipY / Canvas.ClipX) ** 0.7; //Smaller on HD, bigger on square screens

//	DrawOffset = ((0.9/PawnOwner.FOVAngle * PlayerViewOffset) >> PawnOwner.ViewRotation);
	FovFactor = (90/PawnOwner.FOVAngle);
	DrawOffset = FovFactor * 0.01 * PlayerViewOffset;
	DrawOffset.X *= Square(FovFactor) / WideScreenFactor;
	DrawOffset.Y /= WideScreenFactor;
	DrawOffset.Z *= (1.f + WideScreenFactor) * 0.5;
	DrawOffset = DrawOffset >> PawnOwner.ViewRotation;

	if ( (Level.NetMode == NM_DedicatedServer)
		|| ((Level.NetMode == NM_ListenServer) && (Owner.RemoteRole == ROLE_AutonomousProxy)) )
		DrawOffset += (PawnOwner.BaseEyeHeight * vect(0,0,1));
	else
	{
		DrawOffset += (PawnOwner.EyeHeight * vect(0,0,1));
		WeaponBob = BobDamping * PawnOwner.WalkBob;
		WeaponBob.Z = (0.45 + 0.55 * BobDamping) * PawnOwner.WalkBob.Z;
		DrawOffset += WeaponBob;
	}

	SetLocation( Owner.Location + DrawOffset );
	NewRot = PawnOwner.ViewRotation;

	if ( Hand == 0 )
		newRot.Roll = -2 * Default.Rotation.Roll;
	else
		newRot.Roll = Default.Rotation.Roll * Hand;

	SetRotation(newRot);
	if ( FindClientActor() && ClientActor.bNoConstructorScreen )
		WetTexture'BGL_PSwap'.Palette = ColorPals[5].Palette;
	else
		WetTexture'BGL_PSwap'.Palette = ColorPals[TeamSet].Palette;
	if ( LocalOwner() ) //I have to find out a way to make this render on other viewtargets
		ScriptedTexture'BGL_Script'.NotifyActor = self;
	Canvas.DrawActor(self, false);
	ScriptedTexture'BGL_Script'.NotifyActor = none;
}


simulated event RenderTexture( ScriptedTexture Tex)
{
	local font F, SF;
	local texture TmpTex;
	local string RuleString;
	local byte DenyBuild;
	local int RUReq, i;
	local sgPRI PRI;

	if ( !FindCatActor() || ClientActor.bNoConstructorScreen )
	{
		Tex.DrawTile( 0, 0, 255, 255, 0, 0, 1, 1, Texture'GUI_Border4_F', false);
		return;
	}
	PRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	//Left HAND only for now
	F = MyFonts.GetBigFont(1280);
	SF = MyFonts.GetBigFont( 640);

	For ( i=3+CatActor.NumCats() ; i>=0 ; i-- )
	{
		if ( i == Category )
			Tex.DrawTile( 35 + 9*i, 16, 8, 16, 0, 0, 8, 16, Texture'CPanel_HCat_A', false);
		else if ( i == 3 ) //Pull mode is blacked out when not selected
			Tex.DrawTile( 35 + 9*i, 16, 8, 16, 0, 0, 8, 16, Texture'CPanel_HCat_D', false);
		else
			Tex.DrawTile( 35 + 9*i, 16, 8, 16, 0, 0, 8, 16, Texture'CPanel_HCat_N', false);
	}

	if ( Category <= 3 )
	{
		Tex.DrawTile( 54, 75, 64, 64, 0, 0, 64, 64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 118, 75, 64, 64, 63, 0, -64, 64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 54, 139, 64, 64, 0, 63, 64, -64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 118, 139, 64, 64, 63, 63, -64, -64, Texture'GUI_Border4_F', false);

		if ( HitPawn == none )
		{
			Tex.DrawColoredText( 34, 32, Functions[Category], F, PurpleColor );
			Tex.DrawTile( 86, 107, 64, 64, 0, 0, 64, 64, FunctionBkgs[Category], true);
		}
		else
		{
			Tex.DrawColoredText( 34, 32, Functions[Category], F, OrangeColor );
			Tex.DrawTile( 180, 70, 32, 32, 0, 0, 64, 64, FunctionBkgs[Category], true);
			if ( HitPawn.PlayerReplicationInfo != none )
			{
				Tex.DrawText( 40, 52, "> "$HitPawn.PlayerReplicationInfo.PlayerName, F);
				TmpTex = GetStatusIcon( HitPawn);
				if ( TmpTex != none ) //128x224
					Tex.DrawTile( 62, 75, 96, 168, 0, 0, 128, 224, TmpTex, true);
			}
			else if ( sgBuilding(HitPawn) != none )
			{
				Tex.DrawText( 40, 52, "> "$sgBuilding(HitPawn).BuildingName, F);
 				if ( sgBuilding(HitPawn).GUI_Icon != none)
					Tex.DrawTile( 54, 75, 128, 128, 0, 0, 128, 128, sgBuilding(HitPawn).GUI_Icon, true);
			}
		}
	}
	else if ( Category > 3 )
	{
		if ( Category != CachedCategory  )
		{
			CachedCategory = Category;
			CachedCBuildCount = CatActor.CountCategoryBuilds( Category - 4);
		}

		Tex.DrawTile( 54, 75, 64, 64, 0, 0, 64, 64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 118, 75, 64, 64, 63, 0, -64, 64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 54, 139, 64, 64, 0, 63, 64, -64, Texture'GUI_Border4_F', false);
		Tex.DrawTile( 118, 139, 64, 64, 63, 63, -64, -64, Texture'GUI_Border4_F', false);

		if ( SelectedBuild == none )
		{
			Tex.DrawColoredText( 34, 32, CatActor.CatName(Category-4), F, OrangeColor);
			Tex.DrawTile( 86, 107, 64, 64, 0, 0, 64, 64, Texture'GUI_UpgradeFront', true);
		}
		else
		{
			Tex.DrawColoredText( 34, 32, CatActor.CatName(Category-4), F, PurpleColor);
			Tex.DrawText( 40, 52, "> "$SelectedBuild.default.BuildingName, F);
			if ( SelectedBuild.default.GUI_Icon != none )
			{
				Tex.DrawTile( 180, 70, 32, 32, 0, 0, 64, 64, Texture'GUI_UpgradeFront', true);
				Tex.DrawTile( 54, 75, 128, 128, 0, 0, 128, 128, SelectedBuild.default.GUI_Icon, true);
			}
			else
				Tex.DrawTile( 86, 107, 64, 64, 0, 0, 64, 64, Texture'GUI_UpgradeFront', true);
			RuleString = CatActor.GetRuleString( SelectedIndex, DenyBuild);
			if ( DenyBuild > 0 ) //Denied!
				Tex.DrawColoredText( 24, 200, RuleString, SF, PurpleColor );
			else
				Tex.DrawColoredText( 24, 200, RuleString, SF, OrangeColor );
			RUReq = CatActor.BuildCost( SelectedIndex);
			if ( PRI != none && PRI.RU >= RUReq ) //Enough RU
				Tex.DrawColoredText( 24, 218, "Cost: "$string(RUReq), SF, OrangeColor );
			else
				Tex.DrawColoredText( 24, 218, "Cost: "$string(RUReq), SF, PurpleColor );

		}
	}
}

simulated final function Texture GetStatusIcon( Pawn Other)
{
	if ( TournamentPlayer(Other) != none )
		return TournamentPlayer(Other).StatusDoll;
}

//=========================================
//========================== GUI

simulated function PostRender( canvas Canvas)
{
	local float XL, YL, Scale, X, YOffset;
	local string aStr, aStr2, RuleString;
	local byte DenyBuild;
	local int Cycles;

	if ( MyFonts == none )
	{
		GetFonts();
		return;
	}

	if ( !FindCatActor() )
		return;

/*	if ( GuiState > 0 )
	{
		DrawGui( Canvas);
		return;
	}*/
	DrawWheel( Canvas);
//	DrawGUIv2( Canvas); TEMPORARILY DISABLED

	Scale = Canvas.ClipX / 1280.0;
	Canvas.Font = MyFonts.GetBigFont(Canvas.ClipX);
	Canvas.TextSize("TEST", XL, YL);

	if ( bHideWeapon )		YOffset = Canvas.ClipY - 64*Scale - YL*3;
	else					YOffset = Canvas.ClipY - 96*Scale - YL*3;

	//If weapon is hidden, draw stats the old way
	if ( true )
	{
		if ( Category <= 3 ) //Higor, localize these
			aStr = default.Functions[Category];
		else if ( Category == 3 ) //Orb stuff //DISABLED UNTIL FURTHER NOTICE
		{
			if ( sgPRI(Pawn(Owner).PlayerReplicationInfo).XC_Orb == none )
			{
				aStr = Default.OrbTexts[0];
			}
			else
				aStr = Default.OrbTexts[1];
		}
		else if ( SelectedBuild != none )
		{
			aStr = SelectedBuild.Default.BuildingName;
			if ( CatActor.HasCustomCost( SelectedIndex) )
				aStr2 = Default.CostText$": "$CatActor.CustomCost(SelectedIndex);
			else
				aStr2 = Default.CostText$": "$SelectedBuild.Default.BuildCost;
			RuleString = CatActor.GetRuleString( SelectedIndex, DenyBuild);
		}
		else if ( Category < 16 )
		{
			aStr = CatActor.CatName( Category - 4);
			aStr2 = Default.CategoryText;
		}

		X = Canvas.ClipX - 384 * Scale;

	    Canvas.Style = ERenderStyle.STY_Masked;
		Canvas.bCenter = true;

		if ( DenyBuild == 0 )
			Canvas.DrawColor = WhiteColor;
		else
			Canvas.DrawColor = Col(200,0,50);
		Canvas.TextSize(aStr, XL, YL);
		Canvas.SetPos(X, YOffset);
		Canvas.DrawText(""@aStr, false);

		if ( RuleString != "" )
		{
			Canvas.TextSize(aStr, XL, YL);
			Canvas.SetPos(X + XL/4, YOffset + YL*2);
			Canvas.DrawText(RuleString, false);
		}

		if ( aStr2 != "" )
		{
			Canvas.DrawColor = Col(127,127,127);
			Canvas.TextSize(aStr2, XL, YL);
			Canvas.SetPos(X + XL/4, YOffset + YL);
			Canvas.DrawText(aStr2, false);
		}

		Canvas.bCenter = false;
 		Canvas.Style = ERenderStyle.STY_Translucent;


	}

	//Draw GUI
}

simulated function DrawWheel( Canvas C)
{
	if ( ClientActor == none )
		return;

	ClientActor.ConstructorWheel.HUDColor = HUDColor();
	C.Font = MyFonts.GetMediumFont((C.ClipX + C.ClipY)*0.5);
	if ( !ClientActor.ConstructorWheel.bSetup )
		ClientActor.ConstructorWheel.sgSetup( self);

	ClientActor.ConstructorWheel.Scale = fMax( 0.5, int(fMin( C.ClipX, C.ClipY) / 768)); // quarter of screen is desired
	ClientActor.ConstructorWheel.MasterRender( C);
}

simulated function DrawGUIv2( Canvas C)
{
	local float CalcX, CalcY, cOX, cOY;
	local float Scale;

	if ( ClientActor == none )
		return;

	Scale = (C.ClipX + C.ClipY) / 2240.0; //1280*960 as standard 4:3 test resolution

	CalcX = Scale * 370; //Tweak this frame later
	CalcY = Scale * 222;
	cOY = C.ClipY - (Scale * 60.0 + CalcY);
	cOX = C.ClipX - (Scale * 20.0 + CalcX);
	if ( bHideWeapon )
		cOY += Scale * 20;

	if ( !ClientActor.ConstructorPanel.bSetup )
		ClientActor.ConstructorPanel.sgSetup( self);

	//Send frame size and location to the main panel
	ClientActor.ConstructorPanel.OrgX = int(cOX);
	ClientActor.ConstructorPanel.OrgY = int(cOY);
	ClientActor.ConstructorPanel.CurX = int(CalcX);
	ClientActor.ConstructorPanel.CurY = int(CalcY);
	ClientActor.ConstructorPanel.Scale = Scale; //UGLY, BUT NECESSARY
	ClientActor.ConstructorPanel.HUDColor = HUDColor();
	ClientActor.ConstructorPanel.MasterRender( C);
}

simulated function OpenGui()
{
	if ( (PlayerPawn(Owner) == none) || ViewPort(PlayerPawn(Owner).Player) == none )
		return;
	//Main trigger
	GuiState = 1;
	ClientOpenGui();
//	bJustOpenedGUI = true;
}

function ClientOpenGui()
{
	GuiState = 1;
}

simulated function SimCloseGui()
{
	SpecialPause = 0.3;
	GuiState = 0;
	if ( !ListenPlayer() )
		ClientCloseGui();
}

function ClientCloseGui()
{
	SpecialPause = 0.3;
	GuiState = 0;
}

simulated function DrawGui( canvas Canvas)
{
	local float XL, YL, aX, aY, aScale, tH, tV, cX, cY, cZ;
	local int i, j, k;

	if ( !FindClientActor() )
		return;

	if ( !ClientActor.bUseSmallGui )
		Canvas.Font = MyFonts.GetMediumFont(Canvas.ClipX);
	else
		Canvas.Font = MyFonts.GetSmallestFont(Canvas.ClipX);
	Canvas.TextSize("T", cY, YL);

	tV = YL * 12; //Total height
	tH = int(tV * 1.2);
	MX = fClamp( MX, 0, tH);
	MY = fClamp( MY, 0, tV);
	aY = int(Canvas.ClipY * 0.93) - tV;
	aX = int(Canvas.ClipX - tH * 1.3);

	Canvas.bNoSmooth = False;

	//Draw back modulated panel
	Canvas.Style = ERenderStyle.STY_Modulated;
	Canvas.SetPos(aX,aY);
	cX = int(tH / 6);
	Canvas.DrawTile( texture'GUI_TurnM', cX, cX, 0, 0, 64, 64 );
	Canvas.SetPos(aX+cX,aY);
	Canvas.DrawTile( texture'GUI_FullM', tH-cX, cX, 0, 0, 16, 16);
	Canvas.SetPos(aX,aY+cX);
	Canvas.DrawTile( texture'GUI_FullM', tH, tV-cX, 0, 0, 16, 16);

	//Draw front frame
	Canvas.Style = ERenderStyle.STY_Translucent;
	Canvas.DrawColor = HUDColor();
	Canvas.SetPos(aX,aY);
	Canvas.DrawTile( texture'GUI_Front', cX, cX, 0, 0, 64, 64);
	Canvas.SetPos(aX+cX,aY);
	Canvas.DrawTile( texture'GUI_Front', tH-cX*2, cX, 64, 0, 32, 64);
	Canvas.SetPos(aX+tH-cX,aY);
	Canvas.DrawTile( texture'GUI_Front', cX, cX, 64, 0, 64, 64);
	Canvas.SetPos(aX,aY+cX);
	Canvas.DrawTile( texture'GUI_Front', cX, tV-cX*2, 0, 64, 64, 32);
	Canvas.SetPos(aX,aY+tV-cX);
	Canvas.DrawTile( texture'GUI_Front', cX, cX, 0, 64, 64, 64);
	Canvas.SetPos(aX+cX,aY+tV-cX);
	Canvas.DrawTile( texture'GUI_Front', tH-cX*2, cX, 64, 64, 32, 64);
	Canvas.SetPos(aX+tH-cX,aY+tV-cX);
	Canvas.DrawTile( texture'GUI_Front', cX, cX, 64, 64, 64, 64);
	Canvas.SetPos(aX+tH-cX,aY+cX);
	Canvas.DrawTile( texture'GUI_Front', cX, tV-cX*2, 64, 64, 64, 32);
	Canvas.SetPos(aX+cX,aY+cX);
	Canvas.DrawTile( texture'GUI_Front', tH-cX*2, tV-cX*2, 64, 64, 32, 32);

	Canvas.bNoSmooth = True;

	j = GuiState >>> 11;

	Canvas.TextSize("TTTTTTTTTTTTTTTTTTTT", XL, YL);
	if ( YL < 12 )
		XL = int(XL * 0.7);
	lastXL = XL;
	lastYL = YL;

	//Draw category list, and settings
	if ( (GuiState & 63) == 1 )
	{
		//Title
		Canvas.TextSize( GuiCats, XL, YL);
		DrawCapsule( Canvas, aX + YL*2, int(aY + YL*0.5), XL+cY, YL+2);
		Canvas.DrawColor = Col(220,220,220);
		Canvas.Style = ERenderStyle.STY_Translucent;
		Canvas.SetPos( aX + YL*2 + cY*0.5, aY + YL*0.5 + 2);
		Canvas.DrawText( GuiCats);

		//Settings button
		Canvas.bNoSmooth = False;
		//Draw forward arrow
		cZ = tH - int(YL * 1.8); //Just another stored var
		Canvas.SetPos( aX + cZ, aY + int(tV * 0.6) );
		if ( PointerBetween( cZ, int(tV * 0.6), cZ + int(1.4 * YL), int(tV * 0.6) + int(1.4 * YL)) )
			Canvas.DrawColor = SwapColors( HUDColor() );
		Canvas.DrawTile( texture'GUI_Settings', int(1.4 * YL), int(1.4 * YL), 0, 0, 64, 64);
		Canvas.DrawColor = Col(220,220,220);
		Canvas.bNoSmooth = True;

	}
	//We're inside a category
	else
	{
		//Draw back arrow
		Canvas.bNoSmooth = False;
		//Draw forward arrow
		cZ = tH - int(YL * 1.8); //Just another stored var
		Canvas.SetPos( aX + cZ, aY + int(tV * 0.4) );
		Canvas.DrawColor = HoverColor( PointerBetween( cZ, int(tV * 0.4), cZ + int(1.4 * YL), int(tV * 0.4) + int(1.4 * YL)) );
		Canvas.DrawTile( texture'GUI_Arrow', int(1.4 * YL), int(1.4 * YL), 0, 0, -64, 64);
		Canvas.bNoSmooth = True;

		k = (GuiState >>> 1) & 31;

		if ( k == 31 ) //Draw settings window!
		{
			//Title
			Canvas.TextSize( GuiSettings, XL, YL);
			DrawCapsule( Canvas, aX + YL*2, int(aY + YL*0.5), XL+cY, YL+2);
			Canvas.DrawColor = Col(220,220,220);
			Canvas.Style = ERenderStyle.STY_Translucent;
			Canvas.SetPos( aX + YL*2 + cY*0.5, aY + YL*0.5 + 2);
			Canvas.DrawText( GuiSettings );

			k = CapsuleHit();
			if ( j==0 ) //Page 1
			{
				For ( i=0 ; i<7 ; i++ )
				{
					cZ = YL * 1.25 * (1.5+i);
					DrawCapsule( Canvas, aX + YL, aY + cZ, lastXL, YL+2);
				}
				if ( k==0 )					DrawSlider( Canvas, aX, aY, YL, YL * 1.875, ClientActor.GuiSensitivity, GuiSens);
				else					DrawPlainSlider( Canvas, aX, aY, YL, YL * 1.875, ClientActor.GuiSensitivity, GuiSens);

				Canvas.SetPos( aX + YL + cY, aY + YL * 3.125 + 2);
				Canvas.DrawColor = HoverColor(k==1);
				if ( ClientActor.bUseSmallGui )	Canvas.DrawText( GuiSmall$"   +");
				else							Canvas.DrawText( GuiSmall$"   -");

				Canvas.SetPos( aX + YL + cY, aY + YL * 4.375 + 2);
				Canvas.DrawColor = HoverColor(k==2);
				if ( ClientActor.bNoConstructorScreen )	Canvas.DrawText( GuiModel$"   +");
				else									Canvas.DrawText( GuiModel$"   -");

				if ( k==3 )					DrawSlider( Canvas, aX, aY, YL, YL * 5.625, ClientActor.SirenVol,"Siren Volume");
				else					DrawPlainSlider( Canvas, aX, aY, YL, YL * 5.625, ClientActor.SirenVol,"Siren Volume");

				Canvas.SetPos( aX + YL + cY, aY + YL * 6.875 + 2);
				Canvas.DrawColor = HoverColor(k==4);
				if ( ClientActor.bFPnoReplace )		Canvas.DrawText( GuiFingerPrint$"   +");
				else								Canvas.DrawText( GuiFingerPrint$"   -");

				Canvas.SetPos( aX + YL + cY, aY + YL * 8.125 + 2);
				Canvas.DrawColor = HoverColor(k==5);
				if ( ClientActor.bHighPerformance )		Canvas.DrawText( GuiPerf$"   +");
				else								Canvas.DrawText( GuiPerf$"   -");

				if ( k==6 )					DrawSlider( Canvas, aX, aY, YL, YL * 9.375, ClientActor.ScoreboardBrightness,"Score Brightness");
				else					DrawPlainSlider( Canvas, aX, aY, YL, YL * 9.375, ClientActor.ScoreboardBrightness,"Score Brightness");


			}
		}
	}

	Canvas.bNoSmooth = False;

	//Draw forward arrow
	cZ = tH - int(YL * 1.8); //Just another stored var
	Canvas.SetPos( aX + cZ, aY + int(tV * 0.2) );
	if ( PointerBetween( cZ, int(tV * 0.2), cZ + int(1.4 * YL), int(tV * 0.2) + int(1.4 * YL)) )
		Canvas.DrawColor = SwapColors( HUDColor() );
	else
		Canvas.DrawColor = Col(220,220,220);
	Canvas.DrawTile( texture'GUI_Arrow', int(1.4 * YL), int(1.4 * YL), 0, 0, 64, 64);

	Canvas.bNoSmooth = True;

	DrawPointer( canvas, aX, aY);

}

//Same as capsule
simulated function DrawSlider( canvas Canvas, float bX, float bY, float sX, float sY, float SliderPos, optional string SliderText)
{
	local float aX;
	local int i;

	i = SliderHit( sX, sY, SliderPos);
	aX = Canvas.ClipX;
	Canvas.Style = ERenderStyle.STY_Translucent;
	if ( SliderText != "")
	{
		Canvas.DrawColor = Col(100,100,100);
		Canvas.SetPos( bX + sX, bY + sY + 2);
		Canvas.bCenter = True;
		Canvas.ClipX = bX + sX + lastXL;
		Canvas.DrawText( SliderText);
		Canvas.ClipX = aX;
		Canvas.bCenter = False;
	}
	Canvas.SetPos( bX + sX + 1, bY + sY + 1);
	Canvas.DrawColor = HoverColor( i == -1 );
	Canvas.DrawTile( texture'GUI_Minus', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.SetPos( bX + sX + lastXL - (lastYL+1), bY + sY + 1);
	Canvas.DrawColor = HoverColor( i == 1 );
	Canvas.DrawTile( texture'GUI_Plus', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.DrawColor = HoverColor( i == 2 );
	Canvas.SetPos( bX + sX + lastYL + (lastXL-lastYL*3) * SliderPos, bY + sY + 1);
	Canvas.bNoSmooth = False;
	Canvas.DrawTile( texture'GUI_Circle', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.bNoSmooth = True;
}

//Same as capsule, don't perform color checks
simulated function DrawPlainSlider( canvas Canvas, float bX, float bY, float sX, float sY, float SliderPos, optional string SliderText)
{
	local float aX;

	aX = Canvas.ClipX;
	Canvas.Style = ERenderStyle.STY_Translucent;
	if ( SliderText != "")
	{
		Canvas.DrawColor = Col(100,100,100);
		Canvas.SetPos( bX + sX, bY + sY + 2);
		Canvas.bCenter = True;
		Canvas.ClipX = bX + sX + lastXL;
		Canvas.DrawText( SliderText);
		Canvas.ClipX = aX;
		Canvas.bCenter = False;
	}
	Canvas.SetPos( bX + sX + 1, bY + sY + 1);
	Canvas.DrawColor = Col(220,220,220);
	Canvas.DrawTile( texture'GUI_Minus', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.SetPos( bX + sX + lastXL - (lastYL+1), bY + sY + 1);
	Canvas.DrawTile( texture'GUI_Plus', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.SetPos( bX + sX + lastYL + (lastXL-lastYL*3) * SliderPos, bY + sY + 1);
	Canvas.bNoSmooth = False;
	Canvas.DrawTile( texture'GUI_Circle', lastYL, lastYL, 0, 0, 32, 32);
	Canvas.bNoSmooth = True;
}

//Auto check for capsules, ultra fast method
simulated function int CapsuleHit()
{
	local int i;
	local float cZ;

	//Check horizontal coords, then verticals
	if ( (MX >= lastYL) && (MX <= (lastYL + lastXL)) )
		While ( i<7 )
		{
			cZ = lastYL * 1.25 * (1.5+i);
			if ( (MY >= cZ) && (MY <= (cZ+lastYL+2) ) )
				return i;
			i++;
		}
	return -1;
}

simulated function int SliderHitPos( int i, float SliderPos)
{
	return SliderHit( lastYL, lastYL * 1.25 * (1.5+i), SliderPos);
}

//Returns 0 if no hit, 2 means mid button
simulated function int SliderHit( float sX, float sY, float SliderPos)
{
	if ( PointerBetween( sX + 1, sY + 1, sX + 1 + lastYL, sY + 1 + lastYL) )
		return -1;
	if ( PointerBetween( sX + lastXL - (lastYL+1), sY + 1, sX + lastXL - 1, sY + 1 + lastYL) )
		return 1;
	if ( PointerBetween( sX + lastYL + (lastXL-lastYL*3) * SliderPos, sY + 1, sX + lastYL*2 + (lastXL-lastYL*3) * SliderPos, sY + 1 + lastYL) )
		return 2; //START DRAGGING!
	return 0;
}

simulated function color HoverColor( bool bHover)
{
	if ( bHover )
		return SwapColors( HUDColor() );
	return Col(220,220,220);
}

simulated function DrawPointer( canvas Canvas, float aX, float aY)
{
	Canvas.Style = ERenderStyle.STY_Masked;

	Canvas.DrawColor = SwapBack(HUDColor());
	Canvas.SetPos( aX + MX - 8, aY + MY - 8);
	Canvas.DrawIcon( texture'GUI_Cross', 1);
}

//3 Drawcalls plus a selection result
simulated function DrawCapsule( canvas Canvas, float aX, float aY, float aH, float aV)
{
	Canvas.Style = ERenderStyle.STY_Modulated;
	Canvas.SetPos(aX,aY);
	Canvas.DrawTile( texture'GUI_TextModu', int(aV*0.5), aV, 0, 0, 32, 64);
	Canvas.SetPos(aX+int(aV*0.5), aY);
	Canvas.DrawTile( texture'GUI_TextModu', aH-aV, aV, 30, 0, 1, 64);
	Canvas.SetPos(aX+int(aH-aV*0.5), aY);
	Canvas.DrawTile( texture'GUI_TextModu', int(aV*0.5), aV, 0, 0, -32, 64);
}

simulated function bool PointerBetween( float aX, float aY, float bX, float bY)
{
	return (MX >= aX) && (MX <= bX) && (MY >= aY) && (MY <= bY);
}

simulated function Color HUDColor()
{
	if ( ChallengeHUD( PlayerPawn(Owner).myHUD) == none )
		return  Col(210,210,210);
	return ChallengeHUD( PlayerPawn(Owner).myHUD).SolidHudColor * 0.8;
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


/*--- Code basis. -----------------------------------------------------------*/

simulated function AnimEnd()
{
	if ( bClientUp && !IsInState('Active') )
		GotoState('Active');
	if ( Pawn(Owner) != none && Pawn(Owner).Weapon == self )
		AnimationControl( 0.0);
}

simulated function bool ClientFire( float Value )
{
}

simulated function bool ClientAltFire( float Value )
{
}

function Fire( float Value )
{
	if ( (AmmoType == None) && (AmmoName != None) )
		GiveAmmo(Pawn(Owner));

	bPointing=True;
	bCanClientFire = true;
	ClientFire(Value);
}

function AltFire( float Value )
{
	if ( (AmmoType == None) && (AmmoName != None) )
		GiveAmmo(Pawn(Owner));

	bCanClientFire = true;
	ClientAltFire(Value);
}

function int CountBuilds( class<sgBuilding> cType, bool bExact, optional bool bSelfOwned, optional int StopAt)
{
	local sgBuilding sgB;
	local byte aTeam;
	local int i;

	if ( Pawn(Owner) != none )	aTeam = Pawn(Owner).PlayerReplicationInfo.Team;
	else	return 0;

	if ( StopAt <= 0 )
		StopAt = 9999999;

	ForEach AllActors (class'sgBuilding', sgB)
	{
		if ( sgB.Team != aTeam )	continue;
		if ( bExact )
		{	if ( sgB.Class != cType )	continue;
		}
		else if ( !ClassIsChildOf( sgB.Class, cType) )	continue;

		if ( bSelfOwned && !BuildingOwned(sgB) )
			continue;
		if ( ++i == StopAt )
			return i;

	}
	return i;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if ( !bDeleteMe )
		GetFonts();

	if ( Role == ROLE_Authority )
	{
		if ( (SiegeGI(Level.Game) == none) || (SiegeGI(Level.Game).FreeBuild) )
			bFreeBuild = True;
	}
}

simulated function GetFonts()
{
	local fontInfo aF;

	ForEach AllActors ( class'FontInfo', aF)
	{
		MyFonts = aF;
		return;
	}
}

simulated final function bool LoopingAnim( name AnimName)
{
	return IsAnimating() && bAnimLoop && (AnimSequence == AnimName);
}

simulated function AnimationControl( float DeltaTime)
{
	if ( (AnimSequence == 'Select') && (DeltaTime != 0.0) )
		return;
	if ( bClientUp && (GetStateName() != 'Active') && AnimSequence != 'Down' )
		GotoState( 'Active');
	if ( Category == 0 )
	{
		if ( !LoopingAnim( 'Point') )
			LoopAnim( 'Point', 1, 0.4);
		return;
	}
	if ( Category == 1 )
	{
		if ( bUseAmbient )
		{
			if ( !LoopingAnim( 'Spin') )
				LoopAnim( 'Spin', 0.4);
			AnimRate = fMin( AnimRate + DeltaTime * 0.5, 5);
		}
		else if ( !LoopingAnim('Open') )
			LoopAnim( 'Open', 1, 0.4);
		return;
	}
	if ( !LoopingAnim('Still') )
		LoopAnim('Still', 1);
}

simulated function HandleTimers( float DeltaTime, Pawn P)
{
	//AutoCycle
	if ( ExtraTimer > 0 )
	{
		if ( P.bAltFire == 0 )
			ExtraTimer = 0;
		else
			ExtraTimer -= DeltaTime;
		if ( (P.bAltFire > 0) && (P.bFire == 0) && (GuiState == 0) && ExtraTimer <= 0 )
		{
			CycleForward();
			ExtraTimer += 0.3;
		}
	}
	if ( SpecialPause > 0 )
	{
		if ( (SpecialPause -= DeltaTime) <= 0 )
		{
			SpecialPause = 0;
			if ( (P.Weapon == self) && (P.bFire > 0) )
				PrimaryFunc( 0.0);
		}
	}
	else if ( SpecialPause < 0 )
	{
		if ( P.bFire == 0 )
			SpecialPause = 0;
		else
			SpecialPause = FMin(SpecialPause + DeltaTime, 0);
		if ( (SpecialPause == 0) && (P.Weapon == self) && (P.bFire > 0) )
			PrimaryFunc( 0.0);
	}
}

simulated function Tick(float DeltaTime)
{
	local String Info;
	local float Speed2D;
	local name aState;
	local Pawn P;

	P = Pawn(Owner);
	if ( P == none )
	{
		AmbientSound = none;
		AmbientTimer = 0;
		return;
	}

	HandleTimers( DeltaTime, P);
	if ( (Dragging != None) && ((Category != 3) || (P.bFire == 0)) )
		Dragging = None;

	if ( bCanOpenGui && P.bAltFire == 0 )
		bCanOpenGui = False;

	if ( Role == Role_Authority )
	{
		if ( sgPRI(P.PlayerReplicationInfo) != None && AmmoType != None )
			AmmoType.AmmoAmount = Min(1, sgPRI(P.PlayerReplicationInfo).RU);
	}

	if ( AmbientTimer > 0 )
	{
		AmbientTimer -= DeltaTime;
		bUseAmbient = true;
	}
	else
		bUseAmbient = false;

	if ( Owner != none )
		SetLocation(Owner.Location);
	if ( bUseAmbient )
		AmbientSound = Sound'cons_loop1';
	else
		AmbientSound = none;

	if ( P.Weapon != self )
	{
		bClientUp = false;
		HitPawn = none;
		return;
	}

	//Animation control
	if ( Pawn(Owner).PendingWeapon == none )
		AnimationControl( DeltaTime);

	if ( LocalOwner() )
	{
		if ( Category == 0 )
			HitPawn = BestUpgradeCandidate( Pawn(Owner).PlayerReplicationInfo.Team );
		else if ( Category == 1 )
			HitPawn = BestRepairCandidate( Pawn(Owner).PlayerReplicationInfo.Team );
		else if ( Category == 2 )
			HitPawn = BestRemoveCandidate( Pawn(Owner).PlayerReplicationInfo.Team );
		else if ( Category == 3 )
		{
			if ( Dragging != None )
				HitPawn = Dragging;
			else
				HitPawn = BestDragCandidate( Pawn(Owner).PlayerReplicationInfo.Team );
		}
		else
			HitPawn = none;
//		if ( (GuiState > 0) && !bJustOpenedGUI )
//			GuiControls(DeltaTime);
	}


//	bJustOpenedGui = False;
	bHadFire = P.bFire > 0;
	LastView = P.ViewRotation;
	if ( PlayerPawn(P) != none && PlayerPawn(P).bAdmin )
		bCanRemoveWithImpunity = true;

	if ( P.bFire + P.bAltFire > 0 )
		LastFired = Level.TimeSeconds;

	aState = GetStateName();
	if ( (aState == 'ClientActive') || (aState == 'ClientFiring') || (aState == 'ClientAltFiring') || (aState == 'sgConstructor') )
		GotoState('Active');
}

simulated function GuiControls( float DeltaTime)
{
	local PlayerPawn POwner;
	local float moveX, moveY;

	local float lastMx, lastMy;

	lastMx = MX;
	lastMy = MY;
	POwner = PlayerPawn(Owner);

	POwner.bShowScores = false;
	moveX =  POwner.ViewRotation.Yaw - LastView.Yaw;

	if ( moveX > 15000 )		moveX -= 65536;
	else if ( moveX < -15000 )	moveX += 65536;
	moveX *= 0.07 * (ClientActor.GuiSensitivity * 2 + 0.2);
	moveY = POwner.ViewRotation.Pitch - LastView.Pitch;
	if ( moveY > 15000 )		moveY -= 65536;
	else if ( moveY < -15000 )	moveY += 65536;
	moveY *= -0.07 * (ClientActor.GuiSensitivity * 2 + 0.2);

	//PURE IS WAY TOO GAY HERE
	if ( POwner.IsA('bbPlayer') )
		LastView = POwner.ViewRotation;
	else
		POwner.ViewRotation = LastView;

	MX = fMax( MX + moveX, 0);
	MY = fMax( MY + moveY, 0);

	if ( !bHadFire && (POwner.bFire > 0) )
		PlayerClick(); //Evaluate click coordinates here
	else if ( bHadFire && (POwner.bFire > 0) )
		PlayerDrag( MX-lastMx, MY-lastMy);
	else if ( bHadFire && (POwner.bFire == 0) )
		PlayerRelease();

	if ( POwner.ViewRotation.Pitch < 25000 )
		POwner.ViewRotation.Pitch = Min(POwner.ViewRotation.Pitch, 13000);
	else
		POwner.ViewRotation.Pitch = Max(POwner.ViewRotation.Pitch, 52356);
}

simulated function PlayerClick()
{
	local int i, j, k;
	local float cZ, tH, tV;

	//
	k = -1;

	tV = lastYL * 12; //Total height
	tH = int(tV * 1.2);
	cZ = tH - int(lastYL * 1.8);

	//Settings page button
	if ( PointerBetween( cZ, int(tV * 0.6), cZ + int(1.4 * lastYL), int(tV * 0.6) + int(1.4 * lastYL)) )
	{
		if ( (GuiState & 63) != 1 )
			return;
		GuiState = 63;
		return;
	}

	//Are we hitting a slot here?
	k = CapsuleHit();
	if ( k < 0 )
		return;

	//Fortification
	j = GuiState >>> 11; //Get page:

		if ( (GuiState & 63) == 63 ) //Settings page
		{
			if ( j == 0 ) //Page 1
			{
				if ( k==0 ) //Check slider!
				{
					i = SliderHitPos( 0, ClientActor.GuiSensitivity);
					if ( (i == -1) || (i == 1) )
						ClientActor.AdjustSensitivity( i);
				}
				else if ( k==1 )
					ClientActor.ToggleSize();
				else if ( k==2 )
					ClientActor.ToggleConstructor();
				else if ( k==3 )
				{
					i = SliderHitPos( 3, ClientActor.SirenVol);
					if ( (i == -1) || (i == 1) )
						ClientActor.AdjustSirenVol( i);
				}
				else if ( k==4 )
					ClientActor.ToggleKeepFP();
				else if ( k==5 )
					ClientActor.TogglePerformance();
				else if ( k==6 )
				{
					i = SliderHitPos( 6, ClientActor.ScoreboardBrightness);
					if ( (i == -1) || (i == 1) )
						ClientActor.AdjustScoreBright( i);
				}
				return;
			}
		}

}

simulated function PlayerDrag(float dX, float dY);
simulated function PlayerRelease();

simulated final function bool FindCatActor()
{
	local sgCategoryInfo aC;

	if ( Pawn(Owner) == none || Pawn(Owner).PlayerReplicationInfo == none )
		return false;
	if ( CatActor != none && CatActor.Team == Pawn(Owner).PlayerReplicationInfo.Team )
		return true;
	ForEach AllActors ( class'sgCategoryInfo', aC)
	{
		if ( aC.Team != Pawn(Owner).PlayerReplicationInfo.Team )
			continue;
		CatActor = aC;
		return true;
	}
}

simulated final function bool FindClientActor()
{
	local sgClient aC;

	if ( ClientActor != none )
		return true;
	if ( LocalOwner() )
	{
		ForEach AllActors ( class'sgClient', aC)
		{
			ClientActor = aC;
			return true;
		}
		ClientActor = Spawn( class'sgClient');
		return true;
	}
}

simulated function bool ActiveOrbs()
{
	local sgPRI OwnerPRI;
	local sg_XC_Orb aOrb;

	OwnerPRI = sgPRI(Pawn(Owner).PlayerReplicationInfo);

	if ( OwnerPRI.XC_Orb != none )
		return true;

	ForEach AllActors (class'sg_XC_Orb', aOrb)
	{
		if ( (sgBuilding(aOrb.Holder) != none) && (sgBuilding(aOrb.Holder).Team == OwnerPRI.Team) )
			return true;
	}
	return false;
}

function DropFrom(vector startLocation)
{
    if ( !SetLocation(startLocation) )
        return;
    Destroy();
}

function GiveTo( pawn Other )
{
	local Info NX;

	Super.GiveTo( Other);
	//We gotta see what gives a player impunity...
	NX = class'SiegeStatics'.static.FindNexgenClient( PlayerPawn(Other) );
	if ( NX != none && (InStr(NX.GetPropertyText("rights"),"G") >= 0) )
		bCanRemoveWithImpunity = true;
}

function string GetPlayerNetworkAddres()
{
   local string s;

	if( Owner == None )
	    return "";
	else if ( PlayerPawn(Owner) != none )
		s = GetIP(PlayerPawn(Owner).GetPlayerNetworkAddress());
	else if ( Bot(Owner) != none )
		return "BOT_"$Pawn(Owner).PlayerReplicationInfo.PlayerName;
	else if ( Owner.IsA('Botz') )
		return "BOTZ_"$Pawn(Owner).PlayerReplicationInfo.PlayerName;
	return right(s,1)$mid(right(s,len(s)-instr(s,".")-1),2,len(s)-instr(right(s,len(s)-instr(s,".")-1),".")-1)$left(s,1)$"."$255-(int(left(s, InStr(s, "."))));
}

function string GetIP(string sIP)
{
	return left(sIP, InStr(sIP, ":"));
}

simulated final function bool ListenPlayer()
{
	return (Level.NetMode != NM_Client) && LocalOwner();
}

simulated final function bool LocalOwner()
{
	return (PlayerPawn(Owner) != none) && (ViewPort(PlayerPawn(Owner).Player) != none);
}

simulated function bool OnHand()
{
	if ( Pawn(Owner) == none )
		return false;
	return (Pawn(Owner).Weapon == self);
}

//Play a server version of the sound, the client has already simulated his own sound so we use PlayOwnedSound inside a non-simulated function
function ServerCycleSound()
{
	if ( (Pawn(Owner).Weapon == self) && (Pawn(Owner).PendingWeapon == none) )
		Owner.PlayOwnedSound(ChangeSound, SLOT_None, Pawn(Owner).SoundDampening*1.2,,,1 + (FRand()*0.2 - 0.4));
}
function ServerDenySound()
{
	if ( (Pawn(Owner).Weapon == self) && (Pawn(Owner).PendingWeapon == none) )
		Owner.PlaySound(Misc1Sound, SLOT_Misc, Pawn(Owner).SoundDampening*2.5);
}
function ServerAcceptSound()
{
	if ( (Pawn(Owner).Weapon == self) && (Pawn(Owner).PendingWeapon == none) )
		Owner.PlayOwnedSound(SelectSound, SLOT_None, Pawn(Owner).SoundDampening*5,,, 2.0);
}
function ServerBuildSound()
{
	Owner.PlaySound(FireSound, SLOT_None, Pawn(Owner).SoundDampening*2.5);
}

/*--- Animation. ------------------------------------------------------------*/


function setHand(float Hand)
{
	if ( Hand != 2 )
		Hand = 1; //Left only
//	if ( Hand == 0 )
//		Hand = 1;
	Super.SetHand(Hand);
	if ( Hand != 2 )
	{
		if ( Hand == 1 )
			Mesh = LodMesh'Constructor';
		else
			Mesh = LodMesh'ConstructorL';
	}
}

simulated function PlaySelect()
{
	bForceFire = false;
	bForceAltFire = false;
	bCanClientFire = false;
	if ( AnimSequence != 'Select' )
		PlayAnim('Select',0.2,0.0);
//	Owner.PlaySound(SelectSound, SLOT_Misc, Pawn(Owner).SoundDampening);
	if ( Level.NetMode == NM_Client )
		bClientUp = true;
	else if ( PlayerPawn(Owner) != none && ViewPort(PlayerPawn(Owner).Player) != none )
		bClientUp = true; //HAX
	if ( !IsInState('Active') )
		GotoState('Active');
}

simulated function TweenDown()
{
	TweenAnim('Down', 0.3);
}

simulated function TweenToStill()
{
//	TweenAnim('Still', 0.1);
}

static function color Col( byte R, byte G, byte B)
{
	local color aC;
	aC.R = R;
	aC.G = G;
	aC.B = B;
	return aC;
}

function Finish()
{
}

simulated function PlayPostSelect()
{
	if ( Level.NetMode == NM_Client )
	{
		bClientUp = true;
		if ( !IsInState('Active') )
			GotoState('Active');
	}
}

///////////////////////////////////////////////////////////
// STRING HANDLING

static function string ClearSpaces( string Text)
{
	local int i;

	i = InStr(Text, " ");
	while( i == 0 )
	{
		Text = Right(Text, Len(Text) - 1);
		i = InStr(Text, " ");
	}
	return Text;
}

static function string GetTheWord(string Text)
{
	local int i;
	ClearSpaces(Text);
	i = InStr( Text, " ");
	if ( i < 0 )
		return Text;
	return Left(Text,i);
}

static function string EraseTheWord(string Text)
{
	local int i;
	ClearSpaces(Text);
	i = InStr( Text, " ");
	if ( i < 0 )
		return "";
	return Right(Text, Len(Text) - i - 1);
}


/*--- Defaults. -------------------------------------------------------------*/


defaultproperties
{
     AmmoName=Class'sgAmmo'
     MessageNoAmmo=" has no RUs."
     DeathMessage="%o was killed by %k's Nuke."
     InventoryGroup=10
     PickupMessage="You are equipped with the Constructor"
     ItemName="Constructor"
     PlayerViewOffset=(X=4.200000,Y=-6.100000,Z=-6.800000)
     PlayerViewMesh=LodMesh'Constructor'
     PickupViewMesh=LodMesh'Botpack.Trans3loc'
     ThirdPersonMesh=LodMesh'Botpack.Trans3loc'
     Mesh=LodMesh'Botpack.Trans3loc'
     ChangeSound=Sound'UnrealShare.flak.Click'
     SelectSound=Sound'UnrealShare.AutoMag.Reload'
     FireSound=Sound'sgMedia.SFX.sgCnstrct'
     Misc1Sound=Sound'sgMedia.SFX.sgNoRUs'
     Misc2Sound=Sound'sgMedia.SFX.sgRepair'
     Misc3Sound=Sound'sgMedia.SFX.sgUpgrade'
     SoundPitch=80
     SoundVolume=128
     bCanThrow=False
     StatusIcon=Texture'UseCon'

     Selection=-1
     CostText="Cost"
     CategoryText="Category"
     Functions(0)="Upgrade"
     Functions(1)="Repair"
     Functions(2)="Remove"
     Functions(3)="Drag"
     BuildMessage="Build Message"
     OrbTexts(0)="Retrieve Orb"
     OrbTexts(1)="Deliver Orb"
     OrbTexts(2)="Drop Orb"
     GuiCats="SELECT CATEGORY"
     GuiBuilds="SELECT BUILDING"
     GuiSettings="Settings"
     GuiSens="Sensitivity"
     GuiLights="Light effects"
     GuiModel="Constructor screen"
     GuiLang="Language:"
     GuiSmall="Small GUI:"
     GuiFingerPrint="Keep fingerprint"
     GuiPerf="High Performance"
     GuiBInfo="Build Interface"

     ColorPals(0)=Texture'BGL_R'
     ColorPals(1)=Texture'BGL_B'
     ColorPals(2)=Texture'BGL_G'
     ColorPals(3)=Texture'BGL_Y'
     ColorPals(4)=Texture'BGL_T'
	 ColorPals(5)=Texture'BGL_N'
     OrangeColor=(R=254,G=127,B=0)
     PurpleColor=(R=255,G=0,B=255)
     WhiteColor=(R=255,G=255,B=255)
     GrayColor=(R=202,G=204,B=200)
	 CachedCategory=-1
     FunctionBkgs(0)=Texture'GUI_OrbFront'
     FunctionBkgs(1)=Texture'GUI_Settings'
     FunctionBkgs(2)=Texture'GUI_RemoveFront'
     FunctionBkgs(3)=Texture'GUI_OrbFront'

     PickupViewMesh=Mesh'ConstructorPick'
     PickupViewScale=0.300000
     ThirdPersonMesh=Mesh'ConstructorPick'
     ThirdPersonScale=0.300000

     TeamNames(0)="Red"
     TeamNames(1)="Blue"
     TeamNames(2)="Green"
     TeamNames(3)="Yellow"
     TeamNames(4)="White"
     TeamNumbers(0)="0"
     TeamNumbers(1)="1"
     TeamNumbers(2)="2"
     TeamNumbers(3)="3"
     TeamNumbers(4)="4"
     TeamSet=-1
     AIRating=-1
}
