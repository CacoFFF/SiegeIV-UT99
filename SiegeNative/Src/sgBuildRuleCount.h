//Utilitary file for all sgBuildRuleCount hooks

class sgBuildRuleCount : public sgBaseBuildRule
{
public:
	union
	{
		struct
		{
			BITFIELD bOnceOnly:1;
			BITFIELD bStopCounter:1;
			BITFIELD bOvertime:1;
			BITFIELD bOvertimeReached:1;
			BITFIELD bOnlyFinished:1;
			BITFIELD bExactMatch:1; //What to do with this?
			BITFIELD bPersistantTimer:1;
		};
		BITFIELD BIT_bOnceOnly;
		BITFIELD BIT_bOvertime;
		BITFIELD BIT_bOvertimeReached;
		BITFIELD BIT_bPersistantTimer;
	};
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
	DEFINE_SIEGENATIVE_CLASS(sgBuildRuleCount,sgNative::NativeRep)
	
	static INT ST_TargetTimer;
	static INT ST_BuildCount;
	static INT ST_TargetCount;
	static INT ST_bOvertimeReached;
	static INT ST_BuildClass;
	static INT ST_bOnceOnly;
	static INT ST_bPersistantTimer;
	static INT ST_bOvertime;
	static INT ST_MyTimer;

	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(TargetTimer, LoadFrom);
		LOAD_STATIC_PROPERTY(BuildCount, LoadFrom);
		LOAD_STATIC_PROPERTY(TargetCount, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bOvertimeReached, LoadFrom);
		LOAD_STATIC_PROPERTY(BuildClass, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bOnceOnly, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bPersistantTimer, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bOvertime, LoadFrom);
		LOAD_STATIC_PROPERTY(MyTimer, LoadFrom);
	}
};


INT sgBuildRuleCount::ST_TargetTimer = NULL;
INT sgBuildRuleCount::ST_BuildCount = NULL;
INT sgBuildRuleCount::ST_TargetCount = NULL;
INT sgBuildRuleCount::ST_bOvertimeReached = NULL;
INT sgBuildRuleCount::ST_BuildClass = NULL;
INT sgBuildRuleCount::ST_bOnceOnly = NULL;
INT sgBuildRuleCount::ST_bPersistantTimer = NULL;
INT sgBuildRuleCount::ST_bOvertime = NULL;
INT sgBuildRuleCount::ST_MyTimer = NULL;


/*
	reliable if ( !bPersistantTimer && Role==ROLE_Authority )
		BuildCount, TargetCount;
	reliable if ( Role==ROLE_Authority )
		bOvertimeReached, TargetTimer;
	reliable if ( bNetInitial && Role==ROLE_Authority )
		BuildClass, bOnceOnly, bPersistantTimer, bOvertime;
	reliable if ( bPersistantTimer && Role==ROLE_Authority )
		MyTimer;
*/
	

INT* sgBuildRuleCount::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgBuildRuleCount::GetOptimizedRepList);
	Ptr = sgBaseBuildRule::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	if( StaticClass()->ClassFlags & CLASS_NativeReplication )
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
					DOREP(sgBuildRuleCount,bOnceOnly);
					DOREP(sgBuildRuleCount,bPersistantTimer);
					DOREP(sgBuildRuleCount,bOvertime);
				}

				if ( bNetInitial || (NumReps % 5 == 0) ) //Twice a second
				{
					if ( bPersistantTimer )
						DOREP(sgBuildRuleCount,MyTimer)
					else
					{
						DOREP(sgBuildRuleCount,TargetTimer);
						DOREP(sgBuildRuleCount,BuildCount);
						DOREP(sgBuildRuleCount,TargetCount);
						DOREP(sgBuildRuleCount,bOvertimeReached);
					}
				}
			}
		}
	}
	return Ptr;
	unguard;
}




