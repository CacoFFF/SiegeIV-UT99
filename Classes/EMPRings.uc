//=============================================================================
// EMPRings
//=============================================================================
class EMPRings extends Effects;

var() float ds;
var bool done1, done2;

replication
{
	// Things the server should send to the client.
	reliable if ( Role == ROLE_Authority )
		done1, done2, ds;
}

simulated function Tick(float deltaTime)
{
	local EMPRings r;

	if ( !done1 && LifeSpan < 2.0)
	{
		r = Spawn(class'EMPRings',,, Location+vector(rotation)*256);
		r.ds = 320;
		r.done1 = true;
		r.done2 = true;
		r = Spawn(class'EMPRings',,, Location-vector(rotation)*512);
		r.ds = 320;
		r.done1 = true;
		r.done2 = true;
		done1 = true;
	}
	else if( !done2 && LifeSpan < 1.0)
	{
		r = Spawn(Class'EMPRings',,,Location+vector(rotation)*640);
		r.ds = 280;
		r.done1 = true;
		r.done2 = true;
		r = Spawn(Class'EMPRings',,,Location-vector(rotation)*768);
		r.ds = 280;
		r.done1 = true;
		r.done2 = true;
		done2 = true;
	}

	DrawScale = 10 + (ds * (1 - LifeSpan / default.LifeSpan));
	ScaleGlow = LifeSpan/default.LifeSpan;
	AmbientGlow = 128 * ScaleGlow;
}

defaultproperties
{
     ds=350.000000
     RemoteRole=ROLE_SimulatedProxy
     LifeSpan=3.000000
     Rotation=(Pitch=-8192)
	 RotationRate=(Pitch=-4096,Roll=3072,Yaw=-6144)
     DrawType=DT_Mesh
     Style=STY_Translucent
     Mesh=LodMesh'Botpack.UTsRingex'
     DrawScale=400.000000
     AmbientGlow=128
     bUnlit=True
     MultiSkins(0)=Texture'ZAPPYSTUFF_A00'
}
