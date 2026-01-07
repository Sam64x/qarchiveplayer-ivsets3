#pragma once

#include <string_view>
#include <iv_core.h>
#include <sstream>
#include <future>

namespace iv {

class ws_ws {
public:
    ws_ws() {
        iv_core_profile_open(request_, "trackWsServerCmd");
        iv_core_profile_open_cb(answer_, this, &ws_ws::on_answer, "trackWsServerData");
    }
    ~ws_ws() {
        iv_core_profile_close(request_);
        iv_core_profile_close(answer_);
    }
    std::future<std::string> call(std::string_view ip, std::string_view method, std::string_view json, std::string_view sys_params, param_t* user)
    {
        res_ = {};
        req_ = (void*)(intptr_t)++req;
        void* owner = this;
        void* owner_data = req_;

        int timeout = 5;
        int is_local = 0;

        if (ip.empty())
            is_local = 1;

        std::stringstream ss;

        if (sys_params.size())
        {
            ss << "{\"cmd\": \"" << method << "\","
               << "\"ip\": \"" << ip << "\","
               << "\"sys_params\": " << sys_params << ","
               << "\"params\": " << json << "}";
        }
        else
        {
            ss << "{\"cmd\": \"" << method << "\","
               << "\"ip\": \"" << ip << "\","
               << "\"params\": " << json << "}";
        }

        std::string cmd = ss.str();

        param_t p[] = {
                       { PARAM_PCHAR, "cmd", cmd.c_str() },
                       { PARAM_PINT32, "timeout", &timeout },
                       { PARAM_PINT32, "is_local", &is_local },
                       { PARAM_PVOID, "owner", owner },
                       { PARAM_PVOID, "owner_data", owner_data },
                       { PARAM_CONFIG, "user", user },
                       { PARAM_NONE, 0, 0 },
                       };
        int e = iv_core_profile_data(request_, p);
        return res_.get_future();
    }
    static void on_answer(const void* context, const param_t* p)
    {
        ws_ws* ctx = (ws_ws*)context;
        if (!ctx)
            return;

        const char* json = NULL;
        void* owner = NULL;
        void* owner_data = NULL;

        for (each_param(p))
        {
            param_start;
            param_get_pchar(json);
            param_get_pvoid(owner);
            param_get_pvoid(owner_data);
        }

        if (owner != ctx)
            return;
        if (owner_data != ctx->req_)
            return;

        if (json)
            ctx->res_.set_value(json);
    }
private:
    profile_t request_ = nullptr;
    profile_t answer_ = nullptr;
    void* req_ = nullptr;
    std::promise<std::string> res_;
    uint64_t req = 0;


};

}
