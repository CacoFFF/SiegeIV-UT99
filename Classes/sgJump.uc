//=============================================================================
// sgJump 
// nOs*Badger
//=============================================================================
class sgJump extends TournamentPickup;

var int TimeCharge;

function PickupFunction(Pawn Other)
{
    TimeCharge = 0;
    SetTimer(1.0, True);
}

function ResetOwner()
{
    local pawn P;

    P = Pawn(Owner);
    P.JumpZ = P.Default.JumpZ * Level.Game.PlayerJumpZScaling();
    if ( Level.Game.IsA('DeathMatchPlus') )
        P.AirControl = DeathMatchPlus(Level.Game).AirControl;
    else
        P.AirControl = P.Default.AirControl;
    P.bCountJumps = False;
}

function OwnerJumped()
{
    if ( Charge <= 0 ) 
    {
        if ( Owner != None )
        {
            Owner.PlaySound(DeActivateSound);                       
            Pawn(Owner).JumpZ = Pawn(Owner).Default.JumpZ * Level.Game.PlayerJumpZScaling();    
        }       
        UsedUp();
    }

    if ( !Pawn(Owner).bIsWalking )
    {
        TimeCharge=0;

            Owner.PlaySound(sound'BootJmp');                        
    }
    if( Inventory != None )
        Inventory.OwnerJumped();

Charge -= 1;


}

function Timer()
{

    if ( !Pawn(Owner).bAutoActivate )
    {   
        TimeCharge++;
        if (TimeCharge>20)
        {
            OwnerJumped();
            TimeCharge = 0;
        }
    }
}

state Activated
{
    function endstate()
    {
        ResetOwner();
        bActive = false;        
    }
Begin:
    Pawn(Owner).bCountJumps = True;
    Pawn(Owner).AirControl = 1.0;
    Pawn(Owner).JumpZ = Pawn(Owner).Default.JumpZ * 3+Charge;
    Owner.PlaySound(ActivateSound);     
}

state DeActivated
{
Begin:      
}

defaultproperties
{
     ExpireMessage="The AntiGrav Boots have drained."
     bAutoActivate=True
     bActivatable=True
     bDisplayableInv=True
     PickupMessage="You picked up the AntiGrav boots."
     ItemName="AntiGrav Boots"
     RespawnTime=30.000000
     PickupViewMesh=LodMesh'Botpack.jboot'
     Charge=3
     MaxDesireability=0.500000
     PickupSound=Sound'UnrealShare.Pickups.GenPickSnd'
     ActivateSound=Sound'Botpack.Pickups.BootSnd'
     Icon=Texture'UnrealI.Icons.I_Boots'
     RemoteRole=ROLE_DumbProxy
     Mesh=LodMesh'Botpack.jboot'
     AmbientGlow=64
     CollisionRadius=22.000000
     CollisionHeight=14.000000
}
