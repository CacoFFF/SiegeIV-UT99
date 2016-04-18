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

UBOOL NEQ(BYTE A,BYTE B,UPackageMap* Map) {return A!=B;}
UBOOL NEQ(INT A,INT B,UPackageMap* Map) {return A!=B;}
UBOOL NEQ(BITFIELD A,BITFIELD B,UPackageMap* Map) {return A!=B;}
UBOOL NEQ(FLOAT& A,FLOAT& B,UPackageMap* Map) {return *(INT*)&A!=*(INT*)&B;}
UBOOL NEQ(FVector& A,FVector& B,UPackageMap* Map) {return ((INT*)&A)[0]!=((INT*)&B)[0] || ((INT*)&A)[1]!=((INT*)&B)[1] || ((INT*)&A)[2]!=((INT*)&B)[2];}
UBOOL NEQ(FRotator& A,FRotator& B,UPackageMap* Map) {return A.Pitch!=B.Pitch || A.Yaw!=B.Yaw || A.Roll!=B.Roll;}
UBOOL NEQ(UObject* A,UObject* B,UPackageMap* Map) {return (Map->CanSerializeObject(A)?A:NULL)!=B;}
UBOOL NEQ(FName& A,FName B,UPackageMap* Map) {return *(INT*)&A!=*(INT*)&B;}
UBOOL NEQ(FColor& A,FColor& B,UPackageMap* Map) {return *(INT*)&A!=*(INT*)&B;}
UBOOL NEQ(FPlane& A,FPlane& B,UPackageMap* Map) {return
((INT*)&A)[0]!=((INT*)&B)[0] || ((INT*)&A)[1]!=((INT*)&B)[1] ||
((INT*)&A)[2]!=((INT*)&B)[2] || ((INT*)&A)[3]!=((INT*)&B)[3];}
UBOOL NEQ(FString A,FString B,UPackageMap* Map) {return A!=B;}

//nc = Class name
//v  = variable name (identical in both classes)
#define DOREP(nc,v) \
	{if( nc::ST_##v && NEQ(v,((nc*)Recent)->v,Map) ) \
	{ \
		*Ptr++ = nc::ST_##v->RepIndex; \
	}}
#define DOREPARRAY(nc,v) \
	if (nc::ST_##v) \
	{	for( INT i=0; i<ARRAY_COUNT(v); i++ ) \
			if( NEQ(v[i],((nc*)Recent)->v[i],Map) ) \
				*Ptr++ = nc::ST_##v->RepIndex+i; }

/*-----------------------------------------------------------------------------
	Entry point methods.
-----------------------------------------------------------------------------*/

static UClass* SiegeClass = NULL;
static INT SGI_Cores_Offset = 0;

#define LOAD_STATIC_PROPERTY(prop,onclass) ST_##prop = FindObject<UProperty>(onclass,TEXT(#prop))

//Macro: find a class in a package, store in static variable: [classname]_class
#define FIND_PRELOADED_CLASS(clname,onpackage) \
	{for ( TObjectIterator<UClass> It; It; ++It ) \
		if ( (It->GetOuter() == onpackage) && !appStricmp(It->GetName(),TEXT(#clname)) )	\
		{	\
			clname##_class = *It;	\
			break;	\
	}	}

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

#include "sgPRI.h"
#include "sgCategoryInfo.h"
#include "sgBuilding.h"
#include "sgProtector.h"
#include "sgBaseBuildRule.h"
#include "sgBuildRuleCount.h"

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

		debugf( NAME_SiegeNative, TEXT("Level validated, searching for Siege gametype...") );
		for( SiegeClass=Level->Game->GetClass() ; SiegeClass; SiegeClass=SiegeClass->GetSuperClass() ) //Level.Game.IsA('SiegeGI')
			if( appStricmp(SiegeClass->GetName(), TEXT("SiegeGI")) == 0 )
				break;
		if ( SiegeClass )
		{
			debugf( NAME_SiegeNative, TEXT("Siege gametype found: %s, prefetching and validating assets..."), Level->Game->GetClass()->GetFullName() );

			//Let main SiegeIV hold a reference to our class to prevent elimination via garbage collector
			{for( TFieldIterator<UObjectProperty> It(SiegeClass); It && It->GetOwnerClass()==SiegeClass; ++It )
				if ( appStricmp( It->GetName(), TEXT("GCBind")) == 0 )
				{
					//Register in both gameinfo and defaults (SiegeGI.GCBind = class'SiegeNativeActor';)
					*((UObject**) (((DWORD)Level->Game) + It->Offset)) = GetClass();
					*((UObject**) (((DWORD)Level->Game->GetClass()->GetDefaultObject()) + It->Offset)) = GetClass();
					break;
				}
			}
			
			SGI_Cores_Offset = FindStrictScriptVariable( SiegeClass, TEXT("Cores"))->Offset;


			//Setup individual classes
			UPackage* SiegePackage = (UPackage*) SiegeClass->GetOuter();
			Setup_sgPRI				( SiegePackage, GetLevel());
			Setup_sgCategoryInfo	( SiegePackage, GetLevel());
			Setup_sgBuilding		( SiegePackage, GetLevel());
			Setup_sgProtector		( SiegePackage, GetLevel());
			Setup_sgBaseBuildRule	( SiegePackage, GetLevel());
			Setup_sgBuildRuleCount	( SiegePackage, GetLevel());
		}
	}

	unguardobj;
}