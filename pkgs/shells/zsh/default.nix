{ lib
, stdenv
, fetchurl
, fetchpatch
, autoreconfHook
, yodl
, perl
, groff
, util-linux
, texinfo
, ncurses
, pcre
, buildPackages }:

let
  version = "5.9";
in

stdenv.mkDerivation {
  pname = "zsh";
  inherit version;
  outputs = [ "out" "doc" "info" "man" ];

  src = fetchurl {
    url = "mirror://sourceforge/zsh/zsh-${version}.tar.xz";
    sha256 = "sha256-m40ezt1bXoH78ZGOh2dSp92UjgXBoNuhCrhjhC1FrNU=";
  };

  patches = [
    # fix location of timezone data for TZ= completion
    ./tz_completion.patch
  ];

  strictDeps = true;
  nativeBuildInputs = [ autoreconfHook perl groff texinfo pcre]
                      ++ lib.optionals stdenv.isLinux [ util-linux yodl ];

  buildInputs = [ ncurses pcre ];

  configureFlags = [
    "--enable-maildir-support"
    "--enable-multibyte"
    "--with-tcsetpgrp"
    "--enable-pcre"
    "--enable-zprofile=${placeholder "out"}/etc/zprofile"
    "--disable-site-fndir"
  ] ++ lib.optional (stdenv.hostPlatform != stdenv.buildPlatform && !stdenv.hostPlatform.isStatic) [
    # Also see: https://github.com/buildroot/buildroot/commit/2f32e668aa880c2d4a2cce6c789b7ca7ed6221ba
    "zsh_cv_shared_environ=yes"
    "zsh_cv_shared_tgetent=yes"
    "zsh_cv_shared_tigetstr=yes"
    "zsh_cv_sys_dynamic_clash_ok=yes"
    "zsh_cv_sys_dynamic_rtld_global=yes"
    "zsh_cv_sys_dynamic_execsyms=yes"
    "zsh_cv_sys_dynamic_strip_exe=yes"
    "zsh_cv_sys_dynamic_strip_lib=yes"
  ];

  # the zsh/zpty module is not available on hydra
  # so skip groups Y Z
  checkFlags = map (T: "TESTNUM=${T}") (lib.stringToCharacters "ABCDEVW");

  # XXX: think/discuss about this, also with respect to nixos vs nix-on-X
  postInstall = ''
    make install.info install.html
    mkdir -p $out/etc/
    cat > $out/etc/zprofile <<EOF
if test -e /etc/NIXOS; then
  if test -r /etc/zprofile; then
    . /etc/zprofile
  else
    emulate bash
    alias shopt=false
    . /etc/profile
    unalias shopt
    emulate zsh
  fi
  if test -r /etc/zprofile.local; then
    . /etc/zprofile.local
  fi
else
  # on non-nixos we just source the global /etc/zprofile as if we did
  # not use the configure flag
  if test -r /etc/zprofile; then
    . /etc/zprofile
  fi
fi
EOF
    ${if stdenv.hostPlatform == stdenv.buildPlatform then ''
      $out/bin/zsh -c "zcompile $out/etc/zprofile"
    '' else ''
      ${lib.getBin buildPackages.zsh}/bin/zsh -c "zcompile $out/etc/zprofile"
    ''}
    mv $out/etc/zprofile $out/etc/zprofile_zwc_is_used

    rm $out/bin/zsh-${version}
    mkdir -p $out/share/doc/
    mv $out/share/zsh/htmldoc $out/share/doc/zsh-$version
  '';
  # XXX: patch zsh to take zwc if newer _or equal_

  meta = {
    description = "The Z shell";
    longDescription = ''
      Zsh is a UNIX command interpreter (shell) usable as an interactive login
      shell and as a shell script command processor.  Of the standard shells,
      zsh most closely resembles ksh but includes many enhancements.  Zsh has
      command line editing, builtin spelling correction, programmable command
      completion, shell functions (with autoloading), a history mechanism, and
      a host of other features.
    '';
    license = "MIT-like";
    homepage = "https://www.zsh.org/";
    maintainers = with lib.maintainers; [ pSub artturin ];
    platforms = lib.platforms.unix;
  };

  passthru = {
    shellPath = "/bin/zsh";
  };
}
