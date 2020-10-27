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

static UClass* SiegeClass = nullptr;
static PTRINT SGI_Cores_Offset = 0;

#define DEFINE_SIEGENATIVE_CLASS(newclass) \
	typedef newclass ThisClass; \
	static void InternalConstructor( void* X ) { new( (EInternal*)X )newclass(); }

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

#undef VERIFY_CLASS_SIZE
#define VERIFY_CLASS_SIZE(onclass) \
	onclass->Bind(); \
	if ( sizeof(ThisClass) != (PTRINT)onclass->PropertiesSize ) \
		appErrorf(TEXT("Class %s size mismatch: Script=%i C++=%i"), onclass->GetName(), (INT)onclass->PropertiesSize, sizeof(ThisClass));


//Macro: find a class in a package, store in static variable: [classname]_class
#define FIND_PRELOADED_CLASS(clname,onpackage) \
	{for ( TObjectIterator<UClass> It; It; ++It ) \
		if ( (It->GetOuter() == onpackage) && !appStricmp(It->GetName(),TEXT(#clname)) )	\
		{	\
			clname##_class = *It;	\
			break;	\
	}	}
	
//Macro: load a class in a package, store in static variable: [classname]_class
#define PRELOAD_CLASS(clname,onpackage) \
	clname##_class = UObject::StaticLoadClass( UObject::StaticClass(), onpackage, TEXT(#clname), NULL, LOAD_NoWarn | LOAD_Quiet, NULL)
//	static UClass* StaticLoadClass( UClass* BaseClass, UObject* InOuter, const TCHAR* Name, const TCHAR* Filename, DWORD LoadFlags, UPackageMap* Sandbox );

//Macro: Make class able to use NativeReplication features
#define SETUP_CLASS_NATIVEREP(clname) \
	if ( clname##_class->ClassConstructor != clname::InternalConstructor ) \
	{ \
		clname##_class->ClassConstructor = clname::InternalConstructor; \
		clname##_class->ClassFlags |= CLASS_NativeReplication; \
	}

//Macro: Make this class and it's derivate inherit this NativeReplication
//Other classes loaded after this macro will inherit ClassConstructor
#define PROPAGATE_CLASS_NATIVEREP(clname) \
	{ clname##_class->ClassFlags |= CLASS_NativeReplication; \
	for ( TObjectIterator<UClass> It; It; ++It ) \
		if ( It->IsChildOf(clname##_class) ) \
			It->ClassConstructor = clname::InternalConstructor; \
	}
	

static UClass* GetClass( UPackage* Package, const TCHAR* ClassName)
{
//	debugf( NAME_SiegeNative, TEXT("Loading class %s"), ClassName);
	UClass* Result = FindObject<UClass>( Package, ClassName, true);
	if ( !Result )
		Result = LoadClass<AActor>( Package, ClassName, TEXT(""), 0, nullptr);
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
	{ for ( TStrictFieldIterator<UFunction> It(clname##_class) ; It ; ++It ) \
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


#include "UtilClasses.h"
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
		UPackage* SiegePackage = (UPackage*) SiegeClass->GetOuter();
		Setup_sgPRI				( SiegePackage, GetLevel());
		Setup_sgCategoryInfo	( SiegePackage, GetLevel());
		Setup_sgBuilding		( SiegePackage, GetLevel());
		Setup_sgProtector		( SiegePackage, GetLevel());
		Setup_sgBaseBuildRule	( SiegePackage, GetLevel());
		Setup_sgBuildRuleCount	( SiegePackage, GetLevel());
		Setup_sgPlayerData		( SiegePackage, GetLevel());
		Setup_sgTranslocator	( SiegePackage, GetLevel());
		debugf( NAME_SiegeNative, TEXT("Initialization complete") );
	}

	unguardobj;
}