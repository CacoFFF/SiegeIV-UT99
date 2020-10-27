//Utilitary file for all base sgPlayerData hooks


//Designed to be bAlwaysRelevant
class sgPlayerData : public AReplicationInfo
{
public:
	APawn* POwner;
	FLOAT BaseEyeHeight;
	FLOAT SoundDampening;
	FLOAT MaxStepHeight;
	INT OwnerID;
	class sgPRI* OwnerPRI;
	class SiegeGI* SiegeGame;
	class XC_MovementAffector* MA_List;
	INT RealHealth;
	FVector LastRepLoc;
	FLOAT LastRepLocTime;
	union
	{
		struct
		{
			BITFIELD bReplicateLoc:1;
			BITFIELD bReplicateHealth:1;
			BITFIELD bHudEnforceHealth:1;
			BITFIELD bClientXCGEHash:1;
			BITFIELD bForceMovement:1;
			BITFIELD bSpawnProtected:1;
		};
		BITFIELD BIT_bSpawnProtected;
	};

	class SpawnProtEffect* SPEffect GCC_PACK(4);
	UEngine* ClientEngine;

	AActor* DebugAttachment[8];

	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
	virtual UBOOL CheckRecentChanges() {return 1;}; //bAlwaysRelevant actor will attempt to check recents early
	virtual UBOOL NoVariablesToReplicate(AActor *OldVer);
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgPlayerData);
	DEFINE_SIEGENATIVE_CLASS(sgPlayerData)

	static INT ST_BaseEyeHeight;
	static INT ST_RealHealth;
	static INT ST_SoundDampening;
	static INT ST_MaxStepHeight;
	static INT ST_OwnerID;
	static INT ST_bSpawnProtected;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(BaseEyeHeight, LoadFrom);
		LOAD_STATIC_PROPERTY(RealHealth, LoadFrom);
		LOAD_STATIC_PROPERTY(SoundDampening, LoadFrom);
		LOAD_STATIC_PROPERTY(MaxStepHeight, LoadFrom);
		LOAD_STATIC_PROPERTY(OwnerID, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bSpawnProtected, LoadFrom);
		VERIFY_CLASS_SIZE(LoadFrom);
	}
};

INT sgPlayerData::ST_BaseEyeHeight = NULL;
INT sgPlayerData::ST_RealHealth = NULL;
INT sgPlayerData::ST_SoundDampening = NULL;
INT sgPlayerData::ST_MaxStepHeight = NULL;
INT sgPlayerData::ST_OwnerID = NULL;
INT sgPlayerData::ST_bSpawnProtected = NULL;

static UClass* sgPlayerData_class = nullptr;

//sgPlayerData is preloaded by SiegeGI, finding it is enough
static void Setup_sgPlayerData( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgPlayerData_class = GetClass( SiegePackage, TEXT("sgPlayerData"));
	SETUP_CLASS_NATIVEREP(sgPlayerData);
	sgPlayerData::ReloadStatics(sgPlayerData_class);
}

//This function isn't called if bNetInitial or Dirty has data to send
UBOOL sgPlayerData::NoVariablesToReplicate( AActor *OldVer)
{
	sgPlayerData* Old = ((sgPlayerData*)OldVer);
	if ( BaseEyeHeight != Old->BaseEyeHeight )
		return false;
	if ( bReplicateHealth && (RealHealth != Old->RealHealth) )
		return false;
	if ( bNetOwner && (SoundDampening != Old->SoundDampening || MaxStepHeight != Old->MaxStepHeight) )
		return false;
	return true;
}

/*
	unreliable if ( !bNetOwner && Role==ROLE_Authority )
		BaseEyeHeight;
	unreliable if ( !bNetOwner && bReplicateHealth && Role==ROLE_Authority )
		RealHealth;
	unreliable if ( bNetOwner && Role==ROLE_Authority )
		SoundDampening, MaxStepHeight;
	reliable if ( Role==ROLE_Authority )
		OwnerID, bSpawnProtected;
*/

INT* sgPlayerData::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgPlayerData::GetOptimizedRepList);
	if ( bNetInitial )
		Ptr = AReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgPlayerData_class);
	if( sgPlayerData_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			if ( bNetInitial || (NumReps % 16 == 0) )
				DOREP(sgPlayerData,OwnerID);
			DOREP(sgPlayerData,bSpawnProtected);

			// Only replicate modifiers if owner is relevant
			if ( !Owner || Map->CanSerializeObject(Owner) )
			{
				if ( bNetOwner )
				{
					DOREP(sgPlayerData,MaxStepHeight);
					DOREP(sgPlayerData,SoundDampening);
				}
				else
				{
					DOREP(sgPlayerData,BaseEyeHeight);
					if ( bReplicateHealth )
						DOREP(sgPlayerData,RealHealth)
				}
			}
		}
	}
	return Ptr;
	unguard;
}

