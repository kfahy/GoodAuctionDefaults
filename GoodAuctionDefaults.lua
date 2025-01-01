-- Store the last item ID placed in the "for sale" slot. Read upon auction
-- creation.
local last_item_id

-- Load Blizzard's UI so that we can hook into scripts and access globals.
LoadAddOn('Blizzard_AuctionUI')

-- Safely gets a SavedVariables table that stores all the prices.
local function get_saved_prices()
  if type(GoodAuctionDefaultsPrices) ~= 'table' then
    GoodAuctionDefaultsPrices = {}
  end
  return GoodAuctionDefaultsPrices
end

-- Runs after the function of the same name in Blizzard_AuctionUI.lua. Listens
-- for items added to the "for sale" slot, and attempts to set a default price.
-- If an item is added, then it stores the value in the last_item_id variable.
local function AuctionSellItemButton_OnEvent(self, event, ...)
  if event ~= 'NEW_AUCTION_UPDATE' then
    return
  end

  local item_id = select(10, GetAuctionSellItemInfo())
  if item_id then
    -- Default the duration to the longest (24 hours)
    AuctionsShortAuctionButton:SetChecked(nil)
    AuctionsMediumAuctionButton:SetChecked(nil)
    AuctionsLongAuctionButton:SetChecked(1)
    AuctionFrameAuctions.duration = 3
    UpdateDeposit()

    -- This item was added to the "for sale" slot
    last_item_id = item_id
    local saved_price_per_unit = get_saved_prices()[item_id]
    if saved_price_per_unit then
      -- We've sold this item before - fill in a default price.
      local count = select(3, GetAuctionSellItemInfo())
      local saved_price = saved_price_per_unit * count
      MoneyInputFrame_SetCopper(StartPrice, saved_price)
      MoneyInputFrame_SetCopper(BuyoutPrice, saved_price)
    end
  end
end

AuctionsItemButton:HookScript('OnEvent', AuctionSellItemButton_OnEvent)

-- Runs after the function of the same name in Blizzard_AuctionUI.lua. Persists
-- the buyout price at which an item was sold.
local function AuctionsCreateAuctionButton_OnClick()
  if last_item_id and LAST_ITEM_BUYOUT then
    -- After StartAuction() is called, the money input frame is zeroed out, so
    -- grab the price captured in a global variable by Blizzard code.
    get_saved_prices()[last_item_id] = math.ceil(
      LAST_ITEM_BUYOUT / LAST_ITEM_COUNT
    )
  end
end

AuctionsCreateAuctionButton:HookScript(
  'OnClick',
  AuctionsCreateAuctionButton_OnClick
)

-- Show vendor and auction price tooltips
hooksecurefunc(GameTooltip, 'SetBagItem', function(tt, bag, slot)
  local item = select(2, tt:GetItem())
  if not item then
    return
  end

  -- Don't show a price if the item cannot be sold
  local vendor_price = select(11, GetItemInfo(item))
  if not vendor_price or vendor_price <= 0 then
    return
  end

  -- Show the vendor price for the stack by default, or by unit if shift is held
  local item_info = C_Container.GetContainerItemInfo(bag, slot)
  local count = item_info and item_info.stackCount or 1
  local is_show_unit_price = IsShiftKeyDown() and count > 1
  if is_show_unit_price then
    SetTooltipMoney(tt, vendor_price, nil, 'Vendor price (unit):')
  else
    SetTooltipMoney(tt, vendor_price * count, nil, 'Vendor price:')
  end

  -- Show the auction price below the vendor price, if it's available
  local item_id = tonumber(item:match('item:(%d+):'))
  local auction_price_per_unit = get_saved_prices()[tonumber(item_id)]
  if auction_price_per_unit then
    if is_show_unit_price then
      SetTooltipMoney(tt, auction_price_per_unit, nil, 'Auction price (unit):')
    else
      SetTooltipMoney(tt, auction_price_per_unit * count, nil, 'Auction price:')
    end
  end

  tt:Show()
end)
