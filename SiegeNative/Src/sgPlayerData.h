//Utilitary file for all base sgPlayerData hooks


//Designed to be bAlwaysRelevant
class sgPlayerData : public AReplicationInfo
{
public:
	APawn* POwner;
	APlayerPawn* PPOwner;
	FLOAT BaseEyeHeight;
	INT OwnerID;
	sgPRI* OwnerPRI;
	class SiegeGI* SiegeGame;
	INT RealHealth;
	FVector LastRepLoc;
	FLOAT LastRepLocTime;
	BITFIELD bReplicateLoc:1 GCC_PACK(4);
	BITFIELD bReplicateHealth:1;
	BITFIELD bHudEnforceHealth:1;
	BITFIELD bClientXCGEHash:1;
	UEngine* ClientEngine GCC_PACK(4);


	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
	virtual UBOOL CheckRecentChanges() {return 1;}; //bAlwaysRelevant actor will attempt to check recents early
	virtual UBOOL NoVariablesToReplicate(AActor *OldVer);
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgPlayerData);
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgPlayerData();	}

	static UProperty* ST_BaseEyeHeight;
	static UProperty* ST_RealHealth;
	static UProperty* ST_OwnerID;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(BaseEyeHeight, LoadFrom);
		LOAD_STATIC_PROPERTY(RealHealth, LoadFrom);
		LOAD_STATIC_PROPERTY(OwnerID, LoadFrom);
	}
};

UProperty* sgPlayerData::ST_BaseEyeHeight = NULL;
UProperty* sgPlayerData::ST_RealHealth = NULL;
UProperty* sgPlayerData::ST_OwnerID = NULL;

static UClass* sgPlayerData_class = NULL;

//sgPlayerData is preloaded by SiegeGI, finding it is enough
static void Setup_sgPlayerData( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgPlayerData_class = NULL;
	
	FIND_PRELOADED_CLASS(sgPlayerData,SiegePackage);
	check( sgPlayerData_class != NULL);
	SETUP_CLASS_NATIVEREP(sgPlayerData);
	sgPlayerData::ReloadStatics( sgPlayerData_class);
}

//This function isn't called if bNetInitial or Dirty has data to send
UBOOL sgPlayerData::NoVariablesToReplicate( AActor *OldVer)
{
	if ( BaseEyeHeight != ((sgPlayerData*)OldVer)->BaseEyeHeight )
		return 0;
	if ( bReplicateHealth && (RealHealth == ((sgPlayerData*)OldVer)->RealHealth) )
		return 0;
	return 1;
}


INT* sgPlayerData::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgPlayerData::GetOptimizedRepList);
	if ( bNetInitial )
		Ptr = AReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgPlayerData_class != NULL);
	if( sgPlayerData_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			if ( bNetInitial || (NumReps % 64 == 0) )
				DOREP(sgPlayerData,OwnerID);
			if ( !bNetOwner )
			{
				if ( Owner && !Owner->bAlwaysRelevant && !Map->CanSerializeObject(Owner) )
					return Ptr; //Deny replicating if owner isn't relevant
				DOREP(sgPlayerData,BaseEyeHeight);
				if ( bReplicateHealth )
					DOREP(sgPlayerData,RealHealth)
			}
		}
	}
	return Ptr;
	unguard;
}

