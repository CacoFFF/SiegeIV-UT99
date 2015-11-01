class KoalasShockBeam extends supershockbeam;

simulated function Timer()
{
	local SuperShockBeam r;
	
	if (NumPuffs>0)
	{
		r = Spawn(class'KoalasShockBeam',,,Location+MoveAmount);
		r.RemoteRole = ROLE_None;
		r.NumPuffs = NumPuffs -1;
		r.MoveAmount = MoveAmount;
	}
}

defaultproperties
{
Texture=Texture'Botpack.GE1_A00'
Mesh=LodMesh'Botpack.PBolt'
}