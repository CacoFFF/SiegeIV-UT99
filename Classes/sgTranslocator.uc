//=============================================================================
// sgTranslocator.
// Writen by Dim4 and nOs*Badger
//=============================================================================
class sgTranslocator expands Translocator;

simulated exec function GetTranslocator()
{
	PlayerPawn(Owner).GetWeapon( class);
}

function AltFire( float Value )
{
	local sgBuilding B;
	local sgHomingBeacon sgHB;

	local byte OwnerTeam;

	if ( bBotMoveFire )
		return;

	GotoState('NormalFire');

	if ( TTarget != None )
	{
/*		foreach AllActors(class'sgBuilding',B)
		{
			B.bShadowCast=B.bBlockPlayers;
			B.bBlockPlayers=False;
		}
		Pawn(Owner).bCountJumps = True;
		Translocate();
		foreach AllActors(class'sgBuilding',B)
			B.bBlockPlayers=B.bShadowCast;
		return;
*/
		OwnerTeam = Pawn(Owner).PlayerReplicationInfo.Team;
		TTarget.SetPhysics( PHYS_None);
		TTarget.bCollideWorld = false;
		TTarget.SetCollisionSize( Owner.CollisionRadius, Owner.CollisionHeight);
		ForEach AllActors(class'sgBuilding',B)
			if ( B.bCollideActors && B.bBlockActors && (B.Team != OwnerTeam) && class'SiegeStatics'.static.ActorsTouching( TTarget, B) )
			{
				Owner.PlaySound(AltFireSound, SLOT_Misc, 4 * Pawn(Owner).SoundDampening);
				TTarget.Destroy();
				TTarget = none;
				return;
			}
		Translocate();
		return;
	}


	ForEach AllActors( class'sgHomingBeacon', sgHB)
		if ( (sgHB.sPlayerIP == sgPRI(Pawn(Owner).PlayerReplicationInfo).PlayerFingerPrint || sgHB.Owner == Owner) && sgHB.Team == Pawn(Owner).PlayerReplicationInfo.Team)
		{
			Trans(sgHB);
			break;
		}
}

state NormalFire
{
    ignores fire, altfire, AnimEnd;

    function bool PutDown()
    {
        GotoState('DownWeapon');
        return True;
    }

Begin:
    if ( Owner.IsA('Bot') )
        Bot(Owner).SwitchToBestWeapon();
    Sleep(0.3);
    if ( (Pawn(Owner).bFire != 0) && (Pawn(Owner).bAltFire != 0) )
        ReturnToPreviousWeapon();
    GotoState('Idle');
}


function Trans(sgHomingBeacon sgHB)
{
	local sgBuilding B;
	local vector Dest, Start;

	foreach AllActors(class'sgBuilding',B)
	{
		B.bShadowCast=B.bBlockPlayers;
		B.bBlockPlayers=False;
	}

	Start = Pawn(Owner).Location;
	Dest = sgHB.location;
	if ( Pawn(Owner).SetLocation(Dest) )
	{
		Level.Game.PlayTeleportEffect(Owner, true, true);
		SpawnEffect(Start, Dest);
		sgHB.Energy -= (6 - sgHB.Grade) * 1000;
     		//sgHB.Energy -= 5000 - (sgHB.Grade * 1000);
		if (sgHB.Energy <= 0)
			sgHB.Destruct();
	}
	foreach AllActors(class'sgBuilding',B)
		B.bBlockPlayers=B.bShadowCast;
}

function ThrowTarget()
{
	local Vector Start, X,Y,Z;	

	if (Level.Game.LocalLog != None)
		Level.Game.LocalLog.LogSpecialEvent("throw_translocator", Pawn(Owner).PlayerReplicationInfo.PlayerID);
	if (Level.Game.WorldLog != None)
		Level.Game.WorldLog.LogSpecialEvent("throw_translocator", Pawn(Owner).PlayerReplicationInfo.PlayerID);

	if ( Owner.IsA('Bot') )
		bBotMoveFire = true;
	Start = Owner.Location + CalcDrawOffset() + FireOffset.X * X + FireOffset.Y * Y + FireOffset.Z * Z; 		
	Pawn(Owner).ViewRotation = Pawn(Owner).AdjustToss(TossForce, Start, 0, true, true); 
	GetAxes(Pawn(owner).ViewRotation,X,Y,Z);		
	TTarget = Spawn(class'sgTranslocatorTarget',,, Start);
	if (TTarget!=None)
	{
		bTTargetOut = true;
		TTarget.Master = self;
		if ( Owner.IsA('Bot') )
			TTarget.SetCollisionSize(0,0); 
		if ( SiegeGI(Level.Game) != none )
			TTarget.Throw(Pawn(Owner), SiegeGI(Level.Game).TranslocBaseForce + SiegeGI(Level.Game).TranslocLevelForce * Charge, Start);
		else
			TTarget.Throw(Pawn(Owner), MaxTossForce + (Charge *150), Start);
	}
	else GotoState('Idle');
}



defaultproperties
{
     MaxTossForce=850.000000
	 bCanThrow=True
}
