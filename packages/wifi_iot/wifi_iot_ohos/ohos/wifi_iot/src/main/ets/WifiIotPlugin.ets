import { wifi, wifiManager } from '@kit.ConnectivityKit';
import {
  MethodChannel,
  MethodCall,
  MethodResult,
  MethodCallHandler,
  FlutterPlugin,
  FlutterPluginBinding,
  BinaryMessenger,
  AbilityPluginBinding,
} from '@ohos/flutter_ohos'
import { common, UIAbility } from '@kit.AbilityKit';


const TAG: string = "WifiIotPlugin";

export default class WifiIotPlugin implements MethodCallHandler, FlutterPlugin {
  private channel: MethodChannel | null = null;
  private applicationContext: common.Context | null = null
  private ability: UIAbility | null = null;

  getUniqueClassName(): string {
    return TAG;
  }

  static registerWith(): void {
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.onAttachedToEngine1(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  private onAttachedToEngine1(applicationContext: common.Context, messenger: BinaryMessenger): void {
    this.applicationContext = applicationContext;
    this.channel = new MethodChannel(messenger, "wifi_iot");
    this.channel.setMethodCallHandler(this);
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    this.applicationContext = null;
    this.channel?.setMethodCallHandler(null)
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility()
  }

  onDetachedFromAbility(): void {
    this.ability = null;
  }

  // 方法映射
  onMethodCall(call: MethodCall, result: MethodResult): void {
    switch (call.method) {
      // Stand Alone
      case 'loadWifiList':
        this.loadWifiList(result);
        break;
      case 'forceWifiUsage':
        this.forceWifiUsage(call, result);
        break;
      case 'isEnabled':
        this.isEnabled(result);
        break;
      case 'setEnabled':
        this.setEnabled(call, result);
        break;
      case 'findAndConnect':
        this.findAndConnect(call, result);
        break;
      case 'connect':
        this.connect(call, result);
        break;
      case 'registerWifiNetwork':
        this.registerWifiNetwork(call, result);
        break;
      case 'isConnected':
        this.isConnected(result);
        break;
      case 'disconnect':
        this.disconnect(result);
        break;
      case 'getSSID':
        this.getSSID(result);
        break;
      case 'getBSSID':
        this.getBSSID(result);
        break;
      case 'getCurrentSignalStrength':
        this.getCurrentSignalStrength(result);
        break;
      case 'getFrequency':
        this.getFrequency(result);
        break;
      case 'getIP':
        this.getIP(result);
        break;
      case 'removeWifiNetwork':
        this.removeWifiNetwork(call, result);
        break;
      case 'isRegisteredWifiNetwork':
        this.isRegisteredWifiNetwork(call, result);
        break;
      // Access Point
      case 'isWiFiAPEnabled':
        this.isWiFiAPEnabled(result);
        break;
      case 'setWiFiAPEnabled':
        this.setWiFiAPEnabled(call, result);
        break;
      case 'getWiFiAPState':
        this.getWiFiAPState(result);
        break;
      case 'getClientList':
        this.getClientList(call, result);
        break;
      case 'getWiFiAPSSID':
        this.getWiFiAPSSID(result);
        break;
      case 'setWiFiAPSSID':
        this.setWiFiAPSSID(call, result);
        break;
      case 'isSSIDHidden':
        this.isSSIDHidden(result);
        break;
      case 'setSSIDHidden':
        this.setSSIDHidden(call, result);
        break;
      case 'getWiFiAPPreSharedKey':
        this.getWiFiAPPreSharedKey(result);
        break;
      case 'setWiFiAPPreSharedKey':
        this.setWiFiAPPreSharedKey(call, result);
        break;
      case 'showWritePermissionSettings':
        this.showWritePermissionSettings(call, result);
        break;
      case 'setWiFiAPConfiguration':
        this.setWiFiAPConfiguration(call, result);
        break;
      default:
        result.notImplemented();
        break;
    }
  }

  // Stand Alone Methods
  private loadWifiList(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const isWifiEnable = wifiManager.isWifiActive();
    //   if (isWifiEnable) {
    //     result.error(
    //       "WifiIotPlugin.Wifi_Disable", "开始扫描Wi-Fi时需要开启Wi-Fi开关", null);
    //     return;
    //   }
    //   wifiManager.scan();
    //   let scanInfoList = wifiManager.getScanInfoList();
    //   result.success(JSON.stringify(scanInfoList));
    // } catch (error) {
    //   // TODO: Implement error handling.
    //   result.error('LOAD_WIFI_LIST_ERROR', error.message, null);
    // }
  }

  private forceWifiUsage(call: MethodCall, result: MethodResult): void {
    // HarmonyOS doesn't have direct equivalent, but we can return success
    result.notImplemented();
  }

  private isEnabled(result: MethodResult): void {
    try {
      const isActive = wifiManager.isWifiActive();
      result.success(isActive);
    } catch (error) {
      result.error('IS_ENABLED_ERROR', (error as Error).message, null);
    }
  }

  private setEnabled(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }

  private findAndConnect(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }

  private registerWifiNetwork(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
  }


  // NetworkSecurity.WPA: "WPA",
  //   NetworkSecurity.WEP: "WEP",
  //   NetworkSecurity.NONE: "NONE",
  _mapNetworkSecurityToWifiSecType(security: string): wifiManager.WifiSecurityType {
    switch (security) {
      case "WPA":
        // Use PSK for WPA, WPA2, WPA/WPA2 mixed
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK; // WIFI_SEC_TYPE_PSK
      case "WEP":
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_WEP; // WIFI_SEC_TYPE_WEP
      default:
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_OPEN;
        ; // WIFI_SEC_TYPE_OPEN
    }
  }

  private connect(call: MethodCall, result: MethodResult): void {

    const ssid: string = call.argument('ssid');
    const bssid: string | undefined = call.argument('ssid');
    const password: string = call.argument('password');
    const security: string = call.argument('security');
    const joinOnce: boolean = call.argument('join_once');
    const securityType: wifiManager.WifiSecurityType =
      this._mapNetworkSecurityToWifiSecType(call.argument('security') as string)
    const timeoutInSeconds: number = call.argument('timeoutInSeconds');
    const isHiddenSsid: boolean = call.argument("is_hidden");

    // Validate SSID
    if (!ssid || ssid.length === 0 || ssid.length > 32) {
      result.error('CONNECT_ERROR', 'Invalid SSID: SSID must be between 1 and 32 characters', null);
      return;
    }

    // Check WEP support
    if (security && security.toUpperCase() === 'WEP') {
      result.error('CONNECT_ERROR', 'WEP is not supported', null);
      return;
    }

    try {
      // Determine security type
      let wifiConfig: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        bssid:bssid,
        preSharedKey: password,
        securityType: securityType,
        isHiddenSsid:isHiddenSsid,
      }
      let networkIdToRemove: number | null = null;
      wifiManager.addCandidateConfig(wifiConfig)
        .then((networkId: number) => {
          if (joinOnce) {
            networkIdToRemove = networkId;
          }
          return wifiManager.connectToCandidateConfig(networkId);
        })
        .then(() => {
          // Verify connection with timeout
          const startTime = Date.now();
          const checkConnection = (): void => {
            wifiManager.getLinkedInfo()
              .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
                const connected = linkedInfo !== null && linkedInfo.ssid === ssid;
                const elapsed = (Date.now() - startTime) / 1000;

                if (connected) {
                  console.log(`Connected to ${linkedInfo.ssid || '<Unknown Network>'}`);
                  result.success(true);
                } else if (elapsed < timeoutInSeconds) {
                  // Check again after a short delay
                  setTimeout(checkConnection, 500);
                } else {
                  console.log(`Connection timeout after ${timeoutInSeconds} seconds`);
                  if (joinOnce && networkIdToRemove !== null) {
                    wifiManager.removeCandidateConfig(networkIdToRemove);
                  }
                  result.success(false);
                }
              })
              .catch(() => {
                const elapsed = (Date.now() - startTime) / 1000;
                if (elapsed < timeoutInSeconds) {
                  setTimeout(checkConnection, 500);
                } else {
                  if (joinOnce && networkIdToRemove !== null) {
                    wifiManager.removeCandidateConfig(networkIdToRemove);
                  }
                  result.success(false);
                }
              });
          };

          // Start checking connection after a short delay
          setTimeout(checkConnection, 500);
        })
        .catch((error: Error) => {
          console.log(`Not Connected: ${error.message}`);
          if (joinOnce && networkIdToRemove !== null) {
            wifiManager.removeCandidateConfig(networkIdToRemove);
          }
          result.success(false);
        });
    } catch (error) {
      console.log(`Connection error: ${(error as Error).message}`);
      result.error('CONNECT_ERROR', (error as Error).message, null);
    }
  }

  private isConnected(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          const isConnected = linkedInfo !== null && linkedInfo.ssid !== null && linkedInfo.ssid !== '';
          result.success(isConnected);
        })
        .catch(() => {
          result.success(false);
        });
    } catch (error) {
      result.success(false);
    }
  }

  private disconnect(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   wifiManager.getLinkedInfo()
    //     .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
    //       if (linkedInfo && linkedInfo.ssid) {
    //         console.log(`Trying to disconnect from '${linkedInfo.ssid}'`);
    //         wifiManager.disconnect();
    //         result.success(true);
    //       } else {
    //         console.log('Not connected to a network');
    //         result.success(false);
    //       }
    //     })
    //     .catch(() => {
    //       result.success(false);
    //     });
    // } catch (error) {
    //   result.error('DISCONNECT_ERROR', (error as Error).message, null);
    // }
  }

  private getSSID(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          result.success(linkedInfo?.ssid || null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      result.success(null);
    }
  }

  private getBSSID(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          result.success(linkedInfo?.bssid || null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      result.success(null);
    }
  }

  private getCurrentSignalStrength(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          result.success(linkedInfo?.rssi || null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      result.error('GET_SIGNAL_STRENGTH_ERROR', (error as Error).message, null);
    }
  }

  private getFrequency(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          result.success(linkedInfo?.frequency || null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      result.error('GET_FREQUENCY_ERROR', (error as Error).message, null);
    }
  }

  private getIP(result: MethodResult): void {
    try {
      const ipInfo = wifiManager.getIpInfo();
      if (ipInfo && ipInfo.ipAddress !== undefined) {
        // Convert IP address from integer to string format (e.g., 192.168.1.1)
        // Java implementation: strip[0].strip[1].strip[2].strip[3]
        // where strip[0] = (longIp & 0x000000FF) - lowest byte
        //       strip[1] = ((longIp & 0x0000FFFF) >>> 8)
        //       strip[2] = ((longIp & 0x00FFFFFF) >>> 16)
        //       strip[3] = (longIp >>> 24) - highest byte
        const ipAddress = ipInfo.ipAddress as number;
        const byte0 = (ipAddress & 0x000000FF);
        const byte1 = ((ipAddress & 0x0000FFFF) >>> 8);
        const byte2 = ((ipAddress & 0x00FFFFFF) >>> 16);
        const byte3 = (ipAddress >>> 24);
        const ipString = `${byte0}.${byte1}.${byte2}.${byte3}`;
        result.success(ipString);
      } else {
        result.success(null);
      }
    } catch (error) {
      result.error('GET_IP_ERROR', (error as Error).message, null);
    }
  }

  private removeWifiNetwork(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // // Support both 'ssid' and 'prefix_ssid' for compatibility
    // const ssid = arguments['ssid'] as string || '';
    // const prefixSSID = arguments['prefix_ssid'] as string || '';
    // const targetSSID = ssid || prefixSSID;
    //
    // if (targetSSID === '') {
    //   result.error('REMOVE_WIFI_NETWORK_ERROR', 'No SSID or prefix SSID was given!', null);
    //   return;
    // }
    //
    // try {
    //   const deviceConfigs = wifiManager.getDeviceConfigs();
    //   let removed = false;
    //   for (let i = 0; i < deviceConfigs.length; i++) {
    //     const config = deviceConfigs[i];
    //     if (config.ssid) {
    //       // If prefix_ssid is provided, match by prefix; otherwise match exact SSID
    //       const matches = prefixSSID ? config.ssid.startsWith(prefixSSID) : config.ssid === targetSSID;
    //       if (matches) {
    //         wifiManager.removeCandidateConfig(config.networkId);
    //         removed = true;
    //         // If exact match, break early; if prefix match, continue to remove all matches
    //         if (!prefixSSID) {
    //           break;
    //         }
    //       }
    //     }
    //   }
    //   result.success(removed);
    // } catch (error) {
    //   result.error('REMOVE_WIFI_NETWORK_ERROR', (error as Error).message, null);
    // }
  }

  private isRegisteredWifiNetwork(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const ssid = arguments['ssid'] as string;
    //
    // try {
    //   const deviceConfigs = wifiManager.getDeviceConfigs();
    //   const isRegistered = deviceConfigs.some((config: wifiManager.WifiDeviceConfig) => {
    //     return config.ssid === ssid;
    //   });
    //   result.success(isRegistered);
    // } catch (error) {
    //   result.success(false);
    // }
  }

  // Access Point Methods
  private isWiFiAPEnabled(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotInfo = wifiManager.getHotspotConfig();
    //   const isEnabled = hotspotInfo !== null;
    //   result.success(isEnabled);
    // } catch (error) {
    //   result.success(false);
    // }
  }

  private setWiFiAPEnabled(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const state = arguments['state'] as boolean;
    // console.log(`Setting AP WiFi Enable: ${state ? 'enable' : 'disable'}`);
    // // HarmonyOS hotspot API may require additional permissions
    // result.notImplemented();
  }

  private getWiFiAPState(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotInfo = wifiManager.getHotspotConfig();
    //   if (hotspotInfo) {
    //     // WIFI_AP_STATE_ENABLED = 3
    //     result.success(3);
    //   } else {
    //     // WIFI_AP_STATE_DISABLED = 1
    //     result.success(1);
    //   }
    // } catch (error) {
    //   // WIFI_AP_STATE_FAILED = 4
    //   result.success(4);
    // }
  }

  private getClientList(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const onlyReachables = arguments['onlyReachables'] as boolean | undefined || false;
    // const reachableTimeout = arguments['reachableTimeout'] as number | undefined || 300;
    //
    // console.log(`getClientList called with onlyReachables=${onlyReachables}, reachableTimeout=${reachableTimeout}`);
    // // HarmonyOS doesn't provide direct API for getting connected clients
    // // Return empty array to match expected format
    // result.success(JSON.stringify([]));
  }

  private getWiFiAPSSID(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotInfo = wifiManager.getHotspotConfig();
    //   result.success(hotspotInfo?.ssid || null);
    // } catch (error) {
    //   result.success(null);
    // }
  }

  private setWiFiAPSSID(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const ssid = arguments['ssid'] as string;
    // if (ssid) {
    //   console.log(`Setting AP WiFi SSID: '${ssid}'`);
    //   // HarmonyOS hotspot configuration requires special permissions
    //   result.notImplemented();
    // } else {
    //   result.success(null);
    // }
  }

  private isSSIDHidden(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotInfo = wifiManager.getHotsgpotConfig();
    //   result.success(hotspotInfo?.isHiddenSsid || false);
    // } catch (error) {
    //   result.success(false);
    // }
  }

  private setSSIDHidden(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const hidden = arguments['hidden'] as boolean;
    // console.log(`Setting AP WiFi Visibility: ${hidden ? 'hidden' : 'visible'}`);
    // // HarmonyOS hotspot configuration requires special permissions
    // result.notImplemented();
  }

  private getWiFiAPPreSharedKey(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotInfo = wifiManager.getHotspotConfig();
    //   result.success(hotspotInfo?.preSharedKey || null);
    // } catch (error) {
    //   result.success(null);
    // }
  }

  private setWiFiAPPreSharedKey(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const preSharedKey = arguments['preSharedKey'] as string;
    // if (preSharedKey) {
    //   console.log(`Setting AP WiFi PreSharedKey: '${preSharedKey}'`);
    //   // HarmonyOS hotspot configuration requires special permissions
    //   result.notImplemented();
    // } else {
    //   result.success(null);
    // }
  }

  private showWritePermissionSettings(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // const force = arguments['force'] as boolean | undefined || false;
    // console.log(`Requesting write permission settings: force=${force}`);
    // // HarmonyOS doesn't have direct equivalent to Android's write permission settings
    // // This is a no-op on HarmonyOS
    // result.success(true);
  }

  private setWiFiAPConfiguration(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const arguments = call.arguments as Record<string, any>;
    // console.log('Setting WiFi AP Configuration');
    // // HarmonyOS hotspot configuration requires special permissions
    // // This method is deprecated and only works on Android SDK < 26
    // result.notImplemented();
  }
}

