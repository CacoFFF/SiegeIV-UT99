//***********************************************************
// This is a category rule, it will enable techtree functions
//***********************************************************

class sgBaseBuildRule expands Info;


var string RuleString;			//String used to create this rule
var string RuleName;			//Used for initial parenting set
var byte Team;					//Team this rule works for
var sgBaseBuildRule nextRule;	//Serverside chained list
var name TagList[4];			//Team tags for faster iterations in client
var sgCategoryInfo Master;		//Category Info actor
var int AppliedOn[4];			//Bitwise array for the Master category info

replication
{
	reliable if ( bNetInitial && Role==ROLE_Authority )
		RuleName, Team, AppliedOn;
}

function NotifyIn( sgBuilding Other)
{
	if ( nextRule != none )
		nextRule.NotifyIn( Other);
}

function NotifyOut( sgBuilding Other)
{
	if ( nextRule != none )
		nextRule.NotifyOut( Other);
}

simulated function bool IsEnabled()
{
	return True;
}


simulated function bool IsChildRule( sgBaseBuildRule Other);
simulated function AddChild( sgBaseBuildRule Other);
simulated function string GetRuleString( optional bool bNegative);

simulated event PostNetBeginPlay()
{
	local sgBaseBuildRule sgB;
	local sgCategoryInfo sgC;

	Tag = TagList[Team];

	ForEach AllActors (class'sgCategoryInfo', sgC)
	{
		if ( sgC.Team == Team )
		{
			Master = sgC;
			nextRule = sgC.RuleList;
			sgC.RuleList = self;
			MasterSet();
			break;
		}
	}

	//Hook all rules to each other
	ForEach AllActors (class'sgBaseBuildRule', sgB, Tag)
	{
		if ( sgB.IsChildRule( self) )
			sgB.AddChild( self);
		else if ( IsChildRule( sgB) )
			AddChild( sgB);
	}
}

//Set all rule references to this actor in Master, simulated via bitwise replication
simulated function MasterSet()
{
	local int i, k;
	For ( k=0 ; k<4 ; k++ )
		For ( i=0 ; i<32 ; i++ )
			if ( (AppliedOn[k] & (1 << i)) != 0 )
				Master.SetRule(32*k + i, self);
}


defaultproperties
{
	bAlwaysRelevant=True
	RemoteRole=ROLE_SimulatedProxy
	TagList(0)=RedRule
	TagList(1)=BlueRule
	TagList(2)=GreenRule
	TagList(3)=YellowRule
	Team=255
	NetUpdateFrequency=2
	NetPriority=1.6
}