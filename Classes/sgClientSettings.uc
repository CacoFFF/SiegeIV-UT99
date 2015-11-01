//*****************************
// Siege Client settings class
//*****************************
class sgClientSettings expands Object
	config
	perobjectconfig;

var() config bool bUseSmallGui;
var() config bool bOldConstructor;
var() config bool bBuildingLights;
var() config float GuiSensitivity; //0-1
var() config float SirenVol; //0-1
var() config string FingerPrint;
var() config bool bFPnoReplace; //Never replace fingerprint
var() config bool bUseLC; //Lag compensation >>>> DEPRECATED
var() config bool bBuildInfo;
var() config bool bClientIGDropFix;
var() config bool bHighPerformance;
var() config float ScoreboardBrightness;


defaultproperties
{
     SirenVol=1
     GuiSensitivity=0.5
     bOldConstructor=True
     bUseLC=True
     bBuildInfo=True
}
