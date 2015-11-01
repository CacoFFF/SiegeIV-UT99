//=============================================================================
// WildcardsPoisonGuardian.
//
// Optimized by Higor
// Too many speed affecters will do funky stuff on the player... we need to
// make it so speed affecters stack and apply each on top of the player's
// default movement speed.
// sgPlayerData could totally take care of this...
//
// MeshFX fatness and size should vary in real time - TODO later
//
//=============================================================================
class WildcardsPoisonGuardian expands sgGuardian;

var() byte MFXFatness;

//Higor: faster than RADIUSACTORS
var PoisonPlayer Poisoned[16];
var int iPoisoned;
var() bool bNoToxinProtection;


function bool CanAttackPlayer( pawn P)
{
	if ( Super.CanAttackPlayer(P) )
	{
		if ( !bNoToxinProtection && (P.FindInventoryType(class'ToxinSuit') != none) )
			return false;
		return true;
	}
}

function bool AlreadyPoisoned( Pawn Other)
{
	local int i;

	While ( i < iPoisoned )
	{
		if ( (Poisoned[i] == none) || Poisoned[i].bDeleteMe )
		{
			iPoisoned--;
			if ( i != iPoisoned )
				Poisoned[i] = Poisoned[iPoisoned];
			continue;
		}
		if ( Poisoned[i].PoisonedPlayer == Other )
			return true;
		i++;
	}
	return false;
}

function Damage()
{
	local float dist, moScale;
	local vector dir;
	local Pawn p;
	local PoisonPlayer Poison;

	foreach RadiusActors(class 'Pawn', p, ShockSize )
	{
		if ( CanAttackPlayer(p) )
		{
			dir = normal( Location - p.Location);
			dist = VSize( Location - p.Location);
			MoScale = (((ShockSize)-dist)/(ShockSize))+0.1;

			if ( (sgBuilding(p) == none) && !AlreadyPoisoned(p) )
			{
				Poison = Spawn(Class'PoisonPlayer', Owner, , Location);
				Poison.PoisonedPlayer = p;
				Poisoned[iPoisoned++] = Poison;

				switch ( int(Grade) )
				{
					case 0:
						Poison.Slowness	= 0.5;
						Poison.RecoverRate = 0.800;
						break;
					case 1:
						Poison.Slowness	= 1;
						Poison.RecoverRate = 0.600;
						break;
					case 2:
						Poison.Slowness	= 1.5;
						Poison.RecoverRate = 0.400;
						break;
					case 3:
						Poison.Slowness	= 2;
						Poison.RecoverRate = 0.200;
						break;
					case 4:
						Poison.Slowness	= 2.5;
						Poison.RecoverRate = 0.100;
						break;
					case 5:
						Poison.Slowness	= 3;
						Poison.RecoverRate = 0.050;
						break;
				}
			}

			p.TakeDamage(moScale*10, Instigator, 0.5 * (p.CollisionHeight + p.CollisionRadius)*dir, vect(0,0,0), 'sgSpecial');
			if ( FRand() < 0.25) 
			{
				PlaySound(sound'PoisonGasHiss',,4.0);
				Spawn( class'PoisonCloud',, '', VRand() * vect(100,100,40) + Location, RotRand()).DrawScale *= (0.5+2*frand());
			}
		}
	}
}

simulated function FinishBuilding()
{
    local int i;
    local WildcardsMeshFX newFX;

    DrawScale = SpriteScale;

    if ( Role == ROLE_Authority )
        Spawn(class'sgFlash');

    if ( Level.NetMode == NM_DedicatedServer )
        return;

    if ( myFX == None && Model != None )
        for ( i = 0; i < numOfMFX; i++ )
        {
            newFX = Spawn(class'WildcardsMeshFX', Self,,,
              rotator(vect(0,0,0)));
            //newFX.WcNextFX = myFX;
            myFX = newFX;
            myFX.Mesh = Model;
            myFX.DrawScale = DSofMFX;
            myFX.Fatness = MFXFatness;
            myFX.RotationRate.Pitch = MFXrotX.Pitch*FRand();
            myFX.RotationRate.Roll = MFXrotX.Roll*FRand();
            myFX.RotationRate.Yaw = MFXrotX.Yaw*FRand();

        }
}

defaultproperties
{
     MFXFatness=255
     bNoFractionUpgrade=True
     BuildingName="Poison Guardian"
     BuildCost=1500
     BuildTime=35.000000
     Model=LodMesh'UnrealI.TracerM'
     SkinRedTeam=Texture'PoisonGuardianSkinT0'
     SkinBlueTeam=Texture'PoisonGuardianSkinT1'
     SpriteRedTeam=Texture'PoisonGuardianSpriteT0'
     SpriteBlueTeam=Texture'PoisonGuardianSpriteT1'
     SkinGreenTeam=Texture'PoisonGuardianSkinT2'
     SkinYellowTeam=Texture'PoisonGuardianSkinT3'
     SpriteGreenTeam=Texture'PoisonGuardianSpriteT2'
     SpriteYellowTeam=Texture'PoisonGuardianSpriteT3'
     DSofMFX=0.500000
     NumOfMFX=8
     GUI_Icon=Texture'GUI_PGuardian'
}
