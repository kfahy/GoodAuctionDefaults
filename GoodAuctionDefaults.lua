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
    -- Item was added to the "for sale" slot.
    last_item_id = item_id
    local price = get_saved_prices()[item_id]
    if price then
      -- We've sold this item before - fill in a default price.
      MoneyInputFrame_SetCopper(StartPrice, price)
      MoneyInputFrame_SetCopper(BuyoutPrice, price)
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
    get_saved_prices()[last_item_id] = LAST_ITEM_BUYOUT
  end
end

AuctionsCreateAuctionButton:HookScript('OnClick',
    AuctionsCreateAuctionButton_OnClick)

AuctionFrameAuctions.priceType = 1 -- default the price type to "per unit"
AuctionFrameAuctions.duration = 3 -- default the duration to "48 hours"
