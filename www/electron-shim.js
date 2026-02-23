/**
 * Electron Shim for OpenBlock Web Deployment
 * 
 * This script provides browser-compatible stubs for Electron APIs
 * (ipcRenderer, clipboard, @electron/remote, etc.) so the Webpack-bundled
 * OpenBlock GUI can run in a standard web browser without modifications
 * to the minified bundle code.
 *
 * It intercepts `require()` calls for 'electron', 'fs', 'path', and
 * '@electron/remote' and provides no-op or web-compatible implementations.
 */

(function () {
    'use strict';

    // ---- Global Error Handlers (MUST be first) ----
    window.onerror = function (msg, url, line, col, error) {
        console.error('[OpenBlock Web] GLOBAL ERROR:', msg, '\n  URL:', url, '\n  Line:', line, '\n  Col:', col, '\n  Error:', error);
        return false; // Don't suppress the error
    };
    window.addEventListener('unhandledrejection', function (event) {
        console.error('[OpenBlock Web] UNHANDLED PROMISE REJECTION:', event.reason);
        if (event.reason && event.reason.stack) {
            console.error('[OpenBlock Web] Stack:', event.reason.stack);
        }
    });
    console.log('[OpenBlock Web] Global error handlers installed.');

    // ---- Node.js global compatibility ----
    // Many npm packages reference `global` (Node.js global object)
    // In browsers, this must point to `window`
    if (typeof global === 'undefined') {
        window.global = window;
    }
    if (typeof self === 'undefined') {
        window.self = window;
    }

    // ---- ipcRenderer shim ----
    var _ipcListeners = {};
    const ipcRenderer = {
        on: function (channel, listener) {
            console.log('[Web] ipcRenderer.on:', channel);
            (_ipcListeners[channel] = _ipcListeners[channel] || []).push(listener);
            return ipcRenderer;
        },
        once: function (channel, listener) {
            console.log('[Web] ipcRenderer.once:', channel);
            var wrapper = function () {
                ipcRenderer.removeListener(channel, wrapper);
                listener.apply(this, arguments);
            };
            return ipcRenderer.on(channel, wrapper);
        },
        send: function (channel) {
            console.log('[Web] ipcRenderer.send:', channel);
        },
        sendSync: function (channel) {
            console.log('[Web] ipcRenderer.sendSync:', channel);
            if (channel === 'getTelemetryDidOptIn') return true;
            return null;
        },
        invoke: function (channel) {
            console.log('[Web] ipcRenderer.invoke:', channel);
            if (channel === 'get-initial-project-data') {
                // Return a minimal valid Scratch 3 project JSON to bypass the
                // FETCHING_NEW_DEFAULT → storage.load() path that crashes the SB1 fallback
                return Promise.resolve(JSON.stringify({
                    targets: [{
                        isStage: true,
                        name: 'Stage',
                        variables: {},
                        lists: {},
                        broadcasts: {},
                        blocks: {},
                        comments: {},
                        currentCostume: 0,
                        costumes: [{
                            name: 'backdrop1',
                            dataFormat: 'svg',
                            assetId: 'cd21514d0531fdffb22204e0ec5ed84a',
                            md5ext: 'cd21514d0531fdffb22204e0ec5ed84a.svg',
                            rotationCenterX: 240,
                            rotationCenterY: 180
                        }],
                        sounds: [],
                        volume: 100,
                        layerOrder: 0,
                        tempo: 60,
                        videoTransparency: 50,
                        videoState: 'off',
                        textToSpeechLanguage: null
                    }],
                    monitors: [],
                    extensions: [],
                    meta: {
                        semver: '3.0.0',
                        vm: '0.2.0',
                        agent: 'OpenBlock-Web'
                    }
                }));
            }
            if (channel === 'getTelemetryDidOptIn') return Promise.resolve(true);
            return Promise.resolve(null);
        },
        removeListener: function (channel, listener) {
            var list = _ipcListeners[channel];
            if (list) { var i = list.indexOf(listener); if (i >= 0) list.splice(i, 1); }
            return ipcRenderer;
        },
        removeAllListeners: function (channel) {
            if (channel) { delete _ipcListeners[channel]; } else { _ipcListeners = {}; }
            return ipcRenderer;
        }
    };

    // Fire 'ready-to-show' after a short delay so listeners registered during 
    // module init can receive it (simulates Electron's main process behavior)
    setTimeout(function () {
        var listeners = _ipcListeners['ready-to-show'];
        if (listeners) {
            console.log('[Web] Firing ready-to-show event');
            listeners.slice().forEach(function (fn) { fn({}); });
        }
    }, 100);

    // ---- clipboard shim (use browser clipboard API) ----
    const clipboard = {
        readText: function () {
            // This will be overridden anyway; provide fallback
            return '';
        },
        writeText: function (text) {
            if (navigator.clipboard && navigator.clipboard.writeText) {
                navigator.clipboard.writeText(text);
            }
        }
    };

    // ---- Electron module shim ----
    const electronModule = {
        ipcRenderer: ipcRenderer,
        clipboard: clipboard,
        shell: {
            openExternal: function (url) {
                window.open(url, '_blank');
            }
        },
        remote: null
    };

    // ---- @electron/remote shim ----
    const remoteModule = {
        dialog: {
            showMessageBox: function () { return Promise.resolve({ response: 0 }); },
            showMessageBoxSync: function () { return 0; },
            showOpenDialog: function () { return Promise.resolve({ canceled: true, filePaths: [] }); },
            showSaveDialog: function () { return Promise.resolve({ canceled: true }); }
        },
        getCurrentWindow: function () {
            return {
                setTitle: function () { },
                close: function () { },
                isMaximized: function () { return false; },
                minimize: function () { },
                maximize: function () { },
                unmaximize: function () { },
                on: function () { },
                removeListener: function () { }
            };
        },
        app: {
            getPath: function (name) { return '/tmp/' + name; },
            getVersion: function () { return '2.6.3-web'; }
        }
    };

    // ---- fs shim (minimal) ----
    const fsModule = {
        readFile: function (path, cb) {
            // Attempt to fetch the file from the web server instead
            fetch(path.replace(/^.*\/static\//, 'static/'))
                .then(function (res) { return res.arrayBuffer(); })
                .then(function (buf) { cb(null, Buffer.from(buf)); })
                .catch(function (err) { cb(err); });
        },
        readFileSync: function () { return ''; },
        writeFile: function (path, data, cb) { if (cb) cb(null); },
        writeFileSync: function () { },
        existsSync: function () { return false; },
        mkdirSync: function () { },
        readdirSync: function () { return []; },
        statSync: function () { return { isDirectory: function () { return false; } }; }
    };

    // ---- path shim (minimal) ----
    const pathModule = {
        resolve: function () {
            var args = Array.prototype.slice.call(arguments);
            return args.join('/').replace(/\/+/g, '/');
        },
        join: function () {
            var args = Array.prototype.slice.call(arguments);
            return args.join('/').replace(/\/+/g, '/');
        },
        basename: function (p) {
            if (!p) return '';
            var parts = p.replace(/\\/g, '/').split('/');
            return parts[parts.length - 1];
        },
        dirname: function (p) {
            if (!p) return '.';
            var parts = p.replace(/\\/g, '/').split('/');
            parts.pop();
            return parts.join('/') || '.';
        },
        extname: function (p) {
            if (!p) return '';
            var dot = p.lastIndexOf('.');
            return dot > 0 ? p.substring(dot) : '';
        },
        sep: '/',
        delimiter: ':'
    };

    // ---- process shim ----
    // Build a process-like EventEmitter so @electron/remote can call process.on()
    var _processEvents = {};
    var _processShimMethods = {
        on: function (event, fn) { (_processEvents[event] = _processEvents[event] || []).push(fn); return window.process; },
        off: function (event, fn) { var list = _processEvents[event]; if (list) { var i = list.indexOf(fn); if (i >= 0) list.splice(i, 1); } return window.process; },
        once: function (event, fn) { var wrapper = function () { window.process.off(event, wrapper); fn.apply(this, arguments); }; return window.process.on(event, wrapper); },
        emit: function (event) { var list = _processEvents[event]; if (list) { var args = [].slice.call(arguments, 1); list.slice().forEach(function (fn) { fn.apply(null, args); }); } return false; },
        removeListener: function (event, fn) { return window.process.off(event, fn); },
        removeAllListeners: function (event) { if (event) { delete _processEvents[event]; } else { _processEvents = {}; } return window.process; },
        listeners: function (event) { return (_processEvents[event] || []).slice(); },
        listenerCount: function (event) { return (_processEvents[event] || []).length; },
        exit: function () { console.warn('[Web] process.exit() called - ignoring in browser'); },
        kill: function () { console.warn('[Web] process.kill() called - ignoring in browser'); },
        argv: ['browser'],
        pid: 1,
        ppid: 0,
        title: 'browser',
        arch: 'wasm',
        stdout: { write: function (s) { console.log(s); }, isTTY: false },
        stderr: { write: function (s) { console.error(s); }, isTTY: false }
    };
    if (typeof window.process === 'undefined') {
        window.process = {
            env: { NODE_ENV: 'production' },
            platform: 'browser',
            type: 'renderer',
            resourcesPath: '.',
            contextId: 'openblock-web-context',
            versions: { node: '0.0.0', electron: '25.0.0' },
            cwd: function () { return '/'; },
            nextTick: function (fn) { setTimeout(fn, 0); }
        };
    } else {
        if (!window.process.env) window.process.env = {};
        window.process.env.NODE_ENV = 'production';
        if (!window.process.resourcesPath) window.process.resourcesPath = '.';
        if (!window.process.contextId) window.process.contextId = 'openblock-web-context';
        if (!window.process.type) window.process.type = 'renderer';
        if (!window.process.versions) window.process.versions = {};
        if (!window.process.versions.electron) window.process.versions.electron = '25.0.0';
    }
    // Merge EventEmitter methods and extra properties into process
    for (var _pk in _processShimMethods) {
        if (!window.process[_pk]) {
            window.process[_pk] = _processShimMethods[_pk];
        }
    }

    // NOTE: Full Buffer shim is defined below (BufferShim). The minimal shim
    // that was here has been removed to avoid conflicts.

    // ---- EventEmitter shim (events module) ----
    function EventEmitter() {
        this._events = {};
        this._maxListeners = 10;
    }
    EventEmitter.prototype.on = function (type, listener) {
        if (!this._events[type]) this._events[type] = [];
        this._events[type].push(listener);
        return this;
    };
    EventEmitter.prototype.addListener = EventEmitter.prototype.on;
    EventEmitter.prototype.once = function (type, listener) {
        var self = this;
        function wrapped() {
            self.removeListener(type, wrapped);
            listener.apply(this, arguments);
        }
        wrapped.listener = listener;
        this.on(type, wrapped);
        return this;
    };
    EventEmitter.prototype.removeListener = function (type, listener) {
        if (this._events[type]) {
            this._events[type] = this._events[type].filter(function (l) {
                return l !== listener && l.listener !== listener;
            });
        }
        return this;
    };
    EventEmitter.prototype.off = EventEmitter.prototype.removeListener;
    EventEmitter.prototype.removeAllListeners = function (type) {
        if (type) { delete this._events[type]; }
        else { this._events = {}; }
        return this;
    };
    EventEmitter.prototype.emit = function (type) {
        if (!this._events[type]) return false;
        var args = Array.prototype.slice.call(arguments, 1);
        var listeners = this._events[type].slice();
        for (var i = 0; i < listeners.length; i++) {
            listeners[i].apply(this, args);
        }
        return true;
    };
    EventEmitter.prototype.listeners = function (type) {
        return this._events[type] ? this._events[type].slice() : [];
    };
    EventEmitter.prototype.listenerCount = function (type) {
        return this._events[type] ? this._events[type].length : 0;
    };
    EventEmitter.prototype.setMaxListeners = function (n) {
        this._maxListeners = n;
        return this;
    };
    EventEmitter.prototype.getMaxListeners = function () {
        return this._maxListeners;
    };
    EventEmitter.prototype.prependListener = function (type, listener) {
        if (!this._events[type]) this._events[type] = [];
        this._events[type].unshift(listener);
        return this;
    };
    EventEmitter.prototype.eventNames = function () {
        return Object.keys(this._events);
    };
    EventEmitter.listenerCount = function (emitter, type) {
        return emitter.listenerCount(type);
    };
    EventEmitter.EventEmitter = EventEmitter;
    EventEmitter.defaultMaxListeners = 10;

    var eventsModule = EventEmitter;

    // ---- Buffer shim (full) ----
    var bufferModule;
    if (typeof window.Buffer !== 'undefined' && window.Buffer.alloc) {
        // If a real Buffer is available (e.g. via polyfill), use it
        bufferModule = { Buffer: window.Buffer };
    } else {
        // Provide a minimal Buffer implementation
        function BufferShim(arg, encodingOrOffset, length) {
            if (typeof arg === 'number') {
                return new Uint8Array(arg);
            }
            if (typeof arg === 'string') {
                // Handle encoding parameter (e.g., new Buffer(str, 'base64'))
                if (encodingOrOffset === 'base64') {
                    var binaryStr = atob(arg);
                    var bytes = new Uint8Array(binaryStr.length);
                    for (var k = 0; k < binaryStr.length; k++) bytes[k] = binaryStr.charCodeAt(k);
                    return bytes;
                }
                if (encodingOrOffset === 'hex') {
                    var hexBytes = new Uint8Array(arg.length / 2);
                    for (var h = 0; h < arg.length; h += 2) hexBytes[h / 2] = parseInt(arg.substr(h, 2), 16);
                    return hexBytes;
                }
                var encoder = new TextEncoder();
                return encoder.encode(arg);
            }
            if (arg instanceof ArrayBuffer) {
                return new Uint8Array(arg);
            }
            if (ArrayBuffer.isView(arg)) {
                return new Uint8Array(arg.buffer, arg.byteOffset, arg.byteLength);
            }
            if (Array.isArray(arg)) {
                return new Uint8Array(arg);
            }
            return new Uint8Array(0);
        }
        BufferShim.from = function (data, encoding) {
            if (typeof data === 'string') {
                if (encoding === 'base64') {
                    // Decode base64 string to Uint8Array
                    var binaryStr = atob(data);
                    var bytes = new Uint8Array(binaryStr.length);
                    for (var i = 0; i < binaryStr.length; i++) {
                        bytes[i] = binaryStr.charCodeAt(i);
                    }
                    return bytes;
                }
                if (encoding === 'hex') {
                    var hexBytes = new Uint8Array(data.length / 2);
                    for (var j = 0; j < data.length; j += 2) {
                        hexBytes[j / 2] = parseInt(data.substr(j, 2), 16);
                    }
                    return hexBytes;
                }
                // Default: utf-8
                var encoder = new TextEncoder();
                return encoder.encode(data);
            }
            if (data instanceof ArrayBuffer) {
                return new Uint8Array(data);
            }
            if (ArrayBuffer.isView(data)) {
                return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
            }
            if (Array.isArray(data)) {
                return new Uint8Array(data);
            }
            return new Uint8Array(0);
        };
        BufferShim.alloc = function (size, fill) {
            var buf = new Uint8Array(size);
            if (fill !== undefined) buf.fill(fill);
            return buf;
        };
        BufferShim.allocUnsafe = function (size) {
            return new Uint8Array(size);
        };
        BufferShim.isBuffer = function (obj) {
            return obj instanceof Uint8Array;
        };
        BufferShim.concat = function (list, totalLength) {
            if (!totalLength) {
                totalLength = 0;
                for (var i = 0; i < list.length; i++) totalLength += list[i].length;
            }
            var result = new Uint8Array(totalLength);
            var offset = 0;
            for (var j = 0; j < list.length; j++) {
                result.set(list[j], offset);
                offset += list[j].length;
            }
            return result;
        };
        BufferShim.byteLength = function (string) {
            return new TextEncoder().encode(string).length;
        };
        BufferShim.isEncoding = function () { return true; };

        window.Buffer = BufferShim;
        bufferModule = { Buffer: BufferShim };
    }

    // ---- Add Buffer-compatible methods to Uint8Array if missing ----
    // UnicodeTrie and other Node.js modules call readUInt32LE, readUInt32BE, etc.
    if (!Uint8Array.prototype.readUInt32LE) {
        Uint8Array.prototype.readUInt32LE = function (offset) {
            offset = offset || 0;
            return this[offset] | (this[offset + 1] << 8) | (this[offset + 2] << 16) | (this[offset + 3] << 24) >>> 0;
        };
    }
    if (!Uint8Array.prototype.readUInt32BE) {
        Uint8Array.prototype.readUInt32BE = function (offset) {
            offset = offset || 0;
            return ((this[offset] << 24) | (this[offset + 1] << 16) | (this[offset + 2] << 8) | this[offset + 3]) >>> 0;
        };
    }
    if (!Uint8Array.prototype.readUInt16LE) {
        Uint8Array.prototype.readUInt16LE = function (offset) {
            offset = offset || 0;
            return this[offset] | (this[offset + 1] << 8);
        };
    }
    if (!Uint8Array.prototype.readUInt16BE) {
        Uint8Array.prototype.readUInt16BE = function (offset) {
            offset = offset || 0;
            return (this[offset] << 8) | this[offset + 1];
        };
    }
    if (!Uint8Array.prototype.readUInt8) {
        Uint8Array.prototype.readUInt8 = function (offset) {
            return this[offset || 0];
        };
    }
    if (!Uint8Array.prototype.readInt32LE) {
        Uint8Array.prototype.readInt32LE = function (offset) {
            offset = offset || 0;
            return this[offset] | (this[offset + 1] << 8) | (this[offset + 2] << 16) | (this[offset + 3] << 24);
        };
    }
    if (!Uint8Array.prototype.readInt32BE) {
        Uint8Array.prototype.readInt32BE = function (offset) {
            offset = offset || 0;
            return (this[offset] << 24) | (this[offset + 1] << 16) | (this[offset + 2] << 8) | this[offset + 3];
        };
    }
    if (!Uint8Array.prototype.readFloatLE) {
        Uint8Array.prototype.readFloatLE = function (offset) {
            var view = new DataView(this.buffer, this.byteOffset, this.byteLength);
            return view.getFloat32(offset || 0, true);
        };
    }
    if (!Uint8Array.prototype.readDoubleBE) {
        Uint8Array.prototype.readDoubleBE = function (offset) {
            var view = new DataView(this.buffer, this.byteOffset, this.byteLength);
            return view.getFloat64(offset || 0, false);
        };
    }
    if (!Uint8Array.prototype.writeUInt32LE) {
        Uint8Array.prototype.writeUInt32LE = function (value, offset) {
            offset = offset || 0;
            this[offset] = value & 0xFF;
            this[offset + 1] = (value >> 8) & 0xFF;
            this[offset + 2] = (value >> 16) & 0xFF;
            this[offset + 3] = (value >> 24) & 0xFF;
        };
    }
    if (!Uint8Array.prototype.writeUInt32BE) {
        Uint8Array.prototype.writeUInt32BE = function (value, offset) {
            offset = offset || 0;
            this[offset] = (value >> 24) & 0xFF;
            this[offset + 1] = (value >> 16) & 0xFF;
            this[offset + 2] = (value >> 8) & 0xFF;
            this[offset + 3] = value & 0xFF;
        };
    }
    // toString compatible with Node.js Buffer
    var _origUint8ToString = Uint8Array.prototype.toString;
    Uint8Array.prototype.toString = function (encoding) {
        if (encoding === 'utf8' || encoding === 'utf-8') {
            return new TextDecoder().decode(this);
        }
        if (encoding === 'hex') {
            var hex = '';
            for (var i = 0; i < this.length; i++) hex += ('0' + this[i].toString(16)).slice(-2);
            return hex;
        }
        if (encoding === 'base64') {
            var binary = '';
            for (var j = 0; j < this.length; j++) binary += String.fromCharCode(this[j]);
            return btoa(binary);
        }
        return _origUint8ToString.call(this);
    };
    // copy method
    if (!Uint8Array.prototype.copy) {
        Uint8Array.prototype.copy = function (target, targetStart, sourceStart, sourceEnd) {
            targetStart = targetStart || 0;
            sourceStart = sourceStart || 0;
            sourceEnd = sourceEnd || this.length;
            for (var i = sourceStart; i < sourceEnd; i++) {
                target[targetStart++] = this[i];
            }
        };
    }
    // equals method
    if (!Uint8Array.prototype.equals) {
        Uint8Array.prototype.equals = function (other) {
            if (this.length !== other.length) return false;
            for (var i = 0; i < this.length; i++) { if (this[i] !== other[i]) return false; }
            return true;
        };
    }

    // ---- Override require() for Electron modules ----
    var _originalRequire = typeof window.require === 'function' ? window.require : null;

    window.require = function (moduleName) {
        switch (moduleName) {
            case 'electron':
                return electronModule;
            case '@electron/remote':
            case '@electron/remote/renderer':
            case '@electron/remote/renderer/index.js':
                return remoteModule;
            case 'fs':
                return fsModule;
            case 'path':
                return pathModule;
            case 'events':
                return eventsModule;
            case 'buffer':
                return bufferModule;
            case 'util':
                return {
                    inherits: function (ctor, superCtor) {
                        ctor.super_ = superCtor;
                        ctor.prototype = Object.create(superCtor.prototype, {
                            constructor: { value: ctor, enumerable: false, writable: true, configurable: true }
                        });
                    },
                    deprecate: function (fn) { return fn; },
                    isArray: Array.isArray,
                    isBuffer: function (obj) { return obj instanceof Uint8Array; },
                    isFunction: function (obj) { return typeof obj === 'function'; },
                    isString: function (obj) { return typeof obj === 'string'; },
                    isNumber: function (obj) { return typeof obj === 'number'; },
                    isObject: function (obj) { return typeof obj === 'object' && obj !== null; },
                    isUndefined: function (obj) { return obj === undefined; },
                    isNull: function (obj) { return obj === null; },
                    isNullOrUndefined: function (obj) { return obj == null; },
                    format: function () {
                        var args = Array.prototype.slice.call(arguments);
                        if (!args.length) return '';
                        var str = String(args[0]);
                        for (var i = 1; i < args.length; i++) str = str.replace(/%[sdj%]/, String(args[i]));
                        return str;
                    }
                };
            case 'stream':
            case 'readable-stream':
                // A minimal stream shim based on EventEmitter
                function Stream() { EventEmitter.call(this); }
                Stream.prototype = Object.create(EventEmitter.prototype);
                Stream.prototype.constructor = Stream;
                Stream.prototype.pipe = function (dest) { return dest; };
                Stream.Stream = Stream;
                Stream.Readable = Stream;
                Stream.Writable = Stream;
                Stream.Duplex = Stream;
                Stream.Transform = Stream;
                Stream.PassThrough = Stream;
                return Stream;
            case 'source-map-support/source-map-support.js':
            case 'source-map-support':
                return { install: function () { } };
            case 'net':
            case 'tls':
            case 'http':
            case 'https':
            case 'child_process':
            case 'os':
            case 'crypto':
                return (function () {
                    // --- Minimal MD5 implementation for crypto.createHash ---
                    function md5Bytes(input) {
                        var bytes;
                        if (typeof input === 'string') { bytes = new TextEncoder().encode(input); }
                        else if (input instanceof Uint8Array) { bytes = input; }
                        else if (ArrayBuffer.isView(input)) { bytes = new Uint8Array(input.buffer, input.byteOffset, input.byteLength); }
                        else { bytes = new Uint8Array(0); }
                        function safeAdd(x, y) { var lsw = (x & 0xFFFF) + (y & 0xFFFF); return ((x >> 16) + (y >> 16) + (lsw >> 16)) << 16 | lsw & 0xFFFF; }
                        function bitRot(n, c) { return (n << c) | (n >>> (32 - c)); }
                        function cmn(q, a, b, x, s, t) { return safeAdd(bitRot(safeAdd(safeAdd(a, q), safeAdd(x, t)), s), b); }
                        function ff(a, b, c, d, x, s, t) { return cmn((b & c) | ((~b) & d), a, b, x, s, t); }
                        function gg(a, b, c, d, x, s, t) { return cmn((b & d) | (c & (~d)), a, b, x, s, t); }
                        function hh(a, b, c, d, x, s, t) { return cmn(b ^ c ^ d, a, b, x, s, t); }
                        function ii(a, b, c, d, x, s, t) { return cmn(c ^ (b | (~d)), a, b, x, s, t); }
                        function core(x, len) {
                            x[len >> 5] |= 0x80 << (len % 32);
                            x[(((len + 64) >>> 9) << 4) + 14] = len;
                            var a = 1732584193, b = -271733879, c = -1732584194, d = 271733878;
                            for (var i = 0; i < x.length; i += 16) {
                                var oa = a, ob = b, oc = c, od = d;
                                a = ff(a, b, c, d, x[i], 7, -680876936); d = ff(d, a, b, c, x[i + 1], 12, -389564586); c = ff(c, d, a, b, x[i + 2], 17, 606105819); b = ff(b, c, d, a, x[i + 3], 22, -1044525330);
                                a = ff(a, b, c, d, x[i + 4], 7, -176418897); d = ff(d, a, b, c, x[i + 5], 12, 1200080426); c = ff(c, d, a, b, x[i + 6], 17, -1473231341); b = ff(b, c, d, a, x[i + 7], 22, -45705983);
                                a = ff(a, b, c, d, x[i + 8], 7, 1770035416); d = ff(d, a, b, c, x[i + 9], 12, -1958414417); c = ff(c, d, a, b, x[i + 10], 17, -42063); b = ff(b, c, d, a, x[i + 11], 22, -1990404162);
                                a = ff(a, b, c, d, x[i + 12], 7, 1804603682); d = ff(d, a, b, c, x[i + 13], 12, -40341101); c = ff(c, d, a, b, x[i + 14], 17, -1502002290); b = ff(b, c, d, a, x[i + 15], 22, 1236535329);
                                a = gg(a, b, c, d, x[i + 1], 5, -165796510); d = gg(d, a, b, c, x[i + 6], 9, -1069501632); c = gg(c, d, a, b, x[i + 11], 14, 643717713); b = gg(b, c, d, a, x[i], 20, -373897302);
                                a = gg(a, b, c, d, x[i + 5], 5, -701558691); d = gg(d, a, b, c, x[i + 10], 9, 38016083); c = gg(c, d, a, b, x[i + 15], 14, -660478335); b = gg(b, c, d, a, x[i + 4], 20, -405537848);
                                a = gg(a, b, c, d, x[i + 9], 5, 568446438); d = gg(d, a, b, c, x[i + 14], 9, -1019803690); c = gg(c, d, a, b, x[i + 3], 14, -187363961); b = gg(b, c, d, a, x[i + 8], 20, 1163531501);
                                a = gg(a, b, c, d, x[i + 13], 5, -1444681467); d = gg(d, a, b, c, x[i + 2], 9, -51403784); c = gg(c, d, a, b, x[i + 7], 14, 1735328473); b = gg(b, c, d, a, x[i + 12], 20, -1926607734);
                                a = hh(a, b, c, d, x[i + 5], 4, -378558); d = hh(d, a, b, c, x[i + 8], 11, -2022574463); c = hh(c, d, a, b, x[i + 11], 16, 1839030562); b = hh(b, c, d, a, x[i + 14], 23, -35309556);
                                a = hh(a, b, c, d, x[i + 1], 4, -1530992060); d = hh(d, a, b, c, x[i + 4], 11, 1272893353); c = hh(c, d, a, b, x[i + 7], 16, -155497632); b = hh(b, c, d, a, x[i + 10], 23, -1094730640);
                                a = hh(a, b, c, d, x[i + 13], 4, 681279174); d = hh(d, a, b, c, x[i], 11, -358537222); c = hh(c, d, a, b, x[i + 3], 16, -722521979); b = hh(b, c, d, a, x[i + 6], 23, 76029189);
                                a = hh(a, b, c, d, x[i + 9], 4, -640364487); d = hh(d, a, b, c, x[i + 12], 11, -421815835); c = hh(c, d, a, b, x[i + 15], 16, 530742520); b = hh(b, c, d, a, x[i + 2], 23, -995338651);
                                a = ii(a, b, c, d, x[i], 6, -198630844); d = ii(d, a, b, c, x[i + 7], 10, 1126891415); c = ii(c, d, a, b, x[i + 14], 15, -1416354905); b = ii(b, c, d, a, x[i + 5], 21, -57434055);
                                a = ii(a, b, c, d, x[i + 12], 6, 1700485571); d = ii(d, a, b, c, x[i + 3], 10, -1894986606); c = ii(c, d, a, b, x[i + 10], 15, -1051523); b = ii(b, c, d, a, x[i + 1], 21, -2054922799);
                                a = ii(a, b, c, d, x[i + 8], 6, 1873313359); d = ii(d, a, b, c, x[i + 15], 10, -30611744); c = ii(c, d, a, b, x[i + 6], 15, -1560198380); b = ii(b, c, d, a, x[i + 13], 21, 1309151649);
                                a = ii(a, b, c, d, x[i + 4], 6, -145523070); d = ii(d, a, b, c, x[i + 11], 10, -1120210379); c = ii(c, d, a, b, x[i + 2], 15, 718787259); b = ii(b, c, d, a, x[i + 9], 21, -343485551);
                                a = safeAdd(a, oa); b = safeAdd(b, ob); c = safeAdd(c, oc); d = safeAdd(d, od);
                            }
                            return [a, b, c, d];
                        }
                        var bin = [];
                        for (var i = 0; i < bytes.length * 8; i += 8) bin[i >> 5] |= (bytes[i / 8] & 0xFF) << (i % 32);
                        var hash = core(bin, bytes.length * 8);
                        var result = new Uint8Array(16);
                        for (var j = 0; j < 16; j++) result[j] = (hash[j >> 2] >>> ((j % 4) * 8)) & 0xFF;
                        return result;
                    }
                    function toHex(arr) { var h = ''; for (var i = 0; i < arr.length; i++) h += ('0' + arr[i].toString(16)).slice(-2); return h; }
                    return {
                        createHash: function () {
                            var chunks = [];
                            return {
                                update: function (data) {
                                    if (typeof data === 'string') chunks.push(new TextEncoder().encode(data));
                                    else if (data instanceof Uint8Array) chunks.push(data);
                                    else if (ArrayBuffer.isView(data)) chunks.push(new Uint8Array(data.buffer, data.byteOffset, data.byteLength));
                                    return this;
                                },
                                digest: function (encoding) {
                                    var totalLen = 0;
                                    for (var i = 0; i < chunks.length; i++) totalLen += chunks[i].length;
                                    var combined = new Uint8Array(totalLen);
                                    var offset = 0;
                                    for (var j = 0; j < chunks.length; j++) { combined.set(chunks[j], offset); offset += chunks[j].length; }
                                    var hash = md5Bytes(combined);
                                    if (encoding === 'hex') return toHex(hash);
                                    return hash;
                                }
                            };
                        },
                        randomBytes: function (size) { var b = new Uint8Array(size); window.crypto.getRandomValues(b); return b; },
                        createHmac: function () { return { update: function () { return this; }, digest: function () { return ''; } }; }
                    };
                })();
            case 'zlib':
            case 'dgram':
            case 'dns':
            case 'url':
            case 'querystring':
            case 'string_decoder':
                console.log('[Web] Returning empty stub for Node.js core module:', moduleName);
                return {};
            default:
                if (_originalRequire) {
                    try { return _originalRequire(moduleName); }
                    catch (e) {
                        console.warn('[Web] require() fallback failed for:', moduleName);
                        return {};
                    }
                }
                console.warn('[Web] No shim for require("' + moduleName + '")');
                return {};
        }
    };

    // ---- Also handle module.exports pattern used by webpack ----
    if (typeof window.module === 'undefined') {
        window.module = { exports: {} };
    }

    console.log('[OpenBlock Web] Electron shim loaded successfully.');

    // ---- Monkey-patch webpackJsonp to catch SB1 converter FixedAsciiString assertion ----
    // The scratch-sb1-converter (module 3197) throws "Non-ascii character in FixedAsciiString"
    // when given non-SB1 data. This is used as a fallback parser in module 650, but the error
    // can propagate to the React error boundary and crash the entire GUI. We patch the
    // original push method to wrap module 3197's SB1File constructor in a try-catch.
    if (window.webpackJsonp && Array.isArray(window.webpackJsonp)) {
        var _origPush = window.webpackJsonp.push.bind(window.webpackJsonp);
        window.webpackJsonp.push = function (chunk) {
            if (Array.isArray(chunk) && chunk[1]) {
                var origMod3197 = chunk[1][3197];
                if (origMod3197) {
                    chunk[1][3197] = function (module, exports, __webpack_require__) {
                        origMod3197.call(this, module, exports, __webpack_require__);
                        // Wrap SB1File if exported
                        if (module.exports && module.exports.SB1File) {
                            var OrigSB1File = module.exports.SB1File;
                            module.exports.SB1File = function SafeSB1File(input) {
                                try {
                                    return new OrigSB1File(input);
                                } catch (e) {
                                    console.warn('[Web] SB1File parsing skipped (not an SB1 project):', e.message);
                                    throw e; // Re-throw so the caller's catch block handles it
                                }
                            };
                        }
                    };
                }
            }
            return _origPush(chunk);
        };
    }

    // ---- Fetch Interceptor: Redirect OpenBlock Resource Server (127.0.0.1:20112) ----
    // The OpenBlock GUI fetches device lists, extension data, and assets from a local
    // resource server at http://127.0.0.1:20112/. In the web deployment, we intercept
    // these requests and serve them from the static ../external-resources/ directory.
    (function () {
        var _originalFetch = window.fetch;
        var RESOURCE_SERVER_RE = /^https?:\/\/127\.0\.0\.1:20112\//;
        var BASE_URL = '../external-resources/';

        window.fetch = function (input, init) {
            var url = (typeof input === 'string') ? input : (input && input.url ? input.url : '');

            if (RESOURCE_SERVER_RE.test(url)) {
                // Rewrite the URL: http://127.0.0.1:20112/devices/zh-tw.json → ../external-resources/devices/zh-tw.json
                var relativePath = url.replace(RESOURCE_SERVER_RE, '');
                // Deduplicate: if path already starts with external-resources/, don't add it again
                if (relativePath.indexOf('external-resources/') === 0) {
                    relativePath = relativePath.replace('external-resources/', '');
                }
                var newUrl = BASE_URL + relativePath;
                if (!newUrl.includes('?')) newUrl += '?t=' + Date.now();
                console.log('[Web] Resource Server Redirect:', url, '→', newUrl);

                return _originalFetch.call(window, newUrl, init).then(function (response) {
                    if (!response.ok) {
                        console.warn('[Web] Resource redirect got', response.status, 'for', newUrl);
                        return response;
                    }
                    // For device JSON files, just log for debugging
                    if (newUrl.indexOf('/devices/') >= 0 && newUrl.indexOf('.json') >= 0) {
                        console.log('[Web] Device JSON loaded from:', newUrl);
                    }
                    return response;
                }).catch(function (err) {
                    console.warn('[Web] Resource redirect fetch failed for', newUrl, ':', err.message);
                    // Return an empty JSON response to prevent the app from crashing
                    return new Response('[]', {
                        status: 200,
                        statusText: 'OK',
                        headers: { 'Content-Type': 'application/json' }
                    });
                });
            }

            // Pass through all non-resource-server requests
            return _originalFetch.apply(window, arguments);
        };
        console.log('[OpenBlock Web] Resource server fetch interceptor installed.');
    })();


    // ---- XMLHttpRequest Interceptor: Redirect Resource Server URLs ----
    // Some parts of the bundled code may use XMLHttpRequest instead of fetch.
    (function () {
        var _origXHROpen = XMLHttpRequest.prototype.open;
        var RESOURCE_SERVER_RE = /^https?:\/\/127\.0\.0\.1:20112\//;
        var BASE_URL = '../external-resources/';

        XMLHttpRequest.prototype.open = function (method, url) {
            if (typeof url === 'string' && RESOURCE_SERVER_RE.test(url)) {
                var newUrl = BASE_URL + url.replace(RESOURCE_SERVER_RE, '');
                if (!newUrl.includes('?')) newUrl += '?t=' + Date.now();
                console.log('[Web] XHR Resource Redirect:', url, '→', newUrl);
                arguments[1] = newUrl;
            }
            return _origXHROpen.apply(this, arguments);
        };
        console.log('[OpenBlock Web] XHR resource server interceptor installed.');
    })();

    // ---- DOM Element Interceptor ----
    // Rewrites src attributes on <img>, <source>, and <script> elements that point
    // to the local resource server (127.0.0.1:20112). This handles:
    // 1. React rendering <img src="http://127.0.0.1:20112/..."> for device icons
    // 2. loadjs creating <script src="http://127.0.0.1:20112/..."> for extension JS files
    (function () {
        var RESOURCE_SERVER_RE = /^https?:\/\/127\.0\.0\.1:20112\//;
        var BASE_URL = '../external-resources/';

        function rewriteUrl(url) {
            if (url && RESOURCE_SERVER_RE.test(url)) {
                var relativePath = url.replace(RESOURCE_SERVER_RE, '');
                // Deduplicate: if path already starts with external-resources/, don't add it again
                if (relativePath.indexOf('external-resources/') === 0) {
                    relativePath = relativePath.replace('external-resources/', '');
                }
                var finalUrl = BASE_URL + relativePath;
                if (!finalUrl.includes('?')) finalUrl += '?t=' + Date.now();
                return finalUrl;
            }
            return null;
        }

        function rewriteSrc(el) {
            var src = el.getAttribute('src');
            var newSrc = rewriteUrl(src);
            if (newSrc) {
                el.setAttribute('src', newSrc);
                console.log('[Web] Element src rewrite:', src, '→', newSrc);
            }
        }

        // ---- Script src setter override ----
        // loadjs sets script.src = 'http://127.0.0.1:20112/...' which triggers immediate loading.
        // We intercept this via the src property setter.
        var scriptSrcDescriptor = Object.getOwnPropertyDescriptor(HTMLScriptElement.prototype, 'src');
        if (scriptSrcDescriptor && scriptSrcDescriptor.set) {
            Object.defineProperty(HTMLScriptElement.prototype, 'src', {
                get: scriptSrcDescriptor.get,
                set: function (value) {
                    var newValue = rewriteUrl(value);
                    if (newValue) {
                        console.log('[Web] Script src rewrite:', value, '→', newValue);
                        scriptSrcDescriptor.set.call(this, newValue);
                    } else {
                        scriptSrcDescriptor.set.call(this, value);
                    }
                },
                configurable: true,
                enumerable: true
            });
            console.log('[OpenBlock Web] Script src interceptor installed.');
        }

        // ---- MutationObserver for img/source elements ----
        function scanAllImages() {
            var imgs = document.querySelectorAll('img[src], source[src]');
            for (var i = 0; i < imgs.length; i++) {
                rewriteSrc(imgs[i]);
            }
        }

        var observer = new MutationObserver(function (mutations) {
            for (var i = 0; i < mutations.length; i++) {
                var mutation = mutations[i];
                if (mutation.addedNodes) {
                    for (var j = 0; j < mutation.addedNodes.length; j++) {
                        var node = mutation.addedNodes[j];
                        if (node.nodeType === 1) {
                            if ((node.tagName === 'IMG' || node.tagName === 'SOURCE') && node.getAttribute('src')) {
                                rewriteSrc(node);
                            }
                            var children = node.querySelectorAll ? node.querySelectorAll('img[src], source[src]') : [];
                            for (var k = 0; k < children.length; k++) {
                                rewriteSrc(children[k]);
                            }
                        }
                    }
                }
                if (mutation.type === 'attributes' && mutation.attributeName === 'src') {
                    if (mutation.target.tagName === 'IMG' || mutation.target.tagName === 'SOURCE') {
                        rewriteSrc(mutation.target);
                    }
                }
            }
        });

        function startObserver() {
            observer.observe(document.body || document.documentElement, {
                childList: true,
                subtree: true,
                attributes: true,
                attributeFilter: ['src']
            });
            scanAllImages();
            console.log('[OpenBlock Web] DOM element interceptor (MutationObserver) installed.');
        }

        if (document.body) {
            startObserver();
        } else {
            document.addEventListener('DOMContentLoaded', startObserver);
        }
    })();

    // ---- VM loadProject patch ----
    // The scratch-parser's SB3 validator (AJV schema) rejects OpenBlock's
    // default project JSON because it omits some SB3-required fields
    // (monitors, extensions, layerOrder, comments, tempo, videoState, etc.).
    // When validation fails, loadProject falls back to the SB1 parser which
    // crashes with "Non-ascii character in FixedAsciiString" on the JSON string.
    // This patch bypasses the validator entirely: it JSON-parses the input,
    // sets projectVersion = 3, and calls deserializeProject directly.
    (function () {
        console.log('[OpenBlock Web] Installing VM loadProject patch...');

        // Poll for the VM to become available (created by React)
        var patchInterval = setInterval(function () {
            // Look for the VM in React fiber tree
            var vm = window.vm;
            if (!vm) {
                var allElements = document.querySelectorAll('*');
                for (var i = 0; i < allElements.length; i++) {
                    var el = allElements[i];
                    for (var key in el) {
                        if (key.indexOf('__reactFiber$') === 0 || key.indexOf('__reactInternalInstance$') === 0) {
                            var fiber = el[key];
                            while (fiber) {
                                if (fiber.stateNode && fiber.stateNode.props && fiber.stateNode.props.vm) {
                                    vm = fiber.stateNode.props.vm;
                                    window.vm = vm;
                                    break;
                                }
                                fiber = fiber.return;
                            }
                            if (vm) break;
                        }
                    }
                    if (vm) break;
                }
            }

            if (!vm || !vm.loadProject || vm._webPatched) return;

            var origLoadProject = vm.loadProject.bind(vm);

            vm.loadProject = function (input) {
                console.log('[OpenBlock Web] loadProject intercepted, type:', typeof input);

                // Convert input to a JSON object
                var projectJSON;
                try {
                    if (typeof input === 'string') {
                        projectJSON = JSON.parse(input);
                    } else if (typeof input === 'object' && !(input instanceof ArrayBuffer) && !ArrayBuffer.isView(input)) {
                        projectJSON = input;
                    } else if (input instanceof ArrayBuffer || ArrayBuffer.isView(input)) {
                        // Binary input — could be a .sb3 zip or .sb2 binary
                        // Fall back to original loadProject for binary data
                        console.log('[OpenBlock Web] Binary project data, using original loadProject');
                        return origLoadProject(input);
                    } else {
                        projectJSON = JSON.parse(JSON.stringify(input));
                    }
                } catch (parseError) {
                    console.error('[OpenBlock Web] Failed to parse project JSON:', parseError);
                    return origLoadProject(input);
                }

                // Determine version
                if (projectJSON.targets && projectJSON.meta) {
                    // SB3 format (Scratch 3.0)
                    projectJSON.projectVersion = 3;
                    console.log('[OpenBlock Web] Detected SB3 format, skipping validator');
                } else if (projectJSON.objName) {
                    // SB2 format (Scratch 2.0)
                    projectJSON.projectVersion = 2;
                    console.log('[OpenBlock Web] Detected SB2 format, skipping validator');
                } else {
                    // Unknown format — try original path
                    console.warn('[OpenBlock Web] Unknown project format, using original loadProject');
                    return origLoadProject(input);
                }

                // Call deserializeProject directly (skipping the broken validator)
                return vm.deserializeProject(projectJSON, null)
                    .then(function () {
                        vm.runtime.emitProjectLoaded();
                        console.log('[OpenBlock Web] Project loaded successfully, targets:', vm.runtime.targets.length);
                    })
                    .catch(function (error) {
                        console.error('[OpenBlock Web] deserializeProject failed:', error);
                        return Promise.reject(error);
                    });
            };

            vm._webPatched = true;
            clearInterval(patchInterval);
            console.log('[OpenBlock Web] VM loadProject patched successfully.');

            // If project wasn't loaded yet (0 targets), try loading default project
            if (vm.runtime.targets.length === 0) {
                console.log('[OpenBlock Web] No targets loaded, attempting default project load...');
                var storage = vm.runtime.storage;
                if (storage) {
                    storage.load(storage.AssetType.Project, '0', storage.DataFormat.JSON)
                        .then(function (projectAsset) {
                            if (projectAsset && projectAsset.data) {
                                console.log('[OpenBlock Web] Loading default project...');
                                vm.loadProject(projectAsset.data);
                            }
                        })
                        .catch(function (e) {
                            console.error('[OpenBlock Web] Failed to load default project:', e);
                        });
                }
            }
        }, 500);

        // Stop polling after 30 seconds
        setTimeout(function () {
            clearInterval(patchInterval);
        }, 30000);
    })();

})();
