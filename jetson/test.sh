JETSON_ARCH="7.2"
PYENV_PYTHON_VERSION="3.8.10"
OPENPCV_VERSION="4.5.0"
LLVM_VERSION="12.0.1"
LLVM_INSTALL_FOLDER="llvm-12"
POCL_VERSION="release_1_8"
USERNAME="comma"

WORKSPACE="workspace"


cd /data/${WORKSPACE}/

FILE="./clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz1"
if test -f "$FILE"; then
    echo "$FILE exist"
else
    echo "$FILE not exist"
fi

# FILE="./clang+llvm-${LLVM_VERSION}-aarch64-linux-gnu.tar.xz11"
# if [-s "$FILE"];
# then
#     echo "$FILE size 0!!!!"
# else
#     echo "$FILE size not 0!!!!"
# fi

