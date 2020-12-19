//Utilitary file for sgProtector hooks

struct eventShouldAttackTeamPawn_Params
{
	APawn* P;
	BYTE aTeam;
	UBOOL ReturnValue;
};

class sgProtector : public sgBuilding
{
public:
	USound* FireSound;
	UClass* ProjectileType;
	class XC_ProtProjStorage* Store;
	APawn* BufferedEnemies[4];
	BYTE ScanCycle;
	
	UBOOL eventShouldAttackTeamPawn( APawn* P, BYTE aTeam)
	{
		eventShouldAttackTeamPawn_Params Params;
		Params.P = P;
		Params.aTeam = aTeam;
		Params.ReturnValue = 0;
		ProcessEvent( FindFunctionChecked( SIEGENATIVE_ShouldAttackTeamPawn), &Params);
		return Params.ReturnValue;
	}
	
	DECLARE_FUNCTION(execFindTeamTarget);

	void InitDerived( UClass* Class)
	{
		HOOK_SCRIPT_FUNCTION(sgProtector,FindTeamTarget);
	}
};

void sgProtector::execFindTeamTarget( FFrame& Stack, RESULT_DECL)
{
	guard(execFindTeamTarget);
	P_GET_FLOAT(Dist);
	P_GET_BYTE(aTeam);
	P_FINISH;
	
	
	FLOAT DistSq = Dist*Dist;
	FLOAT BestDistSq = DistSq;
	*(APawn**)Result = nullptr;
	
	if ( ScanCycle == 3 )
	{
		for ( APawn* P=Level->PawnList ; P ; P=P->nextPawn )
			if ( P->bCollideActors && (P->Health > 10) && ClassIsA( P->GetClass(), SIEGENATIVE_ScriptedPawn) && (!P->PlayerReplicationInfo || P->PlayerReplicationInfo->Team != Team) )
			{
				FLOAT CurDistSq = (P->Location - Location).SizeSquared();
				if ( CurDistSq < BestDistSq )
				{
					BestDistSq = CurDistSq;
					*(APawn**)Result = P;
				}
			}
	}
	else
	{
		APawn** Cores = (APawn**) (((PTRINT)Level->Game) + SGI_Cores_Offset);
		if ( Level->Game->IsA(SiegeClass) && Cores[aTeam] )
			return;
		for ( APawn* P=Level->PawnList ; P ; P=P->nextPawn )
			if ( P->bCollideActors )
			{
				FLOAT CurDistSq = (P->Location - Location).SizeSquared(); //Distance check is faster in this context
				if ( (CurDistSq < BestDistSq) && eventShouldAttackTeamPawn( P, aTeam) )
				{
					BestDistSq = CurDistSq;
					*(APawn**)Result = P;
				}
			}
	}
	unguard;
}
