import { wifiManager } from '@kit.ConnectivityKit';
import { MethodChannel, MethodCall, MethodResult, MethodCallHandler, FlutterPlugin,
  FlutterPluginBinding,
  BinaryMessenger,
  AbilityPluginBinding} from '@ohos/flutter_ohos'
import { common, UIAbility } from '@kit.AbilityKit';

const TAG: string = "WifiIotPlugin";

export default class WifiIotPlugin implements MethodCallHandler,FlutterPlugin {

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

  private onAttachedToEngine1(applicationContext: Context, messenger: BinaryMessenger) {
    this.applicationContext = applicationContext;
    this.channel = new MethodChannel(messenger, "wifi_iot")
    this.channel.setMethodCallHandler(this)
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
    try {
      // First trigger a scan, then get results
      wifiManager.startScan()
        .then(() => {
          const scanResults = wifiManager.getScanInfoList();
          const wifiList = scanResults.map((scanInfo: any) => {
            return {
              SSID: scanInfo.ssid,
              BSSID: scanInfo.bssid,
              capabilities: scanInfo.capabilities || '',
              frequency: scanInfo.frequency || 0,
              level: scanInfo.rssi || 0,
              timestamp: Date.now()
            };
          });
          result.success(JSON.stringify(wifiList));
        })
        .catch((error: Error) => {
          // If scan fails, try to get cached results
          try {
            const scanResults = wifiManager.getScanInfoList();
            const wifiList = scanResults.map((scanInfo: any) => {
              return {
                SSID: scanInfo.ssid,
                BSSID: scanInfo.bssid,
                capabilities: scanInfo.capabilities || '',
                frequency: scanInfo.frequency || 0,
                level: scanInfo.rssi || 0,
                timestamp: Date.now()
              };
            });
            result.success(JSON.stringify(wifiList));
          } catch (e) {
            result.error('LOAD_WIFI_LIST_ERROR', error.message, null);
          }
        });
    } catch (error) {
      result.error('LOAD_WIFI_LIST_ERROR', (error as Error).message, null);
    }
  }

  private forceWifiUsage(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const useWifi = arguments['useWifi'] as boolean;
    console.log(`Forcing WiFi usage: ${useWifi ? 'Use WiFi' : 'Use Mobile Data'}`);
    // HarmonyOS doesn't have direct equivalent, but we can return success
    result.success(true);
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
    const arguments = call.arguments as Record<string, any>;
    const state = arguments['state'] as boolean;
    try {
      wifiManager.enableWifi(state);
      console.log(`Setting WiFi Enable: ${state ? 'enable' : 'disable'}`);
      result.success(true);
    } catch (error) {
      result.error('SET_ENABLED_ERROR', (error as Error).message, null);
    }
  }

  private findAndConnect(call: MethodCall, result: MethodResult): void {
    // Similar to connect, but with scanning first
    this.connect(call, result);
  }

  private registerWifiNetwork(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const ssid = arguments['ssid'] as string;
    const password = arguments['password'] as string | undefined;
    const security = arguments['security'] as string | undefined;
    const isHidden = arguments['is_hidden'] as boolean | undefined || false;

    try {
      // Determine security type
      let securityType = wifiManager.SecurityType.OPEN;
      if (security) {
        const upperSecurity = security.toUpperCase();
        if (upperSecurity === 'WPA' || upperSecurity === 'WPA2') {
          securityType = wifiManager.SecurityType.WPA2_PSK;
        } else if (upperSecurity === 'WEP') {
          securityType = wifiManager.SecurityType.WEP;
        }
      }

      const wifiConfig: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        preSharedKey: password || '',
        securityType: securityType,
        bssid: arguments['bssid'] as string | undefined || '',
        bandType: wifiManager.WifiBandType.WIFI_BAND_2G,
        isHiddenSsid: isHidden
      };

      wifiManager.addCandidateConfig(wifiConfig)
        .then((networkId: number) => {
          console.log(`Registered WiFi network: ${ssid} with networkId: ${networkId}`);
          result.success(true);
        })
        .catch((error: Error) => {
          console.log(`Failed to register WiFi network: ${error.message}`);
          result.success(false);
        });
    } catch (error) {
      console.log(`Registration error: ${(error as Error).message}`);
      result.error('REGISTER_WIFI_NETWORK_ERROR', (error as Error).message, null);
    }
  }

  private connect(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const ssid = arguments['ssid'] as string;
    const password = arguments['password'] as string | undefined;
    const security = arguments['security'] as string | undefined;
    const joinOnce = arguments['join_once'] as boolean | undefined ?? false;

    try {
      // Determine security type
      let securityType = wifiManager.SecurityType.OPEN;
      if (security) {
        const upperSecurity = security.toUpperCase();
        if (upperSecurity === 'WPA' || upperSecurity === 'WPA2') {
          securityType = wifiManager.SecurityType.WPA2_PSK;
        } else if (upperSecurity === 'WEP') {
          securityType = wifiManager.SecurityType.WEP;
        }
      }

      const wifiConfig: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        preSharedKey: password || '',
        securityType: securityType,
        bssid: arguments['bssid'] as string | undefined || '',
        bandType: wifiManager.WifiBandType.WIFI_BAND_2G,
        isHiddenSsid: arguments['is_hidden'] as boolean | undefined || false
      };

      wifiManager.addCandidateConfig(wifiConfig)
        .then((networkId: number) => {
          return wifiManager.connectToCandidateConfig(networkId);
        })
        .then(() => {
          // Verify connection
          setTimeout(() => {
            wifiManager.getLinkedInfo()
              .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
                const connected = linkedInfo.ssid === ssid;
                console.log(`Connected to ${linkedInfo.ssid || '<Unknown Network>'}`);
                result.success(connected);
              })
              .catch(() => {
                result.success(false);
              });
          }, 1000);
        })
        .catch((error: Error) => {
          console.log(`Not Connected: ${error.message}`);
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
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          if (linkedInfo && linkedInfo.ssid) {
            console.log(`Trying to disconnect from '${linkedInfo.ssid}'`);
            wifiManager.disconnect();
            result.success(true);
          } else {
            console.log('Not connected to a network');
            result.success(false);
          }
        })
        .catch(() => {
          result.success(false);
        });
    } catch (error) {
      result.error('DISCONNECT_ERROR', (error as Error).message, null);
    }
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
      const ipAddress = ipInfo?.ipAddress?.toString() || null;
      result.success(ipAddress);
    } catch (error) {
      result.error('GET_IP_ERROR', (error as Error).message, null);
    }
  }

  private removeWifiNetwork(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    // Support both 'ssid' and 'prefix_ssid' for compatibility
    const ssid = arguments['ssid'] as string || '';
    const prefixSSID = arguments['prefix_ssid'] as string || '';
    const targetSSID = ssid || prefixSSID;

    if (targetSSID === '') {
      console.log('No SSID or prefix SSID was given!');
      result.success(null);
      return;
    }

    try {
      const deviceConfigs = wifiManager.getDeviceConfigs();
      let removed = false;
      for (let i = 0; i < deviceConfigs.length; i++) {
        const config = deviceConfigs[i];
        if (config.ssid) {
          // If prefix_ssid is provided, match by prefix; otherwise match exact SSID
          const matches = prefixSSID ? config.ssid.startsWith(prefixSSID) : config.ssid === targetSSID;
          if (matches) {
            wifiManager.removeCandidateConfig(config.networkId);
            removed = true;
          }
        }
      }
      result.success(removed);
    } catch (error) {
      result.error('REMOVE_WIFI_NETWORK_ERROR', (error as Error).message, null);
    }
  }

  private isRegisteredWifiNetwork(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const ssid = arguments['ssid'] as string;

    try {
      const deviceConfigs = wifiManager.getDeviceConfigs();
      const isRegistered = deviceConfigs.some((config: wifiManager.WifiDeviceConfig) => {
        return config.ssid === ssid;
      });
      result.success(isRegistered);
    } catch (error) {
      result.success(false);
    }
  }

  // Access Point Methods
  private isWiFiAPEnabled(result: MethodResult): void {
    try {
      const hotspotInfo = wifiManager.getHotspotConfig();
      const isEnabled = hotspotInfo !== null;
      result.success(isEnabled);
    } catch (error) {
      result.success(false);
    }
  }

  private setWiFiAPEnabled(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const state = arguments['state'] as boolean;
    console.log(`Setting AP WiFi Enable: ${state ? 'enable' : 'disable'}`);
    // HarmonyOS hotspot API may require additional permissions
    result.notImplemented();
  }

  private getWiFiAPState(result: MethodResult): void {
    try {
      const hotspotInfo = wifiManager.getHotspotConfig();
      if (hotspotInfo) {
        // WIFI_AP_STATE_ENABLED = 3
        result.success(3);
      } else {
        // WIFI_AP_STATE_DISABLED = 1
        result.success(1);
      }
    } catch (error) {
      // WIFI_AP_STATE_FAILED = 4
      result.success(4);
    }
  }

  private getClientList(call: MethodCall, result: MethodResult): void {
    // HarmonyOS doesn't provide direct API for getting connected clients
    result.notImplemented();
  }

  private getWiFiAPSSID(result: MethodResult): void {
    try {
      const hotspotInfo = wifiManager.getHotspotConfig();
      result.success(hotspotInfo?.ssid || null);
    } catch (error) {
      result.success(null);
    }
  }

  private setWiFiAPSSID(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const ssid = arguments['ssid'] as string;
    if (ssid) {
      console.log(`Setting AP WiFi SSID: '${ssid}'`);
      // HarmonyOS hotspot configuration requires special permissions
      result.notImplemented();
    } else {
      result.success(null);
    }
  }

  private isSSIDHidden(result: MethodResult): void {
    try {
      const hotspotInfo = wifiManager.getHotspotConfig();
      result.success(hotspotInfo?.isHiddenSsid || false);
    } catch (error) {
      result.success(false);
    }
  }

  private setSSIDHidden(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const hidden = arguments['hidden'] as boolean;
    console.log(`Setting AP WiFi Visibility: ${hidden ? 'hidden' : 'visible'}`);
    // HarmonyOS hotspot configuration requires special permissions
    result.notImplemented();
  }

  private getWiFiAPPreSharedKey(result: MethodResult): void {
    try {
      const hotspotInfo = wifiManager.getHotspotConfig();
      result.success(hotspotInfo?.preSharedKey || null);
    } catch (error) {
      result.success(null);
    }
  }

  private setWiFiAPPreSharedKey(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const preSharedKey = arguments['preSharedKey'] as string;
    if (preSharedKey) {
      console.log(`Setting AP WiFi PreSharedKey: '${preSharedKey}'`);
      // HarmonyOS hotspot configuration requires special permissions
      result.notImplemented();
    } else {
      result.success(null);
    }
  }

  private showWritePermissionSettings(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    const force = arguments['force'] as boolean | undefined || false;
    console.log(`Requesting write permission settings: force=${force}`);
    // HarmonyOS doesn't have direct equivalent to Android's write permission settings
    // This is a no-op on HarmonyOS
    result.success(true);
  }

  private setWiFiAPConfiguration(call: MethodCall, result: MethodResult): void {
    const arguments = call.arguments as Record<string, any>;
    console.log('Setting WiFi AP Configuration');
    // HarmonyOS hotspot configuration requires special permissions
    // This method is deprecated and only works on Android SDK < 26
    result.notImplemented();
  }
}

