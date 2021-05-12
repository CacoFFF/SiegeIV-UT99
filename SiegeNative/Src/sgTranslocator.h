//Utilitary file for sgTranslocator hooks

class sgTranslocator : public TournamentWeapon, public sgNative::Base
{
public:
//	class TranslocatorTarget* TTarget;
	AProjectile* TTarget;
	FLOAT TossForce;
	FLOAT FireDelay;
	AWeapon* PreviousWeapon;
	AActor* DesiredTarget;
	FLOAT MaxTossForce;
	BITFIELD bBotMoveFire:1 GCC_PACK(4);
	BITFIELD bTTargetOut:1;

	void eventTranslocate()
	{
		ProcessEvent( FindFunctionChecked( SIEGENATIVE_Translocate), NULL);
	}
	
	void eventTrans( sgBuilding* sgHB)
	{
		INT Params[4] = { (INT)sgHB, 0, 0, 0 } ; //Prevent crash if function parameters are expanded at some point
		ProcessEvent( FindFunctionChecked( SIEGENATIVE_Trans), Params);
	}
	
	void CancelXLoc()
	{
		((AActorHook*)Owner)->ServerPlaySound( AltFireSound, SLOT_Misc, 4.0f * ((APawn*)Owner)->SoundDampening);
		GetLevel()->DestroyActor( TTarget, false);
		TTarget = nullptr;
	}

	NO_DEFAULT_CONSTRUCTOR(sgTranslocator);
	DEFINE_SIEGENATIVE_CLASS(sgTranslocator,sgNative::None)
	DECLARE_FUNCTION(execAltFire);

	static void InitDerived( UClass* Class)
	{
		HOOK_SCRIPT_FUNCTION(sgTranslocator,AltFire);
	}
};


void sgTranslocator::execAltFire( FFrame& Stack, RESULT_DECL)
{
	guard(sgTranslocator::execAltFire);
	
	//Classify our node's execution stack
	UFunction* F = Cast<UFunction>(Stack.Node);
	FLOAT Value = 0.f;

	//Called via ProcessEvent >>> Native to Script
	if ( F && F->Func == (Native)&sgBuilding::execTick )
		Value = *((FLOAT*)Stack.Locals);
	//Called via ProcessInternal >>> Script to Native
	else
	{
		Stack.Step( Stack.Object, &Value );
		P_FINISH;
	}
	
	if ( bBotMoveFire || !Owner )
		return;

	((AActorHook*)this)->FastGotoState( SIEGENATIVE_NormalFire);

	APawn* POwner = Cast<APawn>(Owner);
	BYTE OwnerTeam = (POwner && POwner->PlayerReplicationInfo) ? POwner->PlayerReplicationInfo->Team : 255;

	if ( TTarget && !TTarget->bDeleteMe )
	{
		//Low level hash/grid access, super fast
		FMemMark Mark(GMem);
		FVector ALocation = Location;
		if ( Physics == PHYS_None )
			ALocation.Z += Owner->CollisionHeight;
		FCheckResult* Hit = GetLevel()->Hash->ActorEncroachmentCheck( GMem, Owner, ALocation, Rotation, TRACE_Pawns, 0 );
		while ( Hit )
		{
			if ( Hit->Actor && Hit->Actor->IsA(sgBuilding::StaticClass()) && ((sgBuilding*)(Hit->Actor))->Team != OwnerTeam )
			{
				CancelXLoc();
				Mark.Pop();
				return;
			}
			Hit = Hit->GetNext();
		}
		Mark.Pop();
		eventTranslocate();
		return;
	}

	if ( OwnerTeam > 4 )
		return;

	for ( APawn* P=Level->PawnList ; P ; P=P->nextPawn )
		if ( (P->Owner == Owner) && !appStricmp( P->GetClass()->GetName(), TEXT("sgHomingBeacon")) && (((sgBuilding*)P)->Team == OwnerTeam) )
		{
			eventTrans( (sgBuilding*)P);
			break;
		}
	unguard;
}
