class UIEnemyCounter_Panel extends UIPanel;

var localized string str_captured;
var localized string str_unconscious;
var localized string str_killed;
var int text_size;

var UIBGBox bg;
var UIBGBox bg_line;
var UIText CapturedText;
var UIText UnconsciousText;
var UIText KilledText;
var int NumCaptured;
var int NumUnconscious;
var int NumKilled;
var bool KillCounterEnabled;
var float PosX;
var float PosY;
var float CapturedTextY;

simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
    local UITacticalHUD TacticalScreen;
    local float Padding;
    local float TextPosX;

    super.InitPanel(InitName, InitLibID);

    `log("MonJamp_UIEnemyCounter::OnInit");

    RegisterForEvents();
    UpdateCounters();
    
    // Setup UI
    if(GetLanguage() == "RUS")
    {
        text_size = 16;
    }
    else
    {
        text_size = 18;
    }
    
    PosX = -140;
    PosY = -135;
    Padding = 5;
    TextPosX = PosX + Padding;

    TacticalScreen = UITacticalHUD(Screen);

    bg = Spawn(class'UIBGBox', TacticalScreen);
    bg.InitPanel('');
    bg.AnchorBottomRight();
    bg.SetPosition(PosX, PosY);
    bg.SetSize(135, 32*3);
    bg.ProcessMouseEvents(OnMouseEventDelegate);
    bg.OnMouseEventDelegate = OnClick;

    bg_line = Spawn(class'UIBGBox', TacticalScreen);
    bg_line.InitPanel('', class'UIUtilities_Controls'.const.MC_X2BackgroundShading);
    bg_line.AnchorBottomRight();
    bg_line.SetPosition(PosX, PosY + 32);
    bg_line.SetSize(135, 32);

    CapturedText = Spawn(class'UIText', TacticalScreen);
    CapturedText.InitText();
    //CapturedText.SetText("Captured: 0");
    CapturedText.SetHTMLText(GetHTMLString(str_captured, 18));
    // TODO: Is there a way to anchor off other UI elements?
    CapturedText.AnchorBottomRIght();
    CapturedText.SetColor("0x00C853");
    CapturedTextY = bg.Y + Padding;
    CapturedText.SetPosition(TextPosX, bg.Y + Padding);

    UnconsciousText = Spawn(class'UIText', TacticalScreen);
    UnconsciousText.InitText();
    UnconsciousText.SetHTMLText(GetHTMLString(str_unconscious, 18));
    UnconsciousText.AnchorBottomRIght();
    UnconsciousText.SetColor("0xFFC300");
    UnconsciousText.SetPosition(TextPosX, CapturedText.Y + CapturedText.Height);
    
    KillCounterEnabled = true;
    KilledText = Spawn(class'UIText', TacticalScreen);
    KilledText.InitText();
    KilledText.SetHTMLText(GetHTMLString(str_killed, 18));
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
    bg.Hide();
    bg_line.Hide();
    CapturedText.Hide();
    UnconsciousText.Hide();
    KilledText.Hide();
}

function ShowCounters()
{
    bg.Show();
    bg_line.Show();
    CapturedText.Show();
    UnconsciousText.Show();

    if(KillCounterEnabled)
        KilledText.Show();
}

function string GetHTMLString(string in_str, int fontSize)
{
    local string out_str;

    out_str = "<font size ='";
    out_str $= string(FontSize);
    out_str $= "'>";
    out_str $= in_str;
    out_str $= "</font>";

    return out_str;
}

function RefreshDisplayText()
{
    local string str;

    str = str_captured;
    str $= string(NumCaptured); // String concatenation in unreal engine
    CapturedText.SetHTMLText(GetHTMLString(str, text_size));

    str = str_unconscious;
    str $= string(NumUnconscious);
    UnconsciousText.SetHTMLText(GetHTMLString(str, text_size));

    KilledText.Show();
    str = str_killed;
    str $= string(NumKilled);
    KilledText.SetHTMLText(GetHTMLString(str, text_size));
}

function OnClick(UIPanel Panel, int Cmd)
{
    switch(cmd)
    {
        case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
            `log("EnemyCounter_Panel::OnClick");
            ToggleKillCounter();
            break;
    }
}

function ToggleKillCounter()
{

    `log("Counter Toggled!");

    KillCounterEnabled = !KillCounterEnabled;
    
    if(!KillCounterEnabled)
    {
        bg.SetHeight(32*2);
        bg.SetY(bg.Y + 32);
        bg_line.SetY(bg_line.Y + 32);
        CapturedText.SetY(CapturedText.Y + 32);
        UnconsciousText.SetY(UnconsciousText.Y + 32);
        KilledText.Hide();

        /*
        bg.AnimateHeight(32*2);
        NewY = Movie.GetScreenResolution().Y + bg.Y + 32;
        bg.AnimateY(NewY);
        NewY += 5 + 32;
        `log("CapturedText.Y = " $ string(NewY));
        CapturedText.AnimateY(NewY);
        CapturedText.MoveToHighestDepth();
        NewY += 32;
        UnconsciousText.AnimateY(NewY);
        KilledText.AnimateOut(0);
        */
    }
    else
    {
        bg.SetHeight(32*3);
        bg.SetY(bg.Y - 32);
        bg_line.SetY(bg_line.Y - 32);
        CapturedText.SetY(CapturedText.Y - 32);
        UnconsciousText.SetY(UnconsciousText.Y - 32);
        KilledText.Show();

        /*
        bg.AnimateHeight(32*3);
        NewY = Movie.GetScreenResolution().Y + bg.Y - 32;
        bg.AnimateY(NewY);
        NewY += 5 - 32;
        CapturedText.AnimateY(NewY);
        CapturedText.MoveToHighestDepth();
        NewY += 32;
        UnconsciousText.AnimateY(NewY);
        KilledText.AnimateIn(0);
        */
    }
}

simulated function UIPanel ProcessMouseEvents(optional delegate<OnMouseEventDelegate> MouseEventDelegate)
{
	OnMouseEventDelegate = MouseEventDelegate;
	return self;
}