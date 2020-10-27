/*===========================================================================
    C++ class definitions exported from UnrealScript.
    This is automatically generated by the tools.
    Modify manually as long as you keep parity between this and the UC files
===========================================================================*/
#if _MSC_VER
#pragma pack (push,4)
#endif

#ifndef SIEGENATIVE_API
#define SIEGENATIVE_API DLL_IMPORT
#endif

#ifndef NAMES_ONLY
#define AUTOGENERATE_NAME(name) extern SIEGENATIVE_API FName SIEGENATIVE_##name;
#define AUTOGENERATE_FUNCTION(cls,idx,name)
#endif


//Names we want to keep around
AUTOGENERATE_NAME(SiegeNative)
AUTOGENERATE_NAME(ShouldAttackTeamPawn)
AUTOGENERATE_NAME(ScriptedPawn)
AUTOGENERATE_NAME(PostBuild)
AUTOGENERATE_NAME(Translocate);
AUTOGENERATE_NAME(Trans);
AUTOGENERATE_NAME(NormalFire);

#ifndef NAMES_ONLY

class SIEGENATIVE_API ASiegeNativeActor : public AInfo
{
public:
    FName SiegeIV_Pkg;

	//UObject interface
	void InitExecution();
	
    DECLARE_CLASS(ASiegeNativeActor,AInfo,0,SiegeNative)
    NO_DEFAULT_CONSTRUCTOR(ASiegeNativeActor)
};

#endif

#ifndef NAMES_ONLY
#undef AUTOGENERATE_NAME
#undef AUTOGENERATE_FUNCTION
#endif NAMES_ONLY

#if _MSC_VER
#pragma pack (pop)
#endif
