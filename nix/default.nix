{
  lib,
  python3Packages,
  makeWrapper,
  python3,
  ...
}: let
  pname = "pi_air_quality_monitor";
  version = "0.0.1";
in
  python3Packages.buildPythonApplication {
    inherit pname version;
    format = "other";

    src = ../src;

    pythonPath = with python3Packages; [
      pyserial
      flask
      redis
      ipython
      apscheduler
      flask-cors
      (
        buildPythonPackage rec {
          pname = "python-aqi";
          version = "0.6.1";
          src = fetchPypi {
            inherit pname version;
            hash = "sha256-FBoDoP7UiIDchwbKV7A/MPqRq2DpMwR0v5yaj7m5YCA=";
          };
        }
      )
    ];

    nativeBuildInputs = [makeWrapper];
    installFlags = ["prefix=$(out/bin)"];

    postUnpack = ''
      mkdir -p $out/bin
      cp -rvf $src/* $out
    '';

    preFixup = ''
      buildPythonPath "$pythonPath"
      gappsWrapperArgs+=(
        --prefix PYTHONPATH : "$program_PYTHONPATH"
      )
      makeWrapper ${lib.getExe python3} $out/bin/${pname} \
          --add-flags $out/app.py \
          --prefix PYTHONPATH : "$program_PYTHONPATH" \
          --chdir $out/bin
    '';

    meta = {
      description = "An air quality monitoring service with a Raspberry Pi and a SDS011 sensor. ";
      homepage = "https://github.com/rydercalmdown/pi_air_quality_monitor";
      mainProgram = pname;
      platforms = ["aarch64-linux" "x86_64-linux"];
      maintainers = with lib.maintainers; [NotAShelf];
    };
  }
