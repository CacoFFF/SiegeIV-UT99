//=============================================================================
// DashTrail
//=============================================================================
class DashTrail expands Effects;

//TODO: USE FOR SPEED ITEM
simulated function PostBeginPlay()
{
	Mesh = Owner.Mesh;
	AnimFrame = Owner.AnimFrame;
	AnimSequence = Owner.AnimSequence;
	AnimRate = Owner.AnimRate;
	TweenRate = Owner.TweenRate;
	AnimMinRate = Owner.AnimMinRate;
	AnimLast = Owner.AnimLast;
	bAnimLoop = Owner.bAnimLoop;
	bAnimFinished = Owner.bAnimFinished;

	Skin = WetTexture'DashTrailWet';
}

simulated function Tick(float Delta)
{
	ScaleGlow -= 1*Delta;
	if (ScaleGlow <= 0)
		Destroy();
}

defaultproperties
{
	 Physics=phys_projectile
     bAnimLoop=True
     bOwnerNoSee=True
     bHighDetail=True
     RemoteRole=ROLE_None
     AnimRate=17.000000
     LODBias=0.100000
     DrawType=DT_Mesh
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.Soldier'
     bUnlit=True
}
