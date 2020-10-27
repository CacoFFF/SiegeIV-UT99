//Utilitary file for all sgCategoryInfo hooks

class sgCategoryInfo : public AReplicationInfo
{
public:
	// Native replication tag
	INT NativeReplicationTag;

	BYTE Team;

	UClass* NetBuild[128];
	BYTE NetCategory[128];
	class sgBaseBuildRule* NetRules[128];
	INT NetCost[128];
	INT NetWeight[128];
	FStringNoInit NetName[128];
	FStringNoInit NetCategories[17];
	FStringNoInit CatLocalized[17];
	INT NetCategoryWeight[17], NetCategoryMaxWeight[17];
	UTexture* NetCatIcons[17];
	FStringNoInit NetProperties[128];
	BYTE bCatS[17], bCatE[17]; //Cached end/start indices

	BYTE iCat, iBuilds, iRecBuilds;

	FLOAT PriorityTimer;
	BYTE PossiblePriorities[128];

	FStringNoInit NewBuild;
	FStringNoInit NewCategory;

	// Linked list
	class sgBaseBuildRule* RuleList;
	class SiegeCategoryRules* CatObject;


	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgCategoryInfo);
	DEFINE_SIEGENATIVE_CLASS(sgCategoryInfo);

	static INT ST_iBuilds;
	static INT ST_Team;
	static INT ST_iCat;
	static INT ST_NetBuild;
	static INT ST_NetCategory;
	static INT ST_NetCost;
	static INT ST_NetWeight;
	static INT ST_NetCategories;
	static INT ST_NetCategoryWeight;
	static INT ST_NetCategoryMaxWeight;
	static INT ST_NetCatIcons;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(iBuilds, LoadFrom);
		LOAD_STATIC_PROPERTY(Team, LoadFrom);
		LOAD_STATIC_PROPERTY(iCat, LoadFrom);
		LOAD_STATIC_PROPERTY(NetBuild, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategory, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCost, LoadFrom);
		LOAD_STATIC_PROPERTY(NetWeight, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategories, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategoryWeight, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCategoryMaxWeight, LoadFrom);
		LOAD_STATIC_PROPERTY(NetCatIcons, LoadFrom);
		VERIFY_CLASS_SIZE(LoadFrom);
	}
};

INT sgCategoryInfo::ST_iBuilds = 0;
INT sgCategoryInfo::ST_Team = 0;
INT sgCategoryInfo::ST_iCat = 0;
INT sgCategoryInfo::ST_NetBuild = 0;
INT sgCategoryInfo::ST_NetCategory = 0;
INT sgCategoryInfo::ST_NetCost = 0;
INT sgCategoryInfo::ST_NetWeight = 0;
INT sgCategoryInfo::ST_NetCategories = 0;
INT sgCategoryInfo::ST_NetCategoryWeight = 0;
INT sgCategoryInfo::ST_NetCategoryMaxWeight = 0;
INT sgCategoryInfo::ST_NetCatIcons = 0;


static UClass* sgCategoryInfo_class = nullptr;

//sgCategoryInfo is preloaded by SiegeGI, finding it is enough
static void Setup_sgCategoryInfo( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgCategoryInfo_class = GetClass( SiegePackage, TEXT("sgCategoryInfo"));;
	SETUP_CLASS_NATIVEREP(sgCategoryInfo);
	sgCategoryInfo::ReloadStatics( sgCategoryInfo_class);
}


INT* sgCategoryInfo::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgCategoryInfo::GetOptimizedRepList);
	if ( bNetInitial )
		Ptr = AReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgCategoryInfo_class);
	if( sgCategoryInfo_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			//Only same team
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
			{
				// TODO: Distribute load
				if ( bNetInitial || (NumReps % 2 == 0) ) //Avoid heavy polling
				{
					DOREP(sgCategoryInfo,iBuilds);
					DOREP(sgCategoryInfo,Team);
					DOREP(sgCategoryInfo,iCat);
					DOREPARRAY(sgCategoryInfo,NetBuild);
					DOREPARRAY(sgCategoryInfo,NetCategory);
					DOREPARRAY(sgCategoryInfo,NetCost);
					DOREPARRAY(sgCategoryInfo,NetWeight);
					DOREPARRAY(sgCategoryInfo,NetCategories);
					DOREPARRAY(sgCategoryInfo,NetCategoryWeight);
					DOREPARRAY(sgCategoryInfo,NetCategoryMaxWeight);
					DOREPARRAY(sgCategoryInfo,NetCatIcons);
				}
			}
		}
	}
	return Ptr;
	unguard;
}




