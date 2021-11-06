using Cxx = import "./include/c++.capnp";
$Cxx.namespace("cereal");

using Java = import "./include/java.capnp";
$Java.package("ai.comma.openpilot.cereal");
$Java.outerClassname("Dp");

@0xbfa7e645486440c7;

# dp.capnp: a home for deprecated structs

# dp
struct DragonConf {
  dpThermalStarted @0 :Bool;
  dpThermalOverheat @1 :Bool;
  dpAtl @2 :Bool;
  dpAtlOpLong @3 :Bool;
  dpDashcamd @4 :Bool;
  dpAutoShutdown @5 :Bool;
  dpAthenad @6 :Bool;
  dpUploader @7 :Bool;
  dpLateralMode @8 :UInt8;
  dpSignalOffDelay @9 :Float32;
  dpLcMinMph @10 :UInt8;
  dpLcAutoMinMph @11 :UInt8;
  dpLcAutoDelay @12 :Float32;
  dpLaneLessModeCtrl @13 :Bool;
  dpLaneLessMode @14 :UInt8;
  dpAllowGas @15 :Bool;
  dpFollowingProfileCtrl @16 :Bool;
  dpFollowingProfile @17 :UInt8;
  dpAccelProfileCtrl @18 :Bool;
  dpAccelProfile @19 :UInt8;
  dpGearCheck @20 :Bool;
  dpSpeedCheck @21 :Bool;
  dpUiDisplayMode @22 :UInt8;
  dpUiSpeed @23 :Bool;
  dpUiEvent @24 :Bool;
  dpUiMaxSpeed @25 :Bool;
  dpUiFace @26 :Bool;
  dpUiLane @27 :Bool;
  dpUiLead @28 :Bool;
  dpUiSide @29 :Bool;
  dpUiTop @30 :Bool;
  dpUiBlinker @31 :Bool;
  dpUiBrightness @32 :UInt8;
  dpUiVolume @33 :Int8;
  dpToyotaLdw @34 :Bool;
  dpToyotaSng @35 :Bool;
  dpToyotaCruiseOverride @36 :Bool;
  dpToyotaCruiseOverrideVego @37 :Bool;
  dpToyotaCruiseOverrideAt @38 :Float32;
  dpToyotaCruiseOverrideSpeed @39 :Float32;
  dpVwTimebombAssist @40 :Bool;
  dpIpAddr @41 :Text;
  dpCameraOffset @42 :Int8;
  dpPathOffset @43 :Int8;
  dpLocale @44 :Text;
  dpSrLearner @45 :Bool;
  dpSrCustom @46 :Float32;
  dpAppd @47 :Bool;
  dpMapd @48 :Bool;
}