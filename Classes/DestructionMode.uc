//=============================================================================
// DestructionMode.
//=============================================================================
class DestructionMode expands Mutator;

function bool CheckReplacement(actor Other,out byte bSuperRelevant) {

	if(Other.IsA('HealthVial')) {
		ReplaceWith(Other,"Botpack.WarHead");
		return false;
	}
	return true;
}
function ScoreKill(Pawn Killer, Pawn Other)
{
	if ((Killer != Other) && (Other != None) && (Killer != None))
	{
		// Normal kill.
	
		Other.Spawn(class'WarExplosion');
	}
		
	if ( (Other != None) && ((Killer == None) || (Killer == Other)) )
	{
		// Suicide.
		Other.Spawn(class'WarExplosion');
	}

	Super.ScoreKill(Killer, Other);
}

defaultproperties
{
}
