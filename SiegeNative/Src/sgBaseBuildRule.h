//Utilitary file for all sgBaseBuildRule hooks

class sgBaseBuildRule : public AInfo
{
public:
	FStringNoInit RuleString;			//String used to create this rule
	FStringNoInit RuleName;			//Used for initial parenting set
	BYTE Team;					//Team this rule works for
	sgBaseBuildRule* nextRule;	//Serverside chained list
	FName TagList[4];			//Team tags for faster iterations in client
	sgCategoryInfo* Master;		//Category Info actor
	INT AppliedOn[4];			//Bitwise array for the Master category info


	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgBaseBuildRule);
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgBaseBuildRule();	}

	static UProperty* ST_RuleName;
	static UProperty* ST_Team;
	static UProperty* ST_AppliedOn;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(RuleName, LoadFrom);
		LOAD_STATIC_PROPERTY(Team, LoadFrom);
		LOAD_STATIC_PROPERTY(AppliedOn, LoadFrom);
	}
};

UProperty* sgBaseBuildRule::ST_RuleName = NULL;
UProperty* sgBaseBuildRule::ST_Team = NULL;
UProperty* sgBaseBuildRule::ST_AppliedOn = NULL;


static UClass* sgBaseBuildRule_class = NULL;

//sgBaseBuildRule is preloaded by SiegeGI, finding it is enough
static void Setup_sgBaseBuildRule( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgBaseBuildRule_class = NULL;
	
	FIND_PRELOADED_CLASS(sgBaseBuildRule,SiegePackage);
	check( sgBaseBuildRule_class != NULL);
	PROPAGATE_CLASS_NATIVEREP(sgBaseBuildRule);
	sgBaseBuildRule::ReloadStatics( sgBaseBuildRule_class);
}


INT* sgBaseBuildRule::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgBaseBuildRule::GetOptimizedRepList);
	if ( bNetInitial )
		Ptr = AActor::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgBaseBuildRule_class != NULL);
	if( sgBaseBuildRule_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			//Only same team
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
			{
				if ( bNetInitial || (NumReps % 32 == 0) ) //Avoid heavy polling
				{
					DOREP(sgBaseBuildRule,RuleName);
					DOREP(sgBaseBuildRule,Team);
					DOREPARRAY(sgBaseBuildRule,AppliedOn);
				}
			}
		}
	}
	return Ptr;
	unguard;
}




