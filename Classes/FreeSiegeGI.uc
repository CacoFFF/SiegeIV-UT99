//=============================================================================
// FreeSiegeGI.
// * Revised by 7DS'Lust
//=============================================================================

class FreeSiegeGI extends SiegeGI;

function InitGame(string options, out string error)
{
	StartingMaxRu = 300000;
	StartingRu = 300000;
	Super.InitGame( Options, Error);
}

defaultproperties
{
     NumResources=0.200000
     WeaponClasses(0)=None
     WeaponClasses(1)=None
     WeaponClasses(2)=None
     WeaponClasses(3)=None
     WeaponClasses(4)=None
     WeaponClasses(5)=None
     WeaponClasses(6)=None
     WeaponClasses(7)=None
     WeaponClasses(8)=None
     WeaponClasses(9)=None
     WeaponClasses(10)=None
     WeaponClasses(11)=None
     WeaponClasses(12)=None
     FreeBuild=True
     TimeLimit=120
     GameName="Siege IV - Freebuild"
     StartingMaxRU=300000.000000
     StartingRU=300000

}
