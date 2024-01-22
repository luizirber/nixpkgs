{ lib
, fetchPypi
, buildPythonPackage
, pythonOlder
, rustPlatform
, bitstring
, cachetools
, cffi
, deprecation
, iconv
, matplotlib
, numpy
, scipy
, screed
, hypothesis
, pytest-xdist
, pyyaml
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "sourmash";
  version = "4.8.5";
  format = "pyproject";
  disabled = pythonOlder "3.9";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-kBbDONawHxUtLHvs9WMQALBY/2V/T8UNqm7xU3PYoCo=";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    name = "${pname}-${version}";
    hash = "sha256-mL1YqAh0R+6hoKtrUNd3cNuVtDF8/MicYKWiP1RPh48=";
  };

  nativeBuildInputs = with rustPlatform; [
    cargoSetupHook
    maturinBuildHook
    bindgenHook
  ];

  buildInputs = [ iconv ];

  propagatedBuildInputs = [
    bitstring
    cachetools
    cffi
    deprecation
    matplotlib
    numpy
    scipy
    screed
  ];

  pythonImportsCheck = [ "sourmash" ];
  nativeCheckInputs = [
    hypothesis
    pytest-xdist
    pytestCheckHook
    pyyaml
  ];

  # TODO(luizirber): Working on fixing these upstream
  disabledTests = [
    "test_compare_no_such_file"
    "test_do_sourmash_index_multiscaled_rescale_fail"
    "test_metagenome_kreport_out_fail"
  ];

  meta = with lib; {
    description = "Quickly search, compare, and analyze genomic and metagenomic data sets";
    homepage = "https://sourmash.bio";
    changelog = "https://github.com/sourmash-bio/sourmash/releases/tag/v${version}";
    maintainers = with maintainers; [ luizirber ];
    license = licenses.bsd3;
  };
}
