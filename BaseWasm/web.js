// Shared Wasm externs
_Print=(text, len)=>{
  BaseWasm.print(text, len);
};
_printFlush=()=>{
  BaseWasm.printFlush();
};

// Main object, connect with shared exports 
// and externs, + tools.
const BaseWasm = (() => {
  let title="JS_BaseWasm";
  let instance;
  const print = {
    buffer: "",
    decoder: null,
  }
  const methods = {
    log(message) { console.log(title + ' : ' + message); },
    print(ptr, len) { this.print.buffer += this.getString(ptr, len); },
    printFlush() { console.log(this.print.buffer); this.print.buffer = ""; BaseWasm.print.buffer = ""; },
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
      _Init();
      //this.loadEvents(); 
      this.log('Initialized');
      if (this.main) this.main();
    },
    update() { _Update(); this.log('Update'); },

    // Helpers
    getString(ptr, len) { return this.print.decoder.decode(new Uint8Array(BaseWasm.print.buffer, ptr, len)); },    
  };
  return { getInstance() {
    return instance ? instance : (instance = methods, instance.construct(), instance); },
  };
})().getInstance();
