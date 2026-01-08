// Shared Wasm externs
_jsPrint=(text, len)=>{
  BaseWebGPU.print(text, len);
};
_jsPrintFlush=()=>{
  BaseWebGPU.printFlush();
};

// Main object, connect with shared exports 
// and externs, + tools.
const BaseWebGPU = (() => {
  let title="JS_BaseWebGPU";
  let instance;
  const print = {
    buffer: "",
    decoder: null,
  }
  const methods = {
    log(message) { console.log(title + ' : ' + message); },
    print(ptr, len) { this.print.buffer += this.getString(ptr, len); },
    printFlush() { 
      try {
        eval(this.print.buffer);
      } catch (e) {
        console.error("Log eval error:", e);
        console.error("Failed script:", this.print.buffer);
      }
      this.print.buffer = ""; 
    },
    construct() { this.log('Constructed'); },

    // Emscripten
    loadModules() {
      Object.assign(this, { ...Module.wasmExports, ...Module.wasmImports, ...Module.memory });
      this.log('Loaded module with exports and imports');
    },

    // Wasm
    init() { 
      this.print.buffer = "";
      this.print.decoder = new TextDecoder(); 
      this.loadModules();
      this.loadEvents(); 
      this.log('Initialized');
      if (this.main) this.main();
    },
    update() { this.log('Update'); },

    // WebGPU
    loadEvents() {
      this.log('Loaded events with externs.');
    },

    // Helpers
    getString(ptr, len) { 
      if (!wasmMemory || !wasmMemory.buffer) {
        return "<memory not ready>";
      }
      return this.print.decoder.decode(new Uint8Array(wasmMemory.buffer, ptr, len));   
      // return this.print.decoder.decode(new Uint8Array(BaseWebGPU.memory.buffer, ptr, len)); 
    },
  };
  return { getInstance() {
    return instance ? instance : (instance = methods, instance.construct(), instance); },
  };
})().getInstance();
