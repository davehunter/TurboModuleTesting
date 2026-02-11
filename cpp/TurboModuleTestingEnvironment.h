#ifndef _H_TurboModuleTestingEnvironment_
#define _H_TurboModuleTestingEnvironment_
#include <ReactCommon/CxxTurboModuleUtils.h>
#include <ReactCommon/TurboModuleBinding.h>
#include <hermes/hermes.h>
#include <iostream>
#include <jsi/threadsafe.h>
#include <memory>

class SyncCallInvoker : public facebook::react::CallInvoker {
public:
    SyncCallInvoker(facebook::jsi::Runtime& rt)
        : _rt(rt)
    {
    }
    void invokeAsync(facebook::react::CallFunc&& func) noexcept override
    {
        // For testing purposes, we just invoke the function synchronously
        func(_rt);
    }

    void invokeSync(facebook::react::CallFunc&& func) override
    {
        func(_rt);
    }

private:
    facebook::jsi::Runtime& _rt;
};

class TurboModuleTestingEnvironment {
public:
    TurboModuleTestingEnvironment()
        : _hermesRT(facebook::hermes::makeThreadSafeHermesRuntime())
        , _jsInvoker(std::make_shared<SyncCallInvoker>(_hermesRT->getUnsafeRuntime()))
    {
        setupTurboModuleEnvironment();
    }

    void setupTurboModuleEnvironment()
    {
        auto turboModuleProvider = [this](const std::string& name) -> std::shared_ptr<facebook::react::TurboModule> {
            auto moduleName = name.c_str();

            auto turboModuleLookup = _turboModuleCache.find(moduleName);
            if (turboModuleLookup != _turboModuleCache.end()) {
                return turboModuleLookup->second;
            }

            auto& cxxTurboModuleMapProvider = facebook::react::globalExportedCxxTurboModuleMap();
            auto it = cxxTurboModuleMapProvider.find(moduleName);

            if (it != cxxTurboModuleMapProvider.end()) {
                auto turboModule = it->second(jsInvoker());
                _turboModuleCache.insert({ moduleName, turboModule });
                return turboModule;
            };
            return nullptr;
        };

        facebook::react::TurboModuleBinding::install(
            rt(), std::move(turboModuleProvider));
    }

    facebook::jsi::Runtime& rt()
    {
        return _hermesRT->getUnsafeRuntime();
    }

    std::shared_ptr<facebook::react::CallInvoker> jsInvoker()
    {
        return _jsInvoker;
    }

    facebook::jsi::Value evaluteJavascript(std::string jsCode, std::string jsPath = "placeholder.js")
    {
        std::shared_ptr<facebook::jsi::StringBuffer> strBuffer = std::make_shared<facebook::jsi::StringBuffer>(jsCode);
        std::shared_ptr<facebook::jsi::Buffer> buffer = std::static_pointer_cast<facebook::jsi::Buffer>(strBuffer);
        facebook::jsi::Value result = rt().evaluateJavaScript(buffer, jsPath);
        return result;
    }

private:
    std::unique_ptr<facebook::jsi::ThreadSafeRuntime>
        _hermesRT;
    std::shared_ptr<facebook::react::CallInvoker> _jsInvoker;
    std::unordered_map<std::string, std::shared_ptr<facebook::react::TurboModule>> _turboModuleCache;
};

#endif // _H_TurboModuleTestingEnvironment_