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

//nc = c++ hack class
//cc = UScript class
//v  = variable name (identical in both classes)
#define DOREP(nc,cc,v) \
	if( NEQ(v,((nc*)Recent)->v,Map) ) \
	{ \
		static UProperty* sp##v = FindObjectChecked<UProperty>(cc,TEXT(#v)); \
		*Ptr++ = sp##v->RepIndex; \
	}
#define DOREPARRAY(nc,cc,v) \
	static UProperty* sp##v = FindObjectChecked<UProperty>(cc,TEXT(#v)); \
	for( INT i=0; i<ARRAY_COUNT(v); i++ ) \
		if( NEQ(v[i],((nc*)Recent)->v[i],Map) ) \
			*Ptr++ = sp##v->RepIndex+i;

/*-----------------------------------------------------------------------------
	Entry point methods.
-----------------------------------------------------------------------------*/

#include "sgPRI.h"

//
// First function called upon actor spawn.
//
void ASiegeNativeActor::InitExecution()
{
	guard(ASiegeNativeActor::InitExecution);

	AActor::InitExecution(); //Validate that actor has been properly spawned in a level
	
	if ( Level->Game && ((Level->NetMode == NM_DedicatedServer) || (Level->NetMode == NM_ListenServer)) )
	{
		RegisterNames();

		debugf( NAME_SiegeNative, TEXT("Level validated, searching for Siege gametype...") );
		UClass* SiegeClass = Level->Game->GetClass();
		for( ; SiegeClass; SiegeClass=SiegeClass->GetSuperClass() ) //Level.Game.IsA('SiegeGI')
			if( appStricmp(SiegeClass->GetName(), TEXT("SiegeGI")) == 0 )
				break;
		if ( SiegeClass )
		{
			debugf( NAME_SiegeNative, TEXT("Siege gametype found: %s, prefetching and validating assets..."), Level->Game->GetClass()->GetFullName() );
			UPackage* SiegePackage = (UPackage*) SiegeClass->GetOuter();
			Setup_sgPRI( SiegePackage);
		}
	}

	unguardobj;
}