//Utilitary file for all base sgBuilding hooks

class sgBuilding : public APawn
{
public:
	FStringNoInit sPlayerIP;
	FLOAT fRULeech; //RU given to enemy
	INT iRULeech;
	INT iCatTag; //Tag given to build if made from a category
	FLOAT RUinvested;
	class sgPRI* OwnerPRI;
	class sgBuildingVolume* MyVolume;
	INT BlockedReachSpecs[3]; //TArray<INT>
	INT iBlockPoll;
	class ANavigationPoint* N;

	FLOAT SCount, TotalScount, GS;
	class sgMeshFX* myFX;
	INT			 Team;
	BITFIELD	DoneBuilding:1 GCC_PACK(4);
	BITFIELD	bBuildInitialized:1;
	FLOAT BuildingTimer GCC_PACK(4);
	FLOAT ScaleBox; //Scale a build'd collision once it's up and working

	// vars for fire and EMP stuff
	BITFIELD	bReplicateEMP:1 GCC_PACK(4);
	BITFIELD	bReplicateMFX:1;
	BITFIELD	bDisabledByEMP:1;
	BITFIELD	bIsOnFire:1;
	class APawn* TehIncinerator GCC_PACK(4);
	FLOAT BurnPerSecond; //Damage to take per second (burning state)
	FLOAT AccBurn;  //Accumulated burn (precise values)

	// What orb the building has currently attached to it
	class WildcardsOrbs* Orb;
	class sg_XC_Orb* XC_Orb;

	// Building's Attributes
	FStringNoInit            BuildingName;
	INT               BuildCost,UpgradeCost;
	FLOAT             BuildTime,MaxEnergy;
	FLOAT Energy,		 RuRewardScale,        Grade;
	FLOAT BuildDistance;
	BITFIELD	bCanTakeOrb:1 GCC_PACK(4);
	BITFIELD	bOnlyOwnerRemove:1;
	BITFIELD	bNoRemove:1; //Cannot be removed
	BITFIELD	bStandable:1; //Used to prevent translocators from bouncing here
	BITFIELD	bBlocksPath:1; //Blocks pathing

	// Building's Apperance
	FLOAT SpriteScale GCC_PACK(4);

	class UMesh* Model;
	INT VisualData[8];
//	class UTexture* SkinRedTeam, SkinBlueTeam, SkinGreenTeam, SkinYellowTeam;
//	class UTexture* SpriteRedTeam, SpriteBlueTeam, SpriteGreenTeam, SpriteYellowTeam;
	FLOAT DSofMFX;
	INT NumOfMFX;
	FRotator MFXrotX;
	BYTE MFXFatness;
	class UTexture* GUI_Icon;

	BITFIELD	bNoUpgrade:1 GCC_PACK(4);
	BITFIELD	bNoFractionUpgrade:1;
	BITFIELD	bNoNotify:1;
	BITFIELD	bNotifyDestroyed:1;
	BITFIELD	bNotifyCreated:1;
	BITFIELD	bSmokeStatus:1;
	class sgSmokeGenerator* MyGen GCC_PACK(4);
	BYTE DestructionAnnounce;

	
	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}
	virtual FLOAT UpdateFrequency(AActor *Viewer, FVector &ViewDir, FVector &ViewPos);

	NO_DEFAULT_CONSTRUCTOR(sgBuilding);
	
	static void InternalConstructor( void* X )
	{	new( (EInternal*)X )sgBuilding();	}

	static UProperty* ST_BuildTime;
	static UProperty* ST_MaxEnergy;
	static UProperty* ST_Energy;
	static UProperty* ST_SCount;
	static UProperty* ST_TotalScount;
	static UProperty* ST_GS;
	static UProperty* ST_Grade;
	static UProperty* ST_Team;
	static UProperty* ST_OwnerPRI;
	static UProperty* ST_iRULeech;
	static UProperty* ST_bSmokeStatus;
	static UProperty* ST_bNoRemove;
	static UProperty* ST_bOnlyOwnerRemove;
	static UProperty* ST_bDisabledByEMP;
	static UProperty* ST_UpgradeCost;
	static UProperty* ST_bNoUpgrade;
	static UProperty* ST_DSofMFX;
	static UProperty* ST_MFXFatness;
	static UProperty* ST_NumOfMFX;
	static UProperty* ST_MFXrotX;
	static UProperty* ST_Model;
	static void ReloadStatics( UClass* LoadFrom)
	{

		LOAD_STATIC_PROPERTY(BuildTime, LoadFrom);
		LOAD_STATIC_PROPERTY(MaxEnergy, LoadFrom);
		LOAD_STATIC_PROPERTY(Energy, LoadFrom);
		LOAD_STATIC_PROPERTY(SCount, LoadFrom);
		LOAD_STATIC_PROPERTY(TotalScount, LoadFrom);
		LOAD_STATIC_PROPERTY(GS, LoadFrom);
		LOAD_STATIC_PROPERTY(Grade, LoadFrom);
		LOAD_STATIC_PROPERTY(Team, LoadFrom);
		LOAD_STATIC_PROPERTY(OwnerPRI, LoadFrom);
		LOAD_STATIC_PROPERTY(iRULeech, LoadFrom);
		LOAD_STATIC_PROPERTY(bSmokeStatus, LoadFrom);
		LOAD_STATIC_PROPERTY(bNoRemove, LoadFrom);
		LOAD_STATIC_PROPERTY(bOnlyOwnerRemove, LoadFrom);
		LOAD_STATIC_PROPERTY(bDisabledByEMP, LoadFrom);
		LOAD_STATIC_PROPERTY(UpgradeCost, LoadFrom);
		LOAD_STATIC_PROPERTY(bNoUpgrade, LoadFrom);
		LOAD_STATIC_PROPERTY(DSofMFX, LoadFrom);
		LOAD_STATIC_PROPERTY(MFXFatness, LoadFrom);
		LOAD_STATIC_PROPERTY(NumOfMFX, LoadFrom);
		LOAD_STATIC_PROPERTY(MFXrotX, LoadFrom);
		LOAD_STATIC_PROPERTY(Model, LoadFrom);
	}
};

UProperty* sgBuilding::ST_BuildTime = NULL;
UProperty* sgBuilding::ST_MaxEnergy = NULL;
UProperty* sgBuilding::ST_Energy = NULL;
UProperty* sgBuilding::ST_SCount = NULL;
UProperty* sgBuilding::ST_TotalScount = NULL;
UProperty* sgBuilding::ST_GS = NULL;
UProperty* sgBuilding::ST_Grade = NULL;
UProperty* sgBuilding::ST_Team = NULL;
UProperty* sgBuilding::ST_OwnerPRI = NULL;
UProperty* sgBuilding::ST_iRULeech = NULL;
UProperty* sgBuilding::ST_bSmokeStatus = NULL;
UProperty* sgBuilding::ST_bNoRemove = NULL;
UProperty* sgBuilding::ST_bOnlyOwnerRemove = NULL;
UProperty* sgBuilding::ST_bDisabledByEMP = NULL;
UProperty* sgBuilding::ST_UpgradeCost = NULL;
UProperty* sgBuilding::ST_bNoUpgrade = NULL;
UProperty* sgBuilding::ST_DSofMFX = NULL;
UProperty* sgBuilding::ST_MFXFatness = NULL;
UProperty* sgBuilding::ST_NumOfMFX = NULL;
UProperty* sgBuilding::ST_MFXrotX = NULL;
UProperty* sgBuilding::ST_Model = NULL;

static UClass* sgBuilding_class = NULL;

//sgBuilding is preloaded by SiegeGI, finding it is enough
static void Setup_sgBuilding( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgBuilding_class = NULL;
	
	FIND_PRELOADED_CLASS(sgBuilding,SiegePackage);
	debugf( TEXT("SGBUILDING: %i vs %i"), sizeof(class APawn), sgBuilding_class->GetSuperClass()->PropertiesSize);
	debugf( TEXT("SGBUILDING: %i vs %i"), sizeof(class sgBuilding), sgBuilding_class->PropertiesSize);
	check( sgBuilding_class != NULL);
	PROPAGATE_CLASS_NATIVEREP(sgBuilding);
	sgBuilding::ReloadStatics( sgBuilding_class);
}

INT* sgBuilding::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgBuilding::GetOptimizedRepList);
	if ( bNetInitial || NumReps & 1 ) //Half frequency
		Ptr = APawn::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgBuilding_class != NULL);
	if( sgBuilding_class->ClassFlags & CLASS_NativeReplication )
	{
		if( Role==ROLE_Authority )
		{
			//High frequency updates
			if ( SCount > 0 ) //We only need to know when we're building
			{
				DOREP(sgBuilding,BuildTime);
				DOREP(sgBuilding,SCount); //High frequency SCount
				DOREP(sgBuilding,TotalScount);
				DOREP(sgBuilding,GS);
			}
			if ( bReplicateEMP )
				DOREP(sgBuilding,bDisabledByEMP);
			//Initial replication
			if ( bNetInitial )
			{
				if ( !bNoUpgrade && Grade < 5.f ) //We only need to know if we can upgrade
					DOREP(sgBuilding,UpgradeCost);
				DOREP(sgBuilding,bNoUpgrade);
				if ( bReplicateMFX )
				{
					DOREP(sgBuilding,DSofMFX);
					DOREP(sgBuilding,MFXFatness);
					DOREP(sgBuilding,NumOfMFX);
					DOREP(sgBuilding,MFXrotX);
					DOREP(sgBuilding,Model);
				}
			}
			//Low frequency updates
			if ( bNetInitial || (NumReps % 4 == 0) )
			{
				DOREP(sgBuilding,Energy);
				DOREP(sgBuilding,MaxEnergy);
				if ( !bNoUpgrade )
					DOREP(sgBuilding,Grade);
				DOREP(sgBuilding,Team);
				if ( SCount <= 0 )
					DOREP(sgBuilding,SCount); //SCount at lower frequency once finishes
				if ( OwnerPRI )
					DOREP(sgBuilding,OwnerPRI); //Never replicate 'NULL', not necessary
				DOREP(sgBuilding,bSmokeStatus);

				UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
				if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
				{
					DOREP(sgBuilding,iRULeech);
					DOREP(sgBuilding,bNoRemove);
					DOREP(sgBuilding,bOnlyOwnerRemove);
				}
			}
		}
	}
	return Ptr;
	unguard;
}

FLOAT sgBuilding::UpdateFrequency(AActor *Viewer, FVector &ViewDir, FVector &ViewPos)
{
	FLOAT Result = NetUpdateFrequency;

	FVector Delta = ViewPos - Viewer->Location;
	if ( (Delta | ViewDir) < 0.f )
		Result *= 0.5f;
	FLOAT SizeSq = Delta.SizeSquared();
	if ( SizeSq > 2250000.f ) //1500
	{
		Result *= 0.75f;
		if ( SizeSq > 9000000.f ) //3000
			Result *= 0.75f;
	}
	
	if ( bAlwaysRelevant ) //Reduce impact
		Result = (Result + NetUpdateFrequency) * 0.5f;
	
	return Result;
}




