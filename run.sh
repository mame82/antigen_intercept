#!/bin/bash

# Note: 
# ai.medicus.antigen.t21dx.android Flutter layer calls back into Java layer via messages
# Two messages for jailbreak detection and root detection trigger Java code, doing what the name implies.
# The classes implementing the detection are ProGuard obfuscated, thus bypasses only apply to the exact version 
# of the app I used, namely:
#    - package: ai.medicus.antigen.t21dx.android
#    - version: v1.3.6
#    - arch: armv7a (relevant for recompiled libflutter)
#    - also, my test device used Android 9, which could be relevant for the 'android_dlopen_ext' hook (see details below)

# Return values of "jailbreak" detection are aggregated into `e.i.a.b!n` which returns a single boolen (false, if not jailbroken)
# Return values of "root" detection are aggregated into `a.a.a.b!e` which returns a single boolen (false, if not jailbroken)

# Bypassing of these detections is a matter of overwriting the respective return values. Because I am lazy, this is not done
# in a dedicated Frida script, but in respective handlers for `frida-trace`
#
# Below is the correct call to `frida-trace` placing the proper hooks.
# The predefined hook scripts (returning `false` for the two methods) reside in
# 1) __handlers__/a.a.a.b/e.js:
# 2) __handlers__/e.i.a.b/n.js
# This essantially means, if `frida-trace` is called from this directory, it automatically grabs the pre-modded hook handlers,
# ultimately bypassing the detections.

# !!!important!!! 'setenforce 0' has to be set with root permissions to allow loading libflutter from outside of the app directory
# The app will crash otherwise.
# The modified libflutter.so proxies traffic to '192.168.8.199:8080'. It does not require a transparent proxy, as dart::io HttpClient
# is forced to use a real HTTP proxy. The modidfied libflutter also has Cert-Pinning disabled and some "reFlutter" patches applied
# to output ClassTables (as processed by Dart runtime) via logcat.
# The 'android_dl_open' hook is used to replace the 'libflutter.so' file which shall be loaded. As this is done via 'libdl.so' hook
# it could depend on the Android SDK version in use (tested on Android 9)
adb push refluttered/libflutter_arm_test.so /data/local/tmp/libflutter-medicus-amtigen-armv7a.so
adb shell chmod 0777 /data/local/tmp/libflutter-medicus-amtigen-armv7a.so
frida-trace -U -i 'libdl.so!android_dlopen_ext' -j 'e.i.a.b!n' -j 'a.a.a.b!e' -f ai.medicus.antigen.t21dx.android
