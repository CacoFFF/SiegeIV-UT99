//Utilitary file for all sgPRI hooks

class sgPRI : public APlayerReplicationInfo
{
public:
	FLOAT sgInfoCoreKiller;
	FLOAT sgInfoCoreRepair;
	FLOAT sgInfoBuildingHurt;
	FLOAT sgInfoUpgradeRepair;
	INT sgInfoKiller;
	INT sgInfoBuildingMaker;
	INT sgInfoWarheadMaker;
	INT sgInfoWarheadKiller;
	INT sgInfoSpreeCount;
	FStringNoInit CountryPrefix;
	AActor* IpToCountry;
	UBOOL bIpToCountry; //Single bitfield
	FLOAT RU;
	AActor* Orb;
	AActor* XC_Orb;
	FLOAT AccRU;
	FLOAT AccRUTimer;
	BITFIELD bReadyToPlay:1 GCC_PACK(4);
	BITFIELD bGameStarted:1;
	BITFIELD bHideIdentify:1;
	BITFIELD bReplicateRU:1;
	FLOAT ProtectCount GCC_PACK(4);
	AWeapon* WhosGun;
	INT WhosAmmoCount;
	FStringNoInit VisibleMessage;
	INT VisibleMessageNum;
	FStringNoInit sHistory[16];
	BYTE sColors[16];
	BYTE iHistory;
	APawn* PushedBy;
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
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgPRI();	}
	
	static UProperty* ST_sgInfoCoreKiller;
	static UProperty* ST_sgInfoCoreRepair;
	static UProperty* ST_sgInfoBuildingHurt;
	static UProperty* ST_sgInfoUpgradeRepair;
	static UProperty* ST_sgInfoKiller;
	static UProperty* ST_sgInfoBuildingMaker;
	static UProperty* ST_sgInfoWarheadMaker;
	static UProperty* ST_sgInfoWarheadKiller;
	static UProperty* ST_sgInfoSpreeCount;
	static UProperty* ST_CountryPrefix;
	static UProperty* ST_bReadyToPlay;
	static UProperty* ST_XC_Orb;
	static UProperty* ST_Orders;
	static UProperty* ST_RU;
	static UProperty* ST_bHideIdentify;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(sgInfoCoreKiller, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoCoreRepair, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoBuildingHurt, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoUpgradeRepair, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoKiller, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoBuildingMaker, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoWarheadMaker, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoWarheadKiller, LoadFrom);
		LOAD_STATIC_PROPERTY(sgInfoSpreeCount, LoadFrom);
		LOAD_STATIC_PROPERTY(CountryPrefix, LoadFrom);
		LOAD_STATIC_PROPERTY(bReadyToPlay, LoadFrom);
		LOAD_STATIC_PROPERTY(XC_Orb, LoadFrom);
		LOAD_STATIC_PROPERTY(Orders, LoadFrom);
		LOAD_STATIC_PROPERTY(RU, LoadFrom);
		LOAD_STATIC_PROPERTY(bHideIdentify, LoadFrom);
	}
};

UProperty* sgPRI::ST_sgInfoCoreKiller = NULL;
UProperty* sgPRI::ST_sgInfoCoreRepair = NULL;
UProperty* sgPRI::ST_sgInfoBuildingHurt = NULL;
UProperty* sgPRI::ST_sgInfoUpgradeRepair = NULL;
UProperty* sgPRI::ST_sgInfoKiller = NULL;
UProperty* sgPRI::ST_sgInfoBuildingMaker = NULL;
UProperty* sgPRI::ST_sgInfoWarheadMaker = NULL;
UProperty* sgPRI::ST_sgInfoWarheadKiller = NULL;
UProperty* sgPRI::ST_sgInfoSpreeCount = NULL;
UProperty* sgPRI::ST_CountryPrefix = NULL;
UProperty* sgPRI::ST_bReadyToPlay = NULL;
UProperty* sgPRI::ST_XC_Orb = NULL;
UProperty* sgPRI::ST_Orders = NULL;
UProperty* sgPRI::ST_RU = NULL;
UProperty* sgPRI::ST_bHideIdentify = NULL;


static UClass* sgPRI_class = NULL;

//sgPRI is preloaded by SiegeGI, finding it is enough
static void Setup_sgPRI( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgPRI_class = NULL;
	
	FIND_PRELOADED_CLASS(sgPRI,SiegePackage);
	check( sgPRI_class != NULL);
	SETUP_CLASS_NATIVEREP(sgPRI);
	sgPRI::ReloadStatics( sgPRI_class);
}

INT* sgPRI::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgPRI::GetOptimizedRepList);
	Ptr = APlayerReplicationInfo::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgPRI_class != NULL);
	if( sgPRI_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			DOREP(sgPRI,bReadyToPlay);
			if ( bNetOwner || NumReps % 8 == 0 ) //Stats, don't perform heavy polling (every 2 secs?)
			{
				DOREP(sgPRI,sgInfoCoreKiller);
				DOREP(sgPRI,sgInfoBuildingHurt);
				DOREP(sgPRI,sgInfoCoreRepair);
				DOREP(sgPRI,sgInfoUpgradeRepair);
				DOREP(sgPRI,sgInfoKiller);
				DOREP(sgPRI,sgInfoBuildingMaker);
				DOREP(sgPRI,sgInfoWarheadMaker);
				DOREP(sgPRI,sgInfoWarheadKiller);
				if ( IpToCountry )
					DOREP(sgPRI,CountryPrefix);
			}
			if ( bNetOwner )
				DOREP(sgPRI,XC_Orb);

			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo )
			{
				if ( Conn->Actor->PlayerReplicationInfo->bIsSpectator || (Conn->Actor->PlayerReplicationInfo->Team == Team) )
				{
					if ( bNetOwner || NumReps % 4 == 0 ) //No need to spam RU updates if core is simulating
					{
						DOREP(sgPRI,Orders);
						DOREP(sgPRI,RU);
					}
				}
				else
					DOREP(sgPRI,bHideIdentify);
			}
		}
	}
	return Ptr;
	unguard;
}




