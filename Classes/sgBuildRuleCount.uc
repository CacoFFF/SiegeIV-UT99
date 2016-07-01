//***********************************************************
// This is a category rule, it will enable techtree functions
// Building counter
//***********************************************************

class sgBuildRuleCount expands sgBaseBuildRule;

var bool bOnceOnly;
var bool bStopCounter;
var bool bOverTime;
var bool bOverTimeReached;
var bool bOnlyFinished;
var bool bExactMatch; //What to do with this?
var bool bPersistantTimer;
var int BuildCount;
var int TargetCount;
var class<sgBuilding> BuildClass;
var float MyTimer;
var float TargetTimer;
var float TargetLevel;

replication
{
	reliable if ( !bPersistantTimer && Role==ROLE_Authority )
		TargetTimer, BuildCount, TargetCount, bOverTimeReached;
	reliable if ( bNetinitial && Role==ROLE_Authority )
		BuildClass, bPersistantTimer, bOverTime;
	reliable if ( bPersistantTimer && Role==ROLE_Authority )
		MyTimer;
}

simulated function string GetRuleString( optional bool bNegative)
{
	if ( bOverTime && bNegative && bOverTimeReached )
		return "Not available in overtime";
	if ( bOverTime && !bOverTimeReached )
		return "Wait: Overtime";
	if ( bPersistantTimer ) //Cooldown mode
	{
		if ( MyTimer > 0 )
			return "Wait:"@int(MyTimer)@"seconds";
		return "Cooldown ready ("$int(TargetTimer)$")";
	}
	if ( BuildClass == none ) //Debug
		return "Error: no class";
	if ( bNegative )
	{
		if ( TargetTimer > 0 )
			return "Expires in"@int(MyTimer)@"seconds";
		return "Limit:"@BuildClass.default.BuildingName@"("$BuildCount$"/"$TargetCount$")";
	}
	if ( TargetTimer > 0 )
		return "Wait:"@int(MyTimer)@"seconds";
	return "Need:"@BuildClass.default.BuildingName@"("$BuildCount$"/"$TargetCount$")";
}

//Quick way to setup this
function AddRequiresLevel( float minLevel)
{
	bStopCounter = true;
	bOnlyFinished = true;
	SetTimer( 0.9 + FRand() * 0.1, true);
	TargetLevel = minLevel;
}

function NotifyIn( sgBuilding Other)
{
	if ( nextRule != none )
		nextRule.NotifyIn( Other);
	
	if ( !bStopCounter && (Other.class == BuildClass) )
		if ( ++BuildCount >= TargetCount )
		{
			if ( bOnceOnly )
				bStopCounter = true;
			if ( TargetTimer > 0 )
				GotoState('Timing');
		}
	
}

function NotifyOut( sgBuilding Other)
{
	if ( nextRule != none )
		nextRule.NotifyOut( Other);

	if ( !bStopCounter && (Other.class == BuildClass) )
		--BuildCount;
}

event Timer()
{
	local sgBuilding sgB;
	local int oldCount;

	oldCount = BuildCount;
	BuildCount = 0;
	ForEach AllActors ( class'sgBuilding', sgB)
	{
		if ( (sgB.Team == Team) && sgB.class == BuildClass && (sgB.SCount <= 0) && (sgB.Grade >= TargetLevel) )
			BuildCount++;
	}

	if ( (oldCount < TargetCount) && (BuildCount >= TargetCount) )
	{
		if ( TargetTimer > 0 )
			GotoState('Timing');
		if ( bOnceOnly )
			SetTimer(0, false);
	}

}

simulated function bool IsEnabled()
{
	if ( bOverTime && !bOverTimeReached )
		return false;
	if ( bPersistantTimer ) //Cooldown mode
		return (MyTimer <= 0);
	return (BuildCount >= TargetCount) && (TargetTimer <= 0);
}

state Timing
{
	function NotifyOut( sgBuilding Other)
	{
		Global.NotifyOut( Other);
		if ( !bPersistantTimer && (BuildCount < TargetCount) )
			GotoState('');
	}
	event Timer()
	{
		Global.Timer();
		if ( !bPersistantTimer && (BuildCount < TargetCount) )
			GotoState('');
	}
	event Tick( float DeltaTime)
	{
		MyTimer += (DeltaTime / 1.1);
		if ( MyTimer >= TargetTimer )
		{
			if ( bPersistantTimer )
				MyTimer = 0;
			else
			{
				TargetTimer = 0;
				BuildCount = TargetCount;
				bStopCounter = true;
				SetTimer(0,false);
			}
			GotoState('');
		}
	}
}

defaultproperties
{
    TargetCount=1
	NetPriority=1.2
	NetUpdateFrequency=4
}
