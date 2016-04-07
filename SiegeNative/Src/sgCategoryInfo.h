//Utilitary file for all sgCategoryInfo hooks

class sgCategoryInfo : public AReplicationInfo
{
public:
	BYTE Team;
	APlayerPawn* PList[32];
	INT iSize;
	INT	pPosition;
	FLOAT SwitchTimer;
	UClass* NetBuild[128];
	BYTE NetCategory[128];
	class sgBaseBuildRule* NetRules[128];
	INT NetCost[128];
	FStringNoInit NetCategories[17];
	FStringNoInit Netlocalized[17];
	INT iCat;
	FStringNoInit NetProperties[128];
	BYTE iBuilds;
	FLOAT PriorityTimer;
	BYTE CurPriItem;
	BYTE PossiblePriorities[128];
	FStringNoInit NewBuild;
	FStringNoInit NewCategory;
	class sgBaseBuildRule* RuleList;
	class SiegeCategoryRules* CatObject;


	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgCategoryInfo);
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgCategoryInfo();	}

	static UProperty* ST_iBuilds;
	static UProperty* ST_Team;
	static UProperty* ST_iCat;
	static UProperty* ST_NetBuild;
	static UProperty* ST_NetCategory;
	static UProperty* ST_NetCost;
	static UProperty* ST_NetCategories;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(iBuilds, LoadFrom);
		LOAD_STATIC_PROPERTY(Team, LoadFrom);
		LOAD_STATIC_PROPERTY(iCat, LoadFrom);
		LOAD_STATIC_PROPERTY(NetBuild, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategory, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCost, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategories, LoadFrom);
	}
};

UProperty* sgCategoryInfo::ST_iBuilds = NULL;
UProperty* sgCategoryInfo::ST_Team = NULL;
UProperty* sgCategoryInfo::ST_iCat = NULL;
UProperty* sgCategoryInfo::ST_NetBuild = NULL;
UProperty* sgCategoryInfo::ST_NetCategory = NULL;
UProperty* sgCategoryInfo::ST_NetCost = NULL;
UProperty* sgCategoryInfo::ST_NetCategories = NULL;


static UClass* sgCategoryInfo_class = NULL;

//sgCategoryInfo is preloaded by SiegeGI, finding it is enough
static void Setup_sgCategoryInfo( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgCategoryInfo_class = NULL;
	
	FIND_PRELOADED_CLASS(sgCategoryInfo,SiegePackage);
	check( sgCategoryInfo_class != NULL);
	SETUP_CLASS_NATIVEREP(sgCategoryInfo);
	sgCategoryInfo::ReloadStatics( sgCategoryInfo_class);
}


INT* sgCategoryInfo::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgCategoryInfo::GetOptimizedRepList);
	if ( bNetInitial )
		Ptr = AReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgCategoryInfo_class != NULL);
	if( sgCategoryInfo_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			//Only same team
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
			{
				if ( bNetInitial || bNetOwner || (NumReps % 32 == 0) ) //Avoid heavy polling
				{
					DOREP(sgCategoryInfo,iBuilds);
					DOREP(sgCategoryInfo,Team);
					DOREP(sgCategoryInfo,iCat);
					DOREPARRAY(sgCategoryInfo,NetBuild);
					DOREPARRAY(sgCategoryInfo,NetCategory);
					DOREPARRAY(sgCategoryInfo,NetCost);
					DOREPARRAY(sgCategoryInfo,NetCategories);
				}
			}
		}
	}
	return Ptr;
	unguard;
}




