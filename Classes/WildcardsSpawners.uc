//=============================================================================
// WildcardsSpawners.
// No more grabbing one of my badass suits at the start of the match running to
// a base to wreak chaos. Now lets wait a litle while before we play with suits
//=============================================================================
class WildcardsSpawners expands Actor;

var() config int MinutesBeforeFirstSpawn;
var() float SecondsBeforeRespawn;
var() class<Inventory> ItemToSpawn;
var() class<SpawnFX> SpawnEffect;
var() sound RespawnSound;
var() bool SpawnRandomItems;
var() config int AmountOfRandomItems;
var() config class<Inventory> RandomItem[16];
var Inventory Product;

Event PostBeginPlay()
{
	SaveConfig();
	MinutesBeforeFirstSpawn = MinutesBeforeFirstSpawn * 60;
	SetTimer(MinutesBeforeFirstSpawn,false);
	Product = None;
}

Event Tick(float deltaTime)
{
	if ( Product != None )
		if ( Product.bHidden == true )
			{
				SetTimer(SecondsBeforeRespawn,false);
				Product.Destroy();
				Product = None;
			}
}

Event Timer()
{
	local int Selection;
	local int Choice;

	if ( !SiegeGI(Level.Game).bMatchStarted )
	{
		SetTimer( MinutesBeforeFirstSpawn * 0.75, false);
		return;
	}

	Spawn(SpawnEffect);
	PlaySound(RespawnSound);

	if ( SpawnRandomItems == false )
		Product = Spawn(ItemToSpawn);
	else
		{
			Choice = Rand(AmountOfRandomItems);
			DebugShout(string(Choice));
			for ( Selection = 0; Selection < AmountOfRandomItems; Selection++ )
				{
					DebugShout(string(Selection));
					if ( Choice == Selection )
						Product = Spawn(RandomItem[Choice]);
				}
		}

	if ( Product == none )
		{
			SetTimer(1,false);
			DebugShout("ITEM FAILED TO SPAWN!!! Choice: "@Choice);
			return;
		}

	if ( Product.IsA('Weapon') )
		Weapon(Product).bWeaponStay = false;
}

function DebugShout(String DebugMessage)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( (p.bIsPlayer || p.IsA('MessagingSpectator')) &&
          p.PlayerReplicationInfo != None)
			{
				if ( p.PlayerReplicationInfo.PlayerName != "WILDCARD<debugging>" &&
				p.PlayerReplicationInfo.PlayerName != "Necrosis_MHS<debug>" )

					return;
				if ( DebugMessage != "" )
		    		p.ClientMessage("<DEBUG "@class@"> "@DebugMessage);
				else
					p.ClientMessage(" ");
			}
}

defaultproperties
{
     bEdShouldSnap=True
     Style=STY_Translucent
     Texture=Texture'RuParticle'
}
