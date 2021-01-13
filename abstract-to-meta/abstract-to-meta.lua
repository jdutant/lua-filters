--[[
abstract-to-meta

Moves "abstract" "thanks" and "keywords" section to the document metata

Copyright: © 2017–2020 Albert Krewinkel, Julien Dutant
License:   MIT – see LICENSE file for details
]]

-- debug
local pprint = require('pprint')

-- abstract, thanks: list of blocks
-- keywords: list of list of blocks
local abstract = {}
local thanks = {}
local keywords = {}

--- Extract meta from a list of blocks.
function meta_from_blocklist (blocks)
  local body_blocks = {}
  local looking_at = "body"

  for _, block in ipairs(blocks) do
    -- Headers level 1: flag which metadata we're looking at
    --  otherwise store in body text
    if block.t == 'Header' and block.level == 1 then
      if block.identifier == 'abstract' then
          looking_at = "abstract"
      elseif block.identifier == 'thanks' or
          block.identifier == "acknowledgements" or
          block.identifier == "acknowledgments" then
            looking_at = "thanks"
      elseif block.identifier == 'keywords' then
          looking_at = "keywords"
      else
        looking_at = "body"
        body_blocks[#body_blocks + 1] = block
      end
    -- Horizontal Rule: if we're looking at metadata, stop
    --  otherwise keep the rule in blocks
    elseif block.t == 'HorizontalRule' then
      if not (looking_at == "body") then
        looking_at = "body"
      else
        body_blocks[#body_blocks + 1] = block
      end
    -- if looking at metadata: store it
    elseif looking_at == "abstract" then
      abstract[#abstract + 1] = block
    elseif looking_at == "thanks" then
      thanks[#thanks + 1] = block
    elseif looking_at == "keywords" then
       if block.t == "BulletList" then
        keywords[#keywords + 1] = block
       end
    else
      body_blocks[#body_blocks + 1] = block
    end
  end

  return body_blocks
end

-- Turn list of BulletList elements into
-- a MetaList of MetaInlines
function bulletlist_to_metalist (keywords)
  local keyword_list = pandoc.List(pandoc.MetaList({}))
  for _,bullet_list in ipairs(keywords) do
    for _,item in ipairs(bullet_list.c) do

      -- we only use the first block of each item,
      -- and we only use it if it is Plain
      if item[1] and item[1].t == "Plain" then
        keyword_list:insert(pandoc.MetaInlines(item[1].c))
      end

    end
  end

  return keyword_list
end

if PANDOC_VERSION >= {2,9,2} then
  -- Check all block lists with pandoc 2.9.2 or later
  return {{
      Blocks = meta_from_blocklist,
      Meta = function (meta)
        if not meta.abstract and #abstract > 0 then
          meta.abstract = pandoc.MetaBlocks(abstract)
        end
        if not meta.thanks and #abstract > 0 then
          meta.thanks = pandoc.MetaBlocks(thanks)
        end
        if not meta.keywords and #keywords > 0 then
          meta.keywords = bulletlist_to_metalist(keywords)
         end
        return meta
      end
  }}
else
  -- otherwise, just check the top-level block-list
  return {{
      Pandoc = function (doc)
        local meta = doc.meta
        local other_blocks = meta_from_blocklist(doc.blocks)
        if not meta.abstract and #abstract > 0 then
          meta.abstract = pandoc.MetaBlocks(abstract)
        end
        if not meta.thanks and #thanks > 0 then
          meta.thanks = pandoc.MetaBlocks(thanks)
        end
        if not meta.keywords and #keywords > 0 then
          meta.keywords = bulletlist_to_metalist(keywords)
         end
        return pandoc.Pandoc(other_blocks, meta)
      end,
  }}
end
