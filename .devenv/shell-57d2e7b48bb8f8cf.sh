if [ -n "$PS1" ] && [ -e $HOME/.bashrc ]; then
    source $HOME/.bashrc;
fi

shopt -u expand_aliases
PATH=${PATH:-}
nix_saved_PATH="$PATH"
XDG_DATA_DIRS=${XDG_DATA_DIRS:-}
nix_saved_XDG_DATA_DIRS="$XDG_DATA_DIRS"
declare -a envHostTargetHooks=('pkgConfigWrapper_addPkgConfigPath' 'ccWrapper_addCVars' 'bintoolsWrapper_addLDVars' )
NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu='1'
export NIX_CC_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu
DEVENV_TASK_FILE='/nix/store/67gwkyrn8qfd381zka7lgr23bm2d2v2a-tasks.json'
export DEVENV_TASK_FILE
preferLocalBuild='1'
export preferLocalBuild
IFS=' 	
'
depsHostHostPropagated=''
export depsHostHostPropagated
buildInputs=''
export buildInputs
outputLib='out'
outputDevdoc='REMOVE'
RANLIB='ranlib'
export RANLIB
declare -a postFixupHooks=('noBrokenSymlinksInAllOutputs' '_makeSymlinksRelative' '_multioutPropagateDev' )
DEVENV_RUNTIME='/run/user/1000/devenv-303d476'
export DEVENV_RUNTIME
PATH='/nix/store/4bwbk4an4bx7cb8xwffghvjjyfyl7m2i-bash-interactive-5.3p9/bin:/nix/store/dimnagks1qsp7180yw74z0npp7z2ihs3-go-1.26.2/bin:/nix/store/6qbyi9hnp8haj2xjpcbkn8sgbi8nz61v-delve-1.26.1/bin:/nix/store/mip3wvnnvakhk9q3jjr9b169lq6v60ln-gotools-0.44.0/bin:/nix/store/2v52hlwwjs856h62fay6a92wwv0pslzy-gomodifytags-1.17.0/bin:/nix/store/xhb065ccyh4nyqr8hrkvfwx1csv2a4bh-impl-1.5.0/bin:/nix/store/w0js44iyr636gg7gxq4nlprbh3l1n7sp-go-tools-2026.1/bin:/nix/store/v0p2b7kwssm5j3qrw0dcr9k15zvsnly1-gotests-1.9.0/bin:/nix/store/c8glgmzcs86c90172j8g4kibkp3z58vz-iferr-0-unstable-2024-01-22/bin:/nix/store/27awffybla1vqpjj2g8qmsgd1imj2w5l-gopls-0.21.1/bin:/nix/store/c0277k5giric1mn9dklllavbzvxl6hzb-git-2.53.0/bin:/nix/store/lj9iikldz29gc7nizgn4xh30cw33xvdl-openssh-10.3p1/bin:/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/bin:/nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev/bin:/nix/store/mj1k1nsdqr0mp9wsnkg7blgh3xf5wssv-brotli-1.2.0/bin:/nix/store/dgdzsx6i729gcp1rrz85zbaacgl86gab-krb5-1.22.1-dev/bin:/nix/store/qp2qzmh67rqy6i36sh3iqznk1akiw4q1-krb5-1.22.1/bin:/nix/store/yvxyaqh3bzj7nr64zlr1axyf76fgcszb-nghttp2-1.68.1/bin:/nix/store/a327a5lqzwakcs3yjgx4sa1931fph5gf-libidn2-2.3.8-bin/bin:/nix/store/2di90l89y2ygdy3rbws7dhg9nrvd3pnx-openssl-3.6.1-bin/bin:/nix/store/79kr7fafcvvmch13cyczpckz40159pk5-libpsl-0.21.5/bin:/nix/store/91jddg4g6788ilnk3kww8j8jhxhzk6d3-zstd-1.5.7-bin/bin:/nix/store/k0rqiflg1vkn1kj96br5pfxj40p3srz4-zstd-1.5.7/bin:/nix/store/sm2nq18jjqp4x0sxpl6lrvwl9rx6mvj2-curl-8.19.0-bin/bin:/nix/store/v5c3inhfq6xshmwg1c254vfbcy4jp3k9-jq-1.8.1-bin/bin:/nix/store/y3m73nv1ry783kqfjqq17p3kxxaxx5d1-gh-2.92.0/bin:/nix/store/v7mjkia7ki79s5i24ldbzq1khalhgzk0-pkg-config-wrapper-0.29.2/bin:/nix/store/66lksljlljdd5ppgvfk8g89y8xgqcxd7-patchelf-0.15.2/bin:/nix/store/qd70v8g0561vm8m33kmnp79z00cgyi5n-gcc-wrapper-15.2.0/bin:/nix/store/sanx9fg8mry8mq92zhlm5qvb83qlxrlx-gcc-15.2.0/bin:/nix/store/pf30k3mg7n6bibc1k6609gyq7glk00k2-glibc-2.42-61-bin/bin:/nix/store/jjxngswsb214vb58qx485jhmilf0kxxy-coreutils-9.10/bin:/nix/store/kfwagnh6i1mysf7vxq679rzh30z9zj3g-binutils-wrapper-2.46/bin:/nix/store/p2vkw5s89ff1fs2d2rxqxiqil9s0jpcm-binutils-2.46/bin:/nix/store/jjxngswsb214vb58qx485jhmilf0kxxy-coreutils-9.10/bin:/nix/store/vhsirn9m1ifmnw5g1qczzhvqkx6lw1if-findutils-4.10.0/bin:/nix/store/hx084k7pgz4n0vgkvil9gbcnl8y6p1xf-diffutils-3.12/bin:/nix/store/af4a8i43kc2ss4rnmf0swkk2mprsw6xq-gnused-4.9/bin:/nix/store/wf7lr2hf43546jc5kwqh3dbxnpcnw1mn-gnugrep-3.12/bin:/nix/store/lakv43kv98sl6h0ba6wnyg513mcq61vl-gawk-5.4.0/bin:/nix/store/rnvb7bvp53v2dw7pcwh9xb89x5z4rjib-gnutar-1.35/bin:/nix/store/9lhr1c3l9qzv8pzp3idmii1nwvxxjys3-gzip-1.14/bin:/nix/store/zj6r42syyswkhrr174bzppj3n7xhq936-bzip2-1.0.8-bin/bin:/nix/store/yvrwcs1a45rj8142n0l2w9q9s6akamjr-gnumake-4.4.1/bin:/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin:/nix/store/zj7mxwji29zvj9vl70iip7gw4h6ljfam-patch-2.8/bin:/nix/store/2nm5c858fh52s6mhcffm07s3biaxys44-xz-5.8.3-bin/bin:/nix/store/iscmg3ivhx7z67dz14lrg7p77gnsa4dw-file-5.45/bin'
export PATH
PKG_CONFIG='pkg-config'
export PKG_CONFIG
phases='buildPhase'
export phases
NIX_BUILD_CORES='4'
export NIX_BUILD_CORES
mesonFlags=''
export mesonFlags
defaultBuildInputs=''
STRIP='strip'
export STRIP
outputInfo='out'
declare -a envTargetTargetHooks=()
AS='as'
export AS
_substituteStream_has_warned_replace_deprecation='false'
name='devenv-shell-env'
export name
outputDev='out'
outputInclude='out'
HOST_PATH='/nix/store/jjxngswsb214vb58qx485jhmilf0kxxy-coreutils-9.10/bin:/nix/store/vhsirn9m1ifmnw5g1qczzhvqkx6lw1if-findutils-4.10.0/bin:/nix/store/hx084k7pgz4n0vgkvil9gbcnl8y6p1xf-diffutils-3.12/bin:/nix/store/af4a8i43kc2ss4rnmf0swkk2mprsw6xq-gnused-4.9/bin:/nix/store/wf7lr2hf43546jc5kwqh3dbxnpcnw1mn-gnugrep-3.12/bin:/nix/store/lakv43kv98sl6h0ba6wnyg513mcq61vl-gawk-5.4.0/bin:/nix/store/rnvb7bvp53v2dw7pcwh9xb89x5z4rjib-gnutar-1.35/bin:/nix/store/9lhr1c3l9qzv8pzp3idmii1nwvxxjys3-gzip-1.14/bin:/nix/store/zj6r42syyswkhrr174bzppj3n7xhq936-bzip2-1.0.8-bin/bin:/nix/store/yvrwcs1a45rj8142n0l2w9q9s6akamjr-gnumake-4.4.1/bin:/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin:/nix/store/zj7mxwji29zvj9vl70iip7gw4h6ljfam-patch-2.8/bin:/nix/store/2nm5c858fh52s6mhcffm07s3biaxys44-xz-5.8.3-bin/bin:/nix/store/iscmg3ivhx7z67dz14lrg7p77gnsa4dw-file-5.45/bin'
export HOST_PATH
declare -a pkgsTargetTarget=()
initialPath='/nix/store/jjxngswsb214vb58qx485jhmilf0kxxy-coreutils-9.10 /nix/store/vhsirn9m1ifmnw5g1qczzhvqkx6lw1if-findutils-4.10.0 /nix/store/hx084k7pgz4n0vgkvil9gbcnl8y6p1xf-diffutils-3.12 /nix/store/af4a8i43kc2ss4rnmf0swkk2mprsw6xq-gnused-4.9 /nix/store/wf7lr2hf43546jc5kwqh3dbxnpcnw1mn-gnugrep-3.12 /nix/store/lakv43kv98sl6h0ba6wnyg513mcq61vl-gawk-5.4.0 /nix/store/rnvb7bvp53v2dw7pcwh9xb89x5z4rjib-gnutar-1.35 /nix/store/9lhr1c3l9qzv8pzp3idmii1nwvxxjys3-gzip-1.14 /nix/store/zj6r42syyswkhrr174bzppj3n7xhq936-bzip2-1.0.8-bin /nix/store/yvrwcs1a45rj8142n0l2w9q9s6akamjr-gnumake-4.4.1 /nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9 /nix/store/zj7mxwji29zvj9vl70iip7gw4h6ljfam-patch-2.8 /nix/store/2nm5c858fh52s6mhcffm07s3biaxys44-xz-5.8.3-bin /nix/store/iscmg3ivhx7z67dz14lrg7p77gnsa4dw-file-5.45'
doCheck=''
export doCheck
declare -a envHostHostHooks=('pkgConfigWrapper_addPkgConfigPath' 'ccWrapper_addCVars' 'bintoolsWrapper_addLDVars' )
declare -a pkgsBuildBuild=()
READELF='readelf'
export READELF
pkg='/nix/store/qd70v8g0561vm8m33kmnp79z00cgyi5n-gcc-wrapper-15.2.0'
NIX_HARDENING_ENABLE='bindnow format fortify fortify3 libcxxhardeningfast pic relro stackclashprotection stackprotector strictflexarrays1 strictoverflow zerocallusedregs'
export NIX_HARDENING_ENABLE
depsTargetTarget=''
export depsTargetTarget
outputs='out'
export outputs
GOTOOLDIR='/nix/store/mip3wvnnvakhk9q3jjr9b169lq6v60ln-gotools-0.44.0/bin'
export GOTOOLDIR
declare -a preConfigureHooks=('_multioutConfig' )
NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu='1'
export NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu
shellHook='
export PS1="\[\e[0;34m\](devenv)\[\e[0m\] ${PS1-}"


# Override temp directories that stdenv set to NIX_BUILD_TOP.
# Only reset those that still point to the Nix build dir; leave
# any user/CI-supplied value intact so child processes (e.g.
# `devenv processes wait`) compute the same runtime directory.
for var in TMP TMPDIR TEMP TEMPDIR; do
  if [ -n "${!var-}" ] && [ "${!var}" = "${NIX_BUILD_TOP-}" ]; then
    export "$var"=/tmp
  fi
done
if [ -n "${NIX_BUILD_TOP-}" ]; then
  unset NIX_BUILD_TOP
fi

# set path to locales on non-NixOS Linux hosts
if [ -z "${LOCALE_ARCHIVE-}" ]; then
  export LOCALE_ARCHIVE=/nix/store/sp7b84c2jnbskd6dm2n5splgipg9d1f0-glibc-locales-2.42-61/lib/locale/locale-archive
fi


# direnv helper
if [ ! type -p direnv &>/dev/null && -f .envrc ]; then
  echo "An .envrc file was detected, but the direnv command is not installed."
  echo "To use this configuration, please install direnv: https://direnv.net/docs/installation.html"
fi

mkdir -p "$DEVENV_STATE"
if [ ! -L "$DEVENV_DOTFILE/profile" ] || [ "$(/nix/store/jjxngswsb214vb58qx485jhmilf0kxxy-coreutils-9.10/bin/readlink $DEVENV_DOTFILE/profile)" != "/nix/store/dv1lfx9wp9d3lh0wl7rzqh63dknw9xp2-devenv-profile" ]
then
  ln -snf /nix/store/dv1lfx9wp9d3lh0wl7rzqh63dknw9xp2-devenv-profile "$DEVENV_DOTFILE/profile"
fi
unset HOST_PATH NIX_BUILD_CORES __structuredAttrs buildInputs buildPhase builder depsBuildBuild depsBuildBuildPropagated depsBuildTarget depsBuildTargetPropagated depsHostHost depsHostHostPropagated depsTargetTarget depsTargetTargetPropagated dontAddDisableDepTrack doCheck doInstallCheck nativeBuildInputs out outputs patches phases preferLocalBuild propagatedBuildInputs propagatedNativeBuildInputs shell shellHook stdenv strictDeps

mkdir -p /run/user/1000/devenv-303d476
ln -snf /run/user/1000/devenv-303d476 /home/karim/Dev/DevOps-Intro/.devenv/run


export PATH=$GOPATH/bin:$PATH

echo "✨ devenv 2.0.6 is out of date. Please update to 2.1.2: https://devenv.sh/getting-started/#installation" >&2


# Check whether the direnv integration is out of date.
{
  if [[ ":${DIRENV_ACTIVE-}:" == *":/home/karim/Dev/DevOps-Intro:"* ]]; then
    if [[ ! "${DEVENV_NO_DIRENVRC_OUTDATED_WARNING-}" == 1 && ! "${DEVENV_DIRENVRC_ROLLING_UPGRADE-}" == 1 ]]; then
      if [[ ${DEVENV_DIRENVRC_VERSION:-0} -lt 2 ]]; then
        direnv_line=$(grep --color=never -E "source_url.*cachix/devenv" .envrc || echo "")

        echo "✨ The direnv integration in your .envrc is out of date."
        echo ""
        echo -n "RECOMMENDED: devenv can now auto-upgrade the direnv integration. "
        if [[ -n "$direnv_line" ]]; then
          echo "To enable this feature, replace the following line in your .envrc:"
          echo ""
          echo "  $direnv_line"
          echo ""
          echo "with:"
          echo ""
          echo "  eval \"\$(devenv direnvrc)\""
        else
          echo "To enable this feature, replace the \`source_url\` line that fetches the direnvrc integration in your .envrc with:"
          echo ""
          echo "  eval \"$(devenv direnvrc)\""
        fi
        echo ""
          echo "If you prefer to continue managing the integration manually, follow the upgrade instructions at https://devenv.sh/integrations/direnv/."
          echo ""
          echo "To disable this message:"
          echo ""
          echo "  Add the following environment to your .envrc before \`use devenv\`:"
          echo ""
          echo "    export DEVENV_NO_DIRENVRC_OUTDATED_WARNING=1"
          echo ""
          echo "  Or set the following option in your devenv configuration:"
          echo ""
          echo "    devenv.warnOnNewVersion = false;"
          echo ""
      fi
    fi
  fi
} >&2

echo "── DevOps-Intro devenv ──"
go version
git --version
echo "QuickNotes: cd app && go run ."

'
export shellHook
depsBuildBuildPropagated=''
export depsBuildBuildPropagated
depsBuildTarget=''
export depsBuildTarget
outputMan='out'
propagatedNativeBuildInputs=''
export propagatedNativeBuildInputs
declare -a propagatedTargetDepFiles=('propagated-target-target-deps' )
OBJDUMP='objdump'
export OBJDUMP
preConfigurePhases=' updateAutotoolsGnuConfigScriptsPhase'
outputBin='out'
PYTHONHASHSEED='0'
export PYTHONHASHSEED
PYTHONNOUSERSITE='1'
export PYTHONNOUSERSITE
depsBuildTargetPropagated=''
export depsBuildTargetPropagated
outputDoc='out'
NIX_PKG_CONFIG_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu='1'
export NIX_PKG_CONFIG_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu
PKG_CONFIG_PATH='/nix/store/5bs057cgp4nxqff22jg0k1svs121z6a8-bash-interactive-5.3p9-dev/lib/pkgconfig:/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/lib/pkgconfig:/nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev/lib/pkgconfig:/nix/store/1x1msj33z37b65vlxbs51l7i4j92qn9h-brotli-1.2.0-dev/lib/pkgconfig:/nix/store/dgdzsx6i729gcp1rrz85zbaacgl86gab-krb5-1.22.1-dev/lib/pkgconfig:/nix/store/iaf80mkaj9kfgy3h6hf1xqj7la8acr7y-nghttp2-1.68.1-dev/lib/pkgconfig:/nix/store/d2xhslm8a0b1lk0p4plmyip3i194znhy-nghttp3-1.15.0-dev/lib/pkgconfig:/nix/store/yp754aaxmfqdag95053yax1fdaa4s9ck-ngtcp2-1.22.0-dev/lib/pkgconfig:/nix/store/j3ypygy4pwwgkdrkxkhnhxqkwx4yw8zq-libidn2-2.3.8-dev/lib/pkgconfig:/nix/store/dy64cxaygvmjfznysgxk501yds8jij6s-openssl-3.6.1-dev/lib/pkgconfig:/nix/store/ylldnaarbvwkvpn5dasnjjyvvghh6k3r-libpsl-0.21.5-dev/lib/pkgconfig:/nix/store/5c04s19in4y2ij0zzkh4y9gqys8rwgc4-libssh2-1.11.1-dev/lib/pkgconfig:/nix/store/3yl2s5r3yph88imzbgbdrh8pbs9rcjcs-zlib-1.3.2-dev/share/pkgconfig:/nix/store/vbqakw4shfcbmdxs6kkp3jmp9k5br94y-zstd-1.5.7-dev/lib/pkgconfig:/nix/store/p8x5zv9s9qg3ld8b7jdm03hkpdqybjl9-jq-1.8.1-dev/lib/pkgconfig'
export PKG_CONFIG_PATH
NIX_CFLAGS_COMPILE=' -frandom-seed=86aa67916d -isystem /nix/store/5bs057cgp4nxqff22jg0k1svs121z6a8-bash-interactive-5.3p9-dev/include -isystem /nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/include -isystem /nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev/include -isystem /nix/store/1x1msj33z37b65vlxbs51l7i4j92qn9h-brotli-1.2.0-dev/include -isystem /nix/store/dgdzsx6i729gcp1rrz85zbaacgl86gab-krb5-1.22.1-dev/include -isystem /nix/store/iaf80mkaj9kfgy3h6hf1xqj7la8acr7y-nghttp2-1.68.1-dev/include -isystem /nix/store/d2xhslm8a0b1lk0p4plmyip3i194znhy-nghttp3-1.15.0-dev/include -isystem /nix/store/yp754aaxmfqdag95053yax1fdaa4s9ck-ngtcp2-1.22.0-dev/include -isystem /nix/store/j3ypygy4pwwgkdrkxkhnhxqkwx4yw8zq-libidn2-2.3.8-dev/include -isystem /nix/store/dy64cxaygvmjfznysgxk501yds8jij6s-openssl-3.6.1-dev/include -isystem /nix/store/ylldnaarbvwkvpn5dasnjjyvvghh6k3r-libpsl-0.21.5-dev/include -isystem /nix/store/5c04s19in4y2ij0zzkh4y9gqys8rwgc4-libssh2-1.11.1-dev/include -isystem /nix/store/3yl2s5r3yph88imzbgbdrh8pbs9rcjcs-zlib-1.3.2-dev/include -isystem /nix/store/vbqakw4shfcbmdxs6kkp3jmp9k5br94y-zstd-1.5.7-dev/include -isystem /nix/store/p8x5zv9s9qg3ld8b7jdm03hkpdqybjl9-jq-1.8.1-dev/include -isystem /nix/store/5bs057cgp4nxqff22jg0k1svs121z6a8-bash-interactive-5.3p9-dev/include -isystem /nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/include -isystem /nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev/include -isystem /nix/store/1x1msj33z37b65vlxbs51l7i4j92qn9h-brotli-1.2.0-dev/include -isystem /nix/store/dgdzsx6i729gcp1rrz85zbaacgl86gab-krb5-1.22.1-dev/include -isystem /nix/store/iaf80mkaj9kfgy3h6hf1xqj7la8acr7y-nghttp2-1.68.1-dev/include -isystem /nix/store/d2xhslm8a0b1lk0p4plmyip3i194znhy-nghttp3-1.15.0-dev/include -isystem /nix/store/yp754aaxmfqdag95053yax1fdaa4s9ck-ngtcp2-1.22.0-dev/include -isystem /nix/store/j3ypygy4pwwgkdrkxkhnhxqkwx4yw8zq-libidn2-2.3.8-dev/include -isystem /nix/store/dy64cxaygvmjfznysgxk501yds8jij6s-openssl-3.6.1-dev/include -isystem /nix/store/ylldnaarbvwkvpn5dasnjjyvvghh6k3r-libpsl-0.21.5-dev/include -isystem /nix/store/5c04s19in4y2ij0zzkh4y9gqys8rwgc4-libssh2-1.11.1-dev/include -isystem /nix/store/3yl2s5r3yph88imzbgbdrh8pbs9rcjcs-zlib-1.3.2-dev/include -isystem /nix/store/vbqakw4shfcbmdxs6kkp3jmp9k5br94y-zstd-1.5.7-dev/include -isystem /nix/store/p8x5zv9s9qg3ld8b7jdm03hkpdqybjl9-jq-1.8.1-dev/include'
export NIX_CFLAGS_COMPILE
configureFlags=''
export configureFlags
AR='ar'
export AR
declare -a postUnpackHooks=('_updateSourceDateEpochFromSourceRoot' )
nativeBuildInputs='/nix/store/5bs057cgp4nxqff22jg0k1svs121z6a8-bash-interactive-5.3p9-dev /nix/store/dimnagks1qsp7180yw74z0npp7z2ihs3-go-1.26.2 /nix/store/6qbyi9hnp8haj2xjpcbkn8sgbi8nz61v-delve-1.26.1 /nix/store/mip3wvnnvakhk9q3jjr9b169lq6v60ln-gotools-0.44.0 /nix/store/2v52hlwwjs856h62fay6a92wwv0pslzy-gomodifytags-1.17.0 /nix/store/xhb065ccyh4nyqr8hrkvfwx1csv2a4bh-impl-1.5.0 /nix/store/w0js44iyr636gg7gxq4nlprbh3l1n7sp-go-tools-2026.1 /nix/store/v0p2b7kwssm5j3qrw0dcr9k15zvsnly1-gotests-1.9.0 /nix/store/c8glgmzcs86c90172j8g4kibkp3z58vz-iferr-0-unstable-2024-01-22 /nix/store/27awffybla1vqpjj2g8qmsgd1imj2w5l-gopls-0.21.1 /nix/store/c0277k5giric1mn9dklllavbzvxl6hzb-git-2.53.0 /nix/store/6c6l93vpax9nkk6xxznwjn3p3aybdmvs-openssh-10.3p1-dev /nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12 /nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev /nix/store/p8x5zv9s9qg3ld8b7jdm03hkpdqybjl9-jq-1.8.1-dev /nix/store/y3m73nv1ry783kqfjqq17p3kxxaxx5d1-gh-2.92.0 /nix/store/v7mjkia7ki79s5i24ldbzq1khalhgzk0-pkg-config-wrapper-0.29.2'
export nativeBuildInputs
declare -a propagatedHostDepFiles=('propagated-host-host-deps' 'propagated-build-inputs' )
declare -a unpackCmdHooks=('_defaultUnpack' )
PYTHONPATH='/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/lib/python3.13/site-packages'
export PYTHONPATH
NIX_LDFLAGS='-rpath /nix/store/86aa67916dbwn1h9rzc6ll79r4lc4dgm-devenv-shell-env/lib  -L/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/lib -L/nix/store/7ff90dag7i173s49c5m614wny2lpps1l-brotli-1.2.0-lib/lib -L/nix/store/8cr60j6q7rqmcy4k8l6l1cay9579kd6y-krb5-1.22.1-lib/lib -L/nix/store/hms747x82q23p2g6r6kgzqf7li2ryk39-nghttp2-1.68.1-lib/lib -L/nix/store/133x0z91pizyk8zr4l2ccgqlclpkp1lj-nghttp3-1.15.0/lib -L/nix/store/g5sd94mk8w1a0wiipk81ri0prk136d32-ngtcp2-1.22.0/lib -L/nix/store/sgswwrxkhdlfskklqp4gsbi2cskfg07c-libidn2-2.3.8/lib -L/nix/store/wbyqkb1vpm41s4jb8pv0i9h4jv08xdrv-openssl-3.6.1/lib -L/nix/store/79kr7fafcvvmch13cyczpckz40159pk5-libpsl-0.21.5/lib -L/nix/store/9lzm6krq5ikzbqbmazbh5jmzwph99rz3-libssh2-1.11.1/lib -L/nix/store/ixhlv41i2wpl84xgjcks061dz4yssbg3-zlib-1.3.2/lib -L/nix/store/k0rqiflg1vkn1kj96br5pfxj40p3srz4-zstd-1.5.7/lib -L/nix/store/pz6b64891m180yb4hadj1jjg3wm3ybng-curl-8.19.0/lib -L/nix/store/09bq2i0kb008ccg3qdbyxv81ggxxnn09-jq-1.8.1/lib -L/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/lib -L/nix/store/7ff90dag7i173s49c5m614wny2lpps1l-brotli-1.2.0-lib/lib -L/nix/store/8cr60j6q7rqmcy4k8l6l1cay9579kd6y-krb5-1.22.1-lib/lib -L/nix/store/hms747x82q23p2g6r6kgzqf7li2ryk39-nghttp2-1.68.1-lib/lib -L/nix/store/133x0z91pizyk8zr4l2ccgqlclpkp1lj-nghttp3-1.15.0/lib -L/nix/store/g5sd94mk8w1a0wiipk81ri0prk136d32-ngtcp2-1.22.0/lib -L/nix/store/sgswwrxkhdlfskklqp4gsbi2cskfg07c-libidn2-2.3.8/lib -L/nix/store/wbyqkb1vpm41s4jb8pv0i9h4jv08xdrv-openssl-3.6.1/lib -L/nix/store/79kr7fafcvvmch13cyczpckz40159pk5-libpsl-0.21.5/lib -L/nix/store/9lzm6krq5ikzbqbmazbh5jmzwph99rz3-libssh2-1.11.1/lib -L/nix/store/ixhlv41i2wpl84xgjcks061dz4yssbg3-zlib-1.3.2/lib -L/nix/store/k0rqiflg1vkn1kj96br5pfxj40p3srz4-zstd-1.5.7/lib -L/nix/store/pz6b64891m180yb4hadj1jjg3wm3ybng-curl-8.19.0/lib -L/nix/store/09bq2i0kb008ccg3qdbyxv81ggxxnn09-jq-1.8.1/lib'
export NIX_LDFLAGS
propagatedBuildInputs=''
export propagatedBuildInputs
declare -a envBuildHostHooks=('addPythonPath' 'sysconfigdataHook' )
declare -a propagatedBuildDepFiles=('propagated-build-build-deps' 'propagated-native-build-inputs' 'propagated-build-target-deps' )
depsHostHost=''
export depsHostHost
LINENO='79'
declare -a pkgsBuildHost=('/nix/store/5bs057cgp4nxqff22jg0k1svs121z6a8-bash-interactive-5.3p9-dev' '/nix/store/4bwbk4an4bx7cb8xwffghvjjyfyl7m2i-bash-interactive-5.3p9' '/nix/store/dimnagks1qsp7180yw74z0npp7z2ihs3-go-1.26.2' '/nix/store/6qbyi9hnp8haj2xjpcbkn8sgbi8nz61v-delve-1.26.1' '/nix/store/mip3wvnnvakhk9q3jjr9b169lq6v60ln-gotools-0.44.0' '/nix/store/2v52hlwwjs856h62fay6a92wwv0pslzy-gomodifytags-1.17.0' '/nix/store/xhb065ccyh4nyqr8hrkvfwx1csv2a4bh-impl-1.5.0' '/nix/store/w0js44iyr636gg7gxq4nlprbh3l1n7sp-go-tools-2026.1' '/nix/store/v0p2b7kwssm5j3qrw0dcr9k15zvsnly1-gotests-1.9.0' '/nix/store/c8glgmzcs86c90172j8g4kibkp3z58vz-iferr-0-unstable-2024-01-22' '/nix/store/27awffybla1vqpjj2g8qmsgd1imj2w5l-gopls-0.21.1' '/nix/store/c0277k5giric1mn9dklllavbzvxl6hzb-git-2.53.0' '/nix/store/6c6l93vpax9nkk6xxznwjn3p3aybdmvs-openssh-10.3p1-dev' '/nix/store/lj9iikldz29gc7nizgn4xh30cw33xvdl-openssh-10.3p1' '/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12' '/nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev' '/nix/store/1x1msj33z37b65vlxbs51l7i4j92qn9h-brotli-1.2.0-dev' '/nix/store/7ff90dag7i173s49c5m614wny2lpps1l-brotli-1.2.0-lib' '/nix/store/mj1k1nsdqr0mp9wsnkg7blgh3xf5wssv-brotli-1.2.0' '/nix/store/dgdzsx6i729gcp1rrz85zbaacgl86gab-krb5-1.22.1-dev' '/nix/store/8cr60j6q7rqmcy4k8l6l1cay9579kd6y-krb5-1.22.1-lib' '/nix/store/qp2qzmh67rqy6i36sh3iqznk1akiw4q1-krb5-1.22.1' '/nix/store/iaf80mkaj9kfgy3h6hf1xqj7la8acr7y-nghttp2-1.68.1-dev' '/nix/store/hms747x82q23p2g6r6kgzqf7li2ryk39-nghttp2-1.68.1-lib' '/nix/store/yvxyaqh3bzj7nr64zlr1axyf76fgcszb-nghttp2-1.68.1' '/nix/store/d2xhslm8a0b1lk0p4plmyip3i194znhy-nghttp3-1.15.0-dev' '/nix/store/133x0z91pizyk8zr4l2ccgqlclpkp1lj-nghttp3-1.15.0' '/nix/store/yp754aaxmfqdag95053yax1fdaa4s9ck-ngtcp2-1.22.0-dev' '/nix/store/g5sd94mk8w1a0wiipk81ri0prk136d32-ngtcp2-1.22.0' '/nix/store/j3ypygy4pwwgkdrkxkhnhxqkwx4yw8zq-libidn2-2.3.8-dev' '/nix/store/a327a5lqzwakcs3yjgx4sa1931fph5gf-libidn2-2.3.8-bin' '/nix/store/sgswwrxkhdlfskklqp4gsbi2cskfg07c-libidn2-2.3.8' '/nix/store/dy64cxaygvmjfznysgxk501yds8jij6s-openssl-3.6.1-dev' '/nix/store/2di90l89y2ygdy3rbws7dhg9nrvd3pnx-openssl-3.6.1-bin' '/nix/store/wbyqkb1vpm41s4jb8pv0i9h4jv08xdrv-openssl-3.6.1' '/nix/store/ylldnaarbvwkvpn5dasnjjyvvghh6k3r-libpsl-0.21.5-dev' '/nix/store/g6q58mbnmi0f05xpm9nfvfhq963yv7wv-publicsuffix-list-0-unstable-2026-03-26' '/nix/store/79kr7fafcvvmch13cyczpckz40159pk5-libpsl-0.21.5' '/nix/store/5c04s19in4y2ij0zzkh4y9gqys8rwgc4-libssh2-1.11.1-dev' '/nix/store/9lzm6krq5ikzbqbmazbh5jmzwph99rz3-libssh2-1.11.1' '/nix/store/3yl2s5r3yph88imzbgbdrh8pbs9rcjcs-zlib-1.3.2-dev' '/nix/store/ixhlv41i2wpl84xgjcks061dz4yssbg3-zlib-1.3.2' '/nix/store/vbqakw4shfcbmdxs6kkp3jmp9k5br94y-zstd-1.5.7-dev' '/nix/store/91jddg4g6788ilnk3kww8j8jhxhzk6d3-zstd-1.5.7-bin' '/nix/store/k0rqiflg1vkn1kj96br5pfxj40p3srz4-zstd-1.5.7' '/nix/store/sm2nq18jjqp4x0sxpl6lrvwl9rx6mvj2-curl-8.19.0-bin' '/nix/store/pz6b64891m180yb4hadj1jjg3wm3ybng-curl-8.19.0' '/nix/store/p8x5zv9s9qg3ld8b7jdm03hkpdqybjl9-jq-1.8.1-dev' '/nix/store/v5c3inhfq6xshmwg1c254vfbcy4jp3k9-jq-1.8.1-bin' '/nix/store/09bq2i0kb008ccg3qdbyxv81ggxxnn09-jq-1.8.1' '/nix/store/y3m73nv1ry783kqfjqq17p3kxxaxx5d1-gh-2.92.0' '/nix/store/v7mjkia7ki79s5i24ldbzq1khalhgzk0-pkg-config-wrapper-0.29.2' '/nix/store/66lksljlljdd5ppgvfk8g89y8xgqcxd7-patchelf-0.15.2' '/nix/store/9vv51km72lpngs6aixxplrr3c88q4c3c-update-autotools-gnu-config-scripts-hook' '/nix/store/0y5xmdb7qfvimjwbq7ibg1xdgkgjwqng-no-broken-symlinks.sh' '/nix/store/cv1d7p48379km6a85h4zp6kr86brh32q-audit-tmpdir.sh' '/nix/store/85clx3b0xkdf58jn161iy80y5223ilbi-compress-man-pages.sh' '/nix/store/p3l1a5y7nllfyrjn2krlwgcc3z0cd3fq-make-symlinks-relative.sh' '/nix/store/5yzw0vhkyszf2d179m0qfkgxmp5wjjx4-move-docs.sh' '/nix/store/fyaryjvghbkpfnsyw97hb3lyb37s1pd6-move-lib64.sh' '/nix/store/kd4xwxjpjxi71jkm6ka0np72if9rm3y0-move-sbin.sh' '/nix/store/pag6l61paj1dc9sv15l7bm5c17xn5kyk-move-systemd-user-units.sh' '/nix/store/cmzya9irvxzlkh7lfy6i82gbp0saxqj3-multiple-outputs.sh' '/nix/store/x8c40nfigps493a07sdr2pm5s9j1cdc0-patch-shebangs.sh' '/nix/store/cickvswrvann041nqxb0rxilc46svw1n-prune-libtool-files.sh' '/nix/store/xyff06pkhki3qy1ls77w10s0v79c9il0-reproducible-builds.sh' '/nix/store/z7k98578dfzi6l3hsvbivzm7hfqlk0zc-set-source-date-epoch-to-latest.sh' '/nix/store/pilsssjjdxvdphlg2h19p0bfx5q0jzkn-strip.sh' '/nix/store/qd70v8g0561vm8m33kmnp79z00cgyi5n-gcc-wrapper-15.2.0' '/nix/store/kfwagnh6i1mysf7vxq679rzh30z9zj3g-binutils-wrapper-2.46' )
NIX_BINTOOLS='/nix/store/kfwagnh6i1mysf7vxq679rzh30z9zj3g-binutils-wrapper-2.46'
export NIX_BINTOOLS
XDG_DATA_DIRS='/nix/store/4bwbk4an4bx7cb8xwffghvjjyfyl7m2i-bash-interactive-5.3p9/share:/nix/store/dimnagks1qsp7180yw74z0npp7z2ihs3-go-1.26.2/share:/nix/store/6qbyi9hnp8haj2xjpcbkn8sgbi8nz61v-delve-1.26.1/share:/nix/store/c0277k5giric1mn9dklllavbzvxl6hzb-git-2.53.0/share:/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12/share:/nix/store/7xvb5060qcf36ncp47wz62rl3fsccv1g-curl-8.19.0-dev/share:/nix/store/mj1k1nsdqr0mp9wsnkg7blgh3xf5wssv-brotli-1.2.0/share:/nix/store/8cr60j6q7rqmcy4k8l6l1cay9579kd6y-krb5-1.22.1-lib/share:/nix/store/qp2qzmh67rqy6i36sh3iqznk1akiw4q1-krb5-1.22.1/share:/nix/store/yvxyaqh3bzj7nr64zlr1axyf76fgcszb-nghttp2-1.68.1/share:/nix/store/a327a5lqzwakcs3yjgx4sa1931fph5gf-libidn2-2.3.8-bin/share:/nix/store/sgswwrxkhdlfskklqp4gsbi2cskfg07c-libidn2-2.3.8/share:/nix/store/g6q58mbnmi0f05xpm9nfvfhq963yv7wv-publicsuffix-list-0-unstable-2026-03-26/share:/nix/store/79kr7fafcvvmch13cyczpckz40159pk5-libpsl-0.21.5/share:/nix/store/3yl2s5r3yph88imzbgbdrh8pbs9rcjcs-zlib-1.3.2-dev/share:/nix/store/ixhlv41i2wpl84xgjcks061dz4yssbg3-zlib-1.3.2/share:/nix/store/k0rqiflg1vkn1kj96br5pfxj40p3srz4-zstd-1.5.7/share:/nix/store/y3m73nv1ry783kqfjqq17p3kxxaxx5d1-gh-2.92.0/share:/nix/store/v7mjkia7ki79s5i24ldbzq1khalhgzk0-pkg-config-wrapper-0.29.2/share:/nix/store/66lksljlljdd5ppgvfk8g89y8xgqcxd7-patchelf-0.15.2/share'
export XDG_DATA_DIRS
builder='/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin/bash'
export builder
patches=''
export patches
NIX_NO_SELF_RPATH='1'
DETERMINISTIC_BUILD='1'
export DETERMINISTIC_BUILD
DEVENV_PROFILE='/nix/store/dv1lfx9wp9d3lh0wl7rzqh63dknw9xp2-devenv-profile'
export DEVENV_PROFILE
STRINGS='strings'
export STRINGS
declare -a preFixupHooks=('_moveToShare' '_multioutDocs' '_multioutDevs' )
doInstallCheck=''
export doInstallCheck
system='x86_64-linux'
export system
NIX_CC='/nix/store/qd70v8g0561vm8m33kmnp79z00cgyi5n-gcc-wrapper-15.2.0'
export NIX_CC
dontAddDisableDepTrack='1'
export dontAddDisableDepTrack
DEVENV_TASKS=''
export DEVENV_TASKS
prefix='/nix/store/86aa67916dbwn1h9rzc6ll79r4lc4dgm-devenv-shell-env'
strictDeps=''
export strictDeps
DEVENV_ROOT='/home/karim/Dev/DevOps-Intro'
export DEVENV_ROOT
cmakeFlags=''
export cmakeFlags
out='/nix/store/86aa67916dbwn1h9rzc6ll79r4lc4dgm-devenv-shell-env'
export out
declare -a pkgsBuildTarget=()
OSTYPE='linux-gnu'
CC='gcc'
export CC
OPTERR='1'
depsTargetTargetPropagated=''
export depsTargetTargetPropagated
SIZE='size'
export SIZE
hardeningDisable=''
export hardeningDisable
MACHTYPE='x86_64-pc-linux-gnu'
PS4='+ '
outputDevman='out'
depsBuildBuild=''
export depsBuildBuild
DEVENV_STATE='/home/karim/Dev/DevOps-Intro/.devenv/state'
export DEVENV_STATE
NIX_ENFORCE_NO_NATIVE='1'
export NIX_ENFORCE_NO_NATIVE
buildPhase='{ echo "------------------------------------------------------------";
  echo " WARNING: the existence of this path is not guaranteed.";
  echo " It is an internal implementation detail for pkgs.mkShell.";
  echo "------------------------------------------------------------";
  echo;
  # Record all build inputs as runtime dependencies
  export;
} >> "$out"
'
export buildPhase
stdenv='/nix/store/w708nqm6lvvikrq8d3x45g96hzfij0r8-stdenv-linux'
export stdenv
_PYTHON_SYSCONFIGDATA_NAME='_sysconfigdata__linux_x86_64-linux-gnu'
export _PYTHON_SYSCONFIGDATA_NAME
GOROOT='/nix/store/dimnagks1qsp7180yw74z0npp7z2ihs3-go-1.26.2/share/go/'
export GOROOT
BASH='/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin/bash'
declare -a envBuildTargetHooks=('addPythonPath' 'sysconfigdataHook' )
_PYTHON_HOST_PLATFORM='linux-x86_64'
export _PYTHON_HOST_PLATFORM
declare -a pkgsHostTarget=()
DEVENV_DOTFILE='/home/karim/Dev/DevOps-Intro/.devenv'
export DEVENV_DOTFILE
CXX='g++'
export CXX
NM='nm'
export NM
GOTOOLCHAIN='local'
export GOTOOLCHAIN
SOURCE_DATE_EPOCH='315532800'
export SOURCE_DATE_EPOCH
shell='/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin/bash'
export shell
OBJCOPY='objcopy'
export OBJCOPY
declare -a pkgsHostHost=()
HOSTTYPE='x86_64'
IN_NIX_SHELL='impure'
export IN_NIX_SHELL
SHELL='/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin/bash'
export SHELL
CONFIG_SHELL='/nix/store/i27rhb3nr65rkrwz36bchkwmav6ggsmn-bash-5.3p9/bin/bash'
export CONFIG_SHELL
OLDPWD=''
export OLDPWD
declare -a fixupOutputHooks=('if [ -z "${dontPatchELF-}" ]; then patchELF "$prefix"; fi' 'if [[ -z "${noAuditTmpdir-}" && -e "$prefix" ]]; then auditTmpdir "$prefix"; fi' 'if [ -z "${dontGzipMan-}" ]; then compressManPages "$prefix"; fi' '_moveLib64' '_moveSbin' '_moveSystemdUserUnits' 'patchShebangsAuto' '_pruneLibtoolFiles' '_doStrip' )
LD='ld'
export LD
defaultNativeBuildInputs='/nix/store/66lksljlljdd5ppgvfk8g89y8xgqcxd7-patchelf-0.15.2 /nix/store/9vv51km72lpngs6aixxplrr3c88q4c3c-update-autotools-gnu-config-scripts-hook /nix/store/0y5xmdb7qfvimjwbq7ibg1xdgkgjwqng-no-broken-symlinks.sh /nix/store/cv1d7p48379km6a85h4zp6kr86brh32q-audit-tmpdir.sh /nix/store/85clx3b0xkdf58jn161iy80y5223ilbi-compress-man-pages.sh /nix/store/p3l1a5y7nllfyrjn2krlwgcc3z0cd3fq-make-symlinks-relative.sh /nix/store/5yzw0vhkyszf2d179m0qfkgxmp5wjjx4-move-docs.sh /nix/store/fyaryjvghbkpfnsyw97hb3lyb37s1pd6-move-lib64.sh /nix/store/kd4xwxjpjxi71jkm6ka0np72if9rm3y0-move-sbin.sh /nix/store/pag6l61paj1dc9sv15l7bm5c17xn5kyk-move-systemd-user-units.sh /nix/store/cmzya9irvxzlkh7lfy6i82gbp0saxqj3-multiple-outputs.sh /nix/store/x8c40nfigps493a07sdr2pm5s9j1cdc0-patch-shebangs.sh /nix/store/cickvswrvann041nqxb0rxilc46svw1n-prune-libtool-files.sh /nix/store/xyff06pkhki3qy1ls77w10s0v79c9il0-reproducible-builds.sh /nix/store/z7k98578dfzi6l3hsvbivzm7hfqlk0zc-set-source-date-epoch-to-latest.sh /nix/store/pilsssjjdxvdphlg2h19p0bfx5q0jzkn-strip.sh /nix/store/qd70v8g0561vm8m33kmnp79z00cgyi5n-gcc-wrapper-15.2.0'
declare -a envBuildBuildHooks=('addPythonPath' 'sysconfigdataHook' )
__structuredAttrs=''
export __structuredAttrs
NIX_STORE='/nix/store'
export NIX_STORE
GOPATH='/home/karim/Dev/DevOps-Intro/.devenv/state/go'
export GOPATH
fixupPhase ()
{
 
    local output;
    for output in $(getAllOutputNames);
    do
        if [ -e "${!output}" ]; then
            chmod -R u+w,u-s,g-s "${!output}";
        fi;
    done;
    runHook preFixup;
    local output;
    for output in $(getAllOutputNames);
    do
        prefix="${!output}" runHook fixupOutput;
    done;
    recordPropagatedDependencies;
    if [ -n "${setupHook:-}" ]; then
        mkdir -p "${!outputDev}/nix-support";
        substituteAll "$setupHook" "${!outputDev}/nix-support/setup-hook";
    fi;
    if [ -n "${setupHooks:-}" ]; then
        mkdir -p "${!outputDev}/nix-support";
        local hook;
        for hook in ${setupHooks[@]};
        do
            local content;
            consumeEntire content < "$hook";
            substituteAllStream content "file '$hook'" >> "${!outputDev}/nix-support/setup-hook";
            unset -v content;
        done;
        unset -v hook;
    fi;
    if [ -n "${propagatedUserEnvPkgs[*]:-}" ]; then
        mkdir -p "${!outputBin}/nix-support";
        printWords "${propagatedUserEnvPkgs[@]}" > "${!outputBin}/nix-support/propagated-user-env-packages";
    fi;
    runHook postFixup
}
printWords ()
{
 
    (( "$#" > 0 )) || return 0;
    printf '%s ' "$@"
}
runHook ()
{
 
    local hookName="$1";
    shift;
    local hooksSlice="${hookName%Hook}Hooks[@]";
    local hook;
    for hook in "_callImplicitHook 0 $hookName" ${!hooksSlice+"${!hooksSlice}"};
    do
        _logHook "$hookName" "$hook" "$@";
        _eval "$hook" "$@";
    done;
    return 0
}
printLines ()
{
 
    (( "$#" > 0 )) || return 0;
    printf '%s\n' "$@"
}
addToSearchPathWithCustomDelimiter ()
{
 
    local delimiter="$1";
    local varName="$2";
    local dir="$3";
    if [[ -d "$dir" && "${!varName:+${delimiter}${!varName}${delimiter}}" != *"${delimiter}${dir}${delimiter}"* ]]; then
        export "${varName}=${!varName:+${!varName}${delimiter}}${dir}";
    fi
}
stripDirs ()
{
 
    local cmd="$1";
    local ranlibCmd="$2";
    local paths="$3";
    local stripFlags="$4";
    local excludeFlags=();
    local pathsNew=;
    [ -z "$cmd" ] && echo "stripDirs: Strip command is empty" 1>&2 && exit 1;
    [ -z "$ranlibCmd" ] && echo "stripDirs: Ranlib command is empty" 1>&2 && exit 1;
    local pattern;
    if [ -n "${stripExclude:-}" ]; then
        for pattern in "${stripExclude[@]}";
        do
            excludeFlags+=(-a '!' '(' -name "$pattern" -o -wholename "$prefix/$pattern" ')');
        done;
    fi;
    local p;
    for p in ${paths};
    do
        if [ -e "$prefix/$p" ]; then
            pathsNew="${pathsNew} $prefix/$p";
        fi;
    done;
    paths=${pathsNew};
    if [ -n "${paths}" ]; then
        echo "stripping (with command $cmd and flags $stripFlags) in $paths";
        local striperr;
        striperr="$(mktemp --tmpdir="$TMPDIR" 'striperr.XXXXXX')";
        find $paths -type f "${excludeFlags[@]}" -a '!' -path "$prefix/lib/debug/*" -printf '%D-%i,%p\0' | sort -t, -k1,1 -u -z | cut -d, -f2- -z | xargs -r -0 -n1 -P "$NIX_BUILD_CORES" -- $cmd $stripFlags 2> "$striperr" || exit_code=$?;
        [[ "$exit_code" = 123 || -z "$exit_code" ]] || ( cat "$striperr" 1>&2 && exit 1 );
        rm "$striperr";
        find $paths -name '*.a' -type f -exec $ranlibCmd '{}' \; 2> /dev/null;
    fi
}
substituteAll ()
{
 
    local input="$1";
    local output="$2";
    local -a args=();
    _allFlags;
    substitute "$input" "$output" "${args[@]}"
}
_defaultUnpack ()
{
 
    local fn="$1";
    local destination;
    if [ -d "$fn" ]; then
        destination="$(stripHash "$fn")";
        if [ -e "$destination" ]; then
            echo "Cannot copy $fn to $destination: destination already exists!";
            echo "Did you specify two \"srcs\" with the same \"name\"?";
            return 1;
        fi;
        cp -r --preserve=timestamps --reflink=auto -- "$fn" "$destination";
    else
        case "$fn" in 
            *.tar.xz | *.tar.lzma | *.txz)
                ( XZ_OPT="--threads=$NIX_BUILD_CORES" xz -d < "$fn";
                true ) | tar xf - --mode=+w --warning=no-timestamp
            ;;
            *.tar | *.tar.* | *.tgz | *.tbz2 | *.tbz)
                tar xf "$fn" --mode=+w --warning=no-timestamp
            ;;
            *)
                return 1
            ;;
        esac;
    fi
}
_activatePkgs ()
{
 
    local hostOffset targetOffset;
    local pkg;
    for hostOffset in "${allPlatOffsets[@]}";
    do
        local pkgsVar="${pkgAccumVarVars[hostOffset + 1]}";
        for targetOffset in "${allPlatOffsets[@]}";
        do
            (( hostOffset <= targetOffset )) || continue;
            local pkgsRef="${pkgsVar}[$targetOffset - $hostOffset]";
            local pkgsSlice="${!pkgsRef}[@]";
            for pkg in ${!pkgsSlice+"${!pkgsSlice}"};
            do
                activatePackage "$pkg" "$hostOffset" "$targetOffset";
            done;
        done;
    done
}
_doStrip ()
{
 
    local -ra flags=(dontStripHost dontStripTarget);
    local -ra debugDirs=(stripDebugList stripDebugListTarget);
    local -ra allDirs=(stripAllList stripAllListTarget);
    local -ra stripCmds=(STRIP STRIP_FOR_TARGET);
    local -ra ranlibCmds=(RANLIB RANLIB_FOR_TARGET);
    stripDebugList=${stripDebugList[*]:-lib lib32 lib64 libexec bin sbin Applications Library/Frameworks};
    stripDebugListTarget=${stripDebugListTarget[*]:-};
    stripAllList=${stripAllList[*]:-};
    stripAllListTarget=${stripAllListTarget[*]:-};
    local i;
    for i in ${!stripCmds[@]};
    do
        local -n flag="${flags[$i]}";
        local -n debugDirList="${debugDirs[$i]}";
        local -n allDirList="${allDirs[$i]}";
        local -n stripCmd="${stripCmds[$i]}";
        local -n ranlibCmd="${ranlibCmds[$i]}";
        if [[ -n "${dontStrip-}" || -n "${flag-}" ]] || ! type -f "${stripCmd-}" 2> /dev/null 1>&2; then
            continue;
        fi;
        stripDirs "$stripCmd" "$ranlibCmd" "$debugDirList" "${stripDebugFlags[*]:--S -p}";
        stripDirs "$stripCmd" "$ranlibCmd" "$allDirList" "${stripAllFlags[*]:--s -p}";
    done
}
_multioutPropagateDev ()
{
 
    if [ "$(getAllOutputNames)" = "out" ]; then
        return;
    fi;
    local outputFirst;
    for outputFirst in $(getAllOutputNames);
    do
        break;
    done;
    local propagaterOutput="$outputDev";
    if [ -z "$propagaterOutput" ]; then
        propagaterOutput="$outputFirst";
    fi;
    if [ -z "${propagatedBuildOutputs+1}" ]; then
        local po_dirty="$outputBin $outputInclude $outputLib";
        set +o pipefail;
        propagatedBuildOutputs=`echo "$po_dirty"             | tr -s ' ' '\n' | grep -v -F "$propagaterOutput"             | sort -u | tr '\n' ' ' `;
        set -o pipefail;
    fi;
    if [ -z "$propagatedBuildOutputs" ]; then
        return;
    fi;
    mkdir -p "${!propagaterOutput}"/nix-support;
    for output in $propagatedBuildOutputs;
    do
        echo -n " ${!output}" >> "${!propagaterOutput}"/nix-support/propagated-build-inputs;
    done
}
compressManPages ()
{
 
    local dir="$1";
    if [ -L "$dir"/share ] || [ -L "$dir"/share/man ] || [ ! -d "$dir/share/man" ]; then
        return;
    fi;
    echo "gzipping man pages under $dir/share/man/";
    find "$dir"/share/man/ -type f -a '!' -regex '.*\.\(bz2\|gz\|xz\)$' -print0 | xargs -0 -n1 -P "$NIX_BUILD_CORES" gzip -n -f;
    find "$dir"/share/man/ -type l -a '!' -regex '.*\.\(bz2\|gz\|xz\)$' -print0 | sort -z | while IFS= read -r -d '' f; do
        local target;
        target="$(readlink -f "$f")";
        if [ -f "$target".gz ]; then
            ln -sf "$target".gz "$f".gz && rm "$f";
        fi;
    done
}
_multioutDevs ()
{
 
    if [ "$(getAllOutputNames)" = "out" ] || [ -z "${moveToDev-1}" ]; then
        return;
    fi;
    moveToOutput include "${!outputInclude}";
    moveToOutput lib/pkgconfig "${!outputDev}";
    moveToOutput share/pkgconfig "${!outputDev}";
    moveToOutput lib/cmake "${!outputDev}";
    moveToOutput share/aclocal "${!outputDev}";
    for f in "${!outputDev}"/{lib,share}/pkgconfig/*.pc;
    do
        echo "Patching '$f' includedir to output ${!outputInclude}";
        sed -i "/^includedir=/s,=\${prefix},=${!outputInclude}," "$f";
    done
}
concatTo ()
{
 
    local -;
    set -o noglob;
    local -n targetref="$1";
    shift;
    local arg default name type;
    for arg in "$@";
    do
        IFS="=" read -r name default <<< "$arg";
        local -n nameref="$name";
        if [[ -z "${nameref[*]}" && -n "$default" ]]; then
            targetref+=("$default");
        else
            if type=$(declare -p "$name" 2> /dev/null); then
                case "${type#* }" in 
                    -A*)
                        echo "concatTo(): ERROR: trying to use concatTo on an associative array." 1>&2;
                        return 1
                    ;;
                    -a*)
                        targetref+=("${nameref[@]}")
                    ;;
                    *)
                        if [[ "$name" = *"Array" ]]; then
                            nixErrorLog "concatTo(): $name is not declared as array, treating as a singleton. This will become an error in future";
                            targetref+=(${nameref+"${nameref[@]}"});
                        else
                            targetref+=(${nameref-});
                        fi
                    ;;
                esac;
            fi;
        fi;
    done
}
definePhases ()
{
 
    if [ -z "${phases[*]:-}" ]; then
        phases="${prePhases[*]:-} unpackPhase patchPhase ${preConfigurePhases[*]:-}             configurePhase ${preBuildPhases[*]:-} buildPhase checkPhase             ${preInstallPhases[*]:-} installPhase ${preFixupPhases[*]:-} fixupPhase installCheckPhase             ${preDistPhases[*]:-} distPhase ${postPhases[*]:-}";
    fi
}
prependToVar ()
{
 
    local -n nameref="$1";
    local useArray type;
    if [ -n "$__structuredAttrs" ]; then
        useArray=true;
    else
        useArray=false;
    fi;
    if type=$(declare -p "$1" 2> /dev/null); then
        case "${type#* }" in 
            -A*)
                echo "prependToVar(): ERROR: trying to use prependToVar on an associative array." 1>&2;
                return 1
            ;;
            -a*)
                useArray=true
            ;;
            *)
                useArray=false
            ;;
        esac;
    fi;
    shift;
    if $useArray; then
        nameref=("$@" ${nameref+"${nameref[@]}"});
    else
        nameref="$* ${nameref-}";
    fi
}
ccWrapper_addCVars ()
{
 
    local role_post;
    getHostRoleEnvHook;
    local found=;
    if [ -d "$1/include" ]; then
        export NIX_CFLAGS_COMPILE${role_post}+=" -isystem $1/include";
        found=1;
    fi;
    if [ -d "$1/Library/Frameworks" ]; then
        export NIX_CFLAGS_COMPILE${role_post}+=" -iframework $1/Library/Frameworks";
        found=1;
    fi;
    if [[ -n "" && -n ${NIX_STORE:-} && -n $found ]]; then
        local scrubbed="$NIX_STORE/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-${1#"$NIX_STORE"/*-}";
        export NIX_CFLAGS_COMPILE${role_post}+=" -fmacro-prefix-map=$1=$scrubbed";
    fi
}
_moveLib64 ()
{
 
    if [ "${dontMoveLib64-}" = 1 ]; then
        return;
    fi;
    if [ ! -e "$prefix/lib64" -o -L "$prefix/lib64" ]; then
        return;
    fi;
    echo "moving $prefix/lib64/* to $prefix/lib";
    mkdir -p $prefix/lib;
    shopt -s dotglob;
    for i in $prefix/lib64/*;
    do
        mv --no-clobber "$i" $prefix/lib;
    done;
    shopt -u dotglob;
    rmdir $prefix/lib64;
    ln -s lib $prefix/lib64
}
recordPropagatedDependencies ()
{
 
    declare -ra flatVars=(depsBuildBuildPropagated propagatedNativeBuildInputs depsBuildTargetPropagated depsHostHostPropagated propagatedBuildInputs depsTargetTargetPropagated);
    declare -ra flatFiles=("${propagatedBuildDepFiles[@]}" "${propagatedHostDepFiles[@]}" "${propagatedTargetDepFiles[@]}");
    local propagatedInputsIndex;
    for propagatedInputsIndex in "${!flatVars[@]}";
    do
        local propagatedInputsSlice="${flatVars[$propagatedInputsIndex]}[@]";
        local propagatedInputsFile="${flatFiles[$propagatedInputsIndex]}";
        [[ -n "${!propagatedInputsSlice}" ]] || continue;
        mkdir -p "${!outputDev}/nix-support";
        printWords ${!propagatedInputsSlice} > "${!outputDev}/nix-support/$propagatedInputsFile";
    done
}
substituteAllStream ()
{
 
    local -a args=();
    _allFlags;
    substituteStream "$1" "$2" "${args[@]}"
}
substituteInPlace ()
{
 
    local -a fileNames=();
    for arg in "$@";
    do
        if [[ "$arg" = "--"* ]]; then
            break;
        fi;
        fileNames+=("$arg");
        shift;
    done;
    if ! [[ "${#fileNames[@]}" -gt 0 ]]; then
        echo "substituteInPlace called without any files to operate on (files must come before options!)" 1>&2;
        return 1;
    fi;
    for file in "${fileNames[@]}";
    do
        substitute "$file" "$file" "$@";
    done
}
installCheckPhase ()
{
 
    runHook preInstallCheck;
    if [[ -z "${foundMakefile:-}" ]]; then
        echo "no Makefile or custom installCheckPhase, doing nothing";
    else
        if [[ -z "${installCheckTarget:-}" ]] && ! make -n ${makefile:+-f $makefile} "${installCheckTarget:-installcheck}" > /dev/null 2>&1; then
            echo "no installcheck target in ${makefile:-Makefile}, doing nothing";
        else
            local flagsArray=(${enableParallelChecking:+-j${NIX_BUILD_CORES}} SHELL="$SHELL");
            concatTo flagsArray makeFlags makeFlagsArray installCheckFlags installCheckFlagsArray installCheckTarget=installcheck;
            echoCmd 'installcheck flags' "${flagsArray[@]}";
            make ${makefile:+-f $makefile} "${flagsArray[@]}";
            unset flagsArray;
        fi;
    fi;
    runHook postInstallCheck
}
_eval ()
{
 
    if declare -F "$1" > /dev/null 2>&1; then
        "$@";
    else
        eval "$1";
    fi
}
auditTmpdir ()
{
 
    local dir="$1";
    [ -e "$dir" ] || return 0;
    echo "checking for references to $TMPDIR/ in $dir...";
    local tmpdir elf_fifo script_fifo;
    tmpdir="$(mktemp -d)";
    elf_fifo="$tmpdir/elf";
    script_fifo="$tmpdir/script";
    mkfifo "$elf_fifo" "$script_fifo";
    ( find "$dir" -type f -not -path '*/.build-id/*' -print0 | while IFS= read -r -d '' file; do
        if isELF "$file"; then
            printf '%s\0' "$file" 1>&3;
        else
            if isScript "$file"; then
                filename=${file##*/};
                dir=${file%/*};
                if [ -e "$dir/.$filename-wrapped" ]; then
                    printf '%s\0' "$file" 1>&4;
                fi;
            fi;
        fi;
    done;
    exec 3>&- 4>&- ) 3> "$elf_fifo" 4> "$script_fifo" & ( xargs -0 -r -P "$NIX_BUILD_CORES" -n 1 sh -c '
            if { printf :; patchelf --print-rpath "$1"; } | grep -q -F ":$TMPDIR/"; then
                echo "RPATH of binary $1 contains a forbidden reference to $TMPDIR/"
                exit 1
            fi
        ' _ < "$elf_fifo" ) & local pid_elf=$!;
    local pid_script;
    ( xargs -0 -r -P "$NIX_BUILD_CORES" -n 1 sh -c '
            if grep -q -F "$TMPDIR/" "$1"; then
                echo "wrapper script $1 contains a forbidden reference to $TMPDIR/"
                exit 1
            fi
        ' _ < "$script_fifo" ) & local pid_script=$!;
    wait "$pid_elf" || { 
        echo "Some binaries contain forbidden references to $TMPDIR/. Check the error above!";
        exit 1
    };
    wait "$pid_script" || { 
        echo "Some scripts contain forbidden references to $TMPDIR/. Check the error above!";
        exit 1
    };
    rm -r "$tmpdir"
}
configurePhase ()
{
 
    runHook preConfigure;
    : "${configureScript=}";
    if [[ -z "$configureScript" && -x ./configure ]]; then
        configureScript=./configure;
    fi;
    if [ -z "${dontFixLibtool:-}" ]; then
        export lt_cv_deplibs_check_method="${lt_cv_deplibs_check_method-pass_all}";
        local i;
        find . -iname "ltmain.sh" -print0 | while IFS='' read -r -d '' i; do
            echo "fixing libtool script $i";
            fixLibtool "$i";
        done;
        CONFIGURE_MTIME_REFERENCE=$(mktemp configure.mtime.reference.XXXXXX);
        find . -executable -type f -name configure -exec grep -l 'GNU Libtool is free software; you can redistribute it and/or modify' {} \; -exec touch -r {} "$CONFIGURE_MTIME_REFERENCE" \; -exec sed -i s_/usr/bin/file_file_g {} \; -exec touch -r "$CONFIGURE_MTIME_REFERENCE" {} \;;
        rm -f "$CONFIGURE_MTIME_REFERENCE";
    fi;
    if [[ -z "${dontAddPrefix:-}" && -n "$prefix" ]]; then
        local -r prefixKeyOrDefault="${prefixKey:---prefix=}";
        if [ "${prefixKeyOrDefault: -1}" = " " ]; then
            prependToVar configureFlags "$prefix";
            prependToVar configureFlags "${prefixKeyOrDefault::-1}";
        else
            prependToVar configureFlags "$prefixKeyOrDefault$prefix";
        fi;
    fi;
    if [[ -f "$configureScript" ]]; then
        if [ -z "${dontAddDisableDepTrack:-}" ]; then
            if grep -q dependency-tracking "$configureScript"; then
                prependToVar configureFlags --disable-dependency-tracking;
            fi;
        fi;
        if [ -z "${dontDisableStatic:-}" ]; then
            if grep -q enable-static "$configureScript"; then
                prependToVar configureFlags --disable-static;
            fi;
        fi;
        if [ -z "${dontPatchShebangsInConfigure:-}" ]; then
            patchShebangs --build "$configureScript";
        fi;
    fi;
    if [ -n "$configureScript" ]; then
        local -a flagsArray;
        concatTo flagsArray configureFlags configureFlagsArray;
        echoCmd 'configure flags' "${flagsArray[@]}";
        $configureScript "${flagsArray[@]}";
        unset flagsArray;
    else
        echo "no configure script, doing nothing";
    fi;
    runHook postConfigure
}
_addToEnv ()
{
 
    local depHostOffset depTargetOffset;
    local pkg;
    for depHostOffset in "${allPlatOffsets[@]}";
    do
        local hookVar="${pkgHookVarVars[depHostOffset + 1]}";
        local pkgsVar="${pkgAccumVarVars[depHostOffset + 1]}";
        for depTargetOffset in "${allPlatOffsets[@]}";
        do
            (( depHostOffset <= depTargetOffset )) || continue;
            local hookRef="${hookVar}[$depTargetOffset - $depHostOffset]";
            if [[ -z "${strictDeps-}" ]]; then
                local visitedPkgs="";
                for pkg in "${pkgsBuildBuild[@]}" "${pkgsBuildHost[@]}" "${pkgsBuildTarget[@]}" "${pkgsHostHost[@]}" "${pkgsHostTarget[@]}" "${pkgsTargetTarget[@]}";
                do
                    if [[ "$visitedPkgs" = *"$pkg"* ]]; then
                        continue;
                    fi;
                    runHook "${!hookRef}" "$pkg";
                    visitedPkgs+=" $pkg";
                done;
            else
                local pkgsRef="${pkgsVar}[$depTargetOffset - $depHostOffset]";
                local pkgsSlice="${!pkgsRef}[@]";
                for pkg in ${!pkgsSlice+"${!pkgsSlice}"};
                do
                    runHook "${!hookRef}" "$pkg";
                done;
            fi;
        done;
    done
}
runOneHook ()
{
 
    local hookName="$1";
    shift;
    local hooksSlice="${hookName%Hook}Hooks[@]";
    local hook ret=1;
    for hook in "_callImplicitHook 1 $hookName" ${!hooksSlice+"${!hooksSlice}"};
    do
        _logHook "$hookName" "$hook" "$@";
        if _eval "$hook" "$@"; then
            ret=0;
            break;
        fi;
    done;
    return "$ret"
}
nixWarnLog ()
{
 
    _nixLogWithLevel 1 "$*"
}
_moveToShare ()
{
 
    if [ -n "$__structuredAttrs" ]; then
        if [ -z "${forceShare-}" ]; then
            forceShare=(man doc info);
        fi;
    else
        forceShare=(${forceShare:-man doc info});
    fi;
    if [[ -z "$out" ]]; then
        return;
    fi;
    for d in "${forceShare[@]}";
    do
        if [ -d "$out/$d" ]; then
            if [ -d "$out/share/$d" ]; then
                echo "both $d/ and share/$d/ exist!";
            else
                echo "moving $out/$d to $out/share/$d";
                mkdir -p $out/share;
                mv $out/$d $out/share/;
            fi;
        fi;
    done
}
runPhase ()
{
 
    local curPhase="$*";
    if [[ "$curPhase" = unpackPhase && -n "${dontUnpack:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = patchPhase && -n "${dontPatch:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = configurePhase && -n "${dontConfigure:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = buildPhase && -n "${dontBuild:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = checkPhase && -z "${doCheck:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = installPhase && -n "${dontInstall:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = fixupPhase && -n "${dontFixup:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = installCheckPhase && -z "${doInstallCheck:-}" ]]; then
        return;
    fi;
    if [[ "$curPhase" = distPhase && -z "${doDist:-}" ]]; then
        return;
    fi;
    showPhaseHeader "$curPhase";
    dumpVars;
    local startTime endTime;
    startTime=$(date +"%s");
    eval "${!curPhase:-$curPhase}";
    endTime=$(date +"%s");
    showPhaseFooter "$curPhase" "$startTime" "$endTime";
    if [ "$curPhase" = unpackPhase ]; then
        [ -n "${sourceRoot:-}" ] && chmod +x -- "${sourceRoot}";
        cd -- "${sourceRoot:-.}";
    fi
}
patchShebangs ()
{
 
    local pathName;
    local update=false;
    while [[ $# -gt 0 ]]; do
        case "$1" in 
            --host)
                pathName=HOST_PATH;
                shift
            ;;
            --build)
                pathName=PATH;
                shift
            ;;
            --update)
                update=true;
                shift
            ;;
            --)
                shift;
                break
            ;;
            -* | --*)
                echo "Unknown option $1 supplied to patchShebangs" 1>&2;
                return 1
            ;;
            *)
                break
            ;;
        esac;
    done;
    echo "patching script interpreter paths in $@";
    local f;
    local oldPath;
    local newPath;
    local arg0;
    local args;
    local oldInterpreterLine;
    local newInterpreterLine;
    if [[ $# -eq 0 ]]; then
        echo "No arguments supplied to patchShebangs" 1>&2;
        return 0;
    fi;
    local f;
    while IFS= read -r -d '' f; do
        isScript "$f" || continue;
        read -r oldInterpreterLine < "$f" || [ "$oldInterpreterLine" ];
        read -r oldPath arg0 args <<< "${oldInterpreterLine:2}";
        if [[ -z "${pathName:-}" ]]; then
            if [[ -n $strictDeps && $f == "$NIX_STORE"* ]]; then
                pathName=HOST_PATH;
            else
                pathName=PATH;
            fi;
        fi;
        if [[ "$oldPath" == *"/bin/env" ]]; then
            if [[ $arg0 == "-S" ]]; then
                arg0=${args%% *};
                [[ "$args" == *" "* ]] && args=${args#* } || args=;
                newPath="$(PATH="${!pathName}" type -P "env" || true)";
                args="-S $(PATH="${!pathName}" type -P "$arg0" || true) $args";
            else
                if [[ $arg0 == "-"* || $arg0 == *"="* ]]; then
                    echo "$f: unsupported interpreter directive \"$oldInterpreterLine\" (set dontPatchShebangs=1 and handle shebang patching yourself)" 1>&2;
                    exit 1;
                else
                    newPath="$(PATH="${!pathName}" type -P "$arg0" || true)";
                fi;
            fi;
        else
            if [[ -z $oldPath ]]; then
                oldPath="/bin/sh";
            fi;
            newPath="$(PATH="${!pathName}" type -P "$(basename "$oldPath")" || true)";
            args="$arg0 $args";
        fi;
        newInterpreterLine="$newPath $args";
        newInterpreterLine=${newInterpreterLine%${newInterpreterLine##*[![:space:]]}};
        if [[ -n "$oldPath" && ( "$update" == true || "${oldPath:0:${#NIX_STORE}}" != "$NIX_STORE" ) ]]; then
            if [[ -n "$newPath" && "$newPath" != "$oldPath" ]]; then
                echo "$f: interpreter directive changed from \"$oldInterpreterLine\" to \"$newInterpreterLine\"";
                escapedInterpreterLine=${newInterpreterLine//\\/\\\\};
                timestamp=$(stat --printf "%y" "$f");
                tmpFile=$(mktemp -t patchShebangs.XXXXXXXXXX);
                sed -e "1 s|.*|#\!$escapedInterpreterLine|" "$f" > "$tmpFile";
                local restoreReadOnly;
                if [[ ! -w "$f" ]]; then
                    chmod +w "$f";
                    restoreReadOnly=true;
                fi;
                cat "$tmpFile" > "$f";
                rm "$tmpFile";
                if [[ -n "${restoreReadOnly:-}" ]]; then
                    chmod -w "$f";
                fi;
                touch --date "$timestamp" "$f";
            fi;
        fi;
    done < <(find "$@" -type f -perm -0100 -print0)
}
stripHash ()
{
 
    local strippedName casematchOpt=0;
    strippedName="$(basename -- "$1")";
    shopt -q nocasematch && casematchOpt=1;
    shopt -u nocasematch;
    if [[ "$strippedName" =~ ^[a-z0-9]{32}- ]]; then
        echo "${strippedName:33}";
    else
        echo "$strippedName";
    fi;
    if (( casematchOpt )); then
        shopt -s nocasematch;
    fi
}
updateSourceDateEpoch ()
{
 
    local path="$1";
    [[ $path == -* ]] && path="./$path";
    local -a res=($(find "$path" -type f -not -newer "$NIX_BUILD_TOP/.." -printf '%T@ "%p"\0' | sort -n --zero-terminated | tail -n1 --zero-terminated | head -c -1));
    local time="${res[0]//\.[0-9]*/}";
    local newestFile="${res[1]}";
    if [ "${time:-0}" -gt "$SOURCE_DATE_EPOCH" ]; then
        echo "setting SOURCE_DATE_EPOCH to timestamp $time of file $newestFile";
        export SOURCE_DATE_EPOCH="$time";
        local now="$(date +%s)";
        if [ "$time" -gt $((now - 60)) ]; then
            echo "warning: file $newestFile may be generated; SOURCE_DATE_EPOCH may be non-deterministic";
        fi;
    fi
}
toPythonPath ()
{
 
    local paths="$1";
    local result=;
    for i in $paths;
    do
        p="$i/lib/python3.13/site-packages";
        result="${result}${result:+:}$p";
    done;
    echo $result
}
substitute ()
{
 
    local input="$1";
    local output="$2";
    shift 2;
    if [ ! -f "$input" ]; then
        echo "substitute(): ERROR: file '$input' does not exist" 1>&2;
        return 1;
    fi;
    local content;
    consumeEntire content < "$input";
    if [ -e "$output" ]; then
        chmod +w "$output";
    fi;
    substituteStream content "file '$input'" "$@" > "$output"
}
updateAutotoolsGnuConfigScriptsPhase ()
{
 
    if [ -n "${dontUpdateAutotoolsGnuConfigScripts-}" ]; then
        return;
    fi;
    for script in config.sub config.guess;
    do
        for f in $(find . -type f -name "$script");
        do
            echo "Updating Autotools / GNU config script to a newer upstream version: $f";
            cp -f "/nix/store/kppfbp4x7mhfz1q5zswavxxxq71v2f7c-gnu-config-2024-01-01/$script" "$f";
        done;
    done
}
nixNoticeLog ()
{
 
    _nixLogWithLevel 2 "$*"
}
_multioutConfig ()
{
 
    if [ "$(getAllOutputNames)" = "out" ] || [ -z "${setOutputFlags-1}" ]; then
        return;
    fi;
    if [ -z "${shareDocName:-}" ]; then
        local confScript="${configureScript:-}";
        if [ -z "$confScript" ] && [ -x ./configure ]; then
            confScript=./configure;
        fi;
        if [ -f "$confScript" ]; then
            local shareDocName="$(sed -n "s/^PACKAGE_TARNAME='\(.*\)'$/\1/p" < "$confScript")";
        fi;
        if [ -z "$shareDocName" ] || echo "$shareDocName" | grep -q '[^a-zA-Z0-9_-]'; then
            shareDocName="$(echo "$name" | sed 's/-[^a-zA-Z].*//')";
        fi;
    fi;
    prependToVar configureFlags --bindir="${!outputBin}"/bin --sbindir="${!outputBin}"/sbin --includedir="${!outputInclude}"/include --mandir="${!outputMan}"/share/man --infodir="${!outputInfo}"/share/info --docdir="${!outputDoc}"/share/doc/"${shareDocName}" --libdir="${!outputLib}"/lib --libexecdir="${!outputLib}"/libexec --localedir="${!outputLib}"/share/locale;
    prependToVar installFlags pkgconfigdir="${!outputDev}"/lib/pkgconfig m4datadir="${!outputDev}"/share/aclocal aclocaldir="${!outputDev}"/share/aclocal
}
nixErrorLog ()
{
 
    _nixLogWithLevel 0 "$*"
}
getTargetRoleEnvHook ()
{
 
    getRole "$depTargetOffset"
}
nixTalkativeLog ()
{
 
    _nixLogWithLevel 4 "$*"
}
pkgConfigWrapper_addPkgConfigPath ()
{
 
    local role_post;
    getHostRoleEnvHook;
    addToSearchPath "PKG_CONFIG_PATH${role_post}" "$1/lib/pkgconfig";
    addToSearchPath "PKG_CONFIG_PATH${role_post}" "$1/share/pkgconfig"
}
noBrokenSymlinksInAllOutputs ()
{
 
    if [[ -z ${dontCheckForBrokenSymlinks-} ]]; then
        for output in $(getAllOutputNames);
        do
            noBrokenSymlinks "${!output}";
        done;
    fi
}
patchShebangsAuto ()
{
 
    if [[ -z "${dontPatchShebangs-}" && -e "$prefix" ]]; then
        if [[ "$output" != out && "$output" = "$outputDev" ]]; then
            patchShebangs --build "$prefix";
        else
            patchShebangs --host "$prefix";
        fi;
    fi
}
checkPhase ()
{
 
    runHook preCheck;
    if [[ -z "${foundMakefile:-}" ]]; then
        echo "no Makefile or custom checkPhase, doing nothing";
        runHook postCheck;
        return;
    fi;
    if [[ -z "${checkTarget:-}" ]]; then
        if make -n ${makefile:+-f $makefile} check > /dev/null 2>&1; then
            checkTarget="check";
        else
            if make -n ${makefile:+-f $makefile} test > /dev/null 2>&1; then
                checkTarget="test";
            fi;
        fi;
    fi;
    if [[ -z "${checkTarget:-}" ]]; then
        echo "no check/test target in ${makefile:-Makefile}, doing nothing";
    else
        local flagsArray=(${enableParallelChecking:+-j${NIX_BUILD_CORES}} SHELL="$SHELL");
        concatTo flagsArray makeFlags makeFlagsArray checkFlags=VERBOSE=y checkFlagsArray checkTarget;
        echoCmd 'check flags' "${flagsArray[@]}";
        make ${makefile:+-f $makefile} "${flagsArray[@]}";
        unset flagsArray;
    fi;
    runHook postCheck
}
fixLibtool ()
{
 
    local search_path;
    for flag in $NIX_LDFLAGS;
    do
        case $flag in 
            -L*)
                search_path+=" ${flag#-L}"
            ;;
        esac;
    done;
    sed -i "$1" -e "s^eval \(sys_lib_search_path=\).*^\1'${search_path:-}'^" -e 's^eval sys_lib_.+search_path=.*^^'
}
getHostRoleEnvHook ()
{
 
    getRole "$depHostOffset"
}
installPhase ()
{
 
    runHook preInstall;
    if [[ -z "${makeFlags-}" && -z "${makefile:-}" && ! ( -e Makefile || -e makefile || -e GNUmakefile ) ]]; then
        echo "no Makefile or custom installPhase, doing nothing";
        runHook postInstall;
        return;
    else
        foundMakefile=1;
    fi;
    if [ -n "$prefix" ]; then
        mkdir -p "$prefix";
    fi;
    local flagsArray=(${enableParallelInstalling:+-j${NIX_BUILD_CORES}} SHELL="$SHELL");
    concatTo flagsArray makeFlags makeFlagsArray installFlags installFlagsArray installTargets=install;
    echoCmd 'install flags' "${flagsArray[@]}";
    make ${makefile:+-f $makefile} "${flagsArray[@]}";
    unset flagsArray;
    runHook postInstall
}
mapOffset ()
{
 
    local -r inputOffset="$1";
    local -n outputOffset="$2";
    if (( inputOffset <= 0 )); then
        outputOffset=$((inputOffset + hostOffset));
    else
        outputOffset=$((inputOffset - 1 + targetOffset));
    fi
}
genericBuild ()
{
 
    export GZIP_NO_TIMESTAMPS=1;
    if [ -f "${buildCommandPath:-}" ]; then
        source "$buildCommandPath";
        return;
    fi;
    if [ -n "${buildCommand:-}" ]; then
        eval "$buildCommand";
        return;
    fi;
    definePhases;
    for curPhase in ${phases[*]};
    do
        runPhase "$curPhase";
    done
}
_callImplicitHook ()
{
 
    local def="$1";
    local hookName="$2";
    if declare -F "$hookName" > /dev/null; then
        nixTalkativeLog "calling implicit '$hookName' function hook";
        "$hookName";
    else
        if type -p "$hookName" > /dev/null; then
            nixTalkativeLog "sourcing implicit '$hookName' script hook";
            source "$hookName";
        else
            if [ -n "${!hookName:-}" ]; then
                nixTalkativeLog "evaling implicit '$hookName' string hook";
                eval "${!hookName}";
            else
                return "$def";
            fi;
        fi;
    fi
}
exitHandler ()
{
 
    exitCode="$?";
    set +e;
    if [ -n "${showBuildStats:-}" ]; then
        read -r -d '' -a buildTimes < <(times);
        echo "build times:";
        echo "user time for the shell             ${buildTimes[0]}";
        echo "system time for the shell           ${buildTimes[1]}";
        echo "user time for all child processes   ${buildTimes[2]}";
        echo "system time for all child processes ${buildTimes[3]}";
    fi;
    if (( "$exitCode" != 0 )); then
        runHook failureHook;
        if [ -n "${succeedOnFailure:-}" ]; then
            echo "build failed with exit code $exitCode (ignored)";
            mkdir -p "$out/nix-support";
            printf "%s" "$exitCode" > "$out/nix-support/failed";
            exit 0;
        fi;
    else
        runHook exitHook;
    fi;
    return "$exitCode"
}
_makeSymlinksRelative ()
{
 
    local prefixes;
    prefixes=();
    for output in $(getAllOutputNames);
    do
        [ ! -e "${!output}" ] && continue;
        prefixes+=("${!output}");
    done;
    find "${prefixes[@]}" -type l -printf '%H\0%p\0' | xargs -0 -n2 -r -P "$NIX_BUILD_CORES" sh -c '
      output="$1"
      link="$2"

      linkTarget=$(readlink "$link")

      # only touch links that point inside the same output tree
      [[ $linkTarget == "$output"/* ]] || exit 0

      if [ ! -e "$linkTarget" ]; then
        echo "the symlink $link is broken, it points to $linkTarget (which is missing)"
      fi

      echo "making symlink relative: $link"
      ln -snrf "$linkTarget" "$link"
    ' _
}
appendToVar ()
{
 
    local -n nameref="$1";
    local useArray type;
    if [ -n "$__structuredAttrs" ]; then
        useArray=true;
    else
        useArray=false;
    fi;
    if type=$(declare -p "$1" 2> /dev/null); then
        case "${type#* }" in 
            -A*)
                echo "appendToVar(): ERROR: trying to use appendToVar on an associative array, use variable+=([\"X\"]=\"Y\") instead." 1>&2;
                return 1
            ;;
            -a*)
                useArray=true
            ;;
            *)
                useArray=false
            ;;
        esac;
    fi;
    shift;
    if $useArray; then
        nameref=(${nameref+"${nameref[@]}"} "$@");
    else
        nameref="${nameref-} $*";
    fi
}
nixInfoLog ()
{
 
    _nixLogWithLevel 3 "$*"
}
getTargetRole ()
{
 
    getRole "$targetOffset"
}
addPythonPath ()
{
 
    addToSearchPathWithCustomDelimiter : PYTHONPATH $1/lib/python3.13/site-packages
}
_assignFirst ()
{
 
    local varName="$1";
    local _var;
    local REMOVE=REMOVE;
    shift;
    for _var in "$@";
    do
        if [ -n "${!_var-}" ]; then
            eval "${varName}"="${_var}";
            return;
        fi;
    done;
    echo;
    echo "error: _assignFirst: could not find a non-empty variable whose name to assign to ${varName}.";
    echo "       The following variables were all unset or empty:";
    echo "           $*";
    if [ -z "${out:-}" ]; then
        echo '       If you do not want an "out" output in your derivation, make sure to define';
        echo '       the other specific required outputs. This can be achieved by picking one';
        echo "       of the above as an output.";
        echo '       You do not have to remove "out" if you want to have a different default';
        echo '       output, because the first output is taken as a default.';
        echo;
    fi;
    return 1
}
patchPhase ()
{
 
    runHook prePatch;
    local -a patchesArray;
    concatTo patchesArray patches;
    local -a flagsArray;
    concatTo flagsArray patchFlags=-p1;
    for i in "${patchesArray[@]}";
    do
        echo "applying patch $i";
        local uncompress=cat;
        case "$i" in 
            *.gz)
                uncompress="gzip -d"
            ;;
            *.bz2)
                uncompress="bzip2 -d"
            ;;
            *.xz)
                uncompress="xz -d"
            ;;
            *.lzma)
                uncompress="lzma -d"
            ;;
        esac;
        $uncompress < "$i" 2>&1 | patch "${flagsArray[@]}";
    done;
    runHook postPatch
}
_pruneLibtoolFiles ()
{
 
    if [ "${dontPruneLibtoolFiles-}" ] || [ ! -e "$prefix" ]; then
        return;
    fi;
    find "$prefix" -type f -name '*.la' -exec grep -q '^# Generated by .*libtool' {} \; -exec grep -q "^old_library=''" {} \; -exec sed -i {} -e "/^dependency_libs='[^']/ c dependency_libs='' #pruned" \;
}
concatStringsSep ()
{
 
    local sep="$1";
    local name="$2";
    local type oldifs;
    if type=$(declare -p "$name" 2> /dev/null); then
        local -n nameref="$name";
        case "${type#* }" in 
            -A*)
                echo "concatStringsSep(): ERROR: trying to use concatStringsSep on an associative array." 1>&2;
                return 1
            ;;
            -a*)
                local IFS="$(printf '\036')"
            ;;
            *)
                local IFS=" "
            ;;
        esac;
        local ifs_separated="${nameref[*]}";
        echo -n "${ifs_separated//"$IFS"/"$sep"}";
    fi
}
moveToOutput ()
{
 
    local patt="$1";
    local dstOut="$2";
    local output;
    for output in $(getAllOutputNames);
    do
        if [ "${!output}" = "$dstOut" ]; then
            continue;
        fi;
        local srcPath;
        for srcPath in "${!output}"/$patt;
        do
            if [ ! -e "$srcPath" ] && [ ! -L "$srcPath" ]; then
                continue;
            fi;
            if [ "$dstOut" = REMOVE ]; then
                echo "Removing $srcPath";
                rm -r "$srcPath";
            else
                local dstPath="$dstOut${srcPath#${!output}}";
                echo "Moving $srcPath to $dstPath";
                if [ -d "$dstPath" ] && [ -d "$srcPath" ]; then
                    rmdir "$srcPath" --ignore-fail-on-non-empty;
                    if [ -d "$srcPath" ]; then
                        mv -t "$dstPath" "$srcPath"/*;
                        rmdir "$srcPath";
                    fi;
                else
                    mkdir -p "$(readlink -m "$dstPath/..")";
                    mv "$srcPath" "$dstPath";
                fi;
            fi;
            local srcParent="$(readlink -m "$srcPath/..")";
            if [ -n "$(find "$srcParent" -maxdepth 0 -type d -empty 2> /dev/null)" ]; then
                echo "Removing empty $srcParent/ and (possibly) its parents";
                rmdir -p --ignore-fail-on-non-empty "$srcParent" 2> /dev/null || true;
            fi;
        done;
    done
}
noBrokenSymlinks ()
{
 
    local -r output="${1:?}";
    local path;
    local pathParent;
    local symlinkTarget;
    local -i numDanglingSymlinks=0;
    local -i numReflexiveSymlinks=0;
    local -i numUnreadableSymlinks=0;
    if [[ ! -e $output ]]; then
        nixWarnLog "skipping non-existent output $output";
        return 0;
    fi;
    nixInfoLog "running on $output";
    while IFS= read -r -d '' path; do
        pathParent="$(dirname "$path")";
        if ! symlinkTarget="$(readlink "$path")"; then
            nixErrorLog "the symlink $path is unreadable";
            numUnreadableSymlinks+=1;
            continue;
        fi;
        if [[ $symlinkTarget == /* ]]; then
            nixInfoLog "symlink $path points to absolute target $symlinkTarget";
        else
            nixInfoLog "symlink $path points to relative target $symlinkTarget";
            symlinkTarget="$(realpath --no-symlinks --canonicalize-missing "$pathParent/$symlinkTarget")";
        fi;
        if [[ $symlinkTarget = "$TMPDIR"/* ]]; then
            nixErrorLog "the symlink $path points to $TMPDIR directory: $symlinkTarget";
            numDanglingSymlinks+=1;
            continue;
        fi;
        if [[ $symlinkTarget != "$NIX_STORE"/* ]]; then
            nixInfoLog "symlink $path points outside the Nix store; ignoring";
            continue;
        fi;
        if [[ $path == "$symlinkTarget" ]]; then
            nixErrorLog "the symlink $path is reflexive";
            numReflexiveSymlinks+=1;
        else
            if [[ ! -e $symlinkTarget ]]; then
                nixErrorLog "the symlink $path points to a missing target: $symlinkTarget";
                numDanglingSymlinks+=1;
            else
                nixDebugLog "the symlink $path is irreflexive and points to a target which exists";
            fi;
        fi;
    done < <(find "$output" -type l -print0);
    if ((numDanglingSymlinks > 0 || numReflexiveSymlinks > 0 || numUnreadableSymlinks > 0)); then
        nixErrorLog "found $numDanglingSymlinks dangling symlinks, $numReflexiveSymlinks reflexive symlinks and $numUnreadableSymlinks unreadable symlinks";
        exit 1;
    fi;
    return 0
}
isScript ()
{
 
    local fn="$1";
    local fd;
    local magic;
    exec {fd}< "$fn";
    LANG=C read -r -n 2 -u "$fd" magic;
    exec {fd}>&-;
    if [[ "$magic" =~ \#! ]]; then
        return 0;
    else
        return 1;
    fi
}
_allFlags ()
{
 
    export system pname name version;
    while IFS='' read -r varName; do
        nixTalkativeLog "@${varName}@ -> ${!varName}";
        args+=("--subst-var" "$varName");
    done < <(awk 'BEGIN { for (v in ENVIRON) if (v ~ /^[a-z][a-zA-Z0-9_]*$/) print v }')
}
patchELF ()
{
 
    local dir="$1";
    [ -e "$dir" ] || return 0;
    echo "shrinking RPATHs of ELF executables and libraries in $dir";
    local i;
    while IFS= read -r -d '' i; do
        if [[ "$i" =~ .build-id ]]; then
            continue;
        fi;
        if ! isELF "$i"; then
            continue;
        fi;
        echo "shrinking $i";
        patchelf --shrink-rpath "$i" || true;
    done < <(find "$dir" -type f -print0)
}
isELF ()
{
 
    local fn="$1";
    local fd;
    local magic;
    exec {fd}< "$fn";
    LANG=C read -r -n 4 -u "$fd" magic;
    exec {fd}>&-;
    if [ "$magic" = 'ELF' ]; then
        return 0;
    else
        return 1;
    fi
}
consumeEntire ()
{
 
    if IFS='' read -r -d '' "$1"; then
        echo "consumeEntire(): ERROR: Input null bytes, won't process" 1>&2;
        return 1;
    fi
}
getAllOutputNames ()
{
 
    if [ -n "$__structuredAttrs" ]; then
        echo "${!outputs[*]}";
    else
        echo "$outputs";
    fi
}
_overrideFirst ()
{
 
    if [ -z "${!1-}" ]; then
        _assignFirst "$@";
    fi
}
printPhases ()
{
 
    definePhases;
    local phase;
    for phase in ${phases[*]};
    do
        printf '%s\n' "$phase";
    done
}
getHostRole ()
{
 
    getRole "$hostOffset"
}
nixVomitLog ()
{
 
    _nixLogWithLevel 7 "$*"
}
substituteStream ()
{
 
    local var=$1;
    local description=$2;
    shift 2;
    while (( "$#" )); do
        local replace_mode="$1";
        case "$1" in 
            --replace)
                if ! "$_substituteStream_has_warned_replace_deprecation"; then
                    echo "substituteStream() in derivation $name: WARNING: '--replace' is deprecated, use --replace-{fail,warn,quiet}. ($description)" 1>&2;
                    _substituteStream_has_warned_replace_deprecation=true;
                fi;
                replace_mode='--replace-warn'
            ;&
            --replace-quiet | --replace-warn | --replace-fail)
                pattern="$2";
                replacement="$3";
                shift 3;
                if ! [[ "${!var}" == *"$pattern"* ]]; then
                    if [ "$replace_mode" == --replace-warn ]; then
                        printf "substituteStream() in derivation $name: WARNING: pattern %q doesn't match anything in %s\n" "$pattern" "$description" 1>&2;
                    else
                        if [ "$replace_mode" == --replace-fail ]; then
                            printf "substituteStream() in derivation $name: ERROR: pattern %q doesn't match anything in %s\n" "$pattern" "$description" 1>&2;
                            return 1;
                        fi;
                    fi;
                fi;
                eval "$var"'=${'"$var"'//"$pattern"/"$replacement"}'
            ;;
            --subst-var)
                local varName="$2";
                shift 2;
                if ! [[ "$varName" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
                    echo "substituteStream() in derivation $name: ERROR: substitution variables must be valid Bash names, \"$varName\" isn't." 1>&2;
                    return 1;
                fi;
                if [ -z ${!varName+x} ]; then
                    echo "substituteStream() in derivation $name: ERROR: variable \$$varName is unset" 1>&2;
                    return 1;
                fi;
                pattern="@$varName@";
                replacement="${!varName}";
                eval "$var"'=${'"$var"'//"$pattern"/"$replacement"}'
            ;;
            --subst-var-by)
                pattern="@$2@";
                replacement="$3";
                eval "$var"'=${'"$var"'//"$pattern"/"$replacement"}';
                shift 3
            ;;
            *)
                echo "substituteStream() in derivation $name: ERROR: Invalid command line argument: $1" 1>&2;
                return 1
            ;;
        esac;
    done;
    printf "%s" "${!var}"
}
_updateSourceDateEpochFromSourceRoot ()
{
 
    if [ -n "$sourceRoot" ]; then
        updateSourceDateEpoch "$sourceRoot";
    fi
}
nixDebugLog ()
{
 
    _nixLogWithLevel 6 "$*"
}
bintoolsWrapper_addLDVars ()
{
 
    local role_post;
    getHostRoleEnvHook;
    if [[ -d "$1/lib64" && ! -L "$1/lib64" ]]; then
        export NIX_LDFLAGS${role_post}+=" -L$1/lib64";
    fi;
    if [[ -d "$1/lib" ]]; then
        local -a glob=($1/lib/lib*);
        if [ "${#glob[*]}" -gt 0 ]; then
            export NIX_LDFLAGS${role_post}+=" -L$1/lib";
        fi;
    fi
}
nixLog ()
{
 
    [[ -z ${NIX_LOG_FD-} ]] && return 0;
    local callerName="${FUNCNAME[1]}";
    if [[ $callerName == "_callImplicitHook" ]]; then
        callerName="${hookName:?}";
    fi;
    printf "%s: %s\n" "$callerName" "$*" >&"$NIX_LOG_FD"
}
activatePackage ()
{
 
    local pkg="$1";
    local -r hostOffset="$2";
    local -r targetOffset="$3";
    (( hostOffset <= targetOffset )) || exit 1;
    if [ -f "$pkg" ]; then
        nixTalkativeLog "sourcing setup hook '$pkg'";
        source "$pkg";
    fi;
    if [[ -z "${strictDeps-}" || "$hostOffset" -le -1 ]]; then
        addToSearchPath _PATH "$pkg/bin";
    fi;
    if (( hostOffset <= -1 )); then
        addToSearchPath _XDG_DATA_DIRS "$pkg/share";
    fi;
    if [[ "$hostOffset" -eq 0 && -d "$pkg/bin" ]]; then
        addToSearchPath _HOST_PATH "$pkg/bin";
    fi;
    if [[ -f "$pkg/nix-support/setup-hook" ]]; then
        nixTalkativeLog "sourcing setup hook '$pkg/nix-support/setup-hook'";
        source "$pkg/nix-support/setup-hook";
    fi
}
getTargetRoleWrapper ()
{
 
    case $targetOffset in 
        -1)
            export NIX_BINTOOLS_WRAPPER_TARGET_BUILD_x86_64_unknown_linux_gnu=1
        ;;
        0)
            export NIX_BINTOOLS_WRAPPER_TARGET_HOST_x86_64_unknown_linux_gnu=1
        ;;
        1)
            export NIX_BINTOOLS_WRAPPER_TARGET_TARGET_x86_64_unknown_linux_gnu=1
        ;;
        *)
            echo "binutils-wrapper-2.46: used as improper sort of dependency" 1>&2;
            return 1
        ;;
    esac
}
echoCmd ()
{
 
    printf "%s:" "$1";
    shift;
    printf ' %q' "$@";
    echo
}
showPhaseHeader ()
{
 
    local phase="$1";
    echo "Running phase: $phase";
    if [[ -z ${NIX_LOG_FD-} ]]; then
        return;
    fi;
    printf "@nix { \"action\": \"setPhase\", \"phase\": \"%s\" }\n" "$phase" >&"$NIX_LOG_FD"
}
substituteAllInPlace ()
{
 
    local fileName="$1";
    shift;
    substituteAll "$fileName" "$fileName" "$@"
}
unpackFile ()
{
 
    curSrc="$1";
    echo "unpacking source archive $curSrc";
    if ! runOneHook unpackCmd "$curSrc"; then
        echo "do not know how to unpack source archive $curSrc";
        exit 1;
    fi
}
_nixLogWithLevel ()
{
 
    [[ -z ${NIX_LOG_FD-} || ${NIX_DEBUG:-0} -lt ${1:?} ]] && return 0;
    local logLevel;
    case "${1:?}" in 
        0)
            logLevel=ERROR
        ;;
        1)
            logLevel=WARN
        ;;
        2)
            logLevel=NOTICE
        ;;
        3)
            logLevel=INFO
        ;;
        4)
            logLevel=TALKATIVE
        ;;
        5)
            logLevel=CHATTY
        ;;
        6)
            logLevel=DEBUG
        ;;
        7)
            logLevel=VOMIT
        ;;
        *)
            echo "_nixLogWithLevel: called with invalid log level: ${1:?}" >&"$NIX_LOG_FD";
            return 1
        ;;
    esac;
    local callerName="${FUNCNAME[2]}";
    if [[ $callerName == "_callImplicitHook" ]]; then
        callerName="${hookName:?}";
    fi;
    printf "%s: %s: %s\n" "$logLevel" "$callerName" "${2:?}" >&"$NIX_LOG_FD"
}
showPhaseFooter ()
{
 
    local phase="$1";
    local startTime="$2";
    local endTime="$3";
    local delta=$(( endTime - startTime ));
    (( delta < 30 )) && return;
    local H=$((delta/3600));
    local M=$((delta%3600/60));
    local S=$((delta%60));
    echo -n "$phase completed in ";
    (( H > 0 )) && echo -n "$H hours ";
    (( M > 0 )) && echo -n "$M minutes ";
    echo "$S seconds"
}
_addRpathPrefix ()
{
 
    if [ "${NIX_NO_SELF_RPATH:-0}" != 1 ]; then
        export NIX_LDFLAGS="-rpath $1/lib ${NIX_LDFLAGS-}";
    fi
}
unpackPhase ()
{
 
    runHook preUnpack;
    if [ -z "${srcs:-}" ]; then
        if [ -z "${src:-}" ]; then
            echo 'variable $src or $srcs should point to the source';
            exit 1;
        fi;
        srcs="$src";
    fi;
    local -a srcsArray;
    concatTo srcsArray srcs;
    local dirsBefore="";
    for i in *;
    do
        if [ -d "$i" ]; then
            dirsBefore="$dirsBefore $i ";
        fi;
    done;
    for i in "${srcsArray[@]}";
    do
        unpackFile "$i";
    done;
    : "${sourceRoot=}";
    if [ -n "${setSourceRoot:-}" ]; then
        runOneHook setSourceRoot;
    else
        if [ -z "$sourceRoot" ]; then
            for i in *;
            do
                if [ -d "$i" ]; then
                    case $dirsBefore in 
                        *\ $i\ *)

                        ;;
                        *)
                            if [ -n "$sourceRoot" ]; then
                                echo "unpacker produced multiple directories";
                                exit 1;
                            fi;
                            sourceRoot="$i"
                        ;;
                    esac;
                fi;
            done;
        fi;
    fi;
    if [ -z "$sourceRoot" ]; then
        echo "unpacker appears to have produced no directories";
        exit 1;
    fi;
    echo "source root is $sourceRoot";
    if [ "${dontMakeSourcesWritable:-0}" != 1 ]; then
        chmod -R u+w -- "$sourceRoot";
    fi;
    runHook postUnpack
}
sysconfigdataHook ()
{
 
    if [ "$1" = '/nix/store/0r6k8xa2kgqyp3r4v2w7yrb80ma2iawm-python3-3.13.12' ]; then
        export _PYTHON_HOST_PLATFORM='linux-x86_64';
        export _PYTHON_SYSCONFIGDATA_NAME='_sysconfigdata__linux_x86_64-linux-gnu';
    fi
}
_moveSbin ()
{
 
    if [ "${dontMoveSbin-}" = 1 ]; then
        return;
    fi;
    if [ ! -e "$prefix/sbin" -o -L "$prefix/sbin" ]; then
        return;
    fi;
    echo "moving $prefix/sbin/* to $prefix/bin";
    mkdir -p $prefix/bin;
    shopt -s dotglob;
    for i in $prefix/sbin/*;
    do
        mv "$i" $prefix/bin;
    done;
    shopt -u dotglob;
    rmdir $prefix/sbin;
    ln -s bin $prefix/sbin
}
addEnvHooks ()
{
 
    local depHostOffset="$1";
    shift;
    local pkgHookVarsSlice="${pkgHookVarVars[$depHostOffset + 1]}[@]";
    local pkgHookVar;
    for pkgHookVar in "${!pkgHookVarsSlice}";
    do
        eval "${pkgHookVar}s"'+=("$@")';
    done
}
addToSearchPath ()
{
 
    addToSearchPathWithCustomDelimiter ":" "$@"
}
dumpVars ()
{
 
    if [[ "${noDumpEnvVars:-0}" != 1 && -d "$NIX_BUILD_TOP" ]]; then
        local old_umask;
        old_umask=$(umask);
        umask 0077;
        export 2> /dev/null > "$NIX_BUILD_TOP/env-vars";
        umask "$old_umask";
    fi
}
isMachO ()
{
 
    local fn="$1";
    local fd;
    local magic;
    exec {fd}< "$fn";
    LANG=C read -r -n 4 -u "$fd" magic;
    exec {fd}>&-;
    if [[ "$magic" = $(echo -ne "\xfe\xed\xfa\xcf") || "$magic" = $(echo -ne "\xcf\xfa\xed\xfe") ]]; then
        return 0;
    else
        if [[ "$magic" = $(echo -ne "\xfe\xed\xfa\xce") || "$magic" = $(echo -ne "\xce\xfa\xed\xfe") ]]; then
            return 0;
        else
            if [[ "$magic" = $(echo -ne "\xca\xfe\xba\xbe") || "$magic" = $(echo -ne "\xbe\xba\xfe\xca") ]]; then
                return 0;
            else
                return 1;
            fi;
        fi;
    fi
}
nixChattyLog ()
{
 
    _nixLogWithLevel 5 "$*"
}
_multioutDocs ()
{
 
    local REMOVE=REMOVE;
    moveToOutput share/info "${!outputInfo}";
    moveToOutput share/doc "${!outputDoc}";
    moveToOutput share/gtk-doc "${!outputDevdoc}";
    moveToOutput share/devhelp/books "${!outputDevdoc}";
    moveToOutput share/man "${!outputMan}";
    moveToOutput share/man/man3 "${!outputDevman}"
}
buildPhase ()
{
 
    runHook preBuild;
    if [[ -z "${makeFlags-}" && -z "${makefile:-}" && ! ( -e Makefile || -e makefile || -e GNUmakefile ) ]]; then
        echo "no Makefile or custom buildPhase, doing nothing";
    else
        foundMakefile=1;
        local flagsArray=(${enableParallelBuilding:+-j${NIX_BUILD_CORES}} SHELL="$SHELL");
        concatTo flagsArray makeFlags makeFlagsArray buildFlags buildFlagsArray;
        echoCmd 'build flags' "${flagsArray[@]}";
        make ${makefile:+-f $makefile} "${flagsArray[@]}";
        unset flagsArray;
    fi;
    runHook postBuild
}
getRole ()
{
 
    case $1 in 
        -1)
            role_post='_FOR_BUILD'
        ;;
        0)
            role_post=''
        ;;
        1)
            role_post='_FOR_TARGET'
        ;;
        *)
            echo "binutils-wrapper-2.46: used as improper sort of dependency" 1>&2;
            return 1
        ;;
    esac
}
distPhase ()
{
 
    runHook preDist;
    local flagsArray=();
    concatTo flagsArray distFlags distFlagsArray distTarget=dist;
    echo 'dist flags: %q' "${flagsArray[@]}";
    make ${makefile:+-f $makefile} "${flagsArray[@]}";
    if [ "${dontCopyDist:-0}" != 1 ]; then
        mkdir -p "$out/tarballs";
        cp -pvd ${tarballs[*]:-*.tar.gz} "$out/tarballs";
    fi;
    runHook postDist
}
findInputs ()
{
 
    local -r pkg="$1";
    local -r hostOffset="$2";
    local -r targetOffset="$3";
    (( hostOffset <= targetOffset )) || exit 1;
    local varVar="${pkgAccumVarVars[hostOffset + 1]}";
    local varRef="$varVar[$((targetOffset - hostOffset))]";
    local var="${!varRef}";
    unset -v varVar varRef;
    local varSlice="$var[*]";
    case " ${!varSlice-} " in 
        *" $pkg "*)
            return 0
        ;;
    esac;
    unset -v varSlice;
    eval "$var"'+=("$pkg")';
    if ! [ -e "$pkg" ]; then
        echo "build input $pkg does not exist" 1>&2;
        exit 1;
    fi;
    function mapOffset () 
    { 
        local -r inputOffset="$1";
        local -n outputOffset="$2";
        if (( inputOffset <= 0 )); then
            outputOffset=$((inputOffset + hostOffset));
        else
            outputOffset=$((inputOffset - 1 + targetOffset));
        fi
    };
    local relHostOffset;
    for relHostOffset in "${allPlatOffsets[@]}";
    do
        local files="${propagatedDepFilesVars[relHostOffset + 1]}";
        local hostOffsetNext;
        mapOffset "$relHostOffset" hostOffsetNext;
        (( -1 <= hostOffsetNext && hostOffsetNext <= 1 )) || continue;
        local relTargetOffset;
        for relTargetOffset in "${allPlatOffsets[@]}";
        do
            (( "$relHostOffset" <= "$relTargetOffset" )) || continue;
            local fileRef="${files}[$relTargetOffset - $relHostOffset]";
            local file="${!fileRef}";
            unset -v fileRef;
            local targetOffsetNext;
            mapOffset "$relTargetOffset" targetOffsetNext;
            (( -1 <= hostOffsetNext && hostOffsetNext <= 1 )) || continue;
            [[ -f "$pkg/nix-support/$file" ]] || continue;
            local pkgNext;
            read -r -d '' pkgNext < "$pkg/nix-support/$file" || true;
            for pkgNext in $pkgNext;
            do
                findInputs "$pkgNext" "$hostOffsetNext" "$targetOffsetNext";
            done;
        done;
    done
}
_logHook ()
{
 
    if [[ -z ${NIX_LOG_FD-} ]]; then
        return;
    fi;
    local hookKind="$1";
    local hookExpr="$2";
    shift 2;
    if declare -F "$hookExpr" > /dev/null 2>&1; then
        nixTalkativeLog "calling '$hookKind' function hook '$hookExpr'" "$@";
    else
        if type -p "$hookExpr" > /dev/null; then
            nixTalkativeLog "sourcing '$hookKind' script hook '$hookExpr'";
        else
            if [[ "$hookExpr" != "_callImplicitHook"* ]]; then
                local exprToOutput;
                if [[ ${NIX_DEBUG:-0} -ge 5 ]]; then
                    exprToOutput="$hookExpr";
                else
                    local hookExprLine;
                    while IFS= read -r hookExprLine; do
                        hookExprLine="${hookExprLine#"${hookExprLine%%[![:space:]]*}"}";
                        if [[ -n "$hookExprLine" ]]; then
                            exprToOutput+="$hookExprLine\\n ";
                        fi;
                    done <<< "$hookExpr";
                    exprToOutput="${exprToOutput%%\\n }";
                fi;
                nixTalkativeLog "evaling '$hookKind' string hook '$exprToOutput'";
            fi;
        fi;
    fi
}
_moveSystemdUserUnits ()
{
 
    if [ "${dontMoveSystemdUserUnits:-0}" = 1 ]; then
        return;
    fi;
    if [ ! -e "${prefix:?}/lib/systemd/user" ]; then
        return;
    fi;
    local source="$prefix/lib/systemd/user";
    local target="$prefix/share/systemd/user";
    echo "moving $source/* to $target";
    mkdir -p "$target";
    ( shopt -s dotglob;
    for i in "$source"/*;
    do
        mv "$i" "$target";
    done );
    rmdir "$source";
    ln -s "$target" "$source"
}
PATH="$PATH${nix_saved_PATH:+:$nix_saved_PATH}"
XDG_DATA_DIRS="$XDG_DATA_DIRS${nix_saved_XDG_DATA_DIRS:+:$nix_saved_XDG_DATA_DIRS}"

eval "${shellHook:-}"
shopt -s expand_aliases

exec /tmp/devenv-envtCMOZO/script 