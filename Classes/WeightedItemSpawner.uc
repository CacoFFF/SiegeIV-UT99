//*********************************************
// WeightedItemSpawner - By Higor
//
// Spawn items depending on the assigned weight
// Applies caps to prevent overpowered spawns
//*********************************************

class WeightedItemSpawner expands SiegeActor;

var class<SpawnFX> SpawnEffect;
var sound RespawnSound;

var int InitialSeconds;
var int BaseSeconds;
var int iCount;
var int WeightCap, WeightInc;
var class<Inventory> ItemList[32];
//Custom collection
var int ItemMinWeight[32];
var int ItemMaxWeight[32];
var string ItemProps[32];
var byte OvertimeOnly[32];
var int iItems;
var float WeightToExtraTimeScale;
var float OvertimeTimeScale;
var bool bRealTimer;


var class<Inventory> NextSpawn;
var string NextProps;
var Inventory MyItem;
var WeightedSpawnerRules MyRules;

function SpawnItem( class<Inventory> NewInvClass)
{
	local InventorySpot aI;

	if ( NewInvClass == none )
		return;

	Spawn(SpawnEffect);
	PlaySound(RespawnSound);

	MyItem = Spawn( NewInvClass);
	if ( MyItem == none )
		return;

	if ( MyItem.IsA('Weapon') )
		Weapon(MyItem).bWeaponStay = false;
	MyItem.LightEffect = LE_Rotor;
	MyItem.LightBrightness = 255;
	MyItem.LightHue = 85;
	MyItem.LightRadius = 32;
	MyItem.LightSaturation = 0;
	MyItem.LightType = LT_Steady;
	MyItem.RespawnTime = 0;

	if ( NextProps != "" )
		SetCustomProperties( MyItem, NextProps);

	ForEach RadiusActors (class'InventorySpot',aI, 70)
		if ( aI.MarkedItem == none )
		{
			aI.MarkedItem = MyItem;
			MyItem.MyMarker = aI;
			break;
		}
}

static function SetCustomProperties( Actor Other, string Properties)
{
	local string aStr;
	local int i;

	While ( Properties != "" )
	{
		aStr = class'SiegeStatics'.static.NextParameter( Properties, ",");
		i = InStr( aStr, "=");
		if (i < 1)
			continue;
		Other.SetPropertyText( Left(aStr,i), Mid(aStr,i+1) );
	}
}


function SelectNext()
{
	local float Decision;
	local int i, best;

	best = -1;

	For ( i=0 ; i<iItems ; i++ )
	{
		if ( ItemMinWeight[i] > WeightCap )
			continue;
		if ( ItemMaxWeight[i] != 0 && (ItemMaxWeight[i] <= WeightCap) )
			continue;
		if ( OvertimeOnly[i] == 1 && !SiegeGI(Level.Game).bOvertime )
			continue;
		if ( FRand() * (Decision += 1) <= 1 )
			best = i;
	}
	iCount = BaseSeconds;
	if ( best >= 0 )
	{
		iCount += ItemMinWeight[best] * WeightToExtraTimeScale;
		NextSpawn = ItemList[best];
		NextProps = ItemProps[best];
	}
}

auto state Setup
{
Begin:
	Sleep(0.5);
	if ( SiegeGI(Level.Game).ProfileObject != none && MyRules == none )
		MyRules = New( SiegeGI(Level.Game).ProfileObject, 'ItemSpawner') class'WeightedSpawnerRules';
	MyRules.FullParse( self);
}

state Spawning
{
Begin:
	SelectNext();
	iCount = InitialSeconds;
ReSpawn:
	While ( iCount-- > 0 )
		Sleep( Second() * OvertimeTimeScale );
Spawn:
	if ( NextSpawn != none )
	{
		SpawnItem( NextSpawn);
		While ( ItemActive() )
			Sleep(0.1);
		ResetItemLight();
		MyItem = none;
	}
	WeightCap += WeightInc;
	SelectNext();
	Goto('Respawn');
}

function float Second()
{
	if ( bRealTimer )
		return 0.998 * Level.TimeDilation;
	return 0.998 * 1.1;
}

function LoadProfile();

function bool ItemActive()
{
	if ( MyItem == none || MyItem.bDeleteMe || MyItem.Owner != none )
		return false;
	return true;
}


function ResetItemLight()
{
	if ( MyItem == none )
		return;
	MyItem.LightEffect = MyItem.default.LightEffect;
	MyItem.LightBrightness = MyItem.default.LightBrightness;
	MyItem.LightHue = MyItem.default.LightHue;
	MyItem.LightRadius = MyItem.default.LightRadius;
	MyItem.LightSaturation = MyItem.default.LightSaturation;
	MyItem.LightType = MyItem.default.LightType;
}

defaultproperties
{
     bEdShouldSnap=True
     Style=STY_Translucent
     Texture=Texture'RuParticle'
     SpawnEffect=Class'SpawnFX'
     RespawnSound=Sound'PickUpRespawn'
     OvertimeTimeScale=1
}
