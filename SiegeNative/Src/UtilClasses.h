//Utilitary file for other classes

class AActorHook : public AActor
{
public:
	void ServerPlaySound( USound* Sound, BYTE Slot=SLOT_Misc, FLOAT Volume=-1.f, UBOOL bNoOverride=0, FLOAT Radius=-1.f, FLOAT Pitch=1.0);
	void FastGotoState( FName S, FName L=NAME_None);
};

class TournamentWeapon : public AWeapon
{
public:
	class TournamentPickup* Affector;
	FLOAT FireAdjust;
	FStringNoInit WeaponDescription;
	FLOAT InstFlash;
	FVector InstFog;
	BITFIELD bCanClientFire:1 GCC_PACK(4);
	BITFIELD bForceFire:1;
	BITFIELD bForceAltFire:1;
	FLOAT FireTime GCC_PACK(4);
	FLOAT AltFireTime;
	FLOAT FireStartTime;
};



void AActorHook::FastGotoState( FName S, FName L)
{
	FName CurrentStateName = (GetStateFrame() && GetStateFrame()->StateNode!=GetClass()) ? GetStateFrame()->StateNode->GetFName() : NAME_None;

	EGotoState Result = GOTOSTATE_Success;
	if( S != CurrentStateName )
		Result = GotoState( S );

	if( Result==GOTOSTATE_Success )
		GotoLabel( L==NAME_None ? NAME_Begin : L );
}

#pragma DISABLE_OPTIMIZATION
void AActorHook::ServerPlaySound( USound* Sound, BYTE Slot, FLOAT Volume, UBOOL bNoOverride, FLOAT Radius, FLOAT Pitch)
{
	guard(AActorHook::ServerPlaySound);

	if( !Sound )
		return;
	if ( Volume <= 0.f )
		Volume = TransientSoundVolume;
	if ( Radius <= 0.f )
		Radius = TransientSoundRadius;


	// Server-side demo needs a call to execDemoPlaySound for the DemoRecSpectator
	if(		GetLevel() && GetLevel()->DemoRecDriver
		&&	!GetLevel()->DemoRecDriver->ServerConnection
		&&	GetLevel()->GetLevelInfo()->NetMode != NM_Client )
		eventDemoPlaySound(Sound, Slot, Volume, bNoOverride, Radius, Pitch);

	INT Id = GetIndex()*16 + Slot*2 + bNoOverride;
	FLOAT RadiusSquared = Square( Radius ? Radius : 1600.f );
	FVector Parameters = FVector(100 * Volume, Radius, 100 * Pitch);

	// Propagate to all player actors.
	for( APawn* Hearer=Level->PawnList; Hearer; Hearer=Hearer->nextPawn )
		if( Hearer->bIsPlayer )
			CheckHearSound(Hearer, Id, Sound, Parameters,RadiusSquared);
	unguard;
}
#pragma ENABLE_OPTIMIZATION
