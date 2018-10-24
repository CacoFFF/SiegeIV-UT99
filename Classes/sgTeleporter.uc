// ************************************
// sgTeleporter written by nOs*Badger
// Optimized by Higor
// ************************************


class sgTeleporter extends sgBuilding;

var() string URL1;
var bool bHasOtherTele;
var bool bUseBotz;
var NavigationPoint BotzNavig;
var sgTeleporter OtherTele;
var PlayerPawn LocalPlayer;
var Pawn Accepted;

// Teleporter flags
var() bool    bEnabled;         // Teleporter is turned on;
var vector TargetLoc, TelenetLoc; //For client replication of teles

//-----------------------------------------------------------------------------
// Teleporter destination directions.
var() vector  TargetVelocity;   // If bChangesVelocity, set target's velocity to this.

// AI related
var Pawn TriggerPawn;     //used to tell AI how to trigger me
var Pawn TriggerPawn2;

var float LastFired;

//-----------------------------------------------------------------------------
// Teleporter destination functions.

replication
{
    reliable if( Role==ROLE_Authority )
        URL1, TargetLoc, TelenetLoc;
}


//**************************************
// Flags:
// 0x00000100 = bEnabled
// 0x00000200 = bHasOtherTele
function PackStatusFlags()
{
	Super.PackStatusFlags();
	if ( bEnabled )			PackedFlags += 0x00000100;
	if ( bHasOtherTele )	PackedFlags += 0x00000200;
}
simulated function UnpackStatusFlags()
{
	Super.UnpackStatusFlags();
	bEnabled		= (PackedFlags & 0x00000100) != 0;
	bHasOtherTele	= (PackedFlags & 0x00000200) != 0;
}


//First event in creation order
event Spawned()
{
	local WildCardsSuperContainer SC;
	local sgTeleporter aTele;
	local Teleporter Tele;
	local byte aTeam;
	local float Dist;

	Super.Spawned();

	if (Pawn(Owner) == none)
		aTeam = 0;
	else
		aTeam = Pawn(Owner).PlayerReplicationInfo.Team;

	ForEach RadiusActors (class'sgTeleporter', aTele, 80)
		if ( (aTele != self) && (aTele.Team == aTeam) && class'SiegeStatics'.static.ActorsTouchingExt(self,aTele, 2, 8) )
		{
			Destroy();
			return;
		}
	ForEach RadiusActors (class'WildCardsSuperContainer', SC, 100)
		if ( class'SiegeStatics'.static.ActorsTouching(self,SC) )
		{
			Destroy();
			return;
		}
	ForEach AllActors (class'Teleporter', Tele)
		if ( (Tele.URL != "") && class'SiegeStatics'.static.ActorsTouchingExt(self,Tele, 2, 8) )
		{
			Destroy();
			return;
		}

	if ( SiegeGI(Level.Game) != none )
		bUseBotz = SiegeGI(Level.Game).bUseBotz;
}


function SetOwnership()
{
	Super.SetOwnership();
	bOnlyOwnerRemove = true;
}


simulated event PostBuild()
{
	Super.PostBuild();
	URL1=GetTeleporterName();
}

simulated event Timer()
{
	Super.Timer();

	if ( Level.NetMode != NM_DedicatedServer )
	{
		if ( LocalPlayer == none )
			LocalPlayer = FindLocalPlayer();
		else if ( (LocalPlayer.PlayerReplicationInfo != none) && (LocalPlayer.PlayerReplicationInfo.Team == Team) )
			TeleporterGraphics();
		else
			TeleporterGraphics( true);
	}

	if ( SCount > 0 || Role != ROLE_Authority )
        	return;

	if ( Accepted != none )
	{
		if ( Accepted.bDeleteMe || !Class'SiegeStatics'.static.ActorsTouching(Accepted, self) )
		{
			Accepted = none;
			if ( BotzNavig != none )
				BotzNavig.taken = false;
		}
	}
	
	if ( OtherTele != none )
		TargetLoc = OtherTele.Location;
	else
	{
		TargetLoc = vect(0,0,0);
		if ( Owner == none || Owner.bDeleteMe )
			bOnlyOwnerRemove = false;
	}
}

simulated function string GetTeleporterName()
{
	return sPlayerIP@string(Team);
}

simulated event TakeDamage( int Damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType)
{
	local sgTeleporter teleDest;
	if (damageType != 'sgTeleporter')  
	{
		teleDest=FindOther();
    		if (teleDest!=None)
		teleDest.TakeDamage(Damage/2 , instigatedBy, teleDest.Location, momentum, 'sgTeleporter');	
	}
	Super.TakeDamage(Damage , instigatedBy, hitLocation, momentum, damageType);
}



simulated function FinishBuilding()
{
	Super.FinishBuilding();
	bEnabled=true;
	
	if ( Team == 0 )		Tag = 'sgTeleRed';
	else if ( Team == 1 )		Tag = 'sgTeleGlue';
	else if ( Team == 2 )		Tag = 'sgTeleGreen';
	else if ( Team == 3 )		Tag = 'sgTeleGold';
	else		Tag = 'sgTeleExtra';

	if ( Level.NetMode == NM_Client )
		return;

	OtherTele = FindOther();
	if ( OtherTele != none )
	{
		bHasOtherTele = true;
		OtherTele.OtherTele = self;
		OtherTele.bHasOtherTele = true;
		if ( bUseBotz )
		{
			BotzNavig = Spawn( class<NavigationPoint>( DynamicLoadObject("FerBotz.Botz_TelePath", class'class') ), none );
			OtherTele.BotzNavig = OtherTele.Spawn( class<NavigationPoint>( DynamicLoadObject("FerBotz.Botz_TelePath", class'class') ), none,, OtherTele.Location );
			BotzNavig.Trigger( OtherTele.BotzNavig, self);
			OtherTele.BotzNavig.Trigger( BotzNavig, OtherTele);
		}
	}
}



// Accept an actor that has teleported in.
function bool Accept( actor Incoming, Actor Source )
{
    local rotator newRot, oldRot;
    local int oldYaw;
    local float mag;
    local vector oldDir;
    local pawn P;

    // Move the actor here.
    Disable('Touch');
    //log("Move Actor here "$tag);
	newRot = Incoming.Rotation;

    if ( Pawn(Incoming) != None )
    {
        //tell enemies about teleport
        if ( Role == ROLE_Authority )
        {
            P = Level.PawnList;
            While ( P != None )
            {
                if (P.Enemy == Incoming)
                    P.LastSeenPos = Incoming.Location; 
                P = P.nextPawn;
            }
        }
		SetCollision(  false, false, false);
		if ( !Pawn(Incoming).SetLocation(Location) )
		{
			SetCollision(  true, false, false);
			Enable('Touch');
			return false;
		}
		if ( !FastTrace( Location + vector(newRot) * CollisionRadius * 2) )
			newRot.Yaw += 32768;
		if ( (Role == ROLE_Authority) || (Level.TimeSeconds - LastFired > 0.5) )
		{
			Pawn(Incoming).SetRotation(newRot);
			Pawn(Incoming).ViewRotation = newRot;
			LastFired = Level.TimeSeconds;
			if ( !Incoming.Region.Zone.bWaterZone )
				Incoming.SetPhysics(PHYS_Falling);
		}
		Pawn(Incoming).MoveTimer = -1.0;
		Pawn(Incoming).MoveTarget = self;
		PlayTeleportEffect( Incoming, false);
		SetCollision(  true, false, false);
	}
	else
	{
		if ( !Incoming.SetLocation(Location) )
		{
			Enable('Touch');
			return false;
		}
	}

	Enable('Touch');
	Incoming.Velocity = vect(0,0,-1);

    // Play teleport-in effect.
	Accepted = Pawn(Incoming);
	if ( BotzNavig != none )
		BotzNavig.taken = true;
    return true;
}
    
function PlayTeleportEffect(actor Incoming, bool bOut)
{
    if ( Incoming.IsA('Pawn') )
    {
        Incoming.MakeNoise(1.0);
        Level.Game.PlayTeleportEffect(Incoming, bOut, true);
    }
}

//-----------------------------------------------------------------------------
// Teleporter functions.

function Trigger( actor Other, pawn EventInstigator )
{
    local int i;

    //bEnabled = !bEnabled;
    if ( bEnabled ) //teleport any pawns already in my radius
        for (i=0;i<4;i++)
            if ( Touching[i] != None )
                Touch(Touching[i]);
}


simulated function Touch( actor Other )
{
	local sgTeleporter teleDest;
	local Pawn P;
	local vector TLoc;

	P = Pawn(Other);
	if ( !bEnabled || !Other.bCanTeleport || bDisabledByEMP || (P == none) || (P.PlayerReplicationInfo == none) || (P.PlayerReplicationInfo.Team != Team) || (Other == Accepted) )
		return;

	if ( Level.NetMode == NM_Client )
	{
		if ( !bHasOtherTele )
			return;
		if ( P.FindInventoryType(class'sgTeleNetwork') != none )	TLoc = TeleNetLoc;
		else														TLoc = TargetLoc;
		
		if ( TLoc == vect(0,0,0) )
			return;
		Other.bCanTeleport = false;
		Other.SetLocation( TLoc);
		if ( !FastTrace( Location + vector(P.ViewRotation) * CollisionRadius * 2) )
		{
			P.ViewRotation.Yaw += 32768;
			P.ClientSetRotation( Pawn(Other).ViewRotation); //Should this be used?
		}
		Other.bCanTeleport = true;
		return;
	}

	teleDest=FindOther(P);

	if( teleDest != None && teleDest.bEnabled)
	{
		// Teleport the actor into the other teleporter.
		PlayTeleportEffect( P, false);

		if ( teleDest.Accept( P, self ) && (sgPRI(P.PlayerReplicationInfo) != none) )
			sgPRI(P.PlayerReplicationInfo).ProtectCount -= 1.0;
	}

}

function sgTeleporter FindOther(optional Pawn instigator)
{
	local sgTeleporter sgTele;

	if ( (instigator != none) && (instigator.FindInventoryType(class'sgTeleNetwork') != None) )
		return FindNetworkOther();

	if ( OtherTele != none )
		return OtherTele;

	ForEach AllActors ( class'sgTeleporter', sgTele, Tag)
	{
		if ( (sgTele != self) && (sgTele.URL1 == URL1) )
			return sgTele;
	}
	return none;
}

function sgTeleporter FindNetworkOther()
{
	local sgTeleporter sgTele, firstTele;
	local bool bNext;
	ForEach AllActors ( class'sgTeleporter', sgTele, Tag)
	{
		if ( sgTele == self )
		{
			bNext = true;
			continue;
		}
		if ( bNext )
			return sgTele;
		if ( firstTele == none )
			firstTele = sgTele;
	}
	return firstTele;
}

event Destroyed()
{
	Super.Destroyed(); //Just in case...
	if ( OtherTele != none )
	{
		if ( bUseBotz )
		{
			BotzNavig.UnTrigger( none, self);
			OtherTele.BotzNavig.UnTrigger( none, OtherTele);
		}
		OtherTele.OtherTele = none;
		OtherTele.bHasOtherTele = false;
	}
}

simulated function PlayerPawn FindLocalPlayer()
{
	local PlayerPawn P;
	ForEach AllActors (class'PlayerPawn', P)
	{
		if ( (P.Player != none) && (ViewPort(P.Player) != none) )
			return P;
	}
	return none;
}

simulated function TeleporterGraphics( optional bool bReset)
{
	local sgMeshFx theFx;

	if ( myFx == none )
		return;

	if ( bReset )
	{
		if ( myFx.RotationRate == rot(0,0,0) )
		{
			For ( theFx=myFx ; theFx!=none ; theFx=theFx.NextFx )
			{
				theFx.RotationRate.Pitch = Rand(MFXrotX.Pitch);
				theFx.RotationRate.Roll = Rand(MFXrotX.Roll);
				theFx.RotationRate.Yaw = Rand(MFXrotX.Yaw);
				if ( theFx.NextFx == theFx )
					theFx.NextFx = none;
			}
		}
		return;
	}

	if ( bHasOtherTele && (myFx.RotationRate != rot(0,0,0)) )
		return;
	if ( !bHasOtherTele && (myFx.RotationRate == rot(0,0,0)) )
		return;

	For ( theFx=myFx ; theFx!=none ; theFx=theFx.NextFx )
	{
		if ( bHasOtherTele )
		{
			theFx.RotationRate.Pitch = Rand(MFXrotX.Pitch);
			theFx.RotationRate.Roll = Rand(MFXrotX.Roll);
			theFx.RotationRate.Yaw = Rand(MFXrotX.Yaw);
		}
		else
			theFx.RotationRate = rot(0,0,0);
		if ( theFx.NextFx == theFx )
			theFx.NextFx = none;
	}
}



defaultproperties
{
     bNoUpgrade=True
     bOnlyOwnerRemove=True
     BuildingName="Teleporter"
     BuildCost=500
     UpgradeCost=0
     BuildTime=15.000000
     MaxEnergy=2000.000000
     Model=LodMesh'Botpack.Tele2'
     SkinRedTeam=Texture'PlatformSkinT0'
     SkinBlueTeam=Texture'PlatformSkinT1'
     SpriteRedTeam=Texture'MotionAlarmSpriteT0'
     SpriteBlueTeam=Texture'MotionAlarmSpriteT1'
     SkinGreenTeam=Texture'PlatformSkinT2'
     SkinYellowTeam=Texture'PlatformSkinT3'
     SpriteGreenTeam=Texture'MotionAlarmSpriteT2'
     SpriteYellowTeam=Texture'MotionAlarmSpriteT3'
     NumOfMFX=2
     MFXrotX=(Pitch=20000,Yaw=20000,Roll=20000)
     Mesh=LodMesh'Botpack.Tele2'
     MultiSkins(0)=Texture'PlatformSkinT0'
     MultiSkins(1)=Texture'PlatformSkinT1'
     MultiSkins(2)=Texture'PlatformSkinT2'
     MultiSkins(3)=Texture'PlatformSkinT3'
     GUI_Icon=Texture'GUI_Teleporter'
     SoundVolume=128
     CollisionRadius=18.000000
     CollisionHeight=39.000000
     BuildDistance=60
}
