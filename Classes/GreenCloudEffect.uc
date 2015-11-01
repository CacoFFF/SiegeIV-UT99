class GreenCloudEffect expands Effects;

event PostBeginPlay()
{
	Velocity = VRand() * vect(40,40,30);
	if ( FRand() < 0.33 )
		Texture = Texture'Botpack.BioSplat2';
	else if ( FRand() < 0.5 )
	{
		Texture = Texture'MuzzyPulse';
		Style = STY_Translucent;
		ScaleGlow = 0.2;
		AmbientGlow = 10;
		LifeSpan += 1;
	}
	SetTimer(0.5,true);
}

event Timer()
{
	Velocity *= 0.8;
}

function HitWall( vector HitNormal, actor Wall )
{
	Velocity -= (Velocity * (-HitNormal)) * 1.2;
}

defaultproperties
{
	DrawScale=3
	Style=STY_Modulated
	bUnlit=True
	Physics=PHYS_Projectile
	bBounce=True
	bMovable=True
	RemoteRole=ROLE_None
	Texture=Texture'Botpack.BioSplat'
	DrawType=DT_Sprite
	LifeSpan=3
}