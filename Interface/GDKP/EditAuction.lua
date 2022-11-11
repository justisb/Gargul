---@type GL
local _, GL = ...;

GL.AceGUI = GL.AceGUI or LibStub("AceGUI-3.0");
local AceGUI = GL.AceGUI;

---@class EditAuction
GL.Interface.GDKP.EditAuction = {}

---@type EditAuction
local EditAuction = GL.Interface.GDKP.EditAuction;

---@return void
function EditAuction:draw(session, checksum)
    GL:debug("GDKP.Edit:draw");

    local VerticalSpacer;

    -- Release any existing edit auction window
    self:close();

    session = tostring(session);
    checksum = tostring(checksum);
    local Auction = GL.DB:get(string.format("GDKP.Ledger.%s.Auctions.%s", session, checksum));

    -- The given GDKP Ledger entry does not exist
    if (not Auction) then
        return;
    end

    ---@type GDKPOverview
    local Overview = GL.Interface.GDKP.Overview;

    -- Create a container/parent frame
    local Window = AceGUI:Create("InlineGroup");
    Window:SetLayout("Flow");
    Window:SetWidth(300);
    Window:SetHeight(280);
    Window:SetPoint("TOPLEFT", GL.Interface:getItem(Overview, "Window").frame, "TOPRIGHT", 2, 16);
    GL.Interface:setItem(self, "Window", Window);
    Window.frame:SetFrameStrata("HIGH");
    Window.frame:Show();

    local ItemLink = AceGUI:Create("Label");
    ItemLink:SetFontObject(_G["GameFontNormal"]);
    ItemLink:SetFullWidth(true);
    ItemLink:SetText(string.format(
        "|cFF%s%s|r paid |cFF%s%sg|r for\n%s",
        GL:classHexColor(Auction.Winner.class),
        Auction.Winner.name,
        GL:classHexColor("rogue"),
        Auction.price,
        GL.DB.Cache.ItemsByID[tostring(Auction.itemID)].link
    ));
    Window:AddChild(ItemLink);

    VerticalSpacer = AceGUI:Create("SimpleGroup");
    VerticalSpacer:SetLayout("FILL");
    VerticalSpacer:SetFullWidth(true);
    VerticalSpacer:SetHeight(4);
    Window:AddChild(VerticalSpacer);

    local DropDownItems = {};
    local ItemOrder = {};

    local Sessions = GL.DB:get("GDKP.Ledger");
    table.sort(Sessions, function (a, b)
        return a.createdAt < b.createdAt;
    end);
    for _, Session in pairs(Sessions) do
        DropDownItems[Session.ID] = Session.title;
        tinsert(ItemOrder, Session.ID);
    end

    local SessionDropdown = AceGUI:Create("Dropdown");
    SessionDropdown:SetValue(session);
    SessionDropdown:SetList(DropDownItems, ItemOrder);
    SessionDropdown:SetText(DropDownItems[session]);
    SessionDropdown:SetLabel("Session");
    SessionDropdown:SetWidth(250);
    Window:AddChild(SessionDropdown);

    local PlayernameInput = GL.AceGUI:Create("EditBox");
    PlayernameInput:DisableButton(true);
    PlayernameInput:SetHeight(20);
    PlayernameInput:SetWidth(250);
    PlayernameInput:SetText(Auction.Winner.name);
    PlayernameInput:SetLabel("Player name");
    Window:AddChild(PlayernameInput);

    local Checkbox = AceGUI:Create("CheckBox");
    Checkbox:SetValue(Auction.paid);
    Checkbox:SetLabel("Paid");
    Checkbox:SetFullWidth(true);
    Checkbox.text:SetTextColor(.99, .85, .06);
    Checkbox.text:SetFontObject(_G["GameFontHighlightSmall"]);
    Window:AddChild(Checkbox);

    local SaveButton = AceGUI:Create("Button");
    SaveButton:SetText("Save");
    SaveButton:SetWidth(100); -- Minimum is 60
    SaveButton:SetCallback("OnClick", function()
        local somethingChanged = false;
        local newName = strtrim(PlayernameInput:GetText());

        -- The winner was changed
        if (not GL:empty(newName)
            and Auction.Winner.name ~= newName
        ) then
            GL.DB:set(string.format("GDKP.Ledger.%s.Auctions.%s.Winner.name", session, checksum, newName));
            somethingChanged = true;
        end

        -- The session was changed (make sure we do this last!)
        if (session ~= SessionDropdown:GetValue()) then
            GL.GDKP:moveAuction(checksum, session, SessionDropdown:GetValue());
            somethingChanged = true;
        end

        if (somethingChanged) then
            Overview:drawDetails(session);
            self:close();
        end
    end);
    Window:AddChild(SaveButton);

    local CancelButton = AceGUI:Create("Button");
    CancelButton:SetText("Cancel");
    CancelButton:SetWidth(100); -- Minimum is 60
    CancelButton:SetCallback("OnClick", function()
        self:close();
    end);
    Window:AddChild(CancelButton);
end

function EditAuction:close()
    GL.Interface:release(self, "Window");
end

GL:debug("Interfaces/GDKP/EditAuction.lua");