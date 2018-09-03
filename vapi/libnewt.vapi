[CCode (cheader_filename = "newt.h")]
namespace Newt {
    [CCode (cname = "newtInit")]
    public int newtInit();

    [CCode (cname = "newtCls")]
    public void newtCls();

    [CCode (cname = "newtFinished")]
    public int newtFinished();

    [CCode (cname = "newtDrawRootText")]
    public void newtDrawRootText(int col, int row, string text);

    [SimpleType]
    [CCode (cname = "newtComponent", destroy_function = "", has_type_id = false)]
    public struct newtComponent {}

    [CCode (cname = "newtCenteredWindow")]
    public int newtCenteredWindow(int width, int height, string title);

    [CCode (cname = "newtTextbox")]
    public newtComponent newtTextbox(int left, int top, int width, int height, int flags);

    [CCode (cname = "newtTextboxSetText")]
    public void newtTextboxSetText(newtComponent co, string text);

    [CCode (cname = "newtCompactButton")]
    public newtComponent newtCompactButton(int left, int top, string text);

    [CCode (cname = "newtForm")]
    public newtComponent newtForm(newtComponent? vertBar, void * helpTag, int flags);

    [CCode (cname = "newtFormAddComponent")]
    public void newtFormAddComponent(newtComponent form, newtComponent co);

    [CCode (cname = "newtRunForm")]
    public newtComponent newtRunForm(newtComponent form);

    [CCode (cname = "newtEntryGetValue")]
    public unowned string newtEntryGetValue(newtComponent co);

    [CCode (cname = "newtEntry")]
    public newtComponent newtEntry(int left, int top, string? initialValue, int width, out string? resultPtr, int flags);

    [CCode (cname = "newtFormDestroy")]
    public void newtFormDestroy(newtComponent form);

    [CCode (cname = "newtPopWindow")]
    public void newtPopWindow();

    [CCode (cname = "newtTextboxSetColors")]
    public void newtTextboxSetColors(newtComponent co, int normal, int active);

    [CCode (cname = "newtListbox")]
    public newtComponent newtListbox(int left, int top, int height, int flags);

    [CCode (cname = "newtListboxSetWidth")]
    public void newtListboxSetWidth(newtComponent co, int width);

    [CCode (cname = "newtListboxAppendEntry")]
    public int newtListboxAppendEntry(newtComponent co, string text, void* data);

    [CCode (cname = "newtListboxGetCurrent")]
    public void* newtListboxGetCurrent(newtComponent co);

    [CCode (cname = "newtLabel")]
    public newtComponent newtLabel(int left, int top, string text);

    [CCode (cname = "newtFormSetCurrent")]
    public void newtFormSetCurrent(newtComponent co, newtComponent subco);

    [CCode (cname = "newtComponentTakesFocus")]
    public void newtComponentTakesFocus(newtComponent co, bool val);

    [CCode (cname = "newtListboxClear")]
    public void newtListboxClear(newtComponent co);

    [CCode (cname = "newtEntrySet")]
    public void newtEntrySet(newtComponent co, string value, int cursorAtEnd);

    [CCode (cname = "newtLabelSetText")]
    public void newtLabelSetText(newtComponent co, string text);

    [CCode (cname = "newtCheckbox")]
    public newtComponent newtCheckbox(int left, int top, string text, char defValue, string seq, string? result);

    [CCode (cname = "newtCheckboxGetValue")]
    public char newtCheckboxGetValue(newtComponent co);

    [CCode (cname = "newtCheckboxSetValue")]
    public void newtCheckboxSetValue(newtComponent co, char value);

    [CCode (cname = "int", cprefix = "NEWT_FLAG_", has_type_id = false)]
    [Flags]
    public enum Flag {
        WRAP,
        PASSWORD,
        RETURNEXIT,
        SCROLL,
        BORDER
    }

    [CCode (cname = "int", cprefix = "NEWT_COLORSET_", has_type_id = false)]
    public enum Colorset {
        ROOT,
        BORDER,
        WINDOW,
        SHADOW,
        TITLE,
        BUTTON,
        ACTBUTTON,
        CHECKBOX,
        ACTCHECKBOX,
        ENTRY,
        LABEL,
        LISTBOX,
        ACTLISTBOX,
        TEXTBOX,
        ACTTEXTBOX,
        HELPLINE,
        ROOTTEXT,
        EMPTYSCALE,
        FULLSCALE,
        DISENTRY,
        COMPACTBUTTON,
        ACTSELLISTBOX,
    }
}
