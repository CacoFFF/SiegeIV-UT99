//=============================================================================
// IntFileWriter.
// By Higor
//=============================================================================
class IntFileWriter expands StatLogFile;

var string Extension;

var string Locales[8];

//Create base file locales
function CheckLocalization()
{
	local int i;
	local string FileName;
	local bool bSuccess;

	Extension = Localize ( "Siege", "LangExt", "SiegeL");
	Log( Extension);
	//Do version check
	if ( Len(Extension) != 3 ) //<?int?SiegeL.Siege.LangExt?> is a common answer when no locale
	{
		Extension = Mid(Extension,2,3);
		For ( i=0 ; i<ArrayCount(Locales) ; i++ )
		{
			if ( !(Extension ~= Locales[i]) )
				continue;
			bSuccess = true;
			Extension = Locales[i]; //Correct case
			FileName = "SiegeL.";
			StatLogFile = FileName $ "tmp";
			StatLogFinal = FileName $ Locales[i];
			OpenLog();
			StartHeader("[Siege]");
			AddProperty("LangExt", Locales[i]);
			AddString("");
			//Do proper localization in the future (spawn a localizator)
			CloseLog();
		}
	}
	if ( !bSuccess )
		Extension = "int";
}

event PostBeginPlay()
{
	CheckLocalization();
}

/*
function CreateOutput( PlayerPawn Sender, string CreateThisName)
{
	local XC_PathNode PNode;
	local int i, j;

	StartWriter( CreateThisName);
	StartHeader();
	StartActor("LevelInfo");
	EndActor();

	ForEach AllActors (class'XC_PathNode', PNode)
	{
		StartActor( "PathNode" );
		AddVector( "Location", PNode.Location);
		AddRotator( "Rotation", PNode.Rotation);
		AddProperty( "bCollideWhenPlacing", "False");
		EndActor();
	}

	EndExport();
	Sender.ClientMessage("Output generated succesfully on "$CreateThisName$".t3d");
	Destroy();
}
*/


function StartWriter( string ExportString)
{
	if ( ExportString == "" )
		ExportString = "Export";

	StatLogFile = ExportString$".tmp";
	if ( InStr(ExportString,".") < 0 )
		StatLogFinal = ExportString$"."$ Extension;
	else
		StatLogFinal = ExportString;

	OpenLog();
}

function StartHeader( string FirstLine)
{
	AddString( chr(65279)$ FirstLine);
}



function AddVector( string VectorName, vector vTemp)
{
	local string sTemp;
	if ( vTemp == vect(0,0,0) )
		return;

	sTemp = "    "$VectorName$"=(";

	if ( vTemp.X != 0)
		sTemp = sTemp $ "X="$string(vTemp.X)$",";
	if ( vTemp.Y != 0)
		sTemp = sTemp $ "Y="$string(vTemp.Y)$",";
	if ( vTemp.Z != 0)
		sTemp = sTemp $ "Z="$string(vTemp.Z);
	sTemp = sTemp $ ")";

	AddString( sTemp);
}

function AddRotator( string RotatorName, rotator rTemp)
{
	local string sTemp;
	if ( rTemp == rot(0,0,0) )
		return;

	sTemp = "    "$RotatorName$"=(";

	if ( rTemp.Pitch != 0)
		sTemp = sTemp $ "Pitch="$string(rTemp.Pitch)$",";
	if ( rTemp.Yaw != 0)
		sTemp = sTemp $ "Yaw="$string(rTemp.Yaw)$",";
	if ( rTemp.Roll != 0)
		sTemp = sTemp $ "Roll="$string(rTemp.Roll);
	sTemp = sTemp $ ")";

	AddString( sTemp);
}

function AddProperty( string PropertyName, coerce string PropertyValue)
{
	AddString( PropertyName$"="$PropertyValue );
}

function AddIntDesc( string NameStr, string MetaClass, coerce string Description)
{
	AddString( "Object=(Name="$NameStr$",Class=Class,MetaClass="$MetaClass$",Description="$ chr(34) $Description$ chr(34) $")");
}

function AddString( string EventString )
{
	FileLog( EventString );
	FlushLog();
}

defaultproperties
{
	Locales(0)=int
	Locales(1)=est
	Locales(2)=itt
	Locales(3)=frt
	Locales(4)=kot
	Locales(5)=tct
	Locales(6)=rut
	Locales(7)=det
}
