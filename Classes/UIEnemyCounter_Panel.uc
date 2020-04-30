class UIEnemyCounter_Panel extends UIPanel;

var UIBGBox bg;
var UIText CapturedText;
var UIText UnconsciousText;
var UIText KilledText;
var int NumCaptured;
var int NumUnconscious;
var int NumKilled;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
    local UITacticalHUD TacticalScreen;
    local float PosX;
    local float PosY;
    local float Padding;
    local float TextPosX;

    super.InitPanel(InitName, InitLibID);

    `log("MonJamp_UIEnemyCounter::OnInit");

    RegisterForEvents();
    UpdateCounters();
    
    // Setup UI
    PosX = -140;
    PosY = -140;
    Padding = 5;
    TextPosX = PosX + Padding;

    TacticalScreen = UITacticalHUD(Screen);

    bg = Spawn(class'UIBGBox', TacticalScreen);
    bg.InitPanel('');
    bg.AnchorBottomRight();
    bg.SetPosition(PosX, PosY);
    bg.SetSize(135, 32*3);

    CapturedText = Spawn(class'UIText', TacticalScreen);
    CapturedText.InitText();
    //CapturedText.SetText("Captured: 0");
    CapturedText.SetHTMLText(GetHTMLString("Captured: 0", 12));
    // TODO: Is there a way to anchor off other UI elements?
    CapturedText.AnchorBottomRIght();
    CapturedText.SetColor("0x00C853");
    CapturedText.SetPosition(TextPosX, bg.Y + Padding);

    UnconsciousText = Spawn(class'UIText', TacticalScreen);
    UnconsciousText.InitText();
    UnconsciousText.SetHTMLText(GetHTMLString("Unconscious: 0", 12));
    UnconsciousText.AnchorBottomRIght();
    UnconsciousText.SetColor("0xFFC300");
    UnconsciousText.SetPosition(TextPosX, CapturedText.Y + CapturedText.Height);
    
    KilledText = Spawn(class'UIText', TacticalScreen);
    KilledText.InitText();
    KilledText.SetHTMLText(GetHTMLString("Killed: 0", 12));
    KilledText.AnchorBottomRIght();
    KilledText.SetColor("0xC70039");
    KilledText.SetPosition(TextPosX, UnconsciousText.Y + UnconsciousText.Height);

    RefreshDisplayText();

    return self;
}

// This event is triggered after a screen receives focus.
// This happens when another screen is on top of this screen, and that top screen
// is removed, the focus will call back down to this screen and trigger OnReceiveFocus.
simulated function OnReceiveFocus()
{
    `log("MonJamp_UIEnemyCounter::OnReceiveFocus");

    ShowCounters();
    RefreshDisplayText();
}
// This event is triggered after a screen loses focus.
// This happens when another screen is added to the stack on top of this screen,
// which triggers the current screen to lose focus and receive the OnLoseFocus event.
simulated function OnLoseFocus()
{
    `log("MonJamp_UIEnemyCounter::OnLoseFocus");

    HideCounters();
}
// This event is triggered when a screen is removed.
simulated function OnRemoved()
{
    `log("MonJamp_UIEnemyCounter::OnRemoved");

    HideCounters();
}

function RegisterForEvents()
{
    local Object SelfObject;

    `log("MonJamp_UIEnemyCounter::RegisterForEvents");

    // Call UpdateCounter every time a unit is unconscious, dies, or is captured
    SelfObject = self;
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitUnconscious',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitDied',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'UnitCaptured',	UpdateUI, ELD_OnVisualizationBlockCompleted);
    
    `XEVENTMGR.RegisterForEvent(SelfObject, 'BreachPhaseBegin', BeginBreachMode, ELD_OnVisualizationBlockCompleted);
    `XEVENTMGR.RegisterForEvent(SelfObject, 'BreachConfirmed', EndBreachMode, ELD_OnVisualizationBlockCompleted);
}

function EventListenerReturn UpdateUI(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    `log("MonJamp_UIEnemyCounter::UpdateUI");

    UpdateCounters();
    RefreshDisplayText();

    return ELR_NoInterrupt;
}

function EventListenerReturn BeginBreachMode(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    `log("MonJamp_UIEnemyCounter::BeginBreachMode");

    // Update counters before hiding
    UpdateCounters();
    RefreshDisplayText();
    HideCounters();

    return ELR_NoInterrupt;
}

function EventListenerReturn EndBreachMode(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    `log("MonJamp_UIEnemyCounter::EndBreachMode");

    UpdateCounters();
    RefreshDisplayText();
    ShowCounters();

    return ELR_NoInterrupt;
}

function UpdateCounters()
{
    local XComGameStateHistory History;
    local XComGameState_BattleData BattleData;
    local XComGameState_Unit Unit;

    `log("MonJamp_UIEnemyCounter::UpdateCounters");

    History = `XCOMHISTORY;
    BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

    NumCaptured = BattleData.CapturedUnconsciousUnits.Length;

    NumKilled = 0;
    NumUnconscious = 0;

    foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
    {
        if(Unit.ControllingPlayerIsAI())
        {
            if(Unit.IsUnconscious())
            {
                NumUnconscious++;
            }
            else if(!Unit.IsAlive())
            {
                NumKilled++;
            }
        }
    }
}

function HideCounters()
{
    CapturedText.Hide();
    UnconsciousText.Hide();
    KilledText.Hide();
}

function ShowCounters()
{
    CapturedText.Show();
    UnconsciousText.Show();
    KilledText.Show();
}

function string GetHTMLString(string in_str, int fontSize)
{
    local string out_str;

    out_str = "<font sizs ='";
    out_str $= string(FontSize);
    out_str $= "'>";
    out_str $= in_str;
    out_str $= "</font>";

    return out_str;
}

function RefreshDisplayText()
{
    local string str;

    str = "Captured: ";
    str $= string(NumCaptured); // String concatenation in unreal engine
    CapturedText.SetHTMLText(GetHTMLString(str, 12));

    str = "Unconscious: ";
    str $= string(NumUnconscious);
    UnconsciousText.SetHTMLText(GetHTMLString(str, 12));

    str = "Killed: ";
    str $= string(NumKilled);
    KilledText.SetHTMLText(GetHTMLString(str, 12));
}