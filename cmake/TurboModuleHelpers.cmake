set(HOST_APP_PATH "")
set(REACT_COMMON_DIR "")

function (TurboModuleTesting_ConfigureBasedOnApp app_path)
    message(STATUS "⚛️🚀 TurboModuleTesting_ConfigureBasedOnApp: ${app_path}")

    set(HOST_APP_PATH "${app_path}")
    set(HOST_APP_PATH "${app_path}" PARENT_SCOPE)
    set(HOST_APP_PODS_ROOT "${HOST_APP_PATH}/ios/Pods")
    set(HOST_APP_PODS_ROOT "${HOST_APP_PATH}/ios/Pods" PARENT_SCOPE)
    set(HERMES_BASE_PATH "${HOST_APP_PODS_ROOT}/hermes-engine/destroot")
    set(HERMES_BASE_PATH "${HOST_APP_PODS_ROOT}/hermes-engine/destroot" PARENT_SCOPE)
    set(HERMES_FRAMEWORK_PATH "${HERMES_BASE_PATH}/Library/Frameworks/macosx/hermesvm.framework")
    set(HERMES_FRAMEWORK_PATH "${HERMES_BASE_PATH}/Library/Frameworks/macosx/hermesvm.framework" PARENT_SCOPE)
    set(HERMES_INCLUDE_PATH "${HERMES_BASE_PATH}/include")
    set(HERMES_INCLUDE_PATH "${HERMES_BASE_PATH}/include" PARENT_SCOPE)
    set(REACT_COMMON_DIR "${HOST_APP_PATH}/node_modules/react-native/ReactCommon")
    set(REACT_COMMON_DIR "${HOST_APP_PATH}/node_modules/react-native/ReactCommon" PARENT_SCOPE)
    set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios/ReactCodegen")
    set(CODEGEN_BASE_PATH "${HOST_APP_PATH}/ios/build/generated/ios/ReactCodegen" PARENT_SCOPE)

    include("${REACT_COMMON_DIR}/cmake-utils/internal/react-native-platform-selector.cmake")

    add_subdirectory("${REACT_COMMON_DIR}/callinvoker")
    add_subdirectory("${REACT_COMMON_DIR}/reactperflogger")
    add_subdirectory("${REACT_COMMON_DIR}/logger")
    add_subdirectory("${REACT_COMMON_DIR}/react/timing")
    add_subdirectory("${REACT_COMMON_DIR}/react/bridging")
    add_subdirectory("${REACT_COMMON_DIR}/react/debug")
    add_subdirectory("${REACT_COMMON_DIR}/react/featureflags")
    add_subdirectory("${REACT_COMMON_DIR}/react/utils")
    if(ANDROID)
        add_subdirectory("${REACT_COMMON_DIR}/jsinspector-modern")
    else()
        add_library(jsinspector INTERFACE)
        target_include_directories(jsinspector INTERFACE "${REACT_COMMON_DIR}")
    endif()
    add_subdirectory("${REACT_COMMON_DIR}/runtimeexecutor")
    add_subdirectory("${REACT_COMMON_DIR}/react/nativemodule/core")
    add_subdirectory("${REACT_COMMON_DIR}/cxxreact")

    if(NOT ANDROID)
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
        runtimeexecutor
    )

    foreach(rn_target IN LISTS RN_TARGETS)
        if(TARGET ${rn_target})
        ApplyAppleReactNativeSettings(${rn_target})
        LinkInHermes(${rn_target})
        endif()
    endforeach()
    endif()

    set(POD_HEADERS_PATH "${HOST_APP_PODS_ROOT}/Headers/Public")

    target_include_directories(TurboModuleTesting PUBLIC
      "${POD_HEADERS_PATH}/RCTRequired"
      "${POD_HEADERS_PATH}/RCTTypeSafety"
      "${POD_HEADERS_PATH}/FBLazyVector"
      "${POD_HEADERS_PATH}/React-Core"
    )

    LinkInHermes(TurboModuleTesting)
    target_link_libraries(TurboModuleTesting glog_stub react_utils react_bridging)
    # end from this cpp folder

    foreach(rn_stub_lib IN ITEMS folly_runtime glog glog_init boost jsi)
      if(NOT TARGET ${rn_stub_lib})
        add_library(${rn_stub_lib} INTERFACE)
      endif()
    endforeach()

    set(IS_TURBOMODULE_TESTING_CONFIGURED TRUE PARENT_SCOPE)
endfunction()

function(AddTurboModuleJSI targetName turboModuleName)
  # Ruedely use the generated JSI files from the HostApp's build
  list(APPEND JSI_GENERATED_SOURCES
    "${CODEGEN_BASE_PATH}/${turboModuleName}JSI.h"
  )

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

  get_target_property(rn_target_type ${targetName} TYPE)
  if(rn_target_type STREQUAL "INTERFACE_LIBRARY")
    target_include_directories(${targetName} INTERFACE
      ${REACT_COMMON_INCLUDE_DIRS}
      "${FOLLY_ROOT}"
      "${GLOG_ROOT}"
      "${BOOST_ROOT}"
      "${FMT_ROOT}"
      "${DOUBLE_CONVERSION_ROOT}"
      "${FAST_FLOAT_ROOT}"
    )
    target_compile_definitions(${targetName} INTERFACE FOLLY_CFG_NO_COROUTINES=1)
  else()
    target_include_directories(${targetName} PUBLIC
      ${REACT_COMMON_INCLUDE_DIRS}
      "${FOLLY_ROOT}"
      "${GLOG_ROOT}"
      "${BOOST_ROOT}"
      "${FMT_ROOT}"
      "${DOUBLE_CONVERSION_ROOT}"
      "${FAST_FLOAT_ROOT}"
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
    AddTurboModuleJSI(TurboModuleTesting "${turboModuleName}")

    target_link_libraries(${target} TurboModuleTesting)
endfunction()
