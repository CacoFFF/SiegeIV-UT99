//Utilitary file for all sgPRI hooks

class sgPRI : public APlayerReplicationInfo, public sgNative::Base
{
public:
	INT sgInfoKiller;
	INT sgInfoBuildingMaker;
	INT sgInfoWarheadMaker;
	INT sgInfoWarheadKiller;
	INT sgInfoSpreeCount;
	INT sgInfoWarheadFailCount;
	INT sgInfoMineFrags;
	INT sgInfoCoreDmg;

	FStringNoInit CountryPrefix;
	UTexture* CachedFlag;

	AActor* IpToCountry;
	FLOAT ResolveWait;
	UBOOL bIpToCountry; //Single bitfield

	FLOAT RU;
	AActor* Orb;
	AActor* XC_Orb;
	class sgPlayerData* PlayerData;

	FLOAT AccRU;
	FLOAT AccRUTimer;
	union
	{
		struct
		{
			BITFIELD bReadyToPlay:1;
			BITFIELD bGameStarted:1;
			BITFIELD bHideIdentify:1;
			BITFIELD bReplicateRU:1;
		};
		BITFIELD BIT_bReadyToPlay;
		BITFIELD BIT_bHideIdentify;
	};

	//Spawn protection
	FLOAT ProtectCount, SafeProtectTimer;
	AWeapon* LastWeapon;

	FStringNoInit VisibleMessage;
	INT VisibleMessageNum;
	FStringNoInit sHistory[20];
	BYTE sColors[20];
	BYTE iHistory;

	APawn* PushedBy;
	AActor* Stat;

	INT RemoveTimer;
	FLOAT SupplierTimer;
	BITFIELD bReachedSupplier:1 GCC_PACK(4);
	BITFIELD bRequestedFPTime:1;
	BITFIELD bReceivedFingerPrint:1;
	FStringNoInit PlayerFingerPrint GCC_PACK(4);
	FLOAT NoFingerPrintTimer;
	INT iNoFP;
	FName Orders;
	AActor* OrderObject;
	AActor* AIQueuer;

	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}

	NO_DEFAULT_CONSTRUCTOR(sgPRI);
	DEFINE_SIEGENATIVE_CLASS(sgPRI,sgNative::NativeRep)
	
	static INT ST_sgInfoKiller;
	static INT ST_sgInfoBuildingMaker;
	static INT ST_sgInfoWarheadMaker;
	static INT ST_sgInfoWarheadKiller;
	static INT ST_sgInfoWarheadFailCount;
	static INT ST_sgInfoMineFrags;
	static INT ST_sgInfoCoreDmg;
	static INT ST_CountryPrefix;
	static INT ST_bReadyToPlay;
	static INT ST_XC_Orb;
	static INT ST_Orders;
	static INT ST_RU;
	static INT ST_bHideIdentify;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(sgInfoKiller, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoBuildingMaker, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoWarheadMaker, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoWarheadKiller, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoWarheadFailCount, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoMineFrags, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoCoreDmg, LoadFrom);
		LOAD_STATIC_PROPERTY(CountryPrefix, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bReadyToPlay, LoadFrom);
		LOAD_STATIC_PROPERTY(XC_Orb, LoadFrom);
		LOAD_STATIC_PROPERTY(Orders, LoadFrom);
		LOAD_STATIC_PROPERTY(RU, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bHideIdentify, LoadFrom);
	}
};


INT sgPRI::ST_sgInfoKiller = 0;
INT sgPRI::ST_sgInfoBuildingMaker = 0;
INT sgPRI::ST_sgInfoWarheadMaker = 0;
INT sgPRI::ST_sgInfoWarheadKiller = 0;
INT sgPRI::ST_sgInfoWarheadFailCount = 0;
INT sgPRI::ST_sgInfoMineFrags = 0;
INT sgPRI::ST_sgInfoCoreDmg = 0;
INT sgPRI::ST_CountryPrefix = 0;
INT sgPRI::ST_bReadyToPlay = 0;
INT sgPRI::ST_XC_Orb = 0;
INT sgPRI::ST_Orders = 0;
INT sgPRI::ST_RU = 0;
INT sgPRI::ST_bHideIdentify = 0;


INT* sgPRI::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgPRI::GetOptimizedRepList);
	Ptr = APlayerReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	if( sgPRI::StaticClass()->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			DOREP(sgPRI,bReadyToPlay);
			if ( bNetOwner || NumReps % 4 == 0 ) //Stats, don't perform heavy polling (every 2 secs?)
			{
				DOREP(sgPRI,sgInfoKiller);
				DOREP(sgPRI,sgInfoBuildingMaker);
				DOREP(sgPRI,sgInfoWarheadMaker);
				DOREP(sgPRI,sgInfoWarheadKiller);
				DOREP(sgPRI,sgInfoWarheadFailCount);
				DOREP(sgPRI,sgInfoMineFrags);
				DOREP(sgPRI,sgInfoCoreDmg);
				if ( IpToCountry )
					DOREP(sgPRI,CountryPrefix);

				APlayerReplicationInfo* PRI = GetPRI( ((UPackageMapLevel*)Map)->Connection );
				UBOOL bSameTeam = PRI && (PRI->bIsSpectator || PRI->Team == Team);

				if ( bSameTeam )
				{
					DOREP(sgPRI,Orders);
					DOREP(sgPRI,RU);
				}
				if ( bSameTeam || !sgGameReplicationInfo::GLOBAL_bHideEnemyBuilds )
				{
					DOREP(sgPRI,sgInfoBuildingMaker);
				}

			}
			if ( bNetOwner )
				DOREP(sgPRI,XC_Orb);
		}
	}
	return Ptr;
	unguard;
}




