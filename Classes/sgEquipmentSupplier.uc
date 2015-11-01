//=============================================================================
// sgEquipmentSupplier.
// * Revised by 7DS'Lust
// Higor, unified code, added queuers
//=============================================================================
class sgEquipmentSupplier extends sgBuilding
    abstract;

var() float         SupplyRadius;

var bool	bProtected;
var bool AnnounceImmunity;
var config int SuppProtectTimeSecs;
var int Count;
var string ProtectionExpired;
var float PenaltyFactor;

var sgSupplierQueuer QueuerList;
var float QueuerTimer;
var float RotationTime;

simulated function CompleteBuilding()
{
	local pawn P;

	if ( Role != ROLE_Authority )
        return;

	count++;
	if (count>=(SuppProtectTimeSecs*10) && bProtected)
	{	
		bProtected = false;
		if (AnnounceImmunity)
			AnnounceTeam(ProtectionExpired, Team);
	}
	if ( bProtected && (count % 20 == 0) )
		CalculatePenalty();

	if ( bDisabledByEMP )
		return;

	P = FindTarget();
	if ( P == none )
		return;
	Supply(P);

	if ( QueuerList != none )
	{
		QueuerTimer -= 0.1;
		if ( (QueuerList.nextQueuer != none) && (QueuerTimer <= 0) )
			QueuerList.Push();
	}
}

function CalculatePenalty()
{
	local sgBuilding aBuild;
	local float fTmp;

	ForEach VisibleCollidingActors(class'sgBuilding', aBuild, 170)
	{
		if ( (sgEquipmentSupplier(aBuild) == none) && (aBuild.Team == Team) )
			fTmp += 170 - VSize( location - aBuild.Location);
	}
	fTmp /= 170;
	PenaltyFactor = fTmp;
}

function Pawn FindTarget()
{
	local Pawn p;

	foreach RadiusActors(class'Pawn', p, 60)
		if ( p.bIsPlayer && p.Health > 0 &&
          p.PlayerReplicationInfo != None &&
          p.PlayerReplicationInfo.Team == Team)
		{
			if ( !InQueue(P) )
				Spawn( class'sgSupplierQueuer',none).Setup(self,P);
		}

	if ( QueuerList == none )
		return None;
	return QueuerList.POwner;
}

function Supply(Pawn target)
{
	if ( bProtected && sgPRI(target.PlayerReplicationInfo) != none )
		sgPRI( target.PlayerReplicationInfo).bReachedSupplier = True;
}

simulated event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, 
  Vector momentum, name damageType )
{
	if (!bProtected)
		Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
}

function AnnounceTeam(string sMessage, int iTeam)
{
    local Pawn p;

    for ( p = Level.PawnList; p != None; p = p.nextPawn )
	    if ( (p.bIsPlayer || p.IsA('MessagingSpectator')) &&
          p.PlayerReplicationInfo != None && p.playerreplicationinfo.Team == iTeam )
		    p.ClientMessage(sMessage);
}

function bool InQueue( pawn Other)
{
	local sgSupplierQueuer aQ;

	For ( aQ=QueuerList ; aQ!=none ; aQ=aQ.nextQueuer )
		if ( aQ.POwner == Other )
			return true;
	return false;
}


defaultproperties
{
     bOnlyOwnerRemove=True
     SupplyRadius=60.000000
     SkinRedTeam=None
     SkinBlueTeam=None
     RotationTime=0.2
}
