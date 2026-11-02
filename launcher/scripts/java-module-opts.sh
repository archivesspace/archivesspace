ASPACE_JAVA_MODULE_OPTS="--enable-native-access=ALL-UNNAMED"
if [ "${JAVA_MAJOR:-0}" -ge 23 ]; then
    ASPACE_JAVA_MODULE_OPTS="$ASPACE_JAVA_MODULE_OPTS --sun-misc-unsafe-memory-access=allow"
fi
