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
	class sgBuildingCH* CollisionHull;
	FVector InitialLocation;
	FLOAT BaseEnergy;
	INT TimerCount;
	INT PackedFlags;
	// Flags:
	// 0x00000003 = Team (2 bytes)
	// 0x00000004 = bDisabledByEMP
	// 0x00000008 = bSmokeStatus
	// 0x00000010 = bIsOnFire
	// 0x00000020 = bNoRemove
	// 0x00000040 = bOnlyOwnerRemove

	class ANavigationPoint* N;
	class EffectsPool* EffectsPool;

	FLOAT SCount, TotalScount;
	class sgMeshFX* myFX;
	INT			 Team;
	BITFIELD	DoneBuilding:1 GCC_PACK(4);
	BITFIELD	bBuildInitialized:1;
	FLOAT BuildingTimer GCC_PACK(4);
	FLOAT ScaleBox; //Scale a build'd collision once it's up and working

	// vars for fire and EMP stuff
	BITFIELD	bReplicateMFX:1 GCC_PACK(4);
	BITFIELD	bDisabledByEMP:1;
	BITFIELD	bIsOnFire:1;
	class APawn* TehIncinerator GCC_PACK(4);
	FLOAT BurnPerSecond; //Damage to take per second (burning state)
	FLOAT AccBurn;  //Accumulated burn (precise values)

	// What orb the building has currently attached to it
	class WildcardsOrbs* Orb;
	class sg_XC_Orb* XC_Orb;

	// Building's Attributes
	FStringNoInit BuildingName;
	INT   BuildCost,UpgradeCost;
	FLOAT BuildTime,MaxEnergy;
	FLOAT Energy, RuRewardScale, Grade;
	FLOAT BuildDistance;
	union
	{
		struct
		{
			BITFIELD bCanTakeOrb:1;
			BITFIELD bOnlyOwnerRemove:1;
			BITFIELD bTournamentTeamRemove:1;
			BITFIELD bNoRemove:1; //Cannot be removed
			BITFIELD bNoUpgrade:1;
			BITFIELD bNoFractionUpgrade:1;
			BITFIELD bStandable:1; //Used to prevent translocators from bouncing here
			BITFIELD bDragable:1;
			BITFIELD bExpandsTeamSpawn:1; //Increases PlayerStart's chance of being used
		};
		BITFIELD BIT_bOnlyOwnerRemove;
		BITFIELD BIT_bNoUpgrade;
	};

	// Building's Apperance
	FLOAT SpriteScale GCC_PACK(4);

	class UMesh* Model;
	PTRINT VisualData[8];
//	class UTexture* SkinRedTeam, SkinBlueTeam, SkinGreenTeam, SkinYellowTeam;
//	class UTexture* SpriteRedTeam, SpriteBlueTeam, SpriteGreenTeam, SpriteYellowTeam;
	FLOAT DSofMFX;
	INT NumOfMFX;
	FRotator MFXrotX;
	BYTE MFXFatness;
	class UTexture* GUI_Icon;

	union
	{
		struct
		{
			BITFIELD	bNoNotify:1;
			BITFIELD	bNotifyDestroyed:1;
			BITFIELD	bNotifyCreated:1;
			BITFIELD	bSmokeStatus:1;
		};
		BITFIELD BIT_bNoNotify;
	};
	class sgSmokeGenerator* MyGen;

	// Collision Hull damage
	APawn* LastDamageInstigator;
	FName LastDamageType;
	INT LastDamageAmount;
	UBOOL bLastDamageFromHull;

	BYTE DestructionAnnounce;

	
	//AActor interface, native netcode
	virtual INT* GetOptimizedRepList( BYTE* InDefault, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps );
//	virtual UBOOL ShouldDoScriptReplication() {return 1;}
	virtual FLOAT UpdateFrequency(AActor *Viewer, FVector &ViewDir, FVector &ViewPos);

	void eventPostBuild()
	{
		INT Params[4] = {0,0,0,0}; //16 byte space just in case PostBuild is modified in a later release
		ProcessEvent( FindFunctionChecked( SIEGENATIVE_PostBuild), Params);
	}

	DECLARE_FUNCTION(execTick);
	NO_DEFAULT_CONSTRUCTOR(sgBuilding);
	DEFINE_SIEGENATIVE_CLASS(sgBuilding);

	static INT ST_BuildTime;
	static INT ST_MaxEnergy;
	static INT ST_Energy;
	static INT ST_SCount;
	static INT ST_TotalScount;
	static INT ST_Grade;
	static INT ST_OwnerPRI;
	static INT ST_iRULeech;
	static INT ST_PackedFlags;
	static INT ST_UpgradeCost;
	static INT ST_bNoUpgrade;
	static INT ST_DSofMFX;
	static INT ST_MFXFatness;
	static INT ST_NumOfMFX;
	static INT ST_MFXrotX;
	static INT ST_Model;
	static void ReloadStatics( UClass* LoadFrom)
	{
		LOAD_STATIC_PROPERTY(BuildTime, LoadFrom);
		LOAD_STATIC_PROPERTY(MaxEnergy, LoadFrom);
		LOAD_STATIC_PROPERTY(Energy, LoadFrom);
		LOAD_STATIC_PROPERTY(SCount, LoadFrom);
		LOAD_STATIC_PROPERTY(TotalScount, LoadFrom);
		LOAD_STATIC_PROPERTY(Grade, LoadFrom);
		LOAD_STATIC_PROPERTY(OwnerPRI, LoadFrom);
		LOAD_STATIC_PROPERTY(iRULeech, LoadFrom);
		LOAD_STATIC_PROPERTY(PackedFlags, LoadFrom);
		LOAD_STATIC_PROPERTY(UpgradeCost, LoadFrom);
		LOAD_STATIC_PROPERTY_BIT(bNoUpgrade, LoadFrom);
		LOAD_STATIC_PROPERTY(DSofMFX, LoadFrom);
		LOAD_STATIC_PROPERTY(MFXFatness, LoadFrom);
		LOAD_STATIC_PROPERTY(NumOfMFX, LoadFrom);
		LOAD_STATIC_PROPERTY(MFXrotX, LoadFrom);
		LOAD_STATIC_PROPERTY(Model, LoadFrom);
		VERIFY_CLASS_SIZE(LoadFrom);
	}
};

INT sgBuilding::ST_BuildTime = NULL;
INT sgBuilding::ST_MaxEnergy = NULL;
INT sgBuilding::ST_Energy = NULL;
INT sgBuilding::ST_SCount = NULL;
INT sgBuilding::ST_TotalScount = NULL;
INT sgBuilding::ST_Grade = NULL;
INT sgBuilding::ST_OwnerPRI = NULL;
INT sgBuilding::ST_iRULeech = NULL;
INT sgBuilding::ST_PackedFlags = NULL;
INT sgBuilding::ST_UpgradeCost = NULL;
INT sgBuilding::ST_bNoUpgrade = NULL;
INT sgBuilding::ST_DSofMFX = NULL;
INT sgBuilding::ST_MFXFatness = NULL;
INT sgBuilding::ST_NumOfMFX = NULL;
INT sgBuilding::ST_MFXrotX = NULL;
INT sgBuilding::ST_Model = NULL;

static UClass* sgBuilding_class = nullptr;

//sgBuilding is preloaded by SiegeGI, finding it is enough
static void Setup_sgBuilding( UPackage* SiegePackage, ULevel* MyLevel)
{
	sgBuilding_class = GetClass( SiegePackage, TEXT("sgBuilding"));
	PROPAGATE_CLASS_NATIVEREP(sgBuilding);
	HOOK_SCRIPT_FUNCTION(sgBuilding,Tick);
	sgBuilding::ReloadStatics(sgBuilding_class);
}

void sgBuilding::execTick( FFrame& Stack, RESULT_DECL)
{
	guard(sgBuilding::execTick);

	//Classify our node's execution stack
	UFunction* F = Cast<UFunction>(Stack.Node);
	FLOAT DeltaTime;

	//Called via ProcessEvent >>> Native to Script
	if ( F && F->Func == (Native)&sgBuilding::execTick )
		DeltaTime = *((FLOAT*)Stack.Locals);
	//Called via ProcessInternal >>> Script to Native
	else
	{
		Stack.Step( Stack.Object, &DeltaTime );
		P_FINISH;
	}

	//Execute code in Tick
	if ( Level->NetMode != NM_Client )
	{
		if ( !bBuildInitialized )
		{
			bBuildInitialized = true;
			eventPostBuild();
		}
	}
	
	//TickRate independant, keep sane timer values if tickrate gets messed up
	if ( (BuildingTimer += DeltaTime) >= 0.1f )
	{
		BuildingTimer = Clamp( BuildingTimer - 0.1f, 0.0f, 0.1f + appFrand() * 0.1f);
		eventTimer();
	}
	
	if ( CollisionHull && CollisionHull->bStatic )
	{
		CollisionHull->bStatic = false;
		CollisionHull->eventTick(DeltaTime);
		CollisionHull->bStatic = true;
	}

	unguard;
}

INT* sgBuilding::GetOptimizedRepList( BYTE* Recent, FPropertyRetirement* Retire, INT* Ptr, UPackageMap* Map, INT NumReps )
{
	guard(sgBuilding::GetOptimizedRepList);
	if ( bNetInitial || NumReps & 1 ) //Half frequency
		Ptr = APawn::GetOptimizedRepList(Recent,Retire,Ptr,Map,NumReps);
	check(sgBuilding_class);
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
			}
			DOREP(sgBuilding,PackedFlags);

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
				if ( SCount <= 0 )
					DOREP(sgBuilding,SCount); //SCount at lower frequency once finishes
				if ( OwnerPRI )
					DOREP(sgBuilding,OwnerPRI); //Never replicate 'NULL', not necessary

				UNetConnection* Conn = ((UPackageMapLevel*)Map)->Connection;
				if ( Conn->Actor && Conn->Actor->PlayerReplicationInfo && (Conn->Actor->PlayerReplicationInfo->Team == Team) )
				{
					DOREP(sgBuilding,iRULeech);
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




