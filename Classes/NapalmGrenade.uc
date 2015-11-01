//////////////////////////////
// Napalm Grenade
// By Higor

class NapalmGrenade expands sg_Grenade;


function Explosion(vector HitLocation)
{
	local sgBuilding building;
	local int MyTeam;
	local pawn Incinerator;
	local FlameExplosion F;
	local vector ExplosionLine, HitNormal;
	local float ExplosionScale;
	local int i;
	local NapalmFragment NF;

	if ( Region.Zone.bWaterZone && !Region.Zone.IsA('NitrogenZone') )
	{
		Spawn(class'BubbleBurst');
		Spawn(class'BubbleBurst',,,Location - vect(10,0,0) );
		Spawn(class'BubbleBurst',,,Location - vect(-10,0,5) );
		Destroy();
		return;
	}

	if (Pawn(Owner) != none)
		Incinerator = Pawn(Owner);
	else if ( Instigator != none )
		Incinerator = Instigator;

	if ( Incinerator == none || Incinerator.PlayerReplicationInfo == none )
		MyTeam = 255;
	else
		MyTeam = Incinerator.PlayerReplicationInfo.Team;

	HurtRadius(damage, 150, 'Burned', MomentumTransfer, Location);	

	F = Spawn( class'FlameExplosion');
	if ( F != None )
		F.DrawScale *= 1.8;

	foreach RadiusActors(class'sgBuilding', building, 135)
		if (building.Team != MyTeam)
			building.Incinerate( Incinerator, Location, Normal(Location - building.Location) );

	ExplosionLine = Normal(Velocity) * (VSize(Velocity) + 300) * 0.5;
	if ( Trace(HitLocation, HitNormal, Location - vect(0,0,200)) == none )
	{
		ExplosionLine.Z -= VSize(Velocity) * 0.4;
		ExplosionLine *= 1.1;
	}
	else
		ExplosionLine.Z += (100 - (Location.Z - HitLocation.Z)) * 6;

	ExplosionScale = VSize(ExplosionLine) * 0.7;

	For ( i=0 ; i<7 ; i++ )
	{
		NF = Spawn( class'NapalmFragment', Incinerator);
		NF.Instigator = Incinerator;
		NF.Velocity = ExplosionLine + VRand() * ExplosionScale;
		NF.Speed = VSize(NF.Velocity);
	}

	Destroy();
}

defaultproperties
{
	ExplodeTime=2
	damage=50
	Skin=Texture'Jsg_grenade3'
}