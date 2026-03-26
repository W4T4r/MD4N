# ███╗   ███╗██████╗ ██╗  ██╗███╗   ██╗
# ████╗ ████║██╔══██╗██║  ██║████╗  ██║
# ██╔████╔██║██║  ██║███████║██╔██╗ ██║
# ██║╚██╔╝██║██║  ██║╚════██║██║╚██╗██║
# ██║ ╚═╝ ██║██████╔╝     ██║██║ ╚████║
# ╚═╝     ╚═╝╚═════╝      ╚═╝╚═╝  ╚═══╝
#
# user.nix - Shared defaults committed to the repository
# Override these values locally in local/generated/user.nix.
let
  name = "user";
  fullname = "Your Name";
  locale = "en_US.UTF-8";
  timezone = "Asia/Tokyo";
  hostname = "nixos";
  gitName = "Your Name";
  gitEmail = "";
  packageProfile = "full";
  enableLocalFonts = false;
  enableBcompare5 = true;
  enableVesktop = true;
  enableCava = true;
  enableGeminiCli = true;
  enableCodex = true;
  enableClaudeCode = true;
  enableGoogleChrome = true;
  enableThunderbird = true;
  enableObsStudio = true;
  enableDavinciResolve = true;
  enableZotero = true;
  enablePodmanDesktop = true;
  enableDistrobox = true;
  enableDistroshelf = true;
  enableTexliveFull = true;
  enableGlobalProtect = true;
  enableVirtualization = true;
  enableVirtManager = true;
  enableOllama = true;
  enableSteam = true;
  gpuVendor = "generic";
  enableFingerprint = false;
  enableDualBoot = false;
  enableHibernate = false;
  home = "/home/${name}";
  dotroot = "/home/${name}/Documents/MD4N";
  homemanager = "${dotroot}/home-manager";
  cfg = "${homemanager}/config";
  app = "${homemanager}/applications";
  faceFile = "";
  browser = "firefox";
  niriBrowserScript = "${home}/.config/md4n/generated/niri/browser.sh";
  niriOutputsFile = "${home}/.config/niri/outputs.local.kdl";
in {
  inherit name fullname locale timezone hostname gitName gitEmail packageProfile enableLocalFonts enableBcompare5 enableVesktop enableCava enableGeminiCli enableCodex enableClaudeCode enableGoogleChrome enableThunderbird enableObsStudio enableDavinciResolve enableZotero enablePodmanDesktop enableDistrobox enableDistroshelf enableTexliveFull enableGlobalProtect enableVirtualization enableVirtManager enableOllama enableSteam gpuVendor enableFingerprint enableDualBoot enableHibernate home dotroot homemanager cfg app faceFile browser niriBrowserScript niriOutputsFile;
}
