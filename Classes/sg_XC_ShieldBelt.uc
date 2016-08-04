// Shieldbelt subclass, for Siege.
// Made by Higor

class sg_XC_ShieldBelt extends UT_ShieldBelt;

var float NUF_Timer;
var UT_Invisibility Invis;

function bool HandlePickupQuery( inventory Item )
{
	local Inventory I;

	if (item.class == class) //Increase charge by 50
	{
			Charge = 150;

			if (Level.Game.LocalLog != None)
				Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
			if (Level.Game.WorldLog != None)
				Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));

			if ( Item.PickupMessageClass == None )
				Pawn(Owner).ClientMessage(item.PickupMessage, 'Pickup');
			else
				Pawn(Owner).ReceiveLocalizedMessage( item.PickupMessageClass, 0, None, None, item.Class );

			Item.PlaySound (item.PickupSound,,2.0);
			Item.SetReSpawn();
			return true;
	}
	else if (item.class == class'UT_ShieldBelt') //Absorb other shield belts into self
	{
		Charge = 150;

		if (Level.Game.LocalLog != None)
			Level.Game.LocalLog.LogPickup(Item, Pawn(Owner));
		if (Level.Game.WorldLog != None)
			Level.Game.WorldLog.LogPickup(Item, Pawn(Owner));
		if ( Item.PickupMessageClass == None )
			Pawn(Owner).ClientMessage(item.PickupMessage, 'Pickup');
		else
			Pawn(Owner).ReceiveLocalizedMessage( item.PickupMessageClass, 0, None, None, item.Class );
		Item.PlaySound (item.PickupSound,,2.0);
		Item.SetReSpawn();
		return true;
	}


	if ( Inventory == None )
		return false;

	return Inventory.HandlePickupQuery(Item);
}

function PickupFunction(Pawn Other)
{
	local Inventory I;

	if ( Owner == none )
		SetOwner( Other);

	MyEffect = Spawn(class'UT_ShieldBeltEffect', Other,,Other.Location, Other.Rotation); 
	MyEffect.Mesh = Owner.Mesh;
	MyEffect.DrawScale = Owner.Drawscale;

	if ( Level.Game.bTeamGame && (Other.PlayerReplicationInfo != None) )
		TeamNum = Other.PlayerReplicationInfo.Team;
	else
		TeamNum = 3;
	SetEffectTexture();
	Tick(0.0f);


	for ( I=Other.Inventory; I!=None; I=I.Inventory )
	{
		if ( I.class == class'UT_ShieldBelt' )
		{
			Charge = 150;
			I.Destroy();
		}
		else if ( I.Class == class'WildcardsMetalSuit' || I.Class == class'WildcardsRubberSuit' )
		{
			I.Charge -= I.Default.Charge / 2;
			if ( I.Charge <= 0 )
				I.Destroy();
		}
	}
	SetTimer(0.5, true);
}

event Tick( float DeltaTime)
{
	local Pawn POwner;

	Super.Tick( DeltaTime);

	POwner = Pawn(Owner);
	if ( POwner == none || MyEffect == None )
		return;

	if ( POwner.bMeshEnviroMap && POwner.Texture == FireTexture'unrealshare.Belt_fx.Invis' ) //Player has an invisibility powerup
	{
		MyEffect.DrawType = DT_None;
		MyEffect.bHidden = true;
		if ( NUF_Timer < 0.3 ) //Update ASAP to make sure the clients can null Owner before Timer() hits on the effect
			MyEffect.NetUpdateFrequency = 100;
		else
			MyEffect.NetUpdateFrequency = MyEffect.default.NetUpdateFrequency;
		NUF_Timer += DeltaTime / Level.TimeDilation;
		MyEffect.SetOwner(None);
	}
	else
	{
		MyEffect.DrawType = DT_Mesh;
		MyEffect.bHidden = false;
		MyEffect.SetLocation(Owner.Location);
		MyEffect.SetOwner(Owner);
		NUF_Timer = 0;
	}
}