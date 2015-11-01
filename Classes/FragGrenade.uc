//////////////////////////////
// Fragmentation Grenade
// By Higor

class FragGrenade expands sg_Grenade;

function Explosion(vector HitLocation)
{
	HurtRadius( damage, 270, MyDamageType, MomentumTransfer, Location );

	Spawn(class'FragmentationSpawner');
	Destroy();
}

//Assisted explosion
simulated function HitWall( vector HitNormal, actor Wall )
{
	local pawn P;

	if ( (VSize(Velocity) > 50) && Instigator != none && Instigator.PlayerReplicationInfo != none )
	{
		ForEach RadiusActors (class'Pawn', P, 65)
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
	ExplodeTime=3.5
	damage=70
	Skin=Texture'Jsg_grenade1'
	MyDamageType=shredded
	MomentumTransfer=160000
}