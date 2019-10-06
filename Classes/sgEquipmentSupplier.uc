//=============================================================================
// sgEquipmentSupplier.
// * Revised by 7DS'Lust
// Higor, unified code, added queuers
//=============================================================================
class sgEquipmentSupplier extends sgBuilding
    abstract;

var() float SupplyRadius;
var() float SupplySoundFrequency;
var() float SupplyScale;

var bool bProtected;
var bool AnnounceImmunity;
var() bool bGlobalSupply;
var config int SuppProtectTimeSecs;
var int Count;
var string ProtectionExpired;
var float PenaltyFactor;
var int MultiSupplyTicks;

var sgSupplierQueuer QueuerList;

//Special operator that prevents skipping of B
static final operator(32) bool  | ( bool A, bool B )
{
	return A || B;
}


simulated function CompleteBuilding()
{
	local int i, ExtraSupply;
	local sgSupplierQueuer Q;
	local float Scale;
	local int OldMultiSupplyTicks;
	
	if ( Role != ROLE_Authority )
        return;

	count++;
	if (count>=(SuppProtectTimeSecs*10) && bProtected )
	{	
		bProtected = false;
		if (AnnounceImmunity)
			AnnounceTeam(ProtectionExpired, Team);
	}
	if ( bProtected && (count % 20 == 0) )
		CalculatePenalty();

	if ( bDisabledByEMP )
		return;

		
	FindTargets();
	if ( QueuerList != None )
		i = QueuerList.AccumulatorCount();
	if ( i == 0 )
		return;
		
	Scale = SupplyScale;
	if ( !bGlobalSupply )
		Scale /= float(i);
		
	//Apply handicap post-supplier spam
	if ( MultiSupplyTicks > 0 )
	{
		OldMultiSupplyTicks = MultiSupplyTicks;
		Scale *= (1.0 + float(MultiSupplyTicks) * 0.1);
		MultiSupplyTicks = Max( 0, MultiSupplyTicks-i);
	}	
	
	//Supply, first round (and only for global)
	For ( Q=QueuerList ; Q!=None ; Q=Q.nextQueuer )
		if ( !Supply( Q.POwner, Q, Scale) )
		{
			ExtraSupply++;
			Q.bSupplyFull = true;
		}
		
	if ( OldMultiSupplyTicks > 0 )
		MultiSupplyTicks += ExtraSupply;
		
	if ( ExtraSupply >= i ) //None was supplied!
		return;
		
	PlayStockSound( i-ExtraSupply);

	//Needs to resupply what wasn't supplied
	if ( !bGlobalSupply && (ExtraSupply > 0) ) 
	{
		Scale /= float(ExtraSupply);
		For ( Q=QueuerList ; Q!=None ; Q=Q.nextQueuer )
			if ( !Q.bSupplyFull )
				Supply( Q.POwner, Q, Scale);
	}

}

function PlayStockSound( int Players)
{
	if ( FRand() / Sqrt(Sqrt(Players)) < SupplySoundFrequency )
		PlaySound( Sound'sgMedia.sgStockUp', SLOT_Misc, SoundDampening * 2.5);
}


function int HealthLimit()    { return 0; } //Players heal up to this amount of health
function float HealthRate()   { return 0; } //Chance a player heals 1 point (values above 1 may yield more points)
function int ArmorLimit()     { return 0; } //Armor is received up to this amount
function float ArmorRate()    { return 0; } //Chance a player gains 1 armor point (values above 1 may yield more points)

function CalculatePenalty()
{
	local sgBuilding aBuild;

	PenaltyFactor = 1;
	ForEach VisibleCollidingActors( class'sgBuilding', aBuild, 170)
		if ( (sgEquipmentSupplier(aBuild) == none) && (aBuild.Team == Team) )
		{
			PenaltyFactor *= VSize( Location - aBuild.Location) / 170;
			if ( class'SiegeStatics'.static.ActorsTouchingExt( self, aBuild, 10, 10) )
				aBuild.bOnlyOwnerRemove = false;
		}
}

function FindTargets()
{
	local Pawn p;

	ForEach RadiusActors( class'Pawn', p, 60)
		if ( p.bIsPlayer && p.Health > 0 &&
          p.PlayerReplicationInfo != None &&
          p.PlayerReplicationInfo.Team == Team)
		{
			if ( !InQueue(P) )
				Spawn( class'sgSupplierQueuer',none).Setup(self,P);
		}
}

function FindTargets_XC()
{
	local Pawn P;
	
	ForEach PawnActors( class'Pawn', P, 100, Location, true)
		if ( P.bIsPlayer && (P.Health > 0) && (P.PlayerReplicationInfo.Team == Team) 
			&& (VSize(Location-P.Location) < 60+P.CollisionRadius) )
		{
			if ( !InQueue(P) )
				Spawn( class'sgSupplierQueuer',none).Setup(self,P);
		}
}

function sgArmor SpawnArmor( Pawn Other)
{
	local sgArmor theArmor;
	local sgPRI PRI;

	theArmor = Spawn( class'sgArmor');
	if ( theArmor == none )
		return None;
	theArmor.GiveTo( Other);
	theArmor.Charge = 1;
	PRI = sgPRI(Other.PlayerReplicationInfo);
	if ( PRI != none ) //If you go back to heal, you get lamer points
		PRI.sgInfoSpreeCount = Max( 5, PRI.sgInfoSpreeCount+2);
	return theArmor;
}

function bool Supply( Pawn Other, sgSupplierQueuer Accumulator, float SupplyFactor)
{
	local sgPRI PRI;

	if ( bProtected && (sgPRI(Other.PlayerReplicationInfo) != none) )
	{
		PRI = sgPRI(Other.PlayerReplicationInfo);
		PRI.bReachedSupplier = True;
		if ( PRI.ProtectCount > 0 )
		{
			PRI.ProtTimer( 0.05);
			if ( PRI.SupplierTimer > 0 )
				PRI.SupplierTimer += 0.025;
		}
	}
	
	return Accumulator.AddHealth( HealthRate() * SupplyFactor, HealthLimit() )
		| Accumulator.AddArmor( ArmorRate() * SupplyFactor, ArmorLimit() );
}


simulated event TakeDamage( int damage, Pawn instigatedBy, Vector hitLocation, Vector momentum, name damageType )
{
	if (!bProtected)
		Super.TakeDamage(damage, instigatedBy, hitLocation, momentum, damageType);
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
     bDragable=true
     bOnlyOwnerRemove=True
     bExpandsTeamSpawn=True
	 SupplySoundFrequency=0
     SupplyRadius=60.000000
     SkinRedTeam=None
     SkinBlueTeam=None
     SupplyScale=1
}
