//=============================================================================
// Enforcer
// * Revised by 7DS'Lust
// * Higor: client animations fixed
//=============================================================================
class sgEnforcer extends Enforcer;

var float AccuracyScale;


//Unified tracer LC v2
simulated function ProcessTraceHit(Actor Other, Vector HitLocation, Vector HitNormal, Vector X, Vector Y, Vector Z)
{
	local UT_Shellcase s;
	local vector realLoc;

	realLoc = Owner.Location + CalcDrawOffset();
	s = Spawn(class'UT_ShellCase',, '', realLoc + 20 * X + FireOffset.Y * Y + Z);
	if ( s != None )
		s.Eject(((FRand()*0.3+0.4)*X + (FRand()*0.2+0.2)*Y + (FRand()*0.3+1.0) * Z)*160);              
	if (Other == Level) 
	{
		if ( bIsSlave || (SlaveEnforcer != None) )
			Spawn(class'UT_LightWallHitEffect',,, HitLocation+HitNormal, Rotator(HitNormal));
		else
			Spawn(class'UT_WallHit',,, HitLocation+HitNormal, Rotator(HitNormal));
	}
	else if ((Other != self) && (Other != Owner) && (Other != None) ) 
	{
		if ( FRand() < 0.2 )
			X *= 5;
		Other.TakeDamage(HitDamage, Pawn(Owner), HitLocation, 3000.0*X, MyDamageType);
		if ( !Other.bIsPawn && !Other.IsA('Carcass') )
			spawn(class'UT_SpriteSmokePuff',,,HitLocation+HitNormal*9);
		else
			Other.PlaySound(Sound 'ChunkHit',, 4.0,,100);

	}		
}

function SetTwoHands()
{
	if ( SlaveEnforcer == None )
		return;

    if ( SlaveEnforcer.IsA('sgEnforcer') )
    {
        SlaveEnforcer.HitDamage = HitDamage;
        sgEnforcer(SlaveEnforcer).AccuracyScale = AccuracyScale;
    }

    Super.SetTwoHands();
}

state ClientFiring
{
	simulated function AnimEnd()
	{
		if ( (Pawn(Owner) == None) || (Ammotype.AmmoAmount <= 0) )
		{
			PlayIdleAnim();
			GotoState('');
		}
		else if ( !bIsSlave && !bCanClientFire )
			GotoState('');
		else if ( Pawn(Owner).bFire != 0 )
			Global.ClientFire(0);
		else if ( Pawn(Owner).bAltFire != 0 )
			Global.ClientAltFire(0);
		else
		{
			PlayIdleAnim();
			GotoState('');
		}
	}
}


state ClientAltFiring
{
	simulated function AnimEnd()
	{
		if ( Pawn(Owner) == None )
			GotoState('');
		else if ( Ammotype.AmmoAmount <= 0 )
		{
			PlayAnim('T2', 0.9, 0.05);	
			GotoState('');
		}
		else if ( !bIsSlave && !bCanClientFire )
			GotoState('');
		else if ( bFirstFire || Pawn(Owner).bAltFire != 0 )
		{
			if ( AnimSequence == 'T2' )
				PlayAltFiring();
			else
			{
				PlayRepeatFiring();
				bFirstFire = false;
			}
		}
		else if ( Pawn(Owner).bFire != 0 )
		{
			if ( AnimSequence != 'T2' )
				PlayAnim('T2', 0.9, 0.05);	
			else
				Global.ClientFire(0);
		}
		else
		{
			if ( AnimSequence != 'T2' )
				PlayAnim('T2', 0.9, 0.05);	
			else
				GotoState('');
		}
	}
}

State ClientActive
{
	simulated function AnimEnd()
	{
		bBringingUp = false;
		if ( !bIsSlave )
		{
			Super.AnimEnd();
			if ( (SlaveEnforcer != None) && !IsInState('ClientActive') )
			{
				if ( (GetStateName() == 'None') || (GetStateName() == 'sgEnforcer') )
					SlaveEnforcer.GotoState('');
				else
					SlaveEnforcer.GotoState(GetStateName());
			}
		}
	}
}



defaultproperties
{
     AccuracyScale=1.000000
     hitdamage=15
     AmmoName=Class'sgEClip'
     PickupAmmoCount=15
}
