set(HOST_APP_PATH "")
set(NODE_MODULES_PATH "")
set(REACT_COMMON_DIR "")

# TurboModuleTesting_ConfigureBasedOnApp
# Configures the TurboModuleTesting target based on the provided app path. This includes setting up include directories, linking necessary libraries, and configuring paths to Hermes and React Native dependencies.
# Parameters:
#   app_path: The file system path to the host application. This is used to derive paths to node_modules, Pods, and generated code.
#   node_modules_path: (Optional) The file system path to the node_modules directory. If not provided, it will be derived from the app_path.

function (TurboModuleTesting_ConfigureBasedOnApp app_path)
    if(NOT APPLE)
        message(FATAL_ERROR "🛑 TurboModuleTesting_ConfigureBasedOnApp only supports macOS")
    endif()
    
    message(STATUS "⚛️🚀 TurboModuleTesting_ConfigureBasedOnApp: ${app_path}")

    set(HOST_APP_PATH "${app_path}")
    set(HOST_APP_PATH "${app_path}" PARENT_SCOPE)
    set(_configured_node_modules_path "${HOST_APP_PATH}/node_modules")
    if(ARGC GREATER 1)
      set(_configured_node_modules_path "${ARGV1}")
      message(STATUS "⚛️🚀 TurboModuleTesting_ConfigureBasedOnApp node modules: ${_configured_node_modules_path}")
    endif()
    set(NODE_MODULES_PATH "${_configured_node_modules_path}")
    set(NODE_MODULES_PATH "${_configured_node_modules_path}" PARENT_SCOPE)
    set(HOST_APP_PODS_ROOT "${HOST_APP_PATH}/ios/Pods")
    set(HOST_APP_PODS_ROOT "${HOST_APP_PATH}/ios/Pods" PARENT_SCOPE)
    set(HERMES_BASE_PATH "${HOST_APP_PODS_ROOT}/hermes-engine/destroot")
    set(HERMES_BASE_PATH "${HOST_APP_PODS_ROOT}/hermes-engine/destroot" PARENT_SCOPE)
    set(HERMES_FRAMEWORK_PATH "${HERMES_BASE_PATH}/Library/Frameworks/macosx/hermesvm.framework")
    if(NOT EXISTS "${HERMES_FRAMEWORK_PATH}")
      set(HERMES_FRAMEWORK_PATH "${HERMES_BASE_PATH}/Library/Frameworks/macosx/hermes.framework")
    endif()
    if(NOT EXISTS "${HERMES_FRAMEWORK_PATH}")
      message(FATAL_ERROR "🛑 Unable to find Hermes framework at ${HERMES_BASE_PATH}/Library/Frameworks/macosx (expected hermesvm.framework or hermes.framework)")
    endif()
    set(HERMES_FRAMEWORK_PATH "${HERMES_FRAMEWORK_PATH}" PARENT_SCOPE)
    set(HERMES_INCLUDE_PATH "${HERMES_BASE_PATH}/include")
    set(HERMES_INCLUDE_PATH "${HERMES_BASE_PATH}/include" PARENT_SCOPE)
    set(REACT_COMMON_DIR "${NODE_MODULES_PATH}/react-native/ReactCommon")
    set(REACT_COMMON_DIR "${NODE_MODULES_PATH}/react-native/ReactCommon" PARENT_SCOPE)

    # Parse the host app's installed React Native version from its package.json
    # so we can emit compile-time guards for code paths that differ across RN
    # versions (e.g. TurboModuleBinding::install signature change in 0.84).
    set(RN_PKG_JSON "${NODE_MODULES_PATH}/react-native/package.json")
    set(TMT_RN_VERSION_MAJOR 0)
    set(TMT_RN_VERSION_MINOR 0)
    set(TMT_RN_VERSION_PATCH 0)
    if(EXISTS "${RN_PKG_JSON}")
      file(READ "${RN_PKG_JSON}" _rn_pkg_contents)
      string(JSON _rn_version GET "${_rn_pkg_contents}" version)
      if(_rn_version MATCHES "^([0-9]+)\\.([0-9]+)\\.([0-9]+)")
        set(TMT_RN_VERSION_MAJOR ${CMAKE_MATCH_1})
        set(TMT_RN_VERSION_MINOR ${CMAKE_MATCH_2})
        set(TMT_RN_VERSION_PATCH ${CMAKE_MATCH_3})
      endif()
    endif()
    set(TMT_RN_VERSION_MAJOR ${TMT_RN_VERSION_MAJOR} PARENT_SCOPE)
    set(TMT_RN_VERSION_MINOR ${TMT_RN_VERSION_MINOR} PARENT_SCOPE)
    set(TMT_RN_VERSION_PATCH ${TMT_RN_VERSION_PATCH} PARENT_SCOPE)
    message(STATUS "⚛️🚀 React Native version: ${TMT_RN_VERSION_MAJOR}.${TMT_RN_VERSION_MINOR}.${TMT_RN_VERSION_PATCH}")

    # CODEGEN_BASE_PATH can change depending on RN version.  Assume RN 0.84, and fall back to a more general path if the 0.84 one doesn't exist.
    set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios/ReactCodegen")
    set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios/ReactCodegen" PARENT_SCOPE)
    if(NOT EXISTS "${CODEGEN_BASE_PATH}")
      set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios")
      set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios" PARENT_SCOPE)
    endif()

    # `react-native-platform-selector.cmake` was introduced in RN 0.81; it
    # defines `react_native_android_selector` which 0.81+ hermes/* CMakeLists
    # call. RN 0.80 doesn't ship the file and doesn't reference the function,
    # so skip the include when the file isn't present.
    set(_RN_PLATFORM_SELECTOR "${REACT_COMMON_DIR}/cmake-utils/internal/react-native-platform-selector.cmake")
    if(EXISTS "${_RN_PLATFORM_SELECTOR}")
      include("${_RN_PLATFORM_SELECTOR}")
    endif()

    add_subdirectory("${REACT_COMMON_DIR}/callinvoker" "${CMAKE_BINARY_DIR}/callinvoker")
    add_subdirectory("${REACT_COMMON_DIR}/reactperflogger" "${CMAKE_BINARY_DIR}/reactperflogger")
    add_subdirectory("${REACT_COMMON_DIR}/logger" "${CMAKE_BINARY_DIR}/logger")
    add_subdirectory("${REACT_COMMON_DIR}/react/timing" "${CMAKE_BINARY_DIR}/react_timing")
    add_subdirectory("${REACT_COMMON_DIR}/react/bridging" "${CMAKE_BINARY_DIR}/react_bridging")
    add_subdirectory("${REACT_COMMON_DIR}/react/debug" "${CMAKE_BINARY_DIR}/react_debug")
    add_subdirectory("${REACT_COMMON_DIR}/react/featureflags" "${CMAKE_BINARY_DIR}/react_featureflags")
    add_subdirectory("${REACT_COMMON_DIR}/react/utils" "${CMAKE_BINARY_DIR}/react_utils")
    add_library(jsinspector INTERFACE)
    target_include_directories(jsinspector INTERFACE "${REACT_COMMON_DIR}")
    add_subdirectory("${REACT_COMMON_DIR}/runtimeexecutor" "${CMAKE_BINARY_DIR}/runtimeexecutor")
    # RN 0.80's runtimeexecutor/ is header-only (`RuntimeExecutor.h` only); the
    # OBJECT library has no source from which CMake can infer a linker
    # language, so the Generate step fails. Setting LINKER_LANGUAGE explicitly
    # is a no-op for 0.81+ (which has .cpp files) and unblocks 0.80.
    if(TARGET runtimeexecutor)
      set_target_properties(runtimeexecutor PROPERTIES LINKER_LANGUAGE CXX)
    endif()
    add_subdirectory("${REACT_COMMON_DIR}/react/nativemodule/core" "${CMAKE_BINARY_DIR}/react_nativemodule_core")
    add_subdirectory("${REACT_COMMON_DIR}/cxxreact" "${CMAKE_BINARY_DIR}/cxxreact")
    # RN 0.85+ moved JSRuntimeBindings (referenced by jsiexecutor) into a new
    # `jsitooling` subdirectory. It must be added before jsiexecutor so the
    # include paths and target are available.
    if(EXISTS "${REACT_COMMON_DIR}/jsitooling/CMakeLists.txt")
      add_subdirectory("${REACT_COMMON_DIR}/jsitooling" "${CMAKE_BINARY_DIR}/jsitooling")
    endif()
    add_subdirectory("${REACT_COMMON_DIR}/jsiexecutor" "${CMAKE_BINARY_DIR}/jsiexecutor")

    set(RN_TARGETS
        logger
        reactperflogger
        react_utils
        react_debug
        react_bridging
        react_featureflags
        react_timing
        react_nativemodule_core
        react_cxxreact
        jsireact
        runtimeexecutor
    )
    if(TARGET jsitooling)
      list(APPEND RN_TARGETS jsitooling)
    endif()

    # RN 0.80's per-subdir CMakeLists glob `platform/android/.../*.cpp`
    # unconditionally; the android+cxx selector pattern that gates those was
    # introduced in 0.81. On 0.80, strip android-only sources from every RN
    # target so the macOS build doesn't try to compile JNI / pthread_setname_np
    # / fbjni-using translation units. Where a platform/cxx variant of a header
    # exists, add its include path so consumers can still resolve the
    # interface (e.g. react/utils/LowPriorityExecutor.h).
    if(TMT_RN_VERSION_MINOR LESS 81)
      foreach(_tgt IN LISTS RN_TARGETS)
        if(TARGET ${_tgt})
          get_target_property(_srcs ${_tgt} SOURCES)
          if(_srcs)
            list(FILTER _srcs EXCLUDE REGEX "platform/android/.*\\.cpp$")
            set_target_properties(${_tgt} PROPERTIES SOURCES "${_srcs}")
          endif()
        endif()
      endforeach()
      if(TARGET react_utils AND EXISTS "${REACT_COMMON_DIR}/react/utils/platform/cxx")
        target_include_directories(react_utils PUBLIC
          "${REACT_COMMON_DIR}/react/utils/platform/cxx")
      endif()
    endif()

    foreach(rn_target IN LISTS RN_TARGETS)
        if(TARGET ${rn_target})
        ApplyAppleReactNativeSettings(${rn_target})
        LinkInHermes(${rn_target})
        endif()
    endforeach()

    set(POD_HEADERS_PATH "${HOST_APP_PODS_ROOT}/Headers/Public")

    target_include_directories(TurboModuleTesting PUBLIC
      "${POD_HEADERS_PATH}/RCTRequired"
      "${POD_HEADERS_PATH}/RCTTypeSafety"
      "${POD_HEADERS_PATH}/FBLazyVector"
      "${POD_HEADERS_PATH}/React-Core"
    )

    LinkInHermes(TurboModuleTesting)
    target_link_libraries(TurboModuleTesting glog_stub react_utils react_bridging)

    # Surface RN version to translation units that include TurboModuleTesting headers
    # (e.g. TurboModuleTestingEnvironment.h, which selects an install() overload
    # based on the deprecation introduced in RN 0.84).
    target_compile_definitions(TurboModuleTesting PUBLIC
      TMT_RN_VERSION_MAJOR=${TMT_RN_VERSION_MAJOR}
      TMT_RN_VERSION_MINOR=${TMT_RN_VERSION_MINOR}
      TMT_RN_VERSION_PATCH=${TMT_RN_VERSION_PATCH}
    )

    # INTERFACE stubs satisfy unconditional target_link_libraries(... fbjni ...)
    # calls that RN's own CMakeLists make. fbjni / reactnativejni / log are
    # android-only; we strip the android sources that would have referenced
    # their symbols, so the link line becomes harmless when these are stubs.
    foreach(rn_stub_lib IN ITEMS folly_runtime glog glog_init boost jsi
                                 fbjni reactnativejni log)
      if(NOT TARGET ${rn_stub_lib})
        add_library(${rn_stub_lib} INTERFACE)
      endif()
    endforeach()

    set(IS_TURBOMODULE_TESTING_CONFIGURED TRUE PARENT_SCOPE)
endfunction()

function(AddTurboModuleJSI targetName turboModuleName)
  # Rudely use the generated JSI files from the HostApp's build
  set(JSI_GENERATED_HEADER "${CODEGEN_BASE_PATH}/${turboModuleName}JSI.h")
  set(JSI_GENERATED_CPP "${CODEGEN_BASE_PATH}/${turboModuleName}JSI-generated.cpp")

  list(APPEND JSI_GENERATED_SOURCES "${JSI_GENERATED_HEADER}")
  if(EXISTS "${JSI_GENERATED_CPP}")
    list(APPEND JSI_GENERATED_SOURCES "${JSI_GENERATED_CPP}")
  endif()

  target_sources(${targetName} PUBLIC ${JSI_GENERATED_SOURCES})
  target_include_directories(${targetName} PUBLIC
    "${CODEGEN_BASE_PATH}"
  )
endfunction()

function(ApplyAppleReactNativeSettings targetName)
  set(FOLLY_ROOT "${HOST_APP_PODS_ROOT}/RCT-Folly")
  set(GLOG_ROOT "${HOST_APP_PODS_ROOT}/glog/src")
  set(BOOST_ROOT "${HOST_APP_PODS_ROOT}/boost")
  set(FMT_ROOT "${HOST_APP_PODS_ROOT}/fmt/include")
  set(DOUBLE_CONVERSION_ROOT "${HOST_APP_PODS_ROOT}/DoubleConversion")
  set(FAST_FLOAT_ROOT "${HOST_APP_PODS_ROOT}/fast_float/include")

  # RN 0.81.5+ (for example with Expo) ships third-party headers under
  # Pods/ReactNativeDependencies/Headers instead of individual pod folders.
  set(RN_DEP_HEADERS_ROOT "${HOST_APP_PODS_ROOT}/ReactNativeDependencies/Headers")
  if(EXISTS "${RN_DEP_HEADERS_ROOT}")
    set(FOLLY_ROOT "${RN_DEP_HEADERS_ROOT}")
    set(GLOG_ROOT "${RN_DEP_HEADERS_ROOT}")
    set(BOOST_ROOT "${RN_DEP_HEADERS_ROOT}")
    set(FMT_ROOT "${RN_DEP_HEADERS_ROOT}")
    set(DOUBLE_CONVERSION_ROOT "${RN_DEP_HEADERS_ROOT}")
    set(FAST_FLOAT_ROOT "${RN_DEP_HEADERS_ROOT}")
  endif()

  set(THIRD_PARTY_INCLUDE_DIRS)
  foreach(include_dir IN ITEMS
    "${FOLLY_ROOT}"
    "${GLOG_ROOT}"
    "${BOOST_ROOT}"
    "${FMT_ROOT}"
    "${DOUBLE_CONVERSION_ROOT}"
    "${FAST_FLOAT_ROOT}"
  )
    if(EXISTS "${include_dir}")
      list(APPEND THIRD_PARTY_INCLUDE_DIRS "${include_dir}")
    endif()
  endforeach()
  set(REACT_COMMON_INCLUDE_DIRS
    "${REACT_COMMON_DIR}"
    "${REACT_COMMON_DIR}/callinvoker"
    "${REACT_COMMON_DIR}/reactperflogger"
    "${REACT_COMMON_DIR}/logger"
    "${REACT_COMMON_DIR}/react"
    "${REACT_COMMON_DIR}/react/timing"
    "${REACT_COMMON_DIR}/react/bridging"
    "${REACT_COMMON_DIR}/react/debug"
    "${REACT_COMMON_DIR}/react/featureflags"
    "${REACT_COMMON_DIR}/react/utils"
    "${REACT_COMMON_DIR}/react/nativemodule/core"
  )
  # RN 0.85+ ships <react/runtime/JSRuntimeBindings.h> via jsitooling/.
  if(EXISTS "${REACT_COMMON_DIR}/jsitooling")
    list(APPEND REACT_COMMON_INCLUDE_DIRS "${REACT_COMMON_DIR}/jsitooling")
  endif()

  get_target_property(rn_target_type ${targetName} TYPE)
  if(rn_target_type STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(${targetName} INTERFACE
      ${REACT_COMMON_INCLUDE_DIRS}
      ${THIRD_PARTY_INCLUDE_DIRS}
    )
    target_compile_definitions(${targetName} INTERFACE FOLLY_CFG_NO_COROUTINES=1)
  else()
    target_include_directories(${targetName} PUBLIC
      ${REACT_COMMON_INCLUDE_DIRS}
      ${THIRD_PARTY_INCLUDE_DIRS}
    )
    target_compile_definitions(${targetName} PUBLIC FOLLY_CFG_NO_COROUTINES=1)
  endif()
endfunction()

function(LinkInHermes targetName)
  get_target_property(rn_target_type ${targetName} TYPE)
  if(rn_target_type STREQUAL "INTERFACE_LIBRARY")
    target_link_libraries(${targetName} INTERFACE
      "${HERMES_FRAMEWORK_PATH}"
    )
    target_include_directories(${targetName} INTERFACE
      "${HERMES_INCLUDE_PATH}"
    )
  else()
    target_link_libraries(${targetName}
      "${HERMES_FRAMEWORK_PATH}"
    )
    target_include_directories(${targetName} PRIVATE
      "${HERMES_INCLUDE_PATH}"
    )
  endif()
endfunction()

function (TurboModuleTesting_AddTurboModuleDependencies target turboModuleName)
    if(NOT IS_TURBOMODULE_TESTING_CONFIGURED)
        message(FATAL_ERROR "⚛️🚀 TurboModuleTesting_AddTurboModuleDependencies: TurboModuleTesting_ConfigureBasedOnApp must be called before adding dependencies.")
    endif()
    message(STATUS "⚛️🚀 TurboModuleTesting_AddTurboModuleDependencies: ${target} turboModuleName: ${turboModuleName}")

    target_include_directories(${target} PUBLIC "${CODEGEN_BASE_PATH}")

    ApplyAppleReactNativeSettings(${target})
    LinkInHermes(${target})
    target_link_libraries(${target} react_nativemodule_core)
    AddTurboModuleJSI(${target} "${turboModuleName}")

    target_link_libraries(${target} TurboModuleTesting)
endfunction()
