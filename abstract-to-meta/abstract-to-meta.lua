--[[
abstract-to-meta

Moves an "abstract" and "thanks" section to the document metata

Copyright: © 2017–2020 Albert Krewinkel, Julien Dutant
License:   MIT – see LICENSE file for details
]]
local abstract = {}
local thanks = {}

--- Extract abstract from a list of blocks.
function meta_from_blocklist (blocks)
  local body_blocks = {}
  local looking_at_abstract = false
  local looking_at_thanks = false

  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.level == 1 then
      if block.identifier == 'abstract' then
        looking_at_abstract = true
      elseif block.identifier == 'thanks' or
          block.identifier == "acknowledgements" or
          block.identifier == "acknowledgments" then
            looking_at_thanks = true
      else
        looking_at_abstract = false
        looking_at_thanks = false
        body_blocks[#body_blocks + 1] = block
      end
    elseif block.t == 'HorizontalRule' then
      if looking_at_abstract then
        looking_at_abstract = false
      elseif looking_at_thanks then
        looking_at_thanks = false
      else
        body_blocks[#body_blocks + 1] = block
      end
    elseif looking_at_abstract then
      abstract[#abstract + 1] = block
    elseif looking_at_thanks then
      thanks[#thanks + 1] = block
    else
      body_blocks[#body_blocks + 1] = block
    end
  end

  return body_blocks
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
        return pandoc.Pandoc(other_blocks, meta)
      end,
  }}
end
