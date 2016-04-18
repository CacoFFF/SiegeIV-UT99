//Utilitary file for all sgBuildRuleCount hooks

class sgBuildRuleCount : public sgBaseBuildRule
{
public:
	BITFIELD bOnceOnly:1 GCC_PACK(4);
	BITFIELD bStopCounter:1;
	BITFIELD bOverTime:1;
	BITFIELD bOverTimeReached:1;
	BITFIELD bOnlyFinished:1;
	BITFIELD bExactMatch:1; //What to do with this?
	BITFIELD bPersistantTimer:1;
	INT BuildCount GCC_PACK(4);
	INT TargetCount;
	UClass* BuildClass;
	FLOAT MyTimer;
	FLOAT TargetTimer;
	FLOAT TargetLevel;

	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgBuildRuleCount);
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgBuildRuleCount();	}
	
	static UProperty* ST_TargetTimer;
	static UProperty* ST_BuildCount;
	static UProperty* ST_TargetCount;
	static UProperty* ST_bOverTimeReached;
	static UProperty* ST_BuildClass;
	static UProperty* ST_bPersistantTimer;
	static UProperty* ST_bOverTime;
	static UProperty* ST_MyTimer;

	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(TargetTimer, LoadFrom);
		LOAD_STATIC_PROPERTY(BuildCount, LoadFrom);
		LOAD_STATIC_PROPERTY(TargetCount, LoadFrom);
		LOAD_STATIC_PROPERTY(bOverTimeReached, LoadFrom);
		LOAD_STATIC_PROPERTY(BuildClass, LoadFrom);
		LOAD_STATIC_PROPERTY(bPersistantTimer, LoadFrom);
		LOAD_STATIC_PROPERTY(bOverTime, LoadFrom);
		LOAD_STATIC_PROPERTY(MyTimer, LoadFrom);
	}
};


UProperty* sgBuildRuleCount::ST_TargetTimer = NULL;
UProperty* sgBuildRuleCount::ST_BuildCount = NULL;
UProperty* sgBuildRuleCount::ST_TargetCount = NULL;
UProperty* sgBuildRuleCount::ST_bOverTimeReached = NULL;
UProperty* sgBuildRuleCount::ST_BuildClass = NULL;
UProperty* sgBuildRuleCount::ST_bPersistantTimer = NULL;
UProperty* sgBuildRuleCount::ST_bOverTime = NULL;
UProperty* sgBuildRuleCount::ST_MyTimer = NULL;


static UClass* sgBuildRuleCount_class = NULL;

//sgBuildRuleCount is preloaded by SiegeGI, finding it is enough
static void Setup_sgBuildRuleCount( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgBuildRuleCount_class = NULL;
	
	FIND_PRELOADED_CLASS(sgBuildRuleCount,SiegePackage); //HAHA, SiegeGI preloads this for overtime checks!
	check( sgBuildRuleCount_class != NULL);
	SETUP_CLASS_NATIVEREP(sgBuildRuleCount);
	sgBuildRuleCount::ReloadStatics( sgBuildRuleCount_class);
}



	/*
		reliable if ( !bPersistantTimer && Role==ROLE_Authority )
		TargetTimer, BuildCount, TargetCount, bOverTimeReached;
	reliable if ( bNetinitial && Role==ROLE_Authority )
		BuildClass, bPersistantTimer, bOverTime;
	reliable if ( bPersistantTimer && Role==ROLE_Authority )
		MyTimer;
	*/
	

INT* sgBuildRuleCount::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgBuildRuleCount::GetOptimizedRepList);
	Ptr = sgBaseBuildRule::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgBuildRuleCount_class != NULL);
	if( sgBuildRuleCount_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			//Only same team
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
			{
				if ( bNetInitial )
				{
					DOREP(sgBuildRuleCount,BuildClass);
					DOREP(sgBuildRuleCount,bPersistantTimer);
					DOREP(sgBuildRuleCount,bOverTime);

					if ( bPersistantTimer )
						DOREP(sgBuildRuleCount,MyTimer)
					else
					{
						DOREP(sgBuildRuleCount,TargetTimer);
						DOREP(sgBuildRuleCount,BuildCount);
						DOREP(sgBuildRuleCount,TargetCount);
						DOREP(sgBuildRuleCount,bOverTimeReached);
					}
				}
				else if ( NumReps % 5 == 0 ) //Twice a second
				{
					if ( bPersistantTimer )
						DOREP(sgBuildRuleCount,MyTimer)
					else
					{
						DOREP(sgBuildRuleCount,TargetTimer);
						DOREP(sgBuildRuleCount,BuildCount);
						DOREP(sgBuildRuleCount,TargetCount);
						DOREP(sgBuildRuleCount,bOverTimeReached);
					}
				}
			}
		}
	}
	return Ptr;
	unguard;
}




