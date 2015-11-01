//New grenade type for Grenade Launcher

class sgMK2Grenade expands UT_Grenade;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	SetTimer(3+FRand(),false);                  //Grenade begins unarmed
}

//Assisted explosion
simulated function HitWall( vector HitNormal, actor Wall )
{
	local pawn P;

	if ( (VSize(Velocity) > 50) && Instigator != none && Instigator.PlayerReplicationInfo != none )
	{
		ForEach RadiusActors (class'Pawn', P, 50)
		{
			if ( (P.PlayerReplicationInfo != none) && (P.PlayerReplicationInfo.Team != Instigator.PlayerReplicationInfo.Team) )
			{
				Explosion( Location + HitNormal);
				return;
			}
			if ( (sgBuilding(P) != none) && (sgBuilding(P).Team != Instigator.PlayerReplicationInfo.Team) )
			{
				Explosion( Location + HitNormal);
				return;
			}
		}
	}
	Super.HitWall( HitNormal, Wall);
}

defaultproperties
{
	speed=750
}