//=============================================================================
//=============================================================================

//Visual Studio 2015 directives
#pragma warning (disable : 4458) //Allow functions to override global variable names
#pragma warning (disable : 4459) //Allow functions to override global variable names
#pragma warning (disable : 4243) //Allow derivate natives from protected class to be used in master class
#pragma warning (disable : 4297) //Constructors and destructors allowed to throw
#define _CRT_SECURE_NO_WARNINGS //Because older string methods are no longer used

#ifndef _INC_SGBASE
#define _INC_SGBASE


//#define XC_CORE_API DLL_IMPORT

#ifndef __LINUX_X86__
	#define CORE_API DLL_IMPORT
	#define SIEGENATIVE_API DLL_EXPORT
	#define _WIN32_WINNT 0x0501
	#include <windows.h>
	#include <shlobj.h>
#else
	//If we don't disable this, v436 std (some builds) won't be able to run this mod
	#define DO_GUARD 0
	#include <unistd.h>	
#endif

//Safely empty a dynamic array on UT v451
#define SafeEmpty( A) if (A.GetData()) A.Empty()
#define SafeEmptyR( A) if (A->GetData()) A->Empty()


//Engine includes
#include "Engine.h"


//Script
#define warnf GWarn->Logf
#define debugf GLog->Logf
#define NAME_SiegeNative (EName)SIEGENATIVE_SiegeNative.GetIndex()

//XC_Core
//#include "UnXC_Math.h"
//#include "MEMCPY_AMD.h" //Should be better than the default appMemcpy

//Classes here
#include "SiegeNativeClasses.h"

#ifdef __LINUX_X86__
	#undef CPP_PROPERTY
	#define CPP_PROPERTY(name) \
		EC_CppProperty, (BYTE*)&((ThisClass*)1)->name - (BYTE*)1
#endif

#endif
