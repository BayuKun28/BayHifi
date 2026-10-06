package com.baydev.baydev_hifi

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.HashMap

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.baydev.baydev_hifi/usb_hid"
    private val ACTION_USB_PERMISSION = "com.baydev.baydev_hifi.USB_PERMISSION"

    private var usbManager: UsbManager? = null
    private var activeDevice: UsbDevice? = null
    private var activeConnection: UsbDeviceConnection? = null
    private var activeInterface: UsbInterface? = null
    private var endpointIn: UsbEndpoint? = null
    private var endpointOut: UsbEndpoint? = null
    private var methodChannel: MethodChannel? = null

    private var permissionCompleter: ((Boolean) -> Unit)? = null

    private val usbReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val action = intent?.action ?: return
            when (action) {
                ACTION_USB_PERMISSION -> {
                    val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                    val dev: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    synchronized(this) {
                        val completer = permissionCompleter
                        permissionCompleter = null
                        completer?.invoke(granted)
                    }
                    if (granted && dev != null) {
                        methodChannel?.invokeMethod("onPermissionGranted", mapOf("deviceName" to dev.deviceName))
                    }
                }
                UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    if (device != null && (activeDevice == null || activeDevice?.deviceName == device.deviceName)) {
                        closeActiveConnection()
                        methodChannel?.invokeMethod("onDeviceDetached", mapOf("deviceName" to device.deviceName))
                    }
                }
                UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                    val device: UsbDevice? = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE, UsbDevice::class.java)
                    } else {
                        @Suppress("DEPRECATION")
                        intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                    }
                    if (device != null) {
                        val name = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                            device.productName ?: "USB Audio DAC"
                        } else {
                            "USB Audio DAC"
                        }
                        methodChannel?.invokeMethod(
                            "onDeviceAttached",
                            mapOf(
                                "id" to device.deviceName,
                                "vendorId" to device.vendorId,
                                "productId" to device.productId,
                                "productName" to name
                            )
                        )
                    }
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        usbManager = getSystemService(Context.USB_SERVICE) as UsbManager
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        val filter = IntentFilter().apply {
            addAction(ACTION_USB_PERMISSION)
            addAction(UsbManager.ACTION_USB_DEVICE_ATTACHED)
            addAction(UsbManager.ACTION_USB_DEVICE_DETACHED)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(usbReceiver, filter, Context.RECEIVER_EXPORTED)
        } else {
            registerReceiver(usbReceiver, filter)
        }

        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "enumerateDevices" -> {
                    result.success(enumerateDevices())
                }
                "requestPermission" -> {
                    val deviceName = call.argument<String>("deviceName")
                    requestPermission(deviceName, result)
                }
                "openDevice" -> {
                    val deviceName = call.argument<String>("deviceName")
                    val success = openDevice(deviceName)
                    result.success(success)
                }
                "closeDevice" -> {
                    closeActiveConnection()
                    result.success(true)
                }
                "sendOutputReport" -> {
                    val reportId = call.argument<Int>("reportId") ?: 0x4B
                    val data = call.argument<ByteArray>("data")
                    if (data == null) {
                        result.error("INVALID_ARGS", "Data is required", null)
                        return@setMethodCallHandler
                    }
                    val success = sendOutputReport(reportId, data)
                    result.success(success)
                }
                "sendCommandWithResponse" -> {
                    val reportId = call.argument<Int>("reportId") ?: 0x4B
                    val data = call.argument<ByteArray>("data")
                    val timeoutMs = call.argument<Int>("timeoutMs") ?: 4000
                    if (data == null) {
                        result.error("INVALID_ARGS", "Data is required", null)
                        return@setMethodCallHandler
                    }
                    val response = sendCommandWithResponse(reportId, data, timeoutMs)
                    if (response != null) {
                        result.success(response)
                    } else {
                        result.error("COMMUNICATION_ERROR", "Failed to get response from DAC", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun enumerateDevices(): List<Map<String, Any>> {
        val mgr = usbManager ?: return emptyList()
        val list = mutableListOf<Map<String, Any>>()
        for (device in mgr.deviceList.values) {
            val map = HashMap<String, Any>()
            map["id"] = device.deviceName
            map["vendorId"] = device.vendorId
            map["productId"] = device.productId
            val name = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                device.productName ?: "USB Audio DAC"
            } else {
                "USB Audio DAC"
            }
            map["productName"] = name
            val manufacturer = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                device.manufacturerName ?: ""
            } else {
                ""
            }
            map["manufacturer"] = manufacturer
            map["hasPermission"] = mgr.hasPermission(device)
            list.add(map)
        }
        return list
    }

    private fun requestPermission(deviceName: String?, result: MethodChannel.Result) {
        val mgr = usbManager ?: run {
            result.success(false)
            return
        }
        val device = mgr.deviceList.values.find { it.deviceName == deviceName }
            ?: mgr.deviceList.values.firstOrNull() ?: run {
                result.success(false)
                return
            }

        if (mgr.hasPermission(device)) {
            result.success(true)
            return
        }

        synchronized(this) {
            permissionCompleter?.invoke(false)
            permissionCompleter = { granted ->
                try {
                    result.success(granted)
                } catch (_: Exception) {}
            }
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            PendingIntent.FLAG_MUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val intent = Intent(ACTION_USB_PERMISSION).apply {
            setPackage(packageName)
        }
        val pendingIntent = PendingIntent.getBroadcast(this, 0, intent, flags)
        mgr.requestPermission(device, pendingIntent)
    }

    private fun openDevice(deviceName: String?): Boolean {
        closeActiveConnection()
        val mgr = usbManager ?: return false
        val device = mgr.deviceList.values.find { it.deviceName == deviceName }
            ?: mgr.deviceList.values.firstOrNull() ?: return false

        if (!mgr.hasPermission(device)) {
            return false
        }

        val conn = mgr.openDevice(device) ?: return false

        // 1. Search specifically for USB HID interface (Class 3)
        var chosenIface: UsbInterface? = null
        var epIn: UsbEndpoint? = null
        var epOut: UsbEndpoint? = null

        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            if (iface.interfaceClass == UsbConstants.USB_CLASS_HID) {
                chosenIface = iface
                for (e in 0 until iface.endpointCount) {
                    val ep = iface.getEndpoint(e)
                    if (ep.direction == UsbConstants.USB_DIR_IN && epIn == null) {
                        epIn = ep
                    } else if (ep.direction == UsbConstants.USB_DIR_OUT && epOut == null) {
                        epOut = ep
                    }
                }
                break
            }
        }

        // 2. Fallback: Search for Vendor-Specific (Class 0xFF) or non-audio interface
        if (chosenIface == null) {
            for (i in 0 until device.interfaceCount) {
                val iface = device.getInterface(i)
                // Strictly skip Audio Control (1) and Audio Streaming (1)
                if (iface.interfaceClass == UsbConstants.USB_CLASS_AUDIO) continue

                var tempIn: UsbEndpoint? = null
                var tempOut: UsbEndpoint? = null
                for (e in 0 until iface.endpointCount) {
                    val ep = iface.getEndpoint(e)
                    if (ep.direction == UsbConstants.USB_DIR_IN && tempIn == null) {
                        tempIn = ep
                    } else if (ep.direction == UsbConstants.USB_DIR_OUT && tempOut == null) {
                        tempOut = ep
                    }
                }
                if (iface.interfaceClass == 0xFF || tempIn != null || tempOut != null) {
                    chosenIface = iface
                    epIn = tempIn
                    epOut = tempOut
                    break
                }
            }
        }

        // 3. Last fallback: interface 0 (only if no other interface was found)
        if (chosenIface == null && device.interfaceCount > 0) {
            chosenIface = device.getInterface(0)
        }

        if (chosenIface != null) {
            try {
                conn.claimInterface(chosenIface, true)
            } catch (_: Exception) {}
        }

        activeDevice = device
        activeConnection = conn
        activeInterface = chosenIface
        endpointIn = epIn
        endpointOut = epOut
        return true
    }

    private fun sendOutputReport(reportId: Int, data: ByteArray): Boolean {
        val conn = activeConnection ?: return false
        val iface = activeInterface

        val packet = ByteArray(data.size + 1)
        packet[0] = reportId.toByte()
        System.arraycopy(data, 0, packet, 1, data.size)

        // 1. Try Endpoint OUT (Interrupt / Bulk) if available
        if (endpointOut != null) {
            val sent = conn.bulkTransfer(endpointOut, packet, packet.size, 1500)
            if (sent >= 0) return true
        }

        // 2. Standard USB HID SET_REPORT (Output report: 0x02)
        val ifaceId = iface?.id ?: 0
        val requestType = 0x21
        val request = 0x09
        val valueOutput = (0x02 shl 8) or (reportId and 0xFF)

        // Try with 11-byte packet (reportId + data)
        var transferred = conn.controlTransfer(requestType, request, valueOutput, ifaceId, packet, packet.size, 1500)
        if (transferred >= 0) return true

        // Try with raw data (10 bytes)
        transferred = conn.controlTransfer(requestType, request, valueOutput, ifaceId, data, data.size, 1500)
        if (transferred >= 0) return true

        // 3. Try SET_REPORT as Feature report (0x03)
        val valueFeature = (0x03 shl 8) or (reportId and 0xFF)
        transferred = conn.controlTransfer(requestType, request, valueFeature, ifaceId, packet, packet.size, 1500)
        if (transferred >= 0) return true

        transferred = conn.controlTransfer(requestType, request, valueFeature, ifaceId, data, data.size, 1500)
        return transferred >= 0
    }

    private fun sendCommandWithResponse(reportId: Int, data: ByteArray, timeoutMs: Int): ByteArray? {
        val conn = activeConnection ?: return null
        val iface = activeInterface

        val sent = sendOutputReport(reportId, data)
        if (!sent) return null

        // 1. Try reading from Interrupt / Bulk IN endpoint
        if (endpointIn != null) {
            val buffer = ByteArray(64)
            val bytesRead = conn.bulkTransfer(endpointIn, buffer, buffer.size, timeoutMs)
            if (bytesRead > 0) {
                return if (bytesRead > 1 && (buffer[0].toInt() and 0xFF) == reportId) {
                    val clean = ByteArray(bytesRead - 1)
                    System.arraycopy(buffer, 1, clean, 0, clean.size)
                    clean
                } else {
                    val res = ByteArray(bytesRead)
                    System.arraycopy(buffer, 0, res, 0, bytesRead)
                    res
                }
            }
        }

        // 2. Try HID GET_REPORT control transfer (Input report: 0x01)
        val ifaceId = iface?.id ?: 0
        val buffer = ByteArray(64)
        val requestType = 0xA1
        val request = 0x01
        val valueInput = (0x01 shl 8) or (reportId and 0xFF)

        var bytesRead = conn.controlTransfer(requestType, request, valueInput, ifaceId, buffer, buffer.size, timeoutMs)
        if (bytesRead > 0) {
            return if (bytesRead > 1 && (buffer[0].toInt() and 0xFF) == reportId) {
                val clean = ByteArray(bytesRead - 1)
                System.arraycopy(buffer, 1, clean, 0, clean.size)
                clean
            } else {
                val res = ByteArray(bytesRead)
                System.arraycopy(buffer, 0, res, 0, bytesRead)
                res
            }
        }

        // 3. Try HID GET_REPORT as Feature report (0x03)
        val valueFeature = (0x03 shl 8) or (reportId and 0xFF)
        bytesRead = conn.controlTransfer(requestType, request, valueFeature, ifaceId, buffer, buffer.size, timeoutMs)
        if (bytesRead > 0) {
            return if (bytesRead > 1 && (buffer[0].toInt() and 0xFF) == reportId) {
                val clean = ByteArray(bytesRead - 1)
                System.arraycopy(buffer, 1, clean, 0, clean.size)
                clean
            } else {
                val res = ByteArray(bytesRead)
                System.arraycopy(buffer, 0, res, 0, bytesRead)
                res
            }
        }

        return null
    }

    private fun closeActiveConnection() {
        try {
            activeInterface?.let { activeConnection?.releaseInterface(it) }
            activeConnection?.close()
        } catch (_: Exception) {}
        activeDevice = null
        activeConnection = null
        activeInterface = null
        endpointIn = null
        endpointOut = null
    }

    override fun onDestroy() {
        try {
            unregisterReceiver(usbReceiver)
        } catch (_: Exception) {}
        closeActiveConnection()
        super.onDestroy()
    }
}

