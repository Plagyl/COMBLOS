#![no_std]

pub struct SlabAllocator {
    heap_start: usize,
    heap_end: usize,
    initialized: bool,
}

impl SlabAllocator {
    pub const fn new() -> Self {
        SlabAllocator {
            heap_start: 0,
            heap_end: 0,
            initialized: false,
        }
    }

    pub unsafe fn init(&mut self, start: usize, size: usize) {
        self.heap_start = start;
        self.heap_end = start + size;
        self.initialized = true;
    }

    pub unsafe fn allocate(&mut self, size: usize) -> Option<*mut u8> {
        // Un bump allocator très basique
        static mut CURRENT: usize = 0;
        if !self.initialized {
            return None;
        }
        if CURRENT == 0 {
            CURRENT = self.heap_start;
        }
        let alloc_start = CURRENT;
        let alloc_end = alloc_start + size;
        if alloc_end > self.heap_end {
            None
        } else {
            CURRENT = alloc_end;
            Some(alloc_start as *mut u8)
        }
    }

    pub unsafe fn deallocate(&mut self, _ptr: *mut u8) {
        // Pour ce bump allocator, la désallocation n'est pas implémentée.
    }
}

