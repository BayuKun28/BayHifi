// Baydev HiFi — WebHID Hardware Bridge
// Interfaces directly with USB DSP DACs (Kiwi Ears AD1, KT0211L, KT1132L) via the W3C WebHID API.

window.bayHifiWebHid = {
  isSupported: function() {
    return typeof navigator !== 'undefined' && 'hid' in navigator;
  },

  activeDevice: null,
  inputCallbacks: [],
  disconnectCallbacks: [],

  // Enumerate already paired devices that have persistent permission in the browser
  getPairedDevices: async function() {
    if (!window.bayHifiWebHid.isSupported()) return [];
    try {
      const devices = await navigator.hid.getDevices();
      return devices.map(d => ({
        id: 'webhid_' + d.vendorId + '_' + d.productId,
        vendorId: d.vendorId,
        productId: d.productId,
        productName: d.productName || 'USB Audio DAC',
        opened: d.opened
      }));
    } catch (e) {
      console.warn('[WebHID] getPairedDevices error:', e);
      return [];
    }
  },

  // Request user permission for a USB DAC device via native browser popup
  requestDevice: async function() {
    if (!window.bayHifiWebHid.isSupported()) {
      throw new Error('WebHID API is not supported in this browser. Please use Chrome, Edge, or Chromium.');
    }

    const filters = [
      { vendorId: 0x31b2 }, // Kiwi Ears
      { vendorId: 0x3302 }, // KTMicro
      { vendorId: 0x2fc6 }  // Moondrop
    ];

    let devices = [];
    try {
      devices = await navigator.hid.requestDevice({ filters: filters });
    } catch (e) {
      console.log('[WebHID] Filtered request yielded no device, retrying with open filter:', e);
      try {
        devices = await navigator.hid.requestDevice({ filters: [] });
      } catch (err) {
        throw err;
      }
    }

    if (!devices || devices.length === 0) {
      return null;
    }

    const d = devices[0];
    return {
      id: 'webhid_' + d.vendorId + '_' + d.productId,
      vendorId: d.vendorId,
      productId: d.productId,
      productName: d.productName || 'USB Audio DAC',
      opened: d.opened
    };
  },

  // Open HID connection to active or specified device
  connect: async function(vendorId, productId) {
    if (!window.bayHifiWebHid.isSupported()) {
      throw new Error('WebHID API is not supported in this browser.');
    }

    const devices = await navigator.hid.getDevices();
    let dev = null;
    if (vendorId !== undefined && productId !== undefined) {
      dev = devices.find(d => d.vendorId === vendorId && d.productId === productId);
    }
    if (!dev && devices.length > 0) {
      dev = devices[0];
    }
    if (!dev) {
      return null;
    }

    if (!dev.opened) {
      await dev.open();
    }
    window.bayHifiWebHid.activeDevice = dev;

    dev.oninputreport = (event) => {
      const dataView = event.data;
      const bytes = new Uint8Array(dataView.buffer, dataView.byteOffset, dataView.byteLength);
      const reportId = event.reportId;
      const arr = Array.from(bytes);
      for (const cb of window.bayHifiWebHid.inputCallbacks) {
        try {
          cb(reportId, arr);
        } catch (e) {
          console.error('[WebHID] inputreport callback error:', e);
        }
      }
    };

    return {
      id: 'webhid_' + dev.vendorId + '_' + dev.productId,
      vendorId: dev.vendorId,
      productId: dev.productId,
      productName: dev.productName || 'USB Audio DAC',
      opened: dev.opened
    };
  },

  disconnect: async function() {
    const dev = window.bayHifiWebHid.activeDevice;
    if (dev) {
      try {
        if (dev.opened) {
          await dev.close();
        }
      } catch (e) {
        console.warn('[WebHID] close error:', e);
      }
      window.bayHifiWebHid.activeDevice = null;
      for (const cb of window.bayHifiWebHid.disconnectCallbacks) {
        try { cb(); } catch (e) {}
      }
    }
  },

  sendReport: async function(reportId, byteList) {
    const dev = window.bayHifiWebHid.activeDevice;
    if (!dev || !dev.opened) {
      throw new Error('Physical USB DAC is not connected or opened.');
    }
    const u8 = new Uint8Array(byteList);
    await dev.sendReport(reportId, u8);
  },

  registerInputReportCallback: function(callback) {
    window.bayHifiWebHid.inputCallbacks.push(callback);
    return function() {
      const idx = window.bayHifiWebHid.inputCallbacks.indexOf(callback);
      if (idx !== -1) window.bayHifiWebHid.inputCallbacks.splice(idx, 1);
    };
  },

  registerDisconnectCallback: function(callback) {
    window.bayHifiWebHid.disconnectCallbacks.push(callback);
    return function() {
      const idx = window.bayHifiWebHid.disconnectCallbacks.indexOf(callback);
      if (idx !== -1) window.bayHifiWebHid.disconnectCallbacks.splice(idx, 1);
    };
  }
};

if (typeof navigator !== 'undefined' && 'hid' in navigator) {
  navigator.hid.addEventListener('disconnect', (event) => {
    if (window.bayHifiWebHid.activeDevice === event.device) {
      window.bayHifiWebHid.disconnect();
    }
  });
}
