//////////////////////////////
// EMP Grenade
// By Higor

class EMPGrenade expands sg_Grenade;


function Explosion(vector HitLocation)
{
	local sgBuilding building;
	local sgPRI PRIowner;

	if (Pawn(Owner) != none)
		PRIowner = sgPRI(Pawn(Owner).PlayerReplicationInfo);
	else if ( Instigator != none )
		PRIowner = sgPRI(Instigator.PlayerReplicationInfo);

	if ( PRIOwner == none )
	{
		Destroy();
		return;
	}

	PlaySound(Sound'emp2', SLOT_None, 20,,1000,1+(FRand()*0.3-0.15));
	PlaySound(Sound'emp1', SLOT_None, 20,,750);
	Spawn(class'MiniEMPBall');
	Spawn(class'MiniEMPFlash');

	foreach RadiusActors(class'sgBuilding', building, 400)
		if (building.Team != PRIOwner.Team)
		{
			if ( !building.IsA('Mine') && !building.IsA('sgProtector') && VSize(building.Location - Location) > 180 + building.CollisionRadius )
				continue;
			building.Electrify();
			if ( PRIowner != none )
				PRIowner.Score += 0.5;
		}

	Destroy();
}

defaultproperties
{
	Skin=Texture'Jsg_grenade2'
}