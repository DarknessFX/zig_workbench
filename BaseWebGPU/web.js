// Shared Wasm externs
_Print=(text, len)=>{
  BaseWebGPU.print(text, len);
};
_printFlush=()=>{
  BaseWebGPU.printFlush();
};
_onShaderCompiled=(a1,b2,c3)=>{
  BaseWebGPU.log("Shader compiled.");
}

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
    printFlush() { console.log(this.print.buffer); this.print.buffer = ""; BaseWebGPU.memory.buffer = ""; },
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
      this.loadEvents(); 
      this.log('Initialized');
      if (this.main) this.main();
    },
    update() { _Update(); this.log('Update'); },

    // WebGPU
    loadEvents() {
      window.onresize=_onWindowResize;
      window.addEventListener("resize", _onWindowResize);
      this.log('Loaded events with externs.');
    },

    // Helpers
    getString(ptr, len) { return this.print.decoder.decode(new Uint8Array(BaseWebGPU.memory.buffer, ptr, len)); },    
  };
  return { getInstance() {
    return instance ? instance : (instance = methods, instance.construct(), instance); },
  };
})().getInstance();
