//=============================================================================
// WildcardsOrbs.
// The base of all the orbs in SiegeUltimateRC6
//
// Null Orb - When attached to a building prevents the enemy from earning ru 
// for attacking it
//
// Gotta deprecate this one day... without losing the idea of the Null Orb - HIGOR
//=============================================================================
class WildcardsOrbs expands Actor;

var() string OrbName;
var() float OrbScale;
var() sound OrbSoundPickup;
var() sound OrbSoundDrop;
var() sound OrbSoundDelivered;
var() string PickupMessage;
var() color PickupMessageColor;

var WildcardsOrbFx AttachedMeshes[7];
var Pawn OrbHolder;
var int Elevation;

// Lots of Debug Info
var vector ServerLocation;
var vector ClientLocation;
var Pawn ServerOrbHolder;
var Pawn ClientOrbHolder;
var Bool ServerLanded;
var Bool ClientLanded;
var String ServerPhysics;
var String ClientPhysics;

// Ugh.... Replication... My least favorite thing to work with Q.Q
replication
{
    reliable if ( Role == ROLE_Authority )
		ClientPickupOrb, ClientSettle, ServerLanded, ServerLocation, ServerOrbHolder, Elevation, OrbName, OrbScale, 				AttachedMeshes, PickupMessage, PickupMessageColor, ClientFunction, ServerPhysics, ClientDrop;
    reliable if ( Role < ROLE_Authority )
        ClientLocation, ClientOrbHolder, ServerFunction, ClientPhysics;
}

function ServerFunction( int number )
{
	log("(ServerFunction() should run on the SERVER)");
	log("Orb: ServerFunction()"@number);
}

simulated function DropHarder()
{
	if ( Role < ROLE_Authority )
		log("CLIENT: DropHarder() Called");
	else
		log("SERVER: DropHarder() Called");	

	ClientDrop();
}

simulated function ClientFunction( int number )
{
	log("(ClientFunction() should run on the CLIENT)");
	log("Orb: ClientFunction()"@number);
}

simulated event PostBeginPlay()
{
	// EXPLANATION: There is no reason the orb meshes should exist on server!! there just decorations!!
	if ( Role < ROLE_Authority )
		CreateMeshes();

	if ( Role < ROLE_Authority )
		ServerPhysics = "Server Physics Initial Value";
	else
		ClientPhysics = "Client Physics Initial Value";

	ClientFunction(1);
	ServerFunction(1);

}

simulated event Touch( actor Other )
{

	ClientFunction(2);
	ServerFunction(2);

/*
	if ( Role == ROLE_Authority )
		log("SERVER Touch(1): Touch() event executed");

	if ( Role == ROLE_Authority )
		log("SERVER Touch(2): OrbHolder = "@OrbHolder);

	if ( Role == ROLE_Authority )
		log("SERVER Touch(3): sgBuilding(Other) = "@sgBuilding(Other));

	if ( Role == ROLE_Authority )
		log("SERVER Touch(4): Pawn(Other) = "@Pawn(Other));
*/

	if ( OrbHolder == None && sgBuilding(Other) == None && Pawn(Other) != None )
		{
			if ( Role == ROLE_Authority )
				log("SERVER Touch(5): Orb = "@sgPRI(Pawn(Other).PlayerReplicationInfo).Orb);

			log("sgPRI(Pawn(Other).PlayerReplicationInfo).Orb"@sgPRI(Pawn(Other).PlayerReplicationInfo).Orb);

			if ( sgPRI(Pawn(Other).PlayerReplicationInfo).Orb != None )
				{
					sgPRI(Pawn(Other).PlayerReplicationInfo).Orb.
					DisplayMessage("You can only carry one orb at a time!",MakeColor(255,255,255));

				}
			else
				{
					PickupOrb(pawn(Other));
					ClientPickupOrb(pawn(Other));
				}
		}

}

simulated event Tick( float DeltaTime )
{
	local int i;

	if ( Role == ROLE_Authority )
		ServerPhysics = string(Physics);
	else
		{
			// This is kinda ugly but will force physics to sync
		//	if ( ServerPhysics == "2" )
		//		SetPhysics(PHYS_Falling);
		//	ClientPhysics = string(Physics);
		}

	// Meshes Follow orb while it's falling
	if ( Role < ROLE_Authority /* && Physics == PHYS_Falling */ )
		{
			for ( i = 0; i != 4; i++ )
				{
					if ( i == 3 )
						{
							AttachedMeshes[i].SetLocation(ServerLocation);
						}
					else
						AttachedMeshes[i].SetLocation(Location);
				}
		}

	if ( Role == ROLE_Authority )
		ServerLocation = location;
	else
		ClientLocation = Location;

	if ( Role == ROLE_Authority )
		ServerOrbHolder = OrbHolder;
	else
		ClientOrbHolder = OrbHolder;

	OrbHolder = ServerOrbHolder;

	if ( OrbHolder != None )
		{
			bCollideWorld = false;
			bCollideWhenPlacing = false;
			SetPhysics(PHYS_None);

			if ( sgBuilding(OrbHolder) == None )
				Elevation = 56; // Set the orb a little above the Players head.	
			else
				Elevation = 0; // So the orb stays centered

			FollowPlayer();

			if ( sgBuilding(OrbHolder) == None )
				{
					if ( OrbHolder.bIsPlayer != true || OrbHolder.Health <= 0 || OrbHolder.PlayerReplicationInfo == None ||
          			OrbHolder.PlayerReplicationInfo.bIsSpectator == true ||
					sgPRI(OrbHolder.PlayerReplicationInfo).orb == none )
						 DropOrb();
				}
		}
}

simulated function FollowPlayer()
{
	local int i;
	local vector destination;

	destination.x = OrbHolder.location.x;
	destination.y = OrbHolder.location.y;
	destination.z = OrbHolder.location.z+Elevation;
	SetLocation(destination);

/*
	SetPhysics(PHYS_Trailer);
	bTrailerPrePivot = true;
	PrePivot.z = Elevation;
*/

	// No Servers beyond this point
	if ( Role == ROLE_Authority )
		return;

	// Make the orb's meshes follow the orb
	for ( i = 0; i != 3; i++ )
		{
			AttachedMeshes[i].SetLocation(Location);
		}

}

simulated function ClientPickupOrb( Pawn Other )
{
	log("Only LOG ON CLIENT");
	PickupOrb( Other );

	ClientFunction(3);
	ServerFunction(3);
}

simulated function PickupOrb( Pawn Other )
{

	ClientFunction(4);

	if ( Role == ROLE_Authority )
		log("SERVER: Executed the PickupOrb() function");

	// Stupid things happen when the orb is thrown at a building rather than delivered.
	if ( sgBuilding(Other) != None )
		return;

	// Orb now belongs to the player who picked it up.
	OrbHolder = Other;

	if ( Role == ROLE_Authority )
		log("SERVER: OrbHolder = "@OrbHolder);

	sgPRI(OrbHolder.PlayerReplicationInfo).Orb = Self;

	if ( Role == ROLE_Authority )
		log("SERVER: Orb = "@sgPRI(OrbHolder.PlayerReplicationInfo).Orb);

	SetTimer(3,false);
	
	PlaySound(OrbSoundPickup);

	// I have no idea why I have to send a client message in order to get the message colors
	// to work correctly but if I wasted time trying to figure out why, this mod would never 
	// get done!
	if ( Role < ROLE_Authority )
		OrbHolder.ClientMessage("",'CriticalEvent');

	// AutoSelect For the players convience!
	if ( sgConstructor(OrbHolder.Weapon) != None );
		sgConstructor(OrbHolder.Weapon).SetMode(3,0);

	// So the orb won't block the players sight.
	// Were no longer the ownser so don't hide the orb from us!
	bOwnerNoSee = true;
	
	if ( Role < ROLE_Authority )
		{
			AttachedMeshes[0].bOwnerNoSee = true;
			AttachedMeshes[1].bOwnerNoSee = true;
			AttachedMeshes[2].bOwnerNoSee = true;
			AttachedMeshes[3].bOwnerNoSee = true;
		}

	// Then the player becomes the new Owner
	SetOwner(OrbHolder);

	if ( Role < ROLE_Authority )
		{
			AttachedMeshes[0].SetOwner(OrbHolder);
			AttachedMeshes[1].SetOwner(OrbHolder);
			AttachedMeshes[2].SetOwner(OrbHolder);
			AttachedMeshes[3].SetOwner(OrbHolder);
		}

	default.PickupMessage = "Modified Before Xecution of function";
	DisplayMessage("OrbHolder Name is... "$sgPRI(OrbHolder.PlayerReplicationInfo).PlayerName,
	MakeColor(255,0,0));
}

simulated function DeliverOrb(sgBuilding Building)
{
	PlaySound(OrbSoundDelivered);

	DisplayMessage(OrbName$" delivered to: "$Building.BuildingName,MakeColor(0,255,0));
	OrbHolder = Building;

	Building.RuRewardScale = 0;

	// Were no longer the ownser so don't hide the orb from us!
	bOwnerNoSee = false;
	AttachedMeshes[0].bOwnerNoSee = false;
	AttachedMeshes[1].bOwnerNoSee = false;
	AttachedMeshes[2].bOwnerNoSee = false;
	AttachedMeshes[3].bOwnerNoSee = false;

	// Also the building we delivered the orb to becomes the new owner
	SetOwner(Building);
	AttachedMeshes[0].SetOwner(Building);
	AttachedMeshes[1].SetOwner(Building);
	AttachedMeshes[2].SetOwner(Building);
	AttachedMeshes[3].SetOwner(Building);

	// Also let's resize the orb a litle so we can still see the building it's inside
	OrbScale = Building.SpriteScale/2;

	DrawScale = Default.DrawScale*OrbScale;
	AttachedMeshes[0].DrawScale = 8*OrbScale;
	AttachedMeshes[1].DrawScale = 8*OrbScale;
	AttachedMeshes[2].DrawScale = 0.700000*OrbScale;
	AttachedMeshes[3].DrawScale = 0.700000*OrbScale;
}

simulated event landed( vector HitNormal )
{
	if ( Role < ROLE_Authority )
		SetLocation(ServerLocation);		
}

/*
simulated event landed( vector HitNormal )
{

	ClientFunction(5);
	ServerFunction(5);

	if ( Role < ROLE_Authority )
		ClientLanded = true;
	else
		ServerLanded = true;

	if ( Role == ROLE_Authority )
		{
			ServerLocation = Location;
			if ( ServerLanded == true && ClientLanded == false && ClientLocation != ServerLocation )
				{
					log("We need to settle the orb!");
					ClientSettle(location);
				}
		}
	else
		SetLocation(ServerLocation);
		
}
*/

function ClientSettle(vector LocationParameter)
{
	ClientFunction(6);
	ServerFunction(6);
	log("This should not happen on the server");
	SetLocation(LocationParameter);
}

simulated function ClientDrop()
{
	SetPhysics(PHYS_Falling);

	if ( Role < ROLE_Authority )
		log("CLIENT: ClientDrop() Called");
	else
		log("SERVER: ClientDrop() Called");	
}

simulated function DropOrb()
{
	if ( Role < ROLE_Authority )
		log("Orb Dropped on Client");
	else
		log("Orb Dropped on Server");

	if ( Role == ROLE_Authority )
		DropHarder();

	if ( Role == ROLE_Authority )
		ServerLocation = location;
	else
		ClientLocation = Location;

	// if ( Role < ROLE_Authority )
		// SetLocation(ServerLocation);

	SetPhysics(PHYS_Falling);
	bCollideWhenPlacing = true;
	bCollideWorld = true;

	PlaySound(OrbSoundDrop);
	Velocity = Vector(OrbHolder.ViewRotation) * 500 + vect(0,0,220);
	
	SetOwner(None);

	if ( Role < ROLE_Authority )
		{
			AttachedMeshes[0].SetOwner(None);
			AttachedMeshes[1].SetOwner(None);
			AttachedMeshes[2].SetOwner(None);
			AttachedMeshes[3].SetOwner(None);
		}

	if ( sgPRI(OrbHolder.PlayerReplicationInfo) != None )
		sgPRI(OrbHolder.PlayerReplicationInfo).Orb = None;

	// Return to default scale
	OrbScale = Default.OrbScale;
	DrawScale = Default.DrawScale*OrbScale;

	if ( Role < ROLE_Authority )
		{
			AttachedMeshes[0].DrawScale = 8*OrbScale;
			AttachedMeshes[1].DrawScale = 8*OrbScale;
			AttachedMeshes[2].DrawScale = 0.700000*OrbScale;
			AttachedMeshes[3].DrawScale = 0.700000*OrbScale;
		}

	// Last, Nobody is holding this Orb!
	OrbHolder = None;
}



simulated event Timer()
{
	DisplayMessage("Deliver the Orb to a building or hang on to it!",MakeColor(0,255,0));
}

simulated function DisplayMessage(string MessageText, color MessageColor)
{
	if ( Role < ROLE_Authority )
	{
		sgHUD(PlayerPawn(OrbHolder).MyHUD).SpecialMessageColor = MessageColor;
		OrbHolder.ClientMessage(MessageText,'Custom');
	}
}

function AnnounceToPawn(Pawn AnnounceTo, string sMessage)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( p==AnnounceTo && p.PlayerReplicationInfo != None  )
		    AnnounceTo.ClientMessage(sMessage);
}

simulated function Color MakeColor(byte R, byte G, byte B, optional byte A)
{
	local Color C;

	C.R = R;
	C.G = G;
	C.B = B;
	if ( A == 0 )
		A = 255; 
	C.A = A; 
	return C;
}

simulated function CreateMeshes()
{
	local int i;

	DrawScale = Default.DrawScale*OrbScale;
	SetOwner(None);

	// ORB RINGS #1
	i = 0;
	AttachedMeshes[i] = Spawn(class'WildcardsOrbFx',Self,,,rotator(vect(-16388,0,0)));
	AttachedMeshes[i].bMeshEnviroMap = false;
	AttachedMeshes[i].Mesh = LodMesh'UnrealShare.Ringex';
	AttachedMeshes[i].MultiSkins[0] = FireTexture'OrbNullRing';
	AttachedMeshes[i].DrawScale = 8*OrbScale;
	AttachedMeshes[i].RotationRate.Pitch = 30000;
	AttachedMeshes[i].RotationRate.Roll = 0;
	AttachedMeshes[i].RotationRate.Yaw = 0;
	AttachedMeshes[i].SetOwner(None);
	// ORB RINGS #2
	i++;
	AttachedMeshes[i] = Spawn(class'WildcardsOrbFx',Self,,,rotator(vect(0,0,0)));
	AttachedMeshes[i].bMeshEnviroMap = false;
	AttachedMeshes[i].Mesh = LodMesh'UnrealShare.Ringex';
	AttachedMeshes[i].MultiSkins[0] = FireTexture'OrbNullRing';
	AttachedMeshes[i].DrawScale = 8*OrbScale;
	AttachedMeshes[i].RotationRate.Pitch = 0;
	AttachedMeshes[i].RotationRate.Roll = 0;
	AttachedMeshes[i].RotationRate.Yaw = 30000;
	AttachedMeshes[i].SetOwner(None);
	// ORB SPHERE
	i++;
	AttachedMeshes[i] = Spawn(class'WildcardsOrbFx',Self,,,rotator(vect(0,0,0)));
	AttachedMeshes[i].Mesh = LodMesh'Botpack.ShockWavem';
	AttachedMeshes[i].Texture = WetTexture'OrbNullSkin';
	AttachedMeshes[i].DrawScale = 0.700000*OrbScale;
	AttachedMeshes[i].RotationRate.Pitch = 0;
	AttachedMeshes[i].RotationRate.Roll = 0;
	AttachedMeshes[i].RotationRate.Yaw = 0;
	AttachedMeshes[i].SetOwner(None);
	// SERVER SPHERE ( HARDCORE DEBUGING!! )
	i++;
	AttachedMeshes[i] = Spawn(class'WildcardsOrbFx',Self,,,rotator(vect(0,0,0)));
	AttachedMeshes[i].Mesh = LodMesh'Botpack.ShockWavem';
	AttachedMeshes[i].Texture = Texture'CoreSkinTeam0';
	AttachedMeshes[i].DrawScale = 0.700000*OrbScale;
	AttachedMeshes[i].RotationRate.Pitch = 0;
	AttachedMeshes[i].RotationRate.Roll = 0;
	AttachedMeshes[i].RotationRate.Yaw = 0;
	AttachedMeshes[i].SetOwner(None);
}

simulated event Destroyed()
	{
		AttachedMeshes[0].Destroy();
		AttachedMeshes[1].Destroy();
		AttachedMeshes[2].Destroy();
		AttachedMeshes[3].Destroy();
	}

defaultproperties
{
     OrbName="Null Orb"
     OrbScale=0.500000
     OrbSoundPickup=Sound'OrbNullPickup'
     OrbSoundDrop=Sound'OrbNullThrow'
     OrbSoundDelivered=Sound'OrbNullDelivered'
     PickupMessage="YOU SALL NEVER SEE THIS!!! <default variable>"
     PickupMessageColor=(R=255,B=128)
     bOwnerNoSee=True
     bAlwaysRelevant=True
     RemoteRole=ROLE_SimulatedProxy
     Style=STY_Translucent
     Texture=WetTexture'OrbNullSpriteWave'
     DrawScale=0.750000
     CollisionRadius=32.000000
     CollisionHeight=32.000000
     bCollideActors=True
     LightType=LT_Steady
     LightEffect=LE_FastWave
     LightBrightness=255
     LightSaturation=255
     LightRadius=12
     LightPeriod=32
     LightCone=128
     VolumeBrightness=64
     NetPriority=3.000000
}
