//Utilitary file for all base sgGameReplicationInfo hooks


class sgGameReplicationInfo : public ATournamentGameReplicationInfo, public sgNative::Base
{
public:
	class sgBaseCore* Cores[4];
	FLOAT MaxRUs[4];

	//Game Engine version
	INT EngineVersion;

	//Global stat counter
	FStringNoInit           StatTop_Desc[9];
	FStringNoInit           StatTop_Name[9];
	BYTE                    StatTop_Team[9];
	APlayerReplicationInfo* StatTop_PRI[9];
	FLOAT                   StatTop_Value[9];

	//Format: "name;count;name;count;...;"
	FStringNoInit Nukers_Red;
	FStringNoInit Nukers_Blue;
	FStringNoInit Nukers_Green;
	FStringNoInit Nukers_Yellow;

	//Global game settings
	union
	{
		struct
		{
			BITFIELD bTeamDrag:1;
			BITFIELD bHideEnemyBuilds:1;
		};
		BITFIELD BIT_bTeamDrag;
		BITFIELD BIT_bHideEnemyBuilds;
	};

	NO_DEFAULT_CONSTRUCTOR(sgGameReplicationInfo);
	DEFINE_SIEGENATIVE_CLASS(sgGameReplicationInfo,sgNative::VfTable)

	static UBOOL GLOBAL_bHideEnemyBuilds;

	// AActor interface
	UBOOL Tick( FLOAT DeltaTime, enum ELevelTick TickType ) override;
};
UBOOL sgGameReplicationInfo::GLOBAL_bHideEnemyBuilds = 0;


UBOOL sgGameReplicationInfo::Tick( FLOAT DeltaTime, ELevelTick TickType)
{
	GLOBAL_bHideEnemyBuilds = bHideEnemyBuilds;
	return Super::Tick( DeltaTime, TickType);
}