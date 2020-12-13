/*=============================================================================
	SiegeNative.cpp
	
	Created by Higor
=============================================================================*/

#include "SiegeNative.h"
#include "UnNet.h"

/*-----------------------------------------------------------------------------
	Implementation.
-----------------------------------------------------------------------------*/

#define NAMES_ONLY
#define AUTOGENERATE_NAME(name) SIEGENATIVE_API FName SIEGENATIVE_##name;
#define AUTOGENERATE_FUNCTION(cls,idx,name) IMPLEMENT_FUNCTION(cls,idx,name)
#include "SiegeNativeClasses.h"
#undef AUTOGENERATE_FUNCTION
#undef AUTOGENERATE_NAME
#undef NAMES_ONLY
void RegisterNames()
{
	static INT Registered=0;
	if(!Registered++)
	{
		#define NAMES_ONLY
		#define AUTOGENERATE_NAME(name) extern SIEGENATIVE_API FName SIEGENATIVE_##name; SIEGENATIVE_##name=FName(TEXT(#name),FNAME_Intrinsic);
		#define AUTOGENERATE_FUNCTION(cls,idx,name)
		#include "SiegeNativeClasses.h"
		#undef DECLARE_NAME
		#undef NAMES_ONLY
	}
}

IMPLEMENT_PACKAGE(SiegeNative);
IMPLEMENT_CLASS(ASiegeNativeActor);

/*-----------------------------------------------------------------------------
	Replication.
-----------------------------------------------------------------------------*/

template <typename T> inline BOOL FASTCALL NEQ( T& A, T& B, UPackageMap* Map)
{
	return A != B;
}

template<> inline BOOL FASTCALL NEQ<UObject*>( UObject*& A, UObject*& B, UPackageMap* Map)
{
	if ( Map->CanSerializeObject(A) )
		return A != B;
	return nullptr != B;
}

inline bool FASTCALL NEQ( BITFIELD A, BITFIELD B, UPackageMap* Map)
{
	return A != B;
}

//nc = Class name
//v  = variable name (identical in both classes)
#define DOREP(nc,v) \
	{if( nc::ST_##v && NEQ(v,((nc*)Recent)->v,Map) ) \
	{ \
		*Ptr++ = nc::ST_##v; \
	}}
#define DOREPARRAY(nc,v) \
	if (nc::ST_##v) \
	{	for( INT i=0; i<ARRAY_COUNT(v); i++ ) \
			if( NEQ(v[i],((nc*)Recent)->v[i],Map) ) \
				*Ptr++ = nc::ST_##v+i; }

/*-----------------------------------------------------------------------------
	Entry point methods.
-----------------------------------------------------------------------------*/

namespace sgNative
{
	constexpr DWORD None        = 0x0000;
	constexpr DWORD VfTable     = 0x0001;
	constexpr DWORD NativeRep   = 0x0002;

	struct Base
	{
		static void InitDerived( UClass* Class) {}
		static void ReloadStatics( UClass* Class) {}
	};
};

static UPackage* SiegePackage = nullptr;
static UClass* SiegeClass = nullptr;
static PTRINT SGI_Cores_Offset = 0;

#define DEFINE_SIEGENATIVE_CLASS(newclass,options) \
	typedef newclass ThisClass; \
	static void InternalConstructor( void* X ) { new( (EInternal*)X )newclass(); } \
	static UClass*& StaticClass() { static UClass* InternalClass=nullptr; return InternalClass; } \
	\
	static UClass* InitClass() \
	{	\
		UClass* Class = StaticClass() = ::GetClass( TEXT(#newclass)); \
		if ( Class ) \
		{	\
			if ( options & (sgNative::VfTable|sgNative::NativeRep) ) \
			{ \
				if ( options & sgNative::NativeRep ) \
					Class->ClassFlags |= CLASS_NativeReplication; \
				Class->ClassConstructor = newclass::InternalConstructor; \
				for ( TObjectIterator<UClass> It; It; ++It ) \
					if ( It->IsChildOf(Class) ) \
						It->ClassConstructor = newclass::InternalConstructor; \
			} \
			Class->Bind(); \
			if ( sizeof(ThisClass) != (PTRINT)Class->PropertiesSize ) \
				appErrorf(TEXT("Class %s size mismatch: Script=%i C++=%i"), Class->GetName(), (INT)Class->PropertiesSize, sizeof(ThisClass)); \
			InitDerived(Class); \
			ReloadStatics(Class); \
		}	\
		else	\
			appErrorf( TEXT("SiegeNative: Class %s not found."), TEXT(#newclass) ); \
		return Class; \
	}

#define LOAD_STATIC_PROPERTY(prop,onclass) \
	{ \
		UProperty* Property = FindObject<UProperty>(onclass,TEXT(#prop)); \
		if ( !Property ) \
			appErrorf(TEXT("Property %s.%s not found"), onclass->GetName(), TEXT(#prop)); \
		if ( (PTRINT)Property->Offset != STRUCT_OFFSET(ThisClass,prop) ) \
			appErrorf(TEXT("Class %s Member %s offset mismatch: Script=%i C++=%i"), onclass->GetName(), TEXT(#prop), Property->Offset, STRUCT_OFFSET(ThisClass,prop) ); \
		if ( Property->RepIndex == 0 ) \
			appErrorf(TEXT("Property %s in class %s is not replicated!"), TEXT(#prop), onclass->GetName() ); \
		ST_##prop = Property->RepIndex; \
	}

#define LOAD_STATIC_PROPERTY_BIT(prop,onclass) \
	{ \
		UBoolProperty* Property = FindObject<UBoolProperty>(onclass,TEXT(#prop)); \
		if ( !Property ) \
			appErrorf(TEXT("Bool Property %s.%s not found"), onclass->GetName(), TEXT(#prop)); \
		if ( (PTRINT)Property->Offset != STRUCT_OFFSET(ThisClass,BIT_##prop) ) \
			appErrorf(TEXT("Class %s Member %s offset mismatch: Script=%i C++=%i"), onclass->GetName(), TEXT(#prop), Property->Offset, STRUCT_OFFSET(ThisClass,BIT_##prop) ); \
		if ( Property->RepIndex == 0 ) \
			appErrorf(TEXT("Property %s in class %s is not replicated!"), TEXT(#prop), onclass->GetName() ); \
		ST_##prop = Property->RepIndex; \
	}

static UClass* GetClass( const TCHAR* ClassName)
{
//	debugf( NAME_SiegeNative, TEXT("Loading class %s"), ClassName);
	if ( !SiegePackage )
		appErrorf( TEXT("SiegeNative: SiegePackage not loaded"));
	UClass* Result = FindObject<UClass>( SiegePackage, ClassName, true);
	if ( !Result )
		Result = LoadClass<AActor>( SiegePackage, ClassName, TEXT(""), 0, nullptr);
	if ( !Result )
		appErrorf( TEXT("SiegeNative: unable to load class %s"), ClassName );
	return Result;
}

/*-----------------------------------------------------------------------------
	UnrealScript utils
-----------------------------------------------------------------------------*/
	
template < typename T > T& GetPropertyGeneric( UObject* Object, UProperty* Property)
{
	return *(T*) (((PTRINT)Object) + Property->Offset);
}

// For iterating through a linked list of fields (don't search on superfield).
template <class T> class TStrictFieldIterator
{
public:
	TStrictFieldIterator( UStruct* InStruct )
	: Field( InStruct ? InStruct->Children : NULL )
	{
		IterateToNext();
	}
	void operator++()
	{
		Field = Field->Next;
		IterateToNext();
	}
	operator UBOOL()	{	return Field != NULL;	}
	T* operator*()		{	return (T*)Field;	}
	T* operator->()		{	return (T*)Field;	}
protected:
	void IterateToNext()
	{
		while( Field )
		{
			if( Field->IsA(T::StaticClass()) )
				return;
			Field = Field->Next;
		}
	}
	UField* Field;
};

//Macro: Make this script function become a native function
#define HOOK_SCRIPT_FUNCTION(clname,funcname) \
	{ for ( TStrictFieldIterator<UFunction> It(clname::StaticClass()) ; It ; ++It ) \
		if ( !appStricmp(It->GetName(),TEXT(#funcname)) ) \
		{	It->Func = (Native)&clname::exec##funcname; \
			It->FunctionFlags |= FUNC_Native; \
			break; \
	}	}

static UBOOL ClassIsA( UClass* InClass, FName InName)
{
	for( ; InClass; InClass=InClass->GetSuperClass() )
		if( InClass->GetFName() == InName )
			return 1;
	return 0;
}

UProperty* FindStrictScriptVariable( UStruct* InStruct, const TCHAR* PropName)
{
	guard(FindStrictScriptVariable);
	FName NAME_PropName = FName( PropName, FNAME_Find);
	check( NAME_PropName != NAME_None );
	for( TStrictFieldIterator<UProperty> Prop( InStruct ); Prop; ++Prop )
		if( Prop->GetFName() == NAME_PropName )
			return *Prop;
	appThrowf( (TEXT("Property not found in %s!!"), InStruct->GetName() ) );
	return NULL;
	unguardf( (PropName) );
}

/*-----------------------------------------------------------------------------
	Other utils
-----------------------------------------------------------------------------*/
	
static inline APlayerReplicationInfo* GetPRI( UNetConnection* Connection)
{
	APlayerPawn* PlayerPawn = Connection->Actor;
	return PlayerPawn ? PlayerPawn->PlayerReplicationInfo : nullptr;
}

#include "UtilClasses.h"
#include "sgGameReplicationInfo.h"
#include "sgPRI.h"
#include "sgCategoryInfo.h"
#include "sgBuilding.h"
#include "sgProtector.h"
#include "sgBaseBuildRule.h"
#include "sgBuildRuleCount.h"
#include "sgPlayerData.h"
#include "sgTranslocator.h"


//
// First function called upon actor spawn.
//
void ASiegeNativeActor::InitExecution()
{
	guard(ASiegeNativeActor::InitExecution);

	AActor::InitExecution(); //Validate that actor has been properly spawned in a level
	
	if ( Level->bBegunPlay )
	{
		debugf( NAME_SiegeNative, TEXT("[ERROR] This actor will only apply the hook if spawned via ServerActors!!!"));
		return;
	}
	
	if ( Level->Game && ((Level->NetMode == NM_DedicatedServer) || (Level->NetMode == NM_ListenServer)) )
	{
		RegisterNames();

		for( SiegeClass=Level->Game->GetClass() ; SiegeClass; SiegeClass=SiegeClass->GetSuperClass() ) //Level.Game.IsA('SiegeGI')
			if( appStricmp(SiegeClass->GetName(), TEXT("SiegeGI")) == 0 )
				break;

		// Not a Siege gametype
		if ( !SiegeClass )
			return;

		// Not a SiegeNative capable gametype
		UProperty* GCBind = FindField<UObjectProperty>( SiegeClass, TEXT("GCBind"));
		if ( !GCBind )
			return;

		// Save a reference to this class to prevent deletion via garbage collector
		debugf( NAME_SiegeNative, TEXT("Setting up SiegeNative for %s..."), Level->Game->GetPathName() );
		GetPropertyGeneric<UObject*>( Level->Game                                , GCBind) = GetClass();
		GetPropertyGeneric<UObject*>( Level->Game->GetClass()->GetDefaultObject(), GCBind) = GetClass();

		//Get some important offsets
		SGI_Cores_Offset = FindStrictScriptVariable( SiegeClass, TEXT("Cores"))->Offset;

		//Setup individual classes
		SiegePackage = (UPackage*) SiegeClass->GetOuter();
		sgGameReplicationInfo::InitClass();
		sgPRI::InitClass();
		sgCategoryInfo::InitClass();
		sgBuilding::InitClass();
		sgProtector::InitClass();
		sgBaseBuildRule::InitClass();
		sgBuildRuleCount::InitClass();
		sgPlayerData::InitClass();
		sgTranslocator::InitClass();
		debugf( NAME_SiegeNative, TEXT("Initialization complete") );
	}

	unguardobj;
}