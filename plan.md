# ZenBufline Performance & Feature Improvement Plan

## Project Goals
- **Excellent Performance**: Minimize redraws, optimize buffer list iteration, cache aggressively
- **Minimalism**: Keep the codebase simple, maintainable, and focused on core functionality
- **Essential Features**: Add mouse support, better buffer navigation, improved visual feedback

---

## Current State Analysis

### Strengths
- ✅ Simple, clean architecture
- ✅ Uses vim.schedule_wrap for async updates
- ✅ Basic caching for highlight groups and sections
- ✅ Minimal dependencies

### Performance Issues
- ⚠️ Iterates through ALL buffers on every update (including unlisted ones initially)
- ⚠️ Recreates entire tabline string on every buffer event
- ⚠️ No debouncing for rapid buffer changes
- ⚠️ Highlight string formatting happens repeatedly
- ⚠️ No buffer count limit (could have 100+ buffers)

### Missing Features
- ❌ No mouse support (click to switch buffers)
- ❌ No buffer closing functionality
- ❌ No buffer navigation commands
- ❌ No visual indication of buffer position
- ❌ No truncation for long buffer lists

---

## Phase 1: Performance Optimizations

### 1.1 Buffer List Caching
**Problem**: Currently iterates all buffers and regenerates the entire tabline on every event.

**Solution**:
- Cache the list of valid, listed buffers
- Only update cache when buffers are added/deleted
- Separate event for buffer modifications (only update that buffer's display)
- Store buffer metadata (name, modified state, filetype) in cache

**Implementation**:
```lua
local buffer_cache = {
    list = {},        -- ordered list of buffer numbers
    metadata = {},    -- buf_num -> {name, modified, ft}
    last_update = 0   -- timestamp
}
```

### 1.2 Incremental Updates
**Problem**: Regenerates entire tabline even for single buffer modifications.

**Solution**:
- Track which buffer changed
- Only rebuild the affected buffer's display string
- Use table manipulation instead of full concatenation
- Keep tabline parts in memory, update specific indices

### 1.3 Debouncing & Throttling
**Problem**: Rapid buffer switches cause unnecessary redraws.

**Solution**:
- Implement simple debounce timer (10-20ms)
- Skip updates if already scheduled
- Use vim.defer_fn for batching updates

**Implementation**:
```lua
local update_pending = false
local function schedule_update()
    if update_pending then return end
    update_pending = true
    vim.defer_fn(function()
        M.set_tabline()
        update_pending = false
    end, 15)
end
```

### 1.4 String Building Optimization
**Problem**: Multiple string concatenations per buffer.

**Solution**:
- Pre-allocate table with estimated size
- Use single table.concat call
- Cache formatted highlight strings better
- Minimize string operations in hot path

### 1.5 Lazy Highlight Updates
**Problem**: Recalculates all highlights on every buffer event.

**Solution**:
- Only update highlights on ColorScheme event (already done!)
- Cache highlight strings more aggressively
- Validate cache before regenerating

---

## Phase 2: Mouse Support

### 2.1 Click to Switch Buffer
**Feature**: Click on a buffer to switch to it.

**Implementation**:
- Use `%<buf_num>@callback@` syntax in tabline
- Register global click handler function
- Map buffer display position to buffer number

**Example**:
```lua
-- In tabline string:
"%1@v:lua.require'zenbufline'.handle_click@" .. buffer_name .. "%X"

-- Handler:
M.handle_click = function(buf_num)
    vim.api.nvim_set_current_buf(buf_num)
end
```

### 2.2 Middle-Click to Close Buffer
**Feature**: Middle-click (or right-click) to close a buffer.

**Implementation**:
- Add separate click handler for closing
- Use `%<buf_num>@close_callback@` for close button region
- Optional: Show close icon (×) on hover (if feasible in tabline)

**Example**:
```lua
-- Format: " buffer_name [×] "
-- Where [×] is clickable close region
M.close_buffer = function(buf_num)
    if vim.bo[buf_num].modified then
        -- Optional: prompt or force close
        vim.api.nvim_buf_delete(buf_num, {force = false})
    else
        vim.api.nvim_buf_delete(buf_num, {})
    end
end
```

### 2.3 Visual Feedback
**Feature**: Different highlighting for clickable regions.

**Implementation**:
- Subtle color change for buffer name (vs separators)
- Optional: underline or different style for hover effect (limited in tabline)

---

## Phase 3: Essential Buffer Navigation

### 3.1 Buffer Navigation Commands
**Feature**: Keymaps to cycle through buffers.

**Commands**:
```lua
-- Navigate to next buffer
M.next_buffer = function()
    -- Get buffer list from cache
    -- Find current buffer index
    -- Jump to (index + 1) % count
end

-- Navigate to previous buffer
M.prev_buffer = function()
    -- Similar to next, but (index - 1)
end

-- Jump to specific buffer by index (1-9)
M.goto_buffer = function(index)
    -- Jump to nth buffer in list
end
```

**Optional Keymaps**:
```lua
vim.keymap.set('n', '<Tab>', require('zenbufline').next_buffer)
vim.keymap.set('n', '<S-Tab>', require('zenbufline').prev_buffer)
vim.keymap.set('n', '<Leader>1', function() require('zenbufline').goto_buffer(1) end)
-- etc...
```

### 3.2 Buffer Closing Command
**Feature**: Close current buffer intelligently.

**Implementation**:
```lua
M.close_current_buffer = function()
    local buf = vim.api.nvim_get_current_buf()
    -- Jump to next/previous buffer before closing
    -- Delete buffer
end
```

### 3.3 Smart Buffer Ordering
**Feature**: Order buffers by most recently used (MRU).

**Implementation**:
- Track buffer access order in cache
- Update order on BufEnter
- Display in MRU order (optional config)

---

## Phase 4: Visual Improvements

### 4.1 Buffer Truncation
**Problem**: Too many buffers overflow the tabline.

**Solution**:
- Calculate available width
- Show centered window of buffers around current
- Add overflow indicators (« ... »)
- Always show current buffer

**Implementation**:
```lua
local function get_visible_buffers(all_bufs, current_idx, width)
    -- Calculate how many buffers fit in width
    -- Return slice of buffer list centered on current
    -- Add "«" prefix and "»" suffix if truncated
end
```

### 4.2 Buffer Separators
**Feature**: Clear visual separation between buffers.

**Implementation**:
- Use thin vertical line or space
- Different separator for active buffer
- Configurable separator style

### 4.3 Modified Indicator Enhancement
**Feature**: More prominent modified indicator.

**Implementation**:
- Use color change (not just text)
- Bold modified buffers
- Optional: different icon (● instead of [+])

### 4.4 Buffer Index/Count Display
**Feature**: Show buffer position (e.g., "3/10").

**Implementation**:
- Add to right side of tabline
- Format: "ZenbuflineBuffer" highlight
- Update on buffer list changes

---

## Phase 5: Code Quality & Maintainability

### 5.1 Module Refactoring
**Goal**: Separate concerns for better maintainability.

**Structure**:
```
lua/zenbufline/
├── init.lua          -- Main setup & public API
├── config.lua        -- Configuration defaults
├── buffer.lua        -- Buffer list management & caching
├── render.lua        -- Tabline rendering & string building
├── highlights.lua    -- Highlight management
└── mouse.lua         -- Mouse click handlers (optional separate)
```

### 5.2 Configuration Validation
**Goal**: Validate user config early.

**Implementation**:
- Type checking for config options
- Provide helpful error messages
- Set sane defaults for missing values

### 5.3 Performance Monitoring
**Goal**: Track and optimize hot paths.

**Implementation**:
- Optional debug mode to log update times
- Count update frequency
- Identify bottlenecks

### 5.4 Documentation
**Goal**: Clear, comprehensive documentation.

**TODO**:
- Document all public API functions
- Add configuration examples
- Performance tips section
- Troubleshooting guide

---

## Implementation Priority

### High Priority (Core Performance)
1. ✅ Buffer list caching (Phase 1.1)
2. ✅ Debouncing (Phase 1.3)
3. ✅ String building optimization (Phase 1.4)
4. ✅ Mouse click support - switch buffer (Phase 2.1)

### Medium Priority (Essential Features)
5. ⚙️ Buffer navigation commands (Phase 3.1)
6. ⚙️ Mouse close buffer (Phase 2.2)
7. ⚙️ Buffer truncation (Phase 4.1)
8. ⚙️ Incremental updates (Phase 1.2)

### Low Priority (Nice to Have)
9. 📋 Smart buffer ordering (Phase 3.3)
10. 📋 Enhanced visual indicators (Phase 4.2-4.4)
11. 📋 Module refactoring (Phase 5.1)

---

## Performance Targets

### Current Baseline (Estimated)
- Update time: ~1-2ms for 10 buffers, ~5-10ms for 50 buffers
- Updates per second: Unlimited (no throttling)
- Memory: ~1KB per buffer

### Target Goals
- Update time: <0.5ms for 10 buffers, <2ms for 100 buffers
- Updates per second: Max 60-100 (debounced)
- Memory: Similar or better with caching
- Startup time: <5ms
- No perceivable lag on buffer operations

---

## Testing Checklist

### Performance Tests
- [ ] 10 buffers: smooth operation
- [ ] 50 buffers: no noticeable lag
- [ ] 100+ buffers: graceful truncation
- [ ] Rapid buffer switching (10 switches/sec)
- [ ] Multiple windows with different buffers
- [ ] Large files (>10MB) opened

### Feature Tests
- [ ] Mouse click switches buffer
- [ ] Mouse close works correctly
- [ ] Close modified buffer prompts
- [ ] Navigation commands work
- [ ] Highlights update on ColorScheme change
- [ ] Modified indicator appears/disappears
- [ ] Buffer order correct after operations

### Edge Cases
- [ ] Empty buffer list
- [ ] Single buffer
- [ ] Terminal buffers
- [ ] Unnamed buffers
- [ ] Very long filenames
- [ ] Special characters in filenames
- [ ] Fast buffer creation/deletion

---

## Success Criteria

✅ **Performance**: No perceivable lag with <100 buffers
✅ **Mouse Support**: Click to switch, click to close (with close button)
✅ **Minimalism**: Codebase stays <500 LOC for core functionality
✅ **Reliability**: No errors in normal usage
✅ **Usability**: Intuitive behavior, clear visual feedback
✅ **Maintainability**: Well-structured, documented code

---

## Future Considerations (Out of Scope)

- ❌ Buffer groups/tabs (adds complexity)
- ❌ Custom icons per filetype (use external plugins)
- ❌ LSP integration (diagnostics count, etc.)
- ❌ Git status indicators (bloat)
- ❌ Complex animations (performance cost)
- ❌ Split/window indicators (too much visual noise)

**Philosophy**: Keep it simple, fast, and focused on core buffer management.

