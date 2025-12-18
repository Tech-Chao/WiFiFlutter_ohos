import { wifiManager, wifiManagerExt } from '@kit.ConnectivityKit';
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
import {
  abilityAccessCtrl, bundleManager, Permissions, common, UIAbility
} from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import json from '@ohos.util.json';

const TAG: string = "WifiIotPlugin";

export default class WifiIotPlugin implements MethodCallHandler, FlutterPlugin {
  private channel: MethodChannel | null = null;
  private applicationContext: common.Context | null = null;
  private ability: UIAbility | null = null;
  // 是否在请求权限
  private requestingPermission: boolean = false;
  // 需要在退出时移除的网络配置ID列表
  private networkIdsToBeRemovedOnExit: number[] = [];

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
    // 清理需要移除的网络配置
    this.cleanup();
    this.applicationContext = null;
    this.channel?.setMethodCallHandler(null);
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.ability = binding.getAbility();
  }

  onDetachedFromAbility(): void {
    this.ability = null;
  }

  // 清理资源
  private cleanup(): void {
    // 移除需要在退出时删除的网络配置
    for (const networkId of this.networkIdsToBeRemovedOnExit) {
      try {
        wifiManager.removeCandidateConfig(networkId);
      } catch (e) {
        console.error(`${TAG} Failed to remove network config: ${networkId}`);
      }
    }
    this.networkIdsToBeRemovedOnExit = [];
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

  // 检查权限是否授权
  async checkPermissionGrant(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;

    let tokenId: number = 0;
    try {
      const bundleInfo: bundleManager.BundleInfo =
        await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      const appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`${TAG} Failed to get bundle info, code: ${err.code}, message: ${err.message}`);
    }

    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (error) {
      const err: BusinessError = error as BusinessError;
      console.error(`${TAG} Failed to check access token, code: ${err.code}, message: ${err.message}`);
    }
    return grantStatus;
  }

  // 获取Wi-Fi列表
  private async loadWifiList(result: MethodResult): Promise<void> {
    if (await this.checkPermissionGrant('ohos.permission.GET_WIFI_INFO') !==
    abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      if (this.requestingPermission) {
        result.error("WifiIotPlugin.Permission", "Only one permission can be requested at a time", null);
        return;
      }
      this.requestingPermission = true;
    }

    try {
      wifiManager.scan();
      result.success(json.stringify(this.handleNetworkScanResult()));
    } catch (error) {
      const err = error as BusinessError;
      result.error('LOAD_WIFI_LIST_ERROR', err.message, null);
    } finally {
      this.requestingPermission = false;
    }
  }

  // 处理Wi-Fi扫描的结果
  private async handleNetworkScanResult(): Promise<Array<Record<string, Object>>> {
    const scanResults: Array<wifiManager.WifiScanInfo> = await wifiManager.getScanResults();
    const wifiArray: Array<Record<string, Object>> = [];

    scanResults.forEach((scanInfo: wifiManager.WifiScanInfo) => {
      if (scanInfo.ssid && scanInfo.ssid.length > 0) {
        wifiArray.push({
          "SSID": scanInfo.ssid,
          "BSSID": scanInfo.bssid,
          "capabilities": scanInfo.capabilities,
          "frequency": scanInfo.frequency,
          "level": scanInfo.rssi,
          "timestamp": scanInfo.timestamp
        });
      }
    });
    return wifiArray;
  }

  // 从扫描结果中获取安全类型
  private getSecurityTypeFromCapabilities(capabilities: string): string | undefined {
    if (capabilities.includes("WPA") || capabilities.includes("WPA2") || capabilities.includes("WPA/WPA2")) {
      return "WPA";
    } else if (capabilities.includes("WEP")) {
      return "WEP";
    }
    return undefined;
  }

  // 映射安全类型
  private mapNetworkSecurityToWifiSecType(security: string | undefined): wifiManager.WifiSecurityType {
    if (!security) {
      return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_OPEN;
    }
    switch (security.toUpperCase()) {
      case "WPA":
      case "WPA2":
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_PSK;
      case "WEP":
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_WEP;
      default:
        return wifiManager.WifiSecurityType.WIFI_SEC_TYPE_OPEN;
    }
  }

  private forceWifiUsage(call: MethodCall, result: MethodResult): void {
    // HarmonyOS 没有直接等价的API，返回true表示成功

    result.notImplemented();
    // const useWifi = call.argument('useWifi') as boolean;
    // console.log(`${TAG} forceWifiUsage: ${useWifi}`);
    // // 在鸿蒙系统中，网络路由由系统管理，无法直接控制
    // result.success(args);
  }

  private isEnabled(result: MethodResult): void {
    try {
      const isActive = wifiManager.isWifiActive();
      result.success(isActive);
    } catch (error) {
      const err = error as BusinessError;
      result.error('IS_ENABLED_ERROR', err.message, null);
    }
  }

  private setEnabled(call: MethodCall, result: MethodResult): void {
    const state = call.argument('state') as boolean;

    try {
      if (state) {
        wifiManager.enableWifi();
      } else {
        wifiManager.disableWifi();
      }
      console.log(`${TAG} setEnabled: ${state ? 'enable' : 'disable'}`);
      result.success(null);
    } catch (error) {
      const err = error as BusinessError;
      result.error('SET_ENABLED_ERROR', err.message, null);
    }
  }

  private async findAndConnect(call: MethodCall, result: MethodResult) {
    const ssid = call.argument('ssid') as string;
    let bssid = call.argument('bssid') as string | undefined;
    const password = call.argument('password') as string | undefined;
    const joinOnce = call.argument('join_once') as boolean | undefined ?? true;
    const timeoutInSeconds = call.argument('timeout_in_seconds') as number | undefined ?? 30;
    const isHidden = call.argument('is_hidden') as boolean | undefined ?? false;
    // 先扫描，找到匹配的网络后连接
    try {
      wifiManager.scan();
      const scanResults = await wifiManager.getScanResults();

      let security: string | undefined = undefined;
      for (const scanInfo of scanResults) {
        if (scanInfo.ssid === ssid && (!bssid || scanInfo.bssid === bssid)) {
          security = this.getSecurityTypeFromCapabilities(scanInfo.capabilities);
          if (!bssid) {
            bssid = scanInfo.bssid;
          }
          break;
        }
      }

      // 调用连接方法
      this.connectTo(result, ssid, bssid, password, security, joinOnce, isHidden, timeoutInSeconds);
    } catch (error) {
      const err = error as BusinessError;
      result.error('FIND_AND_CONNECT_ERROR', err.message, null);
    }
  }

  private registerWifiNetwork(call: MethodCall, result: MethodResult): void {
    const ssid = call.argument('ssid') as string;
    const bssid = call.argument('bssid') as string | undefined;
    const password = call.argument('password') as string | undefined;
    const security = call.argument('security') as string | undefined;
    const isHidden = call.argument('is_hidden') as boolean | undefined ?? false;

    // 验证SSID
    if (!ssid || ssid.length === 0 || ssid.length > 32) {
      result.error('REGISTER_ERROR', 'Invalid SSID: SSID must be between 1 and 32 characters', null);
      return;
    }

    // 检查WEP支持
    if (security && security.toUpperCase() === 'WEP') {
      result.error('REGISTER_ERROR', 'WEP is not supported', null);
      return;
    }

    try {
      const securityType = this.mapNetworkSecurityToWifiSecType(security ?? undefined);
      const wifiConfig: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        bssid: bssid ?? '',
        preSharedKey: password ?? '',
        securityType: securityType,
        isHiddenSsid: isHidden,
      };

      wifiManager.addCandidateConfig(wifiConfig)
        .then((networkId: number) => {
          console.log(`${TAG} Registered WiFi network: ${ssid} with networkId: ${networkId}`);
          result.success(null);
        })
        .catch((error: BusinessError) => {
          console.error(`${TAG} Failed to register WiFi network: ${error.message}`);
          result.error('REGISTER_ERROR', error.message, null);
        });
    } catch (error) {
      const err = error as BusinessError;
      result.error('REGISTER_ERROR', err.message, null);
    }
  }

  private connect(call: MethodCall, result: MethodResult): void {
    const ssid = call.argument('ssid') as string;
    const bssid = call.argument('bssid') as string | undefined;
    const password = call.argument('password') as string | undefined;
    const security = call.argument('security') as string | undefined;
    const joinOnce = call.argument('join_once') as boolean | undefined ?? true;
    const isHidden = call.argument('is_hidden') as boolean | undefined ?? false;
    const timeoutInSeconds = call.argument('timeout_in_seconds') as number | undefined ?? 30;

    this.connectTo(result, ssid, bssid, password, security, joinOnce, isHidden, timeoutInSeconds);
  }

  private connectTo(
    result: MethodResult,
    ssid: string,
    bssid: string | undefined,
    password: string | undefined,
    security: string | undefined,
    joinOnce: boolean,
    isHidden: boolean,
    timeoutInSeconds: number
  ): void {
    // 验证SSID
    if (!ssid || ssid.length === 0 || ssid.length > 32) {
      result.error('CONNECT_ERROR', 'Invalid SSID: SSID must be between 1 and 32 characters', null);
      return;
    }

    // 检查WEP支持
    if (security && security.toUpperCase() === 'WEP') {
      result.error('CONNECT_ERROR', 'WEP is not supported', null);
      return;
    }

    try {
      const securityType = this.mapNetworkSecurityToWifiSecType(security);
      const wifiConfig: wifiManager.WifiDeviceConfig = {
        ssid: ssid,
        bssid: bssid ?? '',
        preSharedKey: password ?? '',
        securityType: securityType,
        isHiddenSsid: isHidden,
      };

      let networkIdToRemove: number | null = null;

      wifiManager.addCandidateConfig(wifiConfig)
        .then((networkId: number) => {
          if (joinOnce) {
            networkIdToRemove = networkId;
            this.networkIdsToBeRemovedOnExit.push(networkId);
          }
          return wifiManager.connectToCandidateConfig(networkId);
        })
        .then(() => {
          // 验证连接，带超时
          const startTime = Date.now();
          const checkConnection = (): void => {
            wifiManager.getLinkedInfo()
              .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
                const connected = linkedInfo !== null && linkedInfo.ssid === ssid;
                const elapsed = (Date.now() - startTime) / 1000;

                if (connected) {
                  console.log(`${TAG} Connected to ${linkedInfo.ssid || '<Unknown Network>'}`);
                  result.success(true);
                } else if (elapsed < timeoutInSeconds) {
                  setTimeout(checkConnection, 500);
                } else {
                  console.log(`${TAG} Connection timeout after ${timeoutInSeconds} seconds`);
                  if (joinOnce && networkIdToRemove !== null) {
                    wifiManager.removeCandidateConfig(networkIdToRemove);
                    const index = this.networkIdsToBeRemovedOnExit.indexOf(networkIdToRemove);
                    if (index > -1) {
                      this.networkIdsToBeRemovedOnExit.splice(index, 1);
                    }
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
                    const index = this.networkIdsToBeRemovedOnExit.indexOf(networkIdToRemove);
                    if (index > -1) {
                      this.networkIdsToBeRemovedOnExit.splice(index, 1);
                    }
                  }
                  result.success(false);
                }
              });
          };

          setTimeout(checkConnection, 500);
        })
        .catch((error: BusinessError) => {
          console.log(`${TAG} Not Connected: ${error.message}`);
          if (joinOnce && networkIdToRemove !== null) {
            wifiManager.removeCandidateConfig(networkIdToRemove);
            const index = this.networkIdsToBeRemovedOnExit.indexOf(networkIdToRemove);
            if (index > -1) {
              this.networkIdsToBeRemovedOnExit.splice(index, 1);
            }
          }
          result.success(false);
        });
    } catch (error) {
      const err = error as BusinessError;
      console.log(`${TAG} Connection error: ${err.message}`);
      result.error('CONNECT_ERROR', err.message, null);
    }
  }

  private isConnected(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          const isConnected = linkedInfo !== null &&
            linkedInfo.ssid !== null &&
            linkedInfo.ssid !== '' &&
            linkedInfo.connState === wifiManager.ConnState.CONNECTED;
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
      wifiManager.disconnect();
      result.success(true);
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} Disconnect error: ${err.message}`);
      result.success(false);
    }
  }

  private getSSID(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          let ssid = linkedInfo?.ssid || null;
          // 移除可能存在的引号
          if (ssid && ssid.startsWith('"') && ssid.endsWith('"')) {
            ssid = ssid.substring(1, ssid.length - 1);
          }
          result.success(ssid);
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
          const bssid = linkedInfo?.bssid || null;
          result.success(bssid ? bssid.toUpperCase() : null);
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
          result.success(linkedInfo?.rssi ?? null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      const err = error as BusinessError;
      result.error('GET_SIGNAL_STRENGTH_ERROR', err.message, null);
    }
  }

  private getFrequency(result: MethodResult): void {
    try {
      wifiManager.getLinkedInfo()
        .then((linkedInfo: wifiManager.WifiLinkedInfo) => {
          result.success(linkedInfo?.frequency ?? null);
        })
        .catch(() => {
          result.success(null);
        });
    } catch (error) {
      const err = error as BusinessError;
      result.error('GET_FREQUENCY_ERROR', err.message, null);
    }
  }

  private getIP(result: MethodResult): void {
    try {
      const ipInfo = wifiManager.getIpInfo();
      if (ipInfo && ipInfo.ipAddress !== undefined) {
        // 将IP地址从整数转换为字符串格式
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
      const err = error as BusinessError;
      result.error('GET_IP_ERROR', err.message, null);
    }
  }

  private removeWifiNetwork(call: MethodCall, result: MethodResult): void {
    const ssid = call.argument('ssid') as string || '';

    if (ssid === '') {
      result.error('REMOVE_ERROR', 'No SSID was given!', null);
      return;
    }

    try {
      const candidateConfigs = wifiManager.getCandidateConfigs();
      let removed = false;

      for (const config of candidateConfigs) {
        if (config.ssid && config.ssid.startsWith(ssid)) {
          wifiManager.removeCandidateConfig(config.id);
          removed = true;
          break;
        }
      }
      result.success(removed);
    } catch (error) {
      const err = error as BusinessError;
      result.error('REMOVE_ERROR', err.message, null);
    }
  }

  private isRegisteredWifiNetwork(call: MethodCall, result: MethodResult): void {
    const ssid = call.argument('ssid') as string;

    try {
      const candidateConfigs = wifiManager.getCandidateConfigs();
      const isRegistered = candidateConfigs.some((config: wifiManager.WifiDeviceConfig) => {
        return config.ssid === ssid;
      });
      result.success(isRegistered);
    } catch (error) {
      result.success(false);
    }
  }

  // Access Point Methods - 热点相关方法
  // 注意：鸿蒙系统的热点API需要系统应用权限，普通应用可能无法使用

  private isWiFiAPEnabled(result: MethodResult): void {
    try {
      const isActive = wifiManager.isHotspotActive();
      result.success(isActive);
    } catch (error) {
      result.success(false);
    }
  }

  private setWiFiAPEnabled(call: MethodCall, result: MethodResult): void {
    const state = call.argument('state') as boolean;

    try {
      if (canIUse("SystemCapability.Communication.WiFi.AP.Extension")) {
        console.info("当前设备支持 Wi-Fi AP 扩展能力");
        if (state) {
          wifiManagerExt.enableHotspot();
        } else {
          wifiManagerExt.disableHotspot();
        }
        result.success(true);
      } else {
        console.error("");
        result.error('SET_AP_ENABLE_ERROR', '不支持此能力，请检查配置或设备兼容性', null);
      }
    } catch (error) {
      const err = error as BusinessError;
      console.error(`${TAG} setWiFiAPEnabled error: ${err.message}`);
      result.success(false);
    }
  }

  private getWiFiAPState(result: MethodResult): void {
    try {
      const isActive = wifiManager.isHotspotActive();
      if (isActive) {
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
    result.notImplemented();
    // try {
    //   const stations = wifiManager.getStations();
    //   const clientArray: Array<Record<string, Object>> = [];
    //
    //   for (const station of stations) {
    //     clientArray.push({
    //       "IPAddr": station.ipAddress || '',
    //       "HWAddr": station.macAddress || '',
    //       "Device": station.name || '',
    //       "isReachable": true
    //     });
    //   }
    //   result.success(json.stringify(clientArray));
    // } catch (error) {
    //   // 如果获取失败，返回空数组
    //   result.success(json.stringify([]));
    // }
  }

  private getWiFiAPSSID(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotConfig = wifiManager.getHotspotConfig();
    //   result.success(hotspotConfig?.ssid || null);
    // } catch (error) {
    //   result.success(null);
    // }
  }

  private setWiFiAPSSID(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const ssid = call.argument('ssid') as string;
    //
    // try {
    //   const currentConfig = wifiManager.getHotspotConfig();
    //   if (currentConfig) {
    //     currentConfig.ssid = ssid;
    //     wifiManager.setHotspotConfig(currentConfig);
    //     result.success(null);
    //   } else {
    //     result.error('SET_AP_SSID_ERROR', 'Hotspot config not available', null);
    //   }
    // } catch (error) {
    //   const err = error as BusinessError;
    //   result.error('SET_AP_SSID_ERROR', err.message, null);
    // }
  }

  private isSSIDHidden(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotConfig = wifiManager.getHotspotConfig();
    //   result.success(hotspotConfig?.isHiddenSsid || false);
    // } catch (error) {
    //   result.success(false);
    // }
  }

  private setSSIDHidden(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const hidden = call.argument('hidden') as boolean;
    //
    // try {
    //   const currentConfig = wifiManager.getHotspotConfig();
    //   if (currentConfig) {
    //     currentConfig.isHiddenSsid = hidden;
    //     wifiManager.setHotspotConfig(currentConfig);
    //     result.success(null);
    //   } else {
    //     result.error('SET_SSID_HIDDEN_ERROR', 'Hotspot config not available', null);
    //   }
    // } catch (error) {
    //   const err = error as BusinessError;
    //   result.error('SET_SSID_HIDDEN_ERROR', err.message, null);
    // }
  }

  private getWiFiAPPreSharedKey(result: MethodResult): void {
    result.notImplemented();
    // try {
    //   const hotspotConfig = wifiManager.getHotspotConfig();
    //   result.success(hotspotConfig?.preSharedKey || null);
    // } catch (error) {
    //   result.success(null);
    // }
  }

  private setWiFiAPPreSharedKey(call: MethodCall, result: MethodResult): void {
    result.notImplemented();
    // const preSharedKey = call.argument('preSharedKey') as string;
    //
    // try {
    //   const currentConfig = wifiManager.getHotspotConfig();
    //   if (currentConfig) {
    //     currentConfig.preSharedKey = preSharedKey;
    //     wifiManager.setHotspotConfig(currentConfig);
    //     result.success(null);
    //   } else {
    //     result.error('SET_AP_KEY_ERROR', 'Hotspot config not available', null);
    //   }
    // } catch (error) {
    //   const err = error as BusinessError;
    //   result.error('SET_AP_KEY_ERROR', err.message, null);
    // }
  }

  private showWritePermissionSettings(call: MethodCall, result: MethodResult): void {
    // 鸿蒙系统没有直接等价的写入权限设置页面
    // 返回成功，不做任何操作
    result.notImplemented();
  }

  private setWiFiAPConfiguration(call: MethodCall, result: MethodResult): void {
    // 此方法在Android上已废弃，在鸿蒙上不实现
    result.notImplemented();
  }
}
