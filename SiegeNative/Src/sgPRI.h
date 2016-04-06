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
};

static UClass* sgPRI_class = NULL;

//sgPRI is preloaded by SiegeGI, finding it is enough
static void Setup_sgPRI( UPackage* SiegePackage)
{
	sgPRI_class = NULL;
	
	{for ( TObjectIterator<UClass> It; It; ++It )
		if ( (It->GetOuter() == SiegePackage) && !appStricmp(It->GetName(),TEXT("sgPRI")) )
		{
			sgPRI_class = *It;
			break;
	}	}
	check( sgPRI_class != NULL);

	//Perform verification (?)
	if ( false )
		return;

	//Modify the sgPRI class to allow native replication
	sgPRI_class->ClassConstructor = sgPRI::InternalConstructor;
	sgPRI_class->ClassFlags |= CLASS_NativeReplication;
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
			DOREP(sgPRI,sgPRI_class,bReadyToPlay);
			if ( bNetOwner || NumReps % 8 == 0 ) //Stats, don't perform heavy polling (every 2 secs?)
			{
				DOREP(sgPRI,sgPRI_class,sgInfoCoreKiller);
				DOREP(sgPRI,sgPRI_class,sgInfoBuildingHurt);
				DOREP(sgPRI,sgPRI_class,sgInfoCoreRepair);
				DOREP(sgPRI,sgPRI_class,sgInfoUpgradeRepair);
				DOREP(sgPRI,sgPRI_class,sgInfoKiller);
				DOREP(sgPRI,sgPRI_class,sgInfoBuildingMaker);
				DOREP(sgPRI,sgPRI_class,sgInfoWarheadMaker);
				DOREP(sgPRI,sgPRI_class,sgInfoWarheadKiller);
			}
			if ( bNetOwner )
				DOREP(sgPRI,sgPRI_class,XC_Orb);

			//Don't bother evaluating country prefix if IpToCountry mutator hasn't been located
			if ( IpToCountry )
				DOREP(sgPRI,sgPRI_class,CountryPrefix);

			UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
			if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo )
			{
				if ( Conn->Actor->PlayerReplicationInfo->bIsSpectator || (Conn->Actor->PlayerReplicationInfo->Team == Team) )
				{
					if ( bNetOwner || NumReps % 4 == 0 ) //No need to spam RU updates if core is simulating
					{
						DOREP(sgPRI,sgPRI_class,Orders);
						DOREP(sgPRI,sgPRI_class,RU);
					}
				}
				else
					DOREP(sgPRI,sgPRI_class,bHideIdentify);
			}
		}
	}
	return Ptr;
	unguard;
}




