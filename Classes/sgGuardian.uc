//=============================================================================
// sgGuardian
// Written by nOs*Badger
// Higor: optimizing this and bringing it back
//=============================================================================
class sgGuardian extends sgBuilding;

var float ShockSize;

function CompleteBuilding()
{
	if ( !bDisabledByEMP && FRand() < 1/(6/(Grade+1)) )
		Damage();
}

function bool CanAttackPlayer( pawn P)
{
	if ( P.Health <= 0 || P.bHidden ) //Quick rejects
		return false;
	if ( P.bIsPlayer && (P.PlayerReplicationInfo != None) && (P.PlayerReplicationInfo.Team != Team) && !P.PlayerReplicationInfo.bIsSpectator
		|| (ScriptedPawn(P) != None && (P.PlayerReplicationInfo == none || P.PlayerReplicationInfo.Team != Team) )
		|| (sgBuilding(P) != none && sgBuilding(P).Team != Team) )
		return FastTrace(p.Location);
}

function Damage()
{
	local float dist, moScale;
	local vector dir;
	local Pawn p;
	local effects e;

	ForEach RadiusActors(class 'Pawn', p, ShockSize )
		if ( CanAttackPlayer(p) )
		{
			dir = Normal(Location - p.Location);
			dist = VSize(Location - p.Location); 
			MoScale = (((ShockSize)-dist)/(ShockSize))+0.1;
			p.TakeDamage(moScale*10, Instigator, 0.5 * (p.CollisionHeight + p.CollisionRadius)*dir, dir * sqrt(dist) * 250, 'sgSpecial');
			if ( e == none )
				e = SpawnParticles();
		}
}

function Upgraded()
{
	AmbientGlow=255/(6-Grade);
	ShockSize = (Grade*25)+125;
}

function Effects SpawnParticles()
{
	local rotator R;
	if ( FRand() < 0.15 ) 
	{
		PlaySound(sound'UnrealShare.Skrjshot',, 7.0);
		R.Pitch = Rand(65536);
		R.Yaw = Rand(65536);
		R.Roll = Rand(65536);
		return Spawn(Class'UnrealShare.ParticleBurst', Owner,, Location, R);
	}
}

defaultproperties
{
     bDragable=true
     ShockSize=120
     BuildingName="Guardian"
     BuildCost=400
     BuildTime=15.000000
     MaxEnergy=8500.000000
     SpriteScale=0.400000
     Model=LodMesh'Botpack.Module'
     SkinRedTeam=None
     SkinBlueTeam=None
     DSofMFX=3.800000
     NumOfMFX=3
     MFXrotX=(Pitch=20000,Yaw=20000,Roll=20000)
     AmbientGlow=40
     SkinRedTeam=Texture'ContainerSkinTeam0'
     SkinBlueTeam=Texture'ContainerSkinTeam1'
     SpriteRedTeam=Texture'CoreSpriteTeam0'
     SpriteBlueTeam=Texture'CoreSpriteTeam1'
     SkinGreenTeam=Texture'ContainerSkinTeam2'
     SkinYellowTeam=Texture'ContainerSkinTeam3'
     SpriteGreenTeam=Texture'CoreSpriteTeam2'
     SpriteYellowTeam=Texture'CoreSpriteTeam3'
     CollisionHeight=32.000000
     GUI_Icon=Texture'GUI_Guardian'
}
