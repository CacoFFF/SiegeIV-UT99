//=============================================================================
// sgProtProj.
// * Revised by 7DS'Lust
//=============================================================================
class sgProtProj extends Projectile;

var XC_ProtProjStorage Store;
var sgProtProj nextProj;
var byte Team;
var bool bLighting;
var bool bWasWater;
var class<Effects> ImpactClass;

/////////////////////////////////////////////////////
state Inactive
{
	simulated event BeginState()
	{
		SetPhysics( PHYS_None );
		bHidden = true;
		nextProj = Store.ProjPool;
		Store.ProjPool = self;
	}
	simulated event EndState()
	{
		Store.ProjPool = nextProj;
		nextProj = none;
	}
}

simulated state Flying
{
	//Needs Collision, rotation and location set first, in that order
	simulated event BeginState()
	{
		Velocity = Vector(Rotation) * speed;
		SetPhysics( PHYS_Projectile);
		bHidden = false;
		if( Region.zone.bWaterZone )
		{
			Velocity *= 0.7;
			bWasWater = true;
			SetTimer( 0.10, False);
		}
	}
	simulated function ProcessTouch( Actor Other, Vector HitLocation )
	{
		local int hitdamage;
		local vector hitDir;

		if ( sgWarShell(Other) != None )
			return;
		else if ( sgBuilding(Other) != None )
		{
			if ( sgBuilding(Other).Team == Team )
				return;
			if ( sgEquipmentSupplier(Other) != none )
				sgEquipmentSupplier(Other).bProtected = false;
		}
		else if ( Pawn(Other) != None && Pawn(Other).PlayerReplicationInfo != None && Pawn(Other).PlayerReplicationInfo.Team == Team )
			return;

		if ( Role == ROLE_Authority )
		{
			hitDir = Normal(Velocity);
			if ( FRand() < 0.2 )
				hitDir *= 5;
			Other.TakeDamage(Damage, Instigator, HitLocation, MomentumTransfer * hitDir, 'sgSpecial');
		}

		Other.PlaySound(MiscSound, SLOT_Misc, 0.7,,, 0.75+FRand()*0.5);
		if ( Level.NetMode != NM_DedicatedServer )
			Store.SetupImpact( HitLocation);

		GotoState('Inactive');
	}

	simulated function HitWall( vector HitNormal, actor Wall )
	{
		Global.HitWall(HitNormal, Wall);	

		if ( Level.NetMode != NM_DedicatedServer )
		{
			PlaySound(ImpactSound, SLOT_Misc, 0.5,,, 0.75+FRand()*0.5); //Not propagated anyways
			Store.SetupImpact( Location + HitNormal);
		}
		GotoState('Inactive');
	}

	simulated function Timer()
	{
		local bubble1 b;
		if (Level.NetMode!=NM_DedicatedServer)
		{
	 		b=spawn(class'Bubble1',,, Location + VRand() * 2); 
 			b.DrawScale= 0.1 + FRand()*0.2;
 			b.buoyancy = b.mass+(FRand()*0.4+0.1);
 		}
		SetTimer( FRand()*0.1+0.1,False); 	
	}

	simulated function ZoneChange( Zoneinfo NewZone )
	{
		if ( NewZone.bWaterZone && !bWasWater ) 
		{
			Velocity *= 0.7;
			SetTimer( 0.03,False);
		}
		else if ( !NewZone.bWaterZone && bWasWater )
		{
			Velocity /= 0.7;
			SetTimer(0,false);
		}
		bWasWater = NewZone.bWaterZone;
	}
Begin:
	Sleep( 100);
	GotoState( 'Inactive' );
}

///////////////////////////////////////////////////////
simulated function Explode(vector HitLocation, vector HitNormal)
{
}

simulated function AnimEnd()
{
}

defaultproperties
{
     ImpactClass=class'sgProjImp'
     speed=1850.000000
     Damage=15.000000
     MomentumTransfer=7500
     ImpactSound=Sound'sgMedia.SFX.sgProtPhitW'
     MiscSound=Sound'sgMedia.SFX.sgProtPhitF'
     RemoteRole=ROLE_None
     Style=STY_Translucent
     Skin=Texture'sgMedia.GFX.sgProjFront'
     Mesh=LodMesh'UnrealShare.plasmaM'
     DrawScale=0.400000
     ScaleGlow=2.000000
     AmbientGlow=255
     bUnlit=True
     MultiSkins(1)=Texture'sgMedia.GFX.sgProjSide'
     CollisionRadius=4.000000
     CollisionHeight=4.000000
     Team=255
     LifeSpan=0
     bCollideActors=False
}
