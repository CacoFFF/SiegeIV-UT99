//These should never be instantiated on dedicated servers
class FV_GUI_Master expands Object;

var PlayerPawn LocalPlayer; //Identify local player
var FV_GUI_Panel Parent;
var string GUI_Code; //Identify objects and observe changes

var bool bLock; //Completely disables interaction
var bool bNoRender; //Do not propagate PostRender calls
var bool bNoTick; //Do not propagate Tick calls
var bool bNotifyHit;
var bool bNotifyDrag;
var bool bNotifyHold;
var bool bNotifyRelease;
var bool bNotifyHover;


function Created();
function PostRender( Canvas C);

//Ideal Code is:
// - 0x00: Indifferent to button
// - 0x01: Fire
// - 0x02: AltFire

function Tick( float DeltaTime);
function PointerHit( float X, float Y, optional byte Code);
function PointerDrag( float X, float Y, float eX, float eY, optional byte Code);
function PointerHold( float DeltaTime, optional byte Code); //Can be called together with PointerDrag! (before PointerDrag)
function PointerRelease( float X, float Y, optional byte Code);
function PointerHover( float X, float Y);

//Mainframe got resized, either window or a small space within
function FrameResized( float oX, float oY, float XL, float YL);

final function InheritFrom( FV_GUI_Panel InParent)
{
	Parent = InParent; //This should match outer GUI if possible
	LocalPlayer = Parent.LocalPlayer;
}

static final function Color MakeColor( byte R, byte G, byte B, optional byte A)
{
	local Color C;
	C.R = R;
	C.G = G;
	C.B = B;
	C.A = A;
	return C;
}