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
	#define SIEGENATIVE_API DLL_EXPORT
	#define _WIN32_WINNT 0x0501
#else
	//If we don't disable this, v436 std (some builds) won't be able to run this mod
	#include <unistd.h>	
#endif


//Engine includes
#include "Engine.h"


//Script
#define NAME_SiegeNative (EName)SIEGENATIVE_SiegeNative.GetIndex()

//Classes here
#include "SiegeNativeClasses.h"

#endif
